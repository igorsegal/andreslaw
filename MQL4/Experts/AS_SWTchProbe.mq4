// =============================================================================
// AS :: SWTch TARGETED BLACK-BOX PROBE
// EURUSD H1 / target closed historical bar / W4_SR=true
// NO TRADING.
// =============================================================================
#property strict
int OnInit()
{
   datetime target = StrToTime("2026.10.01 10:00");
   int shift = iBarShift(NULL,PERIOD_H1,target,true);
   Print("[AS][SWTCH_PROBE] START target=",
         TimeToString(target,TIME_DATE|TIME_MINUTES),
         " shift=",shift);
   if(shift < 0)
   {
      Print("[AS][SWTCH_PROBE][ERROR] target bar not found");
      return(INIT_FAILED);
   }
   for(int mode=0; mode<=25; mode++)
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
      int err = GetLastError();
      Print("[AS][SWTCH_PROBE]",
            " time=",TimeToString(iTime(NULL,PERIOD_H1,shift),
                                  TIME_DATE|TIME_MINUTES),
            " mode=",mode,
            " value=",DoubleToString(v,8),
            " empty=",(v==EMPTY_VALUE),
            " err=",err);
   }
   Print("[AS][SWTCH_PROBE] END");
   return(INIT_SUCCEEDED);
}
void OnTick()
{
}
