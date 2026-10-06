// =============================================================================
// AS :: FIXED EMA 01 SELFTEST
// RED first: production indicator must not exist yet.
//
// Contract under test:
// Closed historical bars must obey the causal EMA recurrence:
//
// EMA[shift] = alpha * Close[shift]
//            + (1-alpha) * EMA[shift+1]
//
// NO TRADING.
// =============================================================================
#property strict
input int EMA_Period = 50;
input int BarsToTest = 100;
double FixedEMAValue(int shift)
{
   ResetLastError();
   double v = iCustom(
      NULL,
      PERIOD_H1,
      "AS\\AS_FixedEMA_01",
      EMA_Period,
      0,
      shift
   );
   return v;
}
bool ValidValue(double v)
{
   return(v != EMPTY_VALUE &&
          MathIsValidNumber(v) &&
          v != 0.0);
}
int OnInit()
{
   Print("[AS][FIXED_EMA01_TEST] START",
         " period=",EMA_Period,
         " bars=",BarsToTest);
   double alpha = 2.0 / (EMA_Period + 1.0);
   int checked = 0;
   int failed  = 0;
   double checksum = 0.0;
   double weighted = 0.0;
   for(int shift=1; shift<=BarsToTest; shift++)
   {
      ResetLastError();
      double now = FixedEMAValue(shift);
      int errNow = GetLastError();
      double old = FixedEMAValue(shift+1);
      int errOld = GetLastError();
      if(errNow != 0 || errOld != 0 ||
         !ValidValue(now) || !ValidValue(old))
      {
         Print("[AS][FIXED_EMA01_TEST][FAIL]",
               " INDICATOR_NOT_AVAILABLE_OR_INVALID",
               " shift=",shift,
               " now=",DoubleToString(now,8),
               " old=",DoubleToString(old,8),
               " errNow=",errNow,
               " errOld=",errOld);
         failed++;
         break;
      }
      double expected =
         alpha * iClose(NULL,PERIOD_H1,shift)
         + (1.0-alpha) * old;
      double delta = MathAbs(now-expected);
      if(delta > 1e-10)
      {
         Print("[AS][FIXED_EMA01_TEST][FAIL]",
               " RECURRENCE",
               " shift=",shift,
               " actual=",DoubleToString(now,12),
               " expected=",DoubleToString(expected,12),
               " delta=",DoubleToString(delta,12));
         failed++;
         break;
      }
      checksum += now;
      weighted += now * shift;
      checked++;
   }
   Print("[AS][FIXED_EMA01_TEST] SUMMARY",
         " checked=",checked,
         " failed=",failed);
   Print("[AS][FIXED_EMA01_TEST] SIGNATURE",
         " checksum=",DoubleToString(checksum,12),
         " weighted=",DoubleToString(weighted,12));
   if(failed==0 && checked==BarsToTest)
      Print("[AS][FIXED_EMA01_TEST] PASS");
   else
      Print("[AS][FIXED_EMA01_TEST] FAIL");
   return(INIT_SUCCEEDED);
}
void OnTick()
{
}

