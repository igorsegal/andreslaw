#property strict
int OnInit()
{
   datetime target=StrToTime("2026.09.29 05:00");
   int shift=iBarShift(NULL,PERIOD_H1,target,true);
   Print("[AS][SWTSR_PROBE] START",
         " shift=",shift,
         " time=",TimeToString(target,TIME_DATE|TIME_MINUTES));
   for(int mode=0; mode<=50; mode++)
   {
      ResetLastError();
      double v=iCustom(
         NULL,
         PERIOD_H1,
         "SWTsr",
         true,    // ShowLevelsForW2
         false,   // ShowStopLossSR
         mode,
         shift
      );
      int err=GetLastError();
      Print("[AS][SWTSR_PROBE]",
            " mode=",mode,
            " value=",DoubleToString(v,8),
            " empty=",(v==EMPTY_VALUE),
            " err=",err);
   }
   Print("[AS][SWTSR_PROBE] END");
   return(INIT_SUCCEEDED);
}
void OnTick()
{
}


