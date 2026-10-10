#property strict
#include <AS\AS_sr_state.mqh>

input int BarsToScan = 500;
input int MatchWindowBars = 2;

#define K_COUNT 12

double KValues[K_COUNT] = {
   0.10,0.20,0.30,0.40,0.50,0.60,
   0.70,0.80,0.90,1.00,1.50,2.00
};

double SWT_R(int shift)
{
   ResetLastError();
   return iCustom(
      NULL,PERIOD_H1,"SWTsr",
      true,false,
      34,shift
   );
}

double SWT_S(int shift)
{
   ResetLastError();
   return iCustom(
      NULL,PERIOD_H1,"SWTsr",
      true,false,
      35,shift
   );
}

bool ValidPrice(double v)
{
   return(
      v!=EMPTY_VALUE &&
      MathIsValidNumber(v) &&
      v>0.0
   );
}

bool LevelChanged(double a,double b)
{
   return(MathAbs(a-b)>Point*0.1);
}

bool SWTChangedAt(int shift)
{
   if(shift<1 || shift>=Bars-1)
      return false;

   double oldR=SWT_R(shift+1);
   double oldS=SWT_S(shift+1);
   double newR=SWT_R(shift);
   double newS=SWT_S(shift);

   if(!ValidPrice(oldR) || !ValidPrice(oldS) ||
      !ValidPrice(newR) || !ValidPrice(newS))
      return false;

   return(
      LevelChanged(oldR,newR) ||
      LevelChanged(oldS,newS)
   );
}

bool NearSWTChange(int shift,int window)
{
   for(int d=-window; d<=window; d++)
   {
      int s=shift+d;
      if(s<1 || s>=Bars-1)
         continue;
      if(SWTChangedAt(s))
         return true;
   }
   return false;
}

void Analyze()
{
   int bars=MathMin(BarsToScan,Bars-3);
   if(bars<10)
   {
      Print("[AS][SR_HYST_SWEEP] FAIL insufficient_history bars=",bars);
      return;
   }

   int swtChanges=0;
   for(int s=bars; s>=1; s--)
   {
      if(SWTChangedAt(s))
         swtChanges++;
   }

   int seedShift=-1;
   for(int s=bars; s>=1; s--)
   {
      double o=iOpen(NULL,PERIOD_H1,s);
      double c=iClose(NULL,PERIOD_H1,s);
      double bh=AS_sr_BodyHigh(o,c);
      double bl=AS_sr_BodyLow(o,c);

      if(MathIsValidNumber(bh) &&
         MathIsValidNumber(bl) &&
         bh>bl)
      {
         seedShift=s;
         break;
      }
   }

   if(seedShift<2)
   {
      Print("[AS][SR_HYST_SWEEP] FAIL no_seed");
      return;
   }

   AS_sr_State st;
   AS_sr_StateInit(
      st,
      AS_sr_BodyLow(
         iOpen(NULL,PERIOD_H1,seedShift),
         iClose(NULL,PERIOD_H1,seedShift)
      ),
      AS_sr_BodyHigh(
         iOpen(NULL,PERIOD_H1,seedShift),
         iClose(NULL,PERIOD_H1,seedShift)
      )
   );

   int episodes=0;
   int hits[K_COUNT];
   int matches[K_COUNT];
   ArrayInitialize(hits,0);
   ArrayInitialize(matches,0);

   int crossed[K_COUNT];
   ArrayInitialize(crossed,0);

   bool inEpisode=false;
   int direction=0;
   double oldSupport=0.0;
   double oldResistance=0.0;
   double oldWidth=0.0;

   for(int s=seedShift-1; s>=1; s--)
   {
      int phaseBefore=st.phase;
      double supportBefore=st.support;
      double resistanceBefore=st.resistance;

      double o=iOpen(NULL,PERIOD_H1,s);
      double h=iHigh(NULL,PERIOD_H1,s);
      double l=iLow(NULL,PERIOD_H1,s);
      double c=iClose(NULL,PERIOD_H1,s);

      AS_sr_StateStep(st,o,h,l,c);

      if(!inEpisode &&
         phaseBefore==AS_SR_ACTIVE &&
         st.phase!=AS_SR_ACTIVE)
      {
         inEpisode=true;
         episodes++;
         direction=(st.phase==AS_SR_SEEK_HIGH ? 1 : -1);
         oldSupport=supportBefore;
         oldResistance=resistanceBefore;
         oldWidth=oldResistance-oldSupport;

         for(int k=0;k<K_COUNT;k++)
            crossed[k]=0;
      }

      if(inEpisode && oldWidth>0.0)
      {
         double extension=0.0;

         if(direction>0)
            extension=(st.candidate-oldResistance)/oldWidth;
         else if(direction<0)
            extension=(oldSupport-st.candidate)/oldWidth;

         for(int k=0;k<K_COUNT;k++)
         {
            if(!crossed[k] && extension>=KValues[k])
            {
               crossed[k]=1;
               hits[k]++;

               if(NearSWTChange(s,MatchWindowBars))
                  matches[k]++;
            }
         }
      }

      if(inEpisode &&
         phaseBefore!=AS_SR_ACTIVE &&
         st.phase==AS_SR_ACTIVE)
      {
         inEpisode=false;
         direction=0;
         oldSupport=0.0;
         oldResistance=0.0;
         oldWidth=0.0;
      }
   }

   Print(
      "[AS][SR_HYST_SWEEP] SUMMARY",
      " bars=",bars,
      " episodes=",episodes,
      " swtChanges=",swtChanges,
      " matchWindow=+/-",MatchWindowBars
   );

   for(int k=0;k<K_COUNT;k++)
   {
      double episodeRate=
         episodes>0 ? 100.0*hits[k]/episodes : 0.0;

      double precision=
         hits[k]>0 ? 100.0*matches[k]/hits[k] : 0.0;

      double recall=
         swtChanges>0 ? 100.0*matches[k]/swtChanges : 0.0;

      Print(
         "[AS][SR_HYST_SWEEP] K",
         " value=",DoubleToString(KValues[k],2),
         " hits=",hits[k],
         " episodeRate=",DoubleToString(episodeRate,2),"%",
         " matched=",matches[k],
         " matchPrecision=",DoubleToString(precision,2),"%",
         " swtRecallApprox=",DoubleToString(recall,2),"%"
      );
   }

   Print("[AS][SR_HYST_SWEEP] DONE");
}

int OnInit()
{
   Print(
      "[AS][SR_HYST_SWEEP] INIT bars=",
      BarsToScan,
      " window=",
      MatchWindowBars
   );

   // Warm up original SWTsr historical buffers.
   for(int s=1;s<=BarsToScan+3;s++)
   {
      SWT_R(s);
      SWT_S(s);
   }

   Analyze();
   return(INIT_SUCCEEDED);
}

void OnTick()
{
}
