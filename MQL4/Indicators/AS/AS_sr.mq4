#property strict
#property indicator_chart_window
#property indicator_buffers 2
#include <AS\AS_sr_state.mqh>
double ResistanceBuffer[];
double SupportBuffer[];
int OnInit()
{
   IndicatorShortName("AS_sr");
   SetIndexBuffer(0,ResistanceBuffer);
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrTomato);
   SetIndexLabel(0,"AS_sr:R");
   SetIndexEmptyValue(0,EMPTY_VALUE);
   SetIndexBuffer(1,SupportBuffer);
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,2,clrLimeGreen);
   SetIndexLabel(1,"AS_sr:S");
   SetIndexEmptyValue(1,EMPTY_VALUE);
   ArraySetAsSeries(ResistanceBuffer,true);
   ArraySetAsSeries(SupportBuffer,true);
   IndicatorDigits(Digits);
   return(INIT_SUCCEEDED);
}
int OnCalculate(
   const int rates_total,
   const int prev_calculated,
   const datetime &time[],
   const double &open[],
   const double &high[],
   const double &low[],
   const double &close[],
   const long &tick_volume[],
   const long &volume[],
   const int &spread[])
{
   if(rates_total<4)
      return 0;
   // Geometry uses CLOSED bars only.
   // Nothing can change intrabar, so if no new bar appeared
   // there is nothing to rebuild.
   if(prev_calculated>0 && prev_calculated==rates_total)
      return rates_total;
   ArrayInitialize(ResistanceBuffer,EMPTY_VALUE);
   ArrayInitialize(SupportBuffer,EMPTY_VALUE);
   int seedShift=-1;
   // Find oldest usable non-zero body.
   for(int s=rates_total-1; s>=1; s--)
   {
      double bh=AS_sr_BodyHigh(open[s],close[s]);
      double bl=AS_sr_BodyLow(open[s],close[s]);
      if(MathIsValidNumber(bh) &&
         MathIsValidNumber(bl) &&
         bh>bl)
      {
         seedShift=s;
         break;
      }
   }
   if(seedShift<2)
      return rates_total;
   AS_sr_State st;
   AS_sr_StateInit(
      st,
      AS_sr_BodyLow(open[seedShift],close[seedShift]),
      AS_sr_BodyHigh(open[seedShift],close[seedShift])
   );
   // Bootstrap pair is intentionally NOT displayed.
   bool realPairReady=false;
   // Walk history chronologically:
   // large shift -> small shift.
   for(int s=seedShift-1; s>=1; s--)
   {
      int phaseBefore=st.phase;
      AS_sr_StateStep(
         st,
         open[s],
         high[s],
         low[s],
         close[s]
      );
      // First genuine pair appears only after
      // SEEK_HIGH/SEEK_LOW returns to ACTIVE.
      if(phaseBefore!=AS_SR_ACTIVE &&
         st.phase==AS_SR_ACTIVE)
      {
         realPairReady=true;
      }
      // During SEEK state the old pair is no longer active,
      // therefore no active S/R line is drawn.
      if(realPairReady && st.phase==AS_SR_ACTIVE)
      {
         ResistanceBuffer[s]=st.resistance;
         SupportBuffer[s]=st.support;
      }
   }
   // Current forming bar cannot change geometry.
   // It only displays the last confirmed active pair.
   if(realPairReady && st.phase==AS_SR_ACTIVE)
   {
      ResistanceBuffer[0]=st.resistance;
      SupportBuffer[0]=st.support;
   }
   return rates_total;
}
