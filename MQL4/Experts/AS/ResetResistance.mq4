#property strict

input int BarsToScan = 500;

double SWT(int mode,int shift)
{
   ResetLastError();
   return iCustom(NULL,PERIOD_H1,"SWTsr",true,false,mode,shift);
}

double R(int shift)  { return SWT(34,shift); }
double S(int shift)  { return SWT(35,shift); }
double CL(int shift) { return SWT(42,shift); }

bool Valid(double v)
{
   return(v!=EMPTY_VALUE && MathIsValidNumber(v) && v>0.0);
}

bool PairValid(double r,double s)
{
   return(Valid(r) && Valid(s) && r>s);
}

bool Changed(double a,double b)
{
   return(MathAbs(a-b)>Point*0.1);
}

bool ResetAt(int shift)
{
   if(shift<1 || shift>=Bars-1)
      return false;

   double oldR=R(shift+1);
   double oldS=S(shift+1);
   double newR=R(shift);
   double newS=S(shift);

   if(!PairValid(oldR,oldS) || !PairValid(newR,newS))
      return false;

   return(Changed(oldR,newR) || Changed(oldS,newS));
}

void AddError(double errPts,int &n,double &sum,double &mx,int &e01,int &e1,int &e5)
{
   n++;
   sum+=errPts;
   if(errPts>mx) mx=errPts;
   if(errPts<=0.1) e01++;
   if(errPts<=1.0) e1++;
   if(errPts<=5.0) e5++;
}

void PrintMetric(string tag,int n,double sum,double mx,int e01,int e1,int e5)
{
   Print(
      "[AS][RESET_RESISTANCE] ",tag,
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

   int changes=0;
   int down=0;
   int supportAtBreakLow=0;

   int nOldR=0,eOldR01=0,eOldR1=0,eOldR5=0;
   double sOldR=0.0,mOldR=0.0;

   int nMidCL=0,eMidCL01=0,eMidCL1=0,eMidCL5=0;
   double sMidCL=0.0,mMidCL=0.0;

   int nRuleCL=0,eRuleCL01=0,eRuleCL1=0,eRuleCL5=0;
   double sRuleCL=0.0,mRuleCL=0.0;

   int nOldCL=0,eOldCL01=0,eOldCL1=0,eOldCL5=0;
   double sOldCL=0.0,mOldCL=0.0;

   for(int sh=bars; sh>=1; sh--)
   {
      if(!ResetAt(sh))
         continue;

      changes++;

      double oldR=R(sh+1);
      double oldS=S(sh+1);
      double newR=R(sh);
      double newS=S(sh);
      double oldCL=CL(sh+1);
      double newCL=CL(sh);

      double breakLow=iLow(NULL,PERIOD_H1,sh+1);

      if(breakLow<oldS)
         down++;

      if(MathAbs(newS-breakLow)<=Point*0.5)
         supportAtBreakLow++;

      double errOldR=MathAbs(newR-oldR)/Point;
      AddError(errOldR,nOldR,sOldR,mOldR,eOldR01,eOldR1,eOldR5);

      if(Valid(newCL))
      {
         double mid=(newR+newS)/2.0;
         double errMidCL=MathAbs(mid-newCL)/Point;
         AddError(errMidCL,nMidCL,sMidCL,mMidCL,eMidCL01,eMidCL1,eMidCL5);

         double predR=2.0*newCL-newS;
         double errRuleCL=MathAbs(newR-predR)/Point;
         AddError(errRuleCL,nRuleCL,sRuleCL,mRuleCL,eRuleCL01,eRuleCL1,eRuleCL5);
      }

      if(Valid(oldCL))
      {
         double predROldCL=2.0*oldCL-newS;
         double errOldCL=MathAbs(newR-predROldCL)/Point;
         AddError(errOldCL,nOldCL,sOldCL,mOldCL,eOldCL01,eOldCL1,eOldCL5);
      }

      Print(
         "[AS][RESET_RESISTANCE] EVENT",
         " time=",TimeToString(iTime(NULL,PERIOD_H1,sh),TIME_DATE|TIME_MINUTES),
         " oldR=",DoubleToString(oldR,Digits),
         " newR=",DoubleToString(newR,Digits),
         " newS=",DoubleToString(newS,Digits),
         " oldCL=",DoubleToString(oldCL,Digits),
         " newCL=",DoubleToString(newCL,Digits)
      );
   }

   Print(
      "[AS][RESET_RESISTANCE] SUMMARY",
      " changes=",changes,
      " down=",down,
      " supportAtBreakLow=",supportAtBreakLow
   );

   PrintMetric("NEWR_EQ_OLDR",nOldR,sOldR,mOldR,eOldR01,eOldR1,eOldR5);
   PrintMetric("MID_EQ_NEWCL",nMidCL,sMidCL,mMidCL,eMidCL01,eMidCL1,eMidCL5);
   PrintMetric("NEWR_EQ_2NEWCL_MINUS_NEWS",nRuleCL,sRuleCL,mRuleCL,eRuleCL01,eRuleCL1,eRuleCL5);
   PrintMetric("NEWR_EQ_2OLDCL_MINUS_NEWS",nOldCL,sOldCL,mOldCL,eOldCL01,eOldCL1,eOldCL5);

   Print("[AS][RESET_RESISTANCE] DONE");
}

int OnInit()
{
   Print("[AS][RESET_RESISTANCE] INIT bars=",BarsToScan);

   for(int s=1;s<=BarsToScan+3;s++)
   {
      R(s);
      S(s);
      CL(s);
   }

   Analyze();
   return(INIT_SUCCEEDED);
}

void OnTick()
{
}
