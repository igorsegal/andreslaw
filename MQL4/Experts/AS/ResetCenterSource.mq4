#property strict

input int BarsToScan = 500;

double SR(int mode,int shift)
{
   ResetLastError();
   return iCustom(NULL,PERIOD_H1,"SWTsr",true,false,mode,shift);
}

double CH(int mode,int shift)
{
   ResetLastError();
   return iCustom(
      NULL,PERIOD_H1,"SWTch",
      false,false,true,false,
      mode,shift
   );
}

double SR_R(int s)  { return SR(34,s); }
double SR_S(int s)  { return SR(35,s); }
double SR_CL(int s) { return SR(42,s); }

double CH_R(int s)  { return CH(18,s); }
double CH_S(int s)  { return CH(19,s); }
double CH_CL(int s) { return CH(20,s); }

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

   double oldR=SR_R(shift+1);
   double oldS=SR_S(shift+1);
   double newR=SR_R(shift);
   double newS=SR_S(shift);

   if(!PairValid(oldR,oldS) || !PairValid(newR,newS))
      return false;

   return(Changed(oldR,newR) || Changed(oldS,newS));
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
      "[AS][RESET_CENTER_SOURCE] ",tag,
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
   int resets=0;

   int nMidAll=0,eMidAll01=0,eMidAll1=0,eMidAll5=0;
   double sMidAll=0.0,mMidAll=0.0;

   int nMidReset=0,eMidReset01=0,eMidReset1=0,eMidReset5=0;
   double sMidReset=0.0,mMidReset=0.0;

   int nRAll=0,eRAll01=0,eRAll1=0,eRAll5=0;
   double sRAll=0.0,mRAll=0.0;

   int nSAll=0,eSAll01=0,eSAll1=0,eSAll5=0;
   double sSAll=0.0,mSAll=0.0;

   int nWidthAll=0,eWidthAll01=0,eWidthAll1=0,eWidthAll5=0;
   double sWidthAll=0.0,mWidthAll=0.0;

   for(int sh=bars; sh>=1; sh--)
   {
      double srcl=SR_CL(sh);
      double srr=SR_R(sh);
      double srs=SR_S(sh);

      double chr=CH_R(sh);
      double chs=CH_S(sh);
      double chcl=CH_CL(sh);

      if(Valid(srcl) && PairValid(chr,chs))
      {
         double chmid=(chr+chs)/2.0;
         double err=MathAbs(srcl-chmid)/Point;
         AddMetric(
            err,
            nMidAll,sMidAll,mMidAll,
            eMidAll01,eMidAll1,eMidAll5
         );
      }

      if(Valid(srcl) && Valid(chr))
      {
         double errR=MathAbs(srcl-chr)/Point;
         AddMetric(
            errR,
            nRAll,sRAll,mRAll,
            eRAll01,eRAll1,eRAll5
         );
      }

      if(Valid(srcl) && Valid(chs))
      {
         double errS=MathAbs(srcl-chs)/Point;
         AddMetric(
            errS,
            nSAll,sSAll,mSAll,
            eSAll01,eSAll1,eSAll5
         );
      }

      if(PairValid(srr,srs) && PairValid(chr,chs))
      {
         double srw=srr-srs;
         double chw=chr-chs;
         double errW=MathAbs(srw-chw)/Point;

         AddMetric(
            errW,
            nWidthAll,sWidthAll,mWidthAll,
            eWidthAll01,eWidthAll1,eWidthAll5
         );
      }

      if(!ResetAt(sh))
         continue;

      resets++;

      if(Valid(srcl) && PairValid(chr,chs))
      {
         double chmid=(chr+chs)/2.0;
         double err=MathAbs(srcl-chmid)/Point;

         AddMetric(
            err,
            nMidReset,sMidReset,mMidReset,
            eMidReset01,eMidReset1,eMidReset5
         );

         Print(
            "[AS][RESET_CENTER_SOURCE] EVENT",
            " time=",TimeToString(iTime(NULL,PERIOD_H1,sh),TIME_DATE|TIME_MINUTES),
            " srCL=",DoubleToString(srcl,Digits),
            " chR=",DoubleToString(chr,Digits),
            " chS=",DoubleToString(chs,Digits),
            " chMid=",DoubleToString(chmid,Digits),
            " chCL=",DoubleToString(chcl,Digits)
         );
      }
   }

   Print(
      "[AS][RESET_CENTER_SOURCE] SUMMARY",
      " bars=",bars,
      " resets=",resets
   );

   PrintMetric(
      "SRCL_EQ_MID_CHRS_ALL",
      nMidAll,sMidAll,mMidAll,
      eMidAll01,eMidAll1,eMidAll5
   );

   PrintMetric(
      "SRCL_EQ_MID_CHRS_RESET",
      nMidReset,sMidReset,mMidReset,
      eMidReset01,eMidReset1,eMidReset5
   );

   PrintMetric(
      "SRCL_EQ_CHR_ALL",
      nRAll,sRAll,mRAll,
      eRAll01,eRAll1,eRAll5
   );

   PrintMetric(
      "SRCL_EQ_CHS_ALL",
      nSAll,sSAll,mSAll,
      eSAll01,eSAll1,eSAll5
   );

   PrintMetric(
      "SRWIDTH_EQ_CHWIDTH_ALL",
      nWidthAll,sWidthAll,mWidthAll,
      eWidthAll01,eWidthAll1,eWidthAll5
   );

   Print("[AS][RESET_CENTER_SOURCE] DONE");
}

int OnInit()
{
   Print("[AS][RESET_CENTER_SOURCE] INIT bars=",BarsToScan);

   for(int sh=1; sh<=BarsToScan+3; sh++)
   {
      SR_R(sh);
      SR_S(sh);
      SR_CL(sh);
      CH_R(sh);
      CH_S(sh);
      CH_CL(sh);
   }

   Analyze();
   return(INIT_SUCCEEDED);
}

void OnTick()
{
}
