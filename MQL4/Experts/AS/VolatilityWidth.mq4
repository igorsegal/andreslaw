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

double CH_H(int s)  { return CH(14,s); }
double CH_L(int s)  { return CH(15,s); }

bool Valid(double v)
{
   return(v!=EMPTY_VALUE && MathIsValidNumber(v) && v>0.0);
}

bool PairValid(double hi,double lo)
{
   return(Valid(hi) && Valid(lo) && hi>lo);
}

bool Changed(double a,double b)
{
   return(MathAbs(a-b)>Point*0.1);
}

bool ResetAt(int shift)
{
   if(shift<1 || shift>=Bars-2)
      return false;

   double oldR=SR_R(shift+1);
   double oldS=SR_S(shift+1);
   double newR=SR_R(shift);
   double newS=SR_S(shift);

   if(!PairValid(oldR,oldS) || !PairValid(newR,newS))
      return false;

   return(Changed(oldR,newR) || Changed(oldS,newS));
}

void AddError(
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

void PrintError(
   string tag,
   int n,
   double sum,
   double mx,
   int e01,
   int e1,
   int e5)
{
   Print(
      "[AS][VOLATILITY_WIDTH] ",tag,
      " n=",n,
      " <=0.1pt=",e01,
      " <=1pt=",e1,
      " <=5pt=",e5,
      " meanErrPts=",DoubleToString(n>0 ? sum/n : 0.0,3),
      " maxErrPts=",DoubleToString(mx,3)
   );
}

void AddRatio(
   double ratio,
   int &n,
   double &sum,
   double &sum2,
   double &mn,
   double &mx)
{
   if(!MathIsValidNumber(ratio))
      return;

   n++;
   sum+=ratio;
   sum2+=ratio*ratio;
   if(ratio<mn) mn=ratio;
   if(ratio>mx) mx=ratio;
}

void PrintRatio(
   string tag,
   int n,
   double sum,
   double sum2,
   double mn,
   double mx)
{
   double mean=(n>0 ? sum/n : 0.0);
   double variance=(n>0 ? sum2/n-mean*mean : 0.0);
   if(variance<0.0 && variance>-1e-18)
      variance=0.0;
   double sd=(variance>=0.0 ? MathSqrt(variance) : 0.0);

   Print(
      "[AS][VOLATILITY_WIDTH] ",tag,
      " n=",n,
      " mean=",DoubleToString(mean,6),
      " std=",DoubleToString(sd,6),
      " min=",DoubleToString(n>0 ? mn : 0.0,6),
      " max=",DoubleToString(n>0 ? mx : 0.0,6)
   );
}

void Analyze()
{
   int bars=MathMin(BarsToScan,Bars-4);
   int resets=0;

   int nWAll=0,eWAll01=0,eWAll1=0,eWAll5=0;
   double sWAll=0.0,mWAll=0.0;

   int nWReset=0,eWReset01=0,eWReset1=0,eWReset5=0;
   double sWReset=0.0,mWReset=0.0;

   int nWBreak=0,eWBreak01=0,eWBreak1=0,eWBreak5=0;
   double sWBreak=0.0,mWBreak=0.0;

   int nCAll=0,eCAll01=0,eCAll1=0,eCAll5=0;
   double sCAll=0.0,mCAll=0.0;

   int nCReset=0,eCReset01=0,eCReset1=0,eCReset5=0;
   double sCReset=0.0,mCReset=0.0;

   int nCBreak=0,eCBreak01=0,eCBreak1=0,eCBreak5=0;
   double sCBreak=0.0,mCBreak=0.0;

   int nrAll=0;
   double srAll=0.0,sr2All=0.0,rminAll=DBL_MAX,rmaxAll=-DBL_MAX;

   int nrReset=0;
   double srReset=0.0,sr2Reset=0.0,rminReset=DBL_MAX,rmaxReset=-DBL_MAX;

   int nrBreak=0;
   double srBreak=0.0,sr2Break=0.0,rminBreak=DBL_MAX,rmaxBreak=-DBL_MAX;

   for(int sh=bars; sh>=1; sh--)
   {
      double srr=SR_R(sh);
      double srs=SR_S(sh);
      double srcl=SR_CL(sh);

      double chh=CH_H(sh);
      double chl=CH_L(sh);

      if(PairValid(srr,srs) && PairValid(chh,chl))
      {
         double srw=srr-srs;
         double chw=chh-chl;

         AddError(
            MathAbs(srw-chw)/Point,
            nWAll,sWAll,mWAll,eWAll01,eWAll1,eWAll5
         );

         if(chw>0.0)
            AddRatio(srw/chw,nrAll,srAll,sr2All,rminAll,rmaxAll);

         if(Valid(srcl))
         {
            double chmid=(chh+chl)/2.0;
            AddError(
               MathAbs(srcl-chmid)/Point,
               nCAll,sCAll,mCAll,eCAll01,eCAll1,eCAll5
            );
         }
      }

      if(!ResetAt(sh))
         continue;

      resets++;

      if(PairValid(srr,srs) && PairValid(chh,chl))
      {
         double srw=srr-srs;
         double chw=chh-chl;

         AddError(
            MathAbs(srw-chw)/Point,
            nWReset,sWReset,mWReset,eWReset01,eWReset1,eWReset5
         );

         if(chw>0.0)
            AddRatio(
               srw/chw,
               nrReset,srReset,sr2Reset,rminReset,rmaxReset
            );

         if(Valid(srcl))
         {
            double chmid=(chh+chl)/2.0;
            AddError(
               MathAbs(srcl-chmid)/Point,
               nCReset,sCReset,mCReset,eCReset01,eCReset1,eCReset5
            );
         }
      }

      double bh=CH_H(sh+1);
      double bl=CH_L(sh+1);

      if(PairValid(srr,srs) && PairValid(bh,bl))
      {
         double srw=srr-srs;
         double bchw=bh-bl;

         AddError(
            MathAbs(srw-bchw)/Point,
            nWBreak,sWBreak,mWBreak,eWBreak01,eWBreak1,eWBreak5
         );

         if(bchw>0.0)
            AddRatio(
               srw/bchw,
               nrBreak,srBreak,sr2Break,rminBreak,rmaxBreak
            );

         if(Valid(srcl))
         {
            double bmid=(bh+bl)/2.0;
            AddError(
               MathAbs(srcl-bmid)/Point,
               nCBreak,sCBreak,mCBreak,eCBreak01,eCBreak1,eCBreak5
            );
         }

         Print(
            "[AS][VOLATILITY_WIDTH] EVENT",
            " time=",TimeToString(iTime(NULL,PERIOD_H1,sh),TIME_DATE|TIME_MINUTES),
            " srW=",DoubleToString(srw,Digits),
            " chW=",DoubleToString(chh-chl,Digits),
            " breakChW=",DoubleToString(bchw,Digits),
            " ratioBreak=",DoubleToString(srw/bchw,6)
         );
      }
   }

   Print(
      "[AS][VOLATILITY_WIDTH] SUMMARY",
      " bars=",bars,
      " resets=",resets
   );

   PrintError(
      "SRW_EQ_CHW_ALL",
      nWAll,sWAll,mWAll,eWAll01,eWAll1,eWAll5
   );
   PrintRatio(
      "SRW_DIV_CHW_ALL",
      nrAll,srAll,sr2All,rminAll,rmaxAll
   );

   PrintError(
      "SRW_EQ_CHW_RESET",
      nWReset,sWReset,mWReset,eWReset01,eWReset1,eWReset5
   );
   PrintRatio(
      "SRW_DIV_CHW_RESET",
      nrReset,srReset,sr2Reset,rminReset,rmaxReset
   );

   PrintError(
      "SRW_EQ_BREAK_CHW",
      nWBreak,sWBreak,mWBreak,eWBreak01,eWBreak1,eWBreak5
   );
   PrintRatio(
      "SRW_DIV_BREAK_CHW",
      nrBreak,srBreak,sr2Break,rminBreak,rmaxBreak
   );

   PrintError(
      "SRCL_EQ_CHMID_ALL",
      nCAll,sCAll,mCAll,eCAll01,eCAll1,eCAll5
   );
   PrintError(
      "SRCL_EQ_CHMID_RESET",
      nCReset,sCReset,mCReset,eCReset01,eCReset1,eCReset5
   );
   PrintError(
      "SRCL_EQ_BREAK_CHMID",
      nCBreak,sCBreak,mCBreak,eCBreak01,eCBreak1,eCBreak5
   );

   Print("[AS][VOLATILITY_WIDTH] DONE");
}

int OnInit()
{
   Print("[AS][VOLATILITY_WIDTH] INIT bars=",BarsToScan);

   for(int sh=1; sh<=BarsToScan+4; sh++)
   {
      SR_R(sh);
      SR_S(sh);
      SR_CL(sh);
      CH_H(sh);
      CH_L(sh);
   }

   Analyze();
   return(INIT_SUCCEEDED);
}

void OnTick()
{
}
