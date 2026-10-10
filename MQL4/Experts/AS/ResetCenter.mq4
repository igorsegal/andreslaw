#property strict

input int BarsToScan = 500;

double SR_R(int shift)
{
   ResetLastError();
   return iCustom(NULL,PERIOD_H1,"SWTsr",true,false,34,shift);
}

double SR_S(int shift)
{
   ResetLastError();
   return iCustom(NULL,PERIOD_H1,"SWTsr",true,false,35,shift);
}

double SR_CL(int shift)
{
   ResetLastError();
   return iCustom(NULL,PERIOD_H1,"SWTsr",true,false,42,shift);
}

double CH_CL(int shift)
{
   ResetLastError();
   return iCustom(
      NULL,PERIOD_H1,"SWTch",
      false,   // W2_CH
      false,   // W3_SR
      true,    // W4_SR
      false,   // ShowCenterLine
      20,shift
   );
}

bool Valid(double v)
{
   return(v!=EMPTY_VALUE && MathIsValidNumber(v) && v>0.0);
}

bool PairValid(double r,double s)
{
   return(Valid(r) && Valid(s) && r>s);
}

bool LevelChanged(double a,double b)
{
   return(MathAbs(a-b)>Point*0.1);
}

bool ResetAt(int shift)
{
   if(shift<1 || shift>=Bars-1)
      return false;

   double oldR=SR_R(shift+1);
   double oldS=SR_S(shift+1);
   double newR=SR_R(shift);
   double newS=SR_S(shift);

   if(!PairValid(oldR,oldS) || !PairValid(newR,newS))
      return false;

   return(LevelChanged(oldR,newR) || LevelChanged(oldS,newS));
}

void AddMetric(
   double errPts,
   int &n,
   double &sum,
   double &mx,
   int &e01,
   int &e1,
   int &e5)
{
   n++;
   sum+=errPts;
   if(errPts>mx) mx=errPts;
   if(errPts<=0.1) e01++;
   if(errPts<=1.0) e1++;
   if(errPts<=5.0) e5++;
}

void PrintMetric(
   string tag,
   int n,
   double sum,
   double mx,
   int e01,
   int e1,
   int e5)
{
   Print(
      "[AS][RESET_CENTER] ",tag,
      " n=",n,
      " <=0.1pt=",e01,
      " <=1pt=",e1,
      " <=5pt=",e5,
      " meanErrPts=",DoubleToString(n>0 ? sum/n : 0.0,3),
      " maxErrPts=",DoubleToString(mx,3)
   );
}

void Analyze()
{
   int bars=MathMin(BarsToScan,Bars-3);

   int resetCount=0;

   int nAll=0,eAll01=0,eAll1=0,eAll5=0;
   double sAll=0.0,mAll=0.0;

   int nReset=0,eReset01=0,eReset1=0,eReset5=0;
   double sReset=0.0,mReset=0.0;

   int nLag=0,eLag01=0,eLag1=0,eLag5=0;
   double sLag=0.0,mLag=0.0;

   int nMid=0,eMid01=0,eMid1=0,eMid5=0;
   double sMid=0.0,mMid=0.0;

   for(int sh=bars; sh>=1; sh--)
   {
      double srcl=SR_CL(sh);
      double chcl=CH_CL(sh);

      if(Valid(srcl) && Valid(chcl))
      {
         double err=MathAbs(srcl-chcl)/Point;
         AddMetric(err,nAll,sAll,mAll,eAll01,eAll1,eAll5);
      }

      double r=SR_R(sh);
      double s=SR_S(sh);

      if(PairValid(r,s) && Valid(srcl))
      {
         double mid=(r+s)/2.0;
         double errMid=MathAbs(srcl-mid)/Point;
         AddMetric(errMid,nMid,sMid,mMid,eMid01,eMid1,eMid5);
      }

      if(!ResetAt(sh))
         continue;

      resetCount++;

      if(Valid(srcl) && Valid(chcl))
      {
         double errReset=MathAbs(srcl-chcl)/Point;
         AddMetric(errReset,nReset,sReset,mReset,eReset01,eReset1,eReset5);
      }

      double chclOld=CH_CL(sh+1);

      if(Valid(srcl) && Valid(chclOld))
      {
         double errLag=MathAbs(srcl-chclOld)/Point;
         AddMetric(errLag,nLag,sLag,mLag,eLag01,eLag1,eLag5);
      }

      Print(
         "[AS][RESET_CENTER] EVENT",
         " time=",TimeToString(iTime(NULL,PERIOD_H1,sh),TIME_DATE|TIME_MINUTES),
         " srCL=",DoubleToString(srcl,Digits),
         " chCL=",DoubleToString(chcl,Digits),
         " chCL_old=",DoubleToString(chclOld,Digits)
      );
   }

   Print(
      "[AS][RESET_CENTER] SUMMARY",
      " bars=",bars,
      " resets=",resetCount
   );

   PrintMetric("SRCL_EQ_CHCL_ALL",nAll,sAll,mAll,eAll01,eAll1,eAll5);
   PrintMetric("SRCL_EQ_CHCL_RESET",nReset,sReset,mReset,eReset01,eReset1,eReset5);
   PrintMetric("SRCL_EQ_CHCL_OLD_AT_RESET",nLag,sLag,mLag,eLag01,eLag1,eLag5);
   PrintMetric("SRCL_EQ_MID_RS_ALL",nMid,sMid,mMid,eMid01,eMid1,eMid5);

   Print("[AS][RESET_CENTER] DONE");
}

int OnInit()
{
   Print("[AS][RESET_CENTER] INIT bars=",BarsToScan);

   for(int sh=1; sh<=BarsToScan+3; sh++)
   {
      SR_R(sh);
      SR_S(sh);
      SR_CL(sh);
      CH_CL(sh);
   }

   Analyze();
   return(INIT_SUCCEEDED);
}

void OnTick()
{
}
