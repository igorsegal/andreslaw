#property strict

input int BarsToScan = 500;
input int MaxLagBars = 8;

double SR(int mode,int shift)
{
   ResetLastError();
   return iCustom(NULL,PERIOD_H1,"SWTsr",true,false,mode,shift);
}

double CH(int mode,int shift)
{
   ResetLastError();
   return iCustom(NULL,PERIOD_H1,"SWTch",false,false,true,false,mode,shift);
}

double SR_R(int s) { return SR(34,s); }
double SR_S(int s) { return SR(35,s); }
double CH_H(int s) { return CH(14,s); }
double CH_L(int s) { return CH(15,s); }

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

void Analyze()
{
   int bars=MathMin(BarsToScan,Bars-MaxLagBars-4);
   int width=2*MaxLagBars+1;

   int n[];
   double sumErr[];
   double sumRatio[];
   double sumRatio2[];
   int e1[];
   int e5[];
   int e20[];
   int bestCount[];

   ArrayResize(n,width);
   ArrayResize(sumErr,width);
   ArrayResize(sumRatio,width);
   ArrayResize(sumRatio2,width);
   ArrayResize(e1,width);
   ArrayResize(e5,width);
   ArrayResize(e20,width);
   ArrayResize(bestCount,width);

   ArrayInitialize(n,0);
   ArrayInitialize(sumErr,0.0);
   ArrayInitialize(sumRatio,0.0);
   ArrayInitialize(sumRatio2,0.0);
   ArrayInitialize(e1,0);
   ArrayInitialize(e5,0);
   ArrayInitialize(e20,0);
   ArrayInitialize(bestCount,0);

   int resets=0;
   double bestErrSum=0.0;
   double bestErrMax=0.0;

   for(int sh=bars; sh>=1; sh--)
   {
      if(!ResetAt(sh))
         continue;

      double r=SR_R(sh);
      double s=SR_S(sh);
      if(!PairValid(r,s))
         continue;

      double srw=r-s;
      resets++;

      double eventBestErr=DBL_MAX;
      int eventBestOffset=999;

      for(int off=-MaxLagBars; off<=MaxLagBars; off++)
      {
         int csh=sh+off;
         if(csh<1 || csh>=Bars-1)
            continue;

         double h=CH_H(csh);
         double l=CH_L(csh);
         if(!PairValid(h,l))
            continue;

         double chw=h-l;
         if(chw<=0.0)
            continue;

         int idx=off+MaxLagBars;
         double err=MathAbs(srw-chw)/Point;
         double ratio=srw/chw;

         n[idx]++;
         sumErr[idx]+=err;
         sumRatio[idx]+=ratio;
         sumRatio2[idx]+=ratio*ratio;

         if(err<=1.0) e1[idx]++;
         if(err<=5.0) e5[idx]++;
         if(err<=20.0) e20[idx]++;

         if(err<eventBestErr)
         {
            eventBestErr=err;
            eventBestOffset=off;
         }
      }

      if(eventBestOffset!=999)
      {
         int bidx=eventBestOffset+MaxLagBars;
         bestCount[bidx]++;
         bestErrSum+=eventBestErr;
         if(eventBestErr>bestErrMax)
            bestErrMax=eventBestErr;
      }

      Print(
         "[AS][VOLATILITY_LAG] EVENT",
         " time=",TimeToString(iTime(NULL,PERIOD_H1,sh),TIME_DATE|TIME_MINUTES),
         " srW=",DoubleToString(srw,Digits),
         " bestOffset=",eventBestOffset,
         " bestErrPts=",DoubleToString(eventBestErr,3)
      );
   }

   Print(
      "[AS][VOLATILITY_LAG] SUMMARY",
      " bars=",bars,
      " resets=",resets,
      " maxLag=",MaxLagBars,
      " bestMeanErrPts=",DoubleToString(resets>0 ? bestErrSum/resets : 0.0,3),
      " bestMaxErrPts=",DoubleToString(bestErrMax,3)
   );

   for(int off=-MaxLagBars; off<=MaxLagBars; off++)
   {
      int idx=off+MaxLagBars;
      if(n[idx]<=0)
         continue;

      double meanErr=sumErr[idx]/n[idx];
      double meanRatio=sumRatio[idx]/n[idx];
      double variance=sumRatio2[idx]/n[idx]-meanRatio*meanRatio;
      if(variance<0.0 && variance>-1e-18)
         variance=0.0;
      double stdRatio=(variance>=0.0 ? MathSqrt(variance) : 0.0);

      Print(
         "[AS][VOLATILITY_LAG] OFFSET",
         " value=",off,
         " n=",n[idx],
         " meanErrPts=",DoubleToString(meanErr,3),
         " ratioMean=",DoubleToString(meanRatio,6),
         " ratioStd=",DoubleToString(stdRatio,6),
         " <=1pt=",e1[idx],
         " <=5pt=",e5[idx],
         " <=20pt=",e20[idx],
         " bestCount=",bestCount[idx]
      );
   }

   Print("[AS][VOLATILITY_LAG] DONE");
}

int OnInit()
{
   Print(
      "[AS][VOLATILITY_LAG] INIT",
      " bars=",BarsToScan,
      " maxLag=",MaxLagBars
   );

   for(int sh=1; sh<=BarsToScan+MaxLagBars+4; sh++)
   {
      SR_R(sh);
      SR_S(sh);
      CH_H(sh);
      CH_L(sh);
   }

   Analyze();
   return(INIT_SUCCEEDED);
}

void OnTick()
{
}
