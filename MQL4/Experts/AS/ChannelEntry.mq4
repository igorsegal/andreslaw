// =============================================================================
// AS :: SWTch W4 CHANNEL ENTRY PROBE
// Distinguishes occupancy outside channel from FIRST ENTRY across boundary.
// Historical CLOSED H1 bars only.
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
bool ValidValue(double v)
{
   return(v!=EMPTY_VALUE &&
          MathIsValidNumber(v) &&
          v!=0.0);
}
int OnInit()
{
   int valid = 0;
   int invalid = 0;
   int upper_occupancy = 0;
   int lower_occupancy = 0;
   int upper_entries = 0;
   int lower_entries = 0;
   int shown = 0;
   int total = iBars(NULL,PERIOD_H1);
   int max_shift = MathMin(SCAN_BARS,total-2);
   Print("[AS][SWTCH_ENTRY] START symbol=",Symbol(),
         " tf=H1 scan=",max_shift);
   for(int shift=max_shift; shift>=1; shift--)
   {
      double h      = SWTchValue(14,shift);
      double l      = SWTchValue(15,shift);
      double prev_h = SWTchValue(14,shift+1);
      double prev_l = SWTchValue(15,shift+1);
      if(!ValidValue(h) ||
         !ValidValue(l) ||
         !ValidValue(prev_h) ||
         !ValidValue(prev_l))
      {
         invalid++;
         continue;
      }
      valid++;
      double high      = iHigh(NULL,PERIOD_H1,shift);
      double low       = iLow(NULL,PERIOD_H1,shift);
      double prev_high = iHigh(NULL,PERIOD_H1,shift+1);
      double prev_low  = iLow(NULL,PERIOD_H1,shift+1);
      bool upper_out = (high >= h);
      bool lower_out = (low  <= l);
      if(upper_out) upper_occupancy++;
      if(lower_out) lower_occupancy++;
      // First transition from inside to outside.
      bool upper_entry =
         (prev_high < prev_h && high >= h);
      bool lower_entry =
         (prev_low > prev_l && low <= l);
      if(upper_entry) upper_entries++;
      if(lower_entry) lower_entries++;
      if((upper_entry || lower_entry) && shown < 30)
      {
         shown++;
         Print("[AS][SWTCH_ENTRY][EVENT]",
               " time=",TimeToString(iTime(NULL,PERIOD_H1,shift),
                                     TIME_DATE|TIME_MINUTES),
               " upper_entry=",upper_entry,
               " lower_entry=",lower_entry,
               " High=",DoubleToString(high,Digits),
               " H=",DoubleToString(h,Digits),
               " Low=",DoubleToString(low,Digits),
               " L=",DoubleToString(l,Digits));
      }
   }
   Print("[AS][SWTCH_ENTRY][SUMMARY]",
         " valid=",valid,
         " invalid=",invalid,
         " upper_occupancy=",upper_occupancy,
         " lower_occupancy=",lower_occupancy,
         " upper_entries=",upper_entries,
         " lower_entries=",lower_entries,
         " total_entries=",upper_entries+lower_entries);
   Print("[AS][SWTCH_ENTRY] END");
   return(INIT_SUCCEEDED);
}
void OnTick()
{
}
