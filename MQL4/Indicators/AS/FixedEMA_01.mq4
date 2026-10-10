// =============================================================================
// AS :: FIXED EMA 01
//
// Causal / non-repainting EMA for CLOSED historical bars.
//
// Contract:
// - bar 0 may change while the current bar is forming;
// - once a bar is closed, its EMA value is determined only by that bar
//   and older history;
// - initialization seed uses only data available at the seed bar.
//
// NO TRADING.
// =============================================================================
#property strict
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1
#property indicator_label1  "AS Fixed EMA"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRed
#property indicator_width1  2
#property indicator_style1  STYLE_SOLID
input int EMA_Period = 50;
double FixedEMA[];
double g_alpha = 0.0;
// -----------------------------------------------------------------------------
int OnInit()
{
   if(EMA_Period < 1)
   {
      Print("[AS][FIXED_EMA01][ERROR] EMA_Period must be >= 1");
      return(INIT_PARAMETERS_INCORRECT);
   }
   SetIndexBuffer(0,FixedEMA,INDICATOR_DATA);
   ArraySetAsSeries(FixedEMA,true);
   SetIndexEmptyValue(0,EMPTY_VALUE);
   SetIndexDrawBegin(0,EMA_Period-1);
   IndicatorShortName(
      "AS Fixed EMA 01 (" + IntegerToString(EMA_Period) + ")"
   );
   g_alpha = 2.0 / (EMA_Period + 1.0);
   Print("[AS][FIXED_EMA01] INIT period=",EMA_Period,
         " alpha=",DoubleToString(g_alpha,12));
   return(INIT_SUCCEEDED);
}
// -----------------------------------------------------------------------------
int OnCalculate(const int rates_total,
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
   ArraySetAsSeries(close,true);
   if(rates_total < EMA_Period)
      return(0);
   // --------------------------------------------------------------------------
   // Full deterministic initialization.
   //
   // Oldest bar is rates_total-1.
   // The first causal EMA value may exist only after EMA_Period observations.
   // Therefore the SMA seed belongs at:
   //
   //   seed = rates_total - EMA_Period
   //
   // and uses seed ... rates_total-1 only.
   // --------------------------------------------------------------------------
   if(prev_calculated == 0)
   {
      for(int k=rates_total-1; k>rates_total-EMA_Period; k--)
         FixedEMA[k]=EMPTY_VALUE;
      int seed = rates_total-EMA_Period;
      double sum=0.0;
      for(int j=rates_total-1; j>=seed; j--)
         sum += close[j];
      FixedEMA[seed] = sum / EMA_Period;
      // Move causally from old history toward the present.
      for(int i=seed-1; i>=0; i--)
      {
         FixedEMA[i] =
            g_alpha * close[i]
            + (1.0-g_alpha) * FixedEMA[i+1];
      }
      return(rates_total);
   }
   // --------------------------------------------------------------------------
   // Incremental update.
   //
   // No new bar:
   //   recalculate only bar 0.
   //
   // One new bar:
   //   recalculate closed bar 1 from fixed bar 2,
   //   then calculate forming bar 0.
   // --------------------------------------------------------------------------
   int start = rates_total-prev_calculated;
   if(start < 0)
      start=0;
   int maxStart=rates_total-EMA_Period-1;
   if(maxStart < 0)
      return(rates_total);
   if(start > maxStart)
      start=maxStart;
   for(int n=start; n>=0; n--)
   {
      FixedEMA[n] =
         g_alpha * close[n]
         + (1.0-g_alpha) * FixedEMA[n+1];
   }
   return(rates_total);
}
