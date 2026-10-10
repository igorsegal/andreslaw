// =============================================================================
// AS :: SWTch CENTER LAW PROBE
//
// Research only.
// Tests whether SWTch W4 center (buffer 20 = chw4:cl)
// obeys a one-step EMA recurrence:
//
//   C_now = alpha * Price_now + (1-alpha) * C_prev
//
// Therefore:
//
//   alpha = (C_now - C_prev) / (Price_now - C_prev)
//
// Price candidates:
//   CLOSE
//   MEDIAN   = (H+L)/2
//   TYPICAL  = (H+L+C)/3
//   WEIGHTED = (H+L+2*C)/4
//
// CLOSED H1 bars only.
// NO TRADING.
// =============================================================================
#property strict
input int BarsToScan = 500;
int g_phase = 0;
// -----------------------------------------------------------------------------
double SWT_C(int shift)
{
   ResetLastError();
   return iCustom(
      NULL,
      PERIOD_H1,
      "SWTch",
      false,   // W2_CH
      false,   // W3_SR
      true,    // W4_SR
      false,   // ShowCenterLine
      20,      // chw4:cl
      shift
   );
}
// -----------------------------------------------------------------------------
bool ValidValue(double v)
{
   return(v != EMPTY_VALUE &&
          MathIsValidNumber(v) &&
          v != 0.0);
}
// -----------------------------------------------------------------------------
double PriceValue(int priceType,int shift)
{
   double h=iHigh(NULL,PERIOD_H1,shift);
   double l=iLow(NULL,PERIOD_H1,shift);
   double c=iClose(NULL,PERIOD_H1,shift);
   if(priceType==0) return c;
   if(priceType==1) return (h+l)/2.0;
   if(priceType==2) return (h+l+c)/3.0;
   return (h+l+2.0*c)/4.0;
}
// -----------------------------------------------------------------------------
string PriceName(int priceType)
{
   if(priceType==0) return "CLOSE";
   if(priceType==1) return "MEDIAN";
   if(priceType==2) return "TYPICAL";
   return "WEIGHTED";
}
// -----------------------------------------------------------------------------
void TestPriceType(int priceType)
{
   int valid=0;
   int invalid=0;
   int denominator_zero=0;
   double sum=0.0;
   double sum2=0.0;
   double minAlpha=DBL_MAX;
   double maxAlpha=-DBL_MAX;
   for(int b=1; b<=BarsToScan; b++)
   {
      double cNow =SWT_C(b);
      double cPrev=SWT_C(b+1);
      if(!ValidValue(cNow) || !ValidValue(cPrev))
      {
         invalid++;
         continue;
      }
      double p=PriceValue(priceType,b);
      if(!MathIsValidNumber(p) || p<=0.0)
      {
         invalid++;
         continue;
      }
      double denominator=p-cPrev;
      // Numerical singularity only; not a market threshold.
      if(MathAbs(denominator)<1e-12)
      {
         denominator_zero++;
         continue;
      }
      double alpha=(cNow-cPrev)/denominator;
      if(!MathIsValidNumber(alpha))
      {
         invalid++;
         continue;
      }
      valid++;
      sum  += alpha;
      sum2 += alpha*alpha;
      if(alpha<minAlpha) minAlpha=alpha;
      if(alpha>maxAlpha) maxAlpha=alpha;
   }
   if(valid<=0)
   {
      Print("[AS][SWT_CENTER_LAW]",
            " price=",PriceName(priceType),
            " valid=0",
            " invalid=",invalid,
            " denominator_zero=",denominator_zero);
      return;
   }
   double mean=sum/valid;
   double variance=(sum2/valid)-(mean*mean);
   if(variance<0.0 && variance>-1e-18)
      variance=0.0;
   double stddev=
      (variance>=0.0 ? MathSqrt(variance) : EMPTY_VALUE);
   Print("[AS][SWT_CENTER_LAW]",
         " price=",PriceName(priceType),
         " valid=",valid,
         " invalid=",invalid,
         " denominator_zero=",denominator_zero,
         " mean_alpha=",DoubleToString(mean,12),
         " std_alpha=",DoubleToString(stddev,12),
         " min_alpha=",DoubleToString(minAlpha,12),
         " max_alpha=",DoubleToString(maxAlpha,12));
}
// -----------------------------------------------------------------------------
int OnInit()
{
   double alpha400=2.0/(400.0+1.0);
   Print("[AS][SWT_CENTER_LAW] INIT",
         " bars=",BarsToScan,
         " alpha400=",DoubleToString(alpha400,12));
   EventSetTimer(3);
   return(INIT_SUCCEEDED);
}
// -----------------------------------------------------------------------------
void OnDeinit(const int reason)
{
   EventKillTimer();
}
// -----------------------------------------------------------------------------
void OnTimer()
{
   if(g_phase==0)
   {
      // SWTch historical warm-up.
      for(int b=1; b<=BarsToScan+2; b++)
      {
         double c=SWT_C(b);
      }
      Print("[AS][SWT_CENTER_LAW] WARMUP_DONE");
      g_phase=1;
      return;
   }
   EventKillTimer();
   TestPriceType(0); // CLOSE
   TestPriceType(1); // MEDIAN
   TestPriceType(2); // TYPICAL
   TestPriceType(3); // WEIGHTED
   Print("[AS][SWT_CENTER_LAW] DONE");
}
