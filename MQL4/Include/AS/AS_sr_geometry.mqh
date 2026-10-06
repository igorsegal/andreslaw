#ifndef __AS_SR_GEOMETRY_MQH__
#define __AS_SR_GEOMETRY_MQH__
int AS_sr_DetectBreak(
   double open,
   double high,
   double low,
   double close,
   double support,
   double resistance)
{
   if(!MathIsValidNumber(open) ||
      !MathIsValidNumber(high) ||
      !MathIsValidNumber(low) ||
      !MathIsValidNumber(close) ||
      !MathIsValidNumber(support) ||
      !MathIsValidNumber(resistance))
      return 0;
   if(support >= resistance)
      return 0;
   if(close > resistance)
      return 1;
   if(close < support)
      return -1;
   return 0;
}
double AS_sr_BodyHigh(double open,double close)
{
   return MathMax(open,close);
}
double AS_sr_BodyLow(double open,double close)
{
   return MathMin(open,close);
}
double AS_sr_PeakRange(
   const double &highs[],
   const double &lows[],
   int count)
{
   if(count<=0)
      return 0.0;
   double peak=0.0;
   for(int i=0; i<count; i++)
   {
      if(!MathIsValidNumber(highs[i]) ||
         !MathIsValidNumber(lows[i]) ||
         highs[i] < lows[i])
         return 0.0;
      double range=highs[i]-lows[i];
      if(range>peak)
         peak=range;
   }
   return peak;
}
double AS_sr_MaxBodyHigh(
   const double &opens[],
   const double &closes[],
   int count)
{
   if(count<=0)
      return 0.0;
   double result=AS_sr_BodyHigh(opens[0],closes[0]);
   for(int i=1; i<count; i++)
   {
      double v=AS_sr_BodyHigh(opens[i],closes[i]);
      if(v>result)
         result=v;
   }
   return result;
}
double AS_sr_MinBodyLow(
   const double &opens[],
   const double &closes[],
   int count)
{
   if(count<=0)
      return 0.0;
   double result=AS_sr_BodyLow(opens[0],closes[0]);
   for(int i=1; i<count; i++)
   {
      double v=AS_sr_BodyLow(opens[i],closes[i]);
      if(v<result)
         result=v;
   }
   return result;
}
bool AS_sr_BuildPair(
   int direction,
   double activeLevel,
   double peakRange,
   double &support,
   double &resistance)
{
   support=0.0;
   resistance=0.0;
   if(!MathIsValidNumber(activeLevel) ||
      !MathIsValidNumber(peakRange) ||
      peakRange<=0.0)
      return false;
   if(direction==1)
   {
      resistance=activeLevel;
      support=activeLevel-peakRange;
      return(support<resistance);
   }
   if(direction==-1)
   {
      support=activeLevel;
      resistance=activeLevel+peakRange;
      return(support<resistance);
   }
   return false;
}
bool AS_sr_IsBodyHighConfirmed(
   double candidateHigh,
   double nextOpen,
   double nextClose)
{
   if(!MathIsValidNumber(candidateHigh) ||
      !MathIsValidNumber(nextOpen) ||
      !MathIsValidNumber(nextClose))
      return false;
   double nextBodyHigh=AS_sr_BodyHigh(nextOpen,nextClose);
   // Equal high is NOT a new extreme.
   return(nextBodyHigh<=candidateHigh);
}
bool AS_sr_IsBodyLowConfirmed(
   double candidateLow,
   double nextOpen,
   double nextClose)
{
   if(!MathIsValidNumber(candidateLow) ||
      !MathIsValidNumber(nextOpen) ||
      !MathIsValidNumber(nextClose))
      return false;
   double nextBodyLow=AS_sr_BodyLow(nextOpen,nextClose);
   // Equal low is NOT a new extreme.
   return(nextBodyLow>=candidateLow);
}#endif
