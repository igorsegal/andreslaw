#property strict
#include <AS\AS_sr_state.mqh>

input int BarsToScan = 500;

struct EpisodeStats
{
   int total;
   int up;
   int down;
   int hit025;
   int hit050;
   int hit100;
   int hit200;
   int barsSum;
   int barsMax;
   double sumMaxExtensionW;
   double maxExtensionW;
};

void InitStats(EpisodeStats &x)
{
   x.total=0;
   x.up=0;
   x.down=0;
   x.hit025=0;
   x.hit050=0;
   x.hit100=0;
   x.hit200=0;
   x.barsSum=0;
   x.barsMax=0;
   x.sumMaxExtensionW=0.0;
   x.maxExtensionW=0.0;
}

void RecordEpisode(
   EpisodeStats &x,
   int direction,
   int bars,
   double maxExtensionW)
{
   x.total++;
   if(direction>0) x.up++;
   if(direction<0) x.down++;

   if(maxExtensionW>=0.25) x.hit025++;
   if(maxExtensionW>=0.50) x.hit050++;
   if(maxExtensionW>=1.00) x.hit100++;
   if(maxExtensionW>=2.00) x.hit200++;

   x.barsSum+=bars;
   if(bars>x.barsMax) x.barsMax=bars;

   x.sumMaxExtensionW+=maxExtensionW;
   if(maxExtensionW>x.maxExtensionW)
      x.maxExtensionW=maxExtensionW;
}

void Analyze()
{
   int bars=MathMin(BarsToScan,Bars-3);
   if(bars<10)
   {
      Print("[AS][SR_HYST] FAIL insufficient_history bars=",bars);
      return;
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
      Print("[AS][SR_HYST] FAIL no_seed");
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

   EpisodeStats stats;
   InitStats(stats);

   bool inEpisode=false;
   int direction=0;
   int episodeBars=0;
   double oldSupport=0.0;
   double oldResistance=0.0;
   double oldWidth=0.0;
   double maxExtensionW=0.0;

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
         direction=(st.phase==AS_SR_SEEK_HIGH ? 1 : -1);
         episodeBars=1;
         oldSupport=supportBefore;
         oldResistance=resistanceBefore;
         oldWidth=oldResistance-oldSupport;
         maxExtensionW=0.0;
      }
      else if(inEpisode)
      {
         episodeBars++;
      }

      if(inEpisode && oldWidth>0.0)
      {
         double extension=0.0;

         if(direction>0)
            extension=(st.candidate-oldResistance)/oldWidth;
         else if(direction<0)
            extension=(oldSupport-st.candidate)/oldWidth;

         if(extension>maxExtensionW)
            maxExtensionW=extension;
      }

      if(inEpisode &&
         phaseBefore!=AS_SR_ACTIVE &&
         st.phase==AS_SR_ACTIVE)
      {
         RecordEpisode(
            stats,
            direction,
            episodeBars,
            maxExtensionW
         );

         Print(
            "[AS][SR_HYST] EPISODE",
            " time=",
            TimeToString(
               iTime(NULL,PERIOD_H1,s),
               TIME_DATE|TIME_MINUTES
            ),
            " dir=",direction,
            " bars=",episodeBars,
            " maxExtW=",DoubleToString(maxExtensionW,6)
         );

         inEpisode=false;
         direction=0;
         episodeBars=0;
         oldSupport=0.0;
         oldResistance=0.0;
         oldWidth=0.0;
         maxExtensionW=0.0;
      }
   }

   Print(
      "[AS][SR_HYST] SUMMARY",
      " episodes=",stats.total,
      " up=",stats.up,
      " down=",stats.down,
      " meanBars=",
      DoubleToString(
         stats.total>0 ? (double)stats.barsSum/stats.total : 0.0,
         3
      ),
      " maxBars=",stats.barsMax,
      " meanMaxExtW=",
      DoubleToString(
         stats.total>0 ? stats.sumMaxExtensionW/stats.total : 0.0,
         6
      ),
      " maxExtW=",DoubleToString(stats.maxExtensionW,6)
   );

   Print(
      "[AS][SR_HYST] THRESHOLDS",
      " K025=",stats.hit025,
      " K050=",stats.hit050,
      " K100=",stats.hit100,
      " K200=",stats.hit200
   );

   if(stats.total>0)
   {
      Print(
         "[AS][SR_HYST] RATES",
         " K025=",
         DoubleToString(100.0*stats.hit025/stats.total,2),"%",
         " K050=",
         DoubleToString(100.0*stats.hit050/stats.total,2),"%",
         " K100=",
         DoubleToString(100.0*stats.hit100/stats.total,2),"%",
         " K200=",
         DoubleToString(100.0*stats.hit200/stats.total,2),"%"
      );
   }

   Print("[AS][SR_HYST] DONE");
}

int OnInit()
{
   Print("[AS][SR_HYST] INIT bars=",BarsToScan);
   Analyze();
   return(INIT_SUCCEEDED);
}

void OnTick()
{
}
