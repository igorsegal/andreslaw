// =============================================================================
// AS :: SWTch W4 CHANNEL HIT PROBE
// Historical closed-bar scan.
// Objective events only:
//   High >= chw4:H
//   Low  <= chw4:L
// NO TRADING.
// =============================================================================
#property strict
#define SCAN_BARS 500
double SWTchValue(int mode,int shift)
{
   ResetLastError();
   double v = iCustom(
      NULL,
      PERIOD_H1,
      "SWTch",
      false,   // W2_CH
      false,   // W3_SR
      true,    // W4_SR
      false,   // ShowCenterLine
      mode,
      shift
   );
   if(GetLastError()!=0)
      return EMPTY_VALUE;
   return v;
}
int OnInit()
{
   int upper_hits = 0;
   int lower_hits = 0;
   int both_hits  = 0;
   int valid_bars = 0;
   int invalid    = 0;
   int shown      = 0;
   Print("[AS][SWTCH_HIT] START symbol=",Symbol(),
         " tf=H1 scan=",SCAN_BARS);
   int max_shift = MathMin(SCAN_BARS,Bars-2);
   for(int shift=max_shift; shift>=1; shift--)
   {
      double h = SWTchValue(14,shift); // chw4:H
      double l = SWTchValue(15,shift); // chw4:L
      if(h==EMPTY_VALUE || l==EMPTY_VALUE ||
         !MathIsValidNumber(h) || !MathIsValidNumber(l) ||
         h==0.0 || l==0.0)
      {
         invalid++;
         continue;
      }
      valid_bars++;
      double bar_high = iHigh(NULL,PERIOD_H1,shift);
      double bar_low  = iLow(NULL,PERIOD_H1,shift);
      bool upper = (bar_high >= h);
      bool lower = (bar_low  <= l);
      if(upper) upper_hits++;
      if(lower) lower_hits++;
      if(upper && lower) both_hits++;
      if((upper || lower) && shown < 20)
      {
         shown++;
         Print("[AS][SWTCH_HIT][EVENT]",
               " time=",TimeToString(iTime(NULL,PERIOD_H1,shift),
                                     TIME_DATE|TIME_MINUTES),
               " upper=",upper,
               " lower=",lower,
               " High=",DoubleToString(bar_high,Digits),
               " H=",DoubleToString(h,Digits),
               " Low=",DoubleToString(bar_low,Digits),
               " L=",DoubleToString(l,Digits));
      }
   }
   Print("[AS][SWTCH_HIT][SUMMARY]",
         " valid=",valid_bars,
         " invalid=",invalid,
         " upper_hits=",upper_hits,
         " lower_hits=",lower_hits,
         " both_hits=",both_hits,
         " events=",upper_hits+lower_hits);
   Print("[AS][SWTCH_HIT] END");
   return(INIT_SUCCEEDED);
}
void OnTick()
{
}
