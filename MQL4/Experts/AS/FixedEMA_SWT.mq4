// =============================================================================
// AS :: FIXED EMA vs SWTch CENTER PROBE
//
// Research only.
// Compares causal AS_FixedEMA_01 against SWTch W4 center (buffer 20).
//
// Fixed research periods:
// 20, 50, 100, 200, 400
//
// Metrics:
// - MAE versus SWT center
// - mean absolute center step
//
// CLOSED H1 bars only.
// NO TRADING.
// =============================================================================
#property strict
input int BarsToScan = 500;
int g_phase=0;
double SWT_C(int shift)
{
   ResetLastError();
   return iCustom(
      NULL,
      PERIOD_H1,
      "SWTch",
      false,
      false,
      true,
      false,
      20,
      shift
   );
}
double FIXED(int period,int shift)
{
   ResetLastError();
   return iCustom(
      NULL,
      PERIOD_H1,
      "AS\\FixedEMA_01",
      period,
      0,
      shift
   );
}
bool ValidValue(double v)
{
   return(v!=EMPTY_VALUE &&
          MathIsValidNumber(v) &&
          v!=0.0);
}
void TestPeriod(int period)
{
   int valid=0;
   int invalid=0;
   int stepPairs=0;
   double sumMAE=0.0;
   double sumFixedStep=0.0;
   double sumSwtStep=0.0;
   for(int b=1; b<=BarsToScan; b++)
   {
      double sc=SWT_C(b);
      double fv=FIXED(period,b);
      if(!ValidValue(sc) || !ValidValue(fv))
      {
         invalid++;
         continue;
      }
      valid++;
      sumMAE += MathAbs(fv-sc);
      if(b < BarsToScan)
      {
         double sc2=SWT_C(b+1);
         double fv2=FIXED(period,b+1);
         if(ValidValue(sc2) && ValidValue(fv2))
         {
            stepPairs++;
            sumSwtStep   += MathAbs(sc-sc2);
            sumFixedStep += MathAbs(fv-fv2);
         }
      }
   }
   Print("[AS][FIXED_SWT_COMPARE]",
         " period=",period,
         " valid=",valid,
         " invalid=",invalid,
         " MAE=",
         DoubleToString(valid>0 ? sumMAE/valid : 0.0,8),
         " SWT_STEP=",
         DoubleToString(stepPairs>0 ? sumSwtStep/stepPairs : 0.0,8),
         " FIXED_STEP=",
         DoubleToString(stepPairs>0 ? sumFixedStep/stepPairs : 0.0,8));
}
int OnInit()
{
   Print("[AS][FIXED_SWT_COMPARE] INIT bars=",BarsToScan);
   EventSetTimer(3);
   return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason)
{
   EventKillTimer();
}
void OnTimer()
{
   if(g_phase==0)
   {
      // Warm up SWTch + Fixed EMA instances.
      for(int b=1; b<=BarsToScan+2; b++)
      {
         double s=SWT_C(b);
         double f20 =FIXED(20,b);
         double f50 =FIXED(50,b);
         double f100=FIXED(100,b);
         double f200=FIXED(200,b);
         double f334=FIXED(334,b);
         double f400=FIXED(400,b);
      }
      Print("[AS][FIXED_SWT_COMPARE] WARMUP_DONE");
      g_phase=1;
      return;
   }
   EventKillTimer();
   TestPeriod(20);
   TestPeriod(50);
   TestPeriod(100);
   TestPeriod(200);
   TestPeriod(334);
   TestPeriod(400);
   Print("[AS][FIXED_SWT_COMPARE] DONE");
}

