// =============================================================================
// AS_Channel_01
//
// Simple transparent volatility channel.
//
// CENTER     = EMA(Close, CenterPeriod)
//
// VOLATILITY = population standard deviation of residuals
//              Residual = Close - EMA
//              over VolatilityWindow historical bars
//
// INNER = CENTER +/- InnerK * VOLATILITY
// OUTER = CENTER +/- OuterK * VOLATILITY
//
// Research version.
// NO trading logic.
// NO SWT dependency.
// NO hidden buffers.
// =============================================================================
#property strict
#property indicator_chart_window
#property indicator_buffers 5
input int    CenterPeriod     = 20;
input int    VolatilityWindow = 50;
input double InnerK           = 2.0;
input double OuterK           = 3.0;
double BufCenter[];
double BufInnerHigh[];
double BufInnerLow[];
double BufOuterHigh[];
double BufOuterLow[];
// -----------------------------------------------------------------------------
// Population standard deviation of historical Close-EMA residuals.
//
// For bar shift:
// use only bar shift and OLDER bars:
// shift ... shift+VolatilityWindow-1
//
// Therefore historical calculation has no future-bar dependency.
// -----------------------------------------------------------------------------
bool ResidualStdDev(const int shift,
                    const int rates_total,
                    double &outSigma)
{
   if(VolatilityWindow < 2)
      return false;
   if(shift < 0)
      return false;
   // The oldest residual also needs enough older bars for its EMA.
   if(shift + VolatilityWindow + CenterPeriod - 2 >= rates_total)
      return false;
   double sum  = 0.0;
   double sum2 = 0.0;
   for(int j=0; j<VolatilityWindow; j++)
   {
      int s=shift+j;
      double center=iMA(NULL,0,
                        CenterPeriod,
                        0,
                        MODE_EMA,
                        PRICE_CLOSE,
                        s);
      double residual=iClose(NULL,0,s)-center;
      sum  += residual;
      sum2 += residual*residual;
   }
   double n=(double)VolatilityWindow;
   double mean=sum/n;
   double variance=(sum2/n)-(mean*mean);
   // Floating-point protection only.
   if(variance < 0.0 && variance > -1.0e-15)
      variance=0.0;
   if(variance < 0.0 || !MathIsValidNumber(variance))
      return false;
   outSigma=MathSqrt(variance);
   return MathIsValidNumber(outSigma);
}
// -----------------------------------------------------------------------------
int OnInit()
{
   if(CenterPeriod < 1 ||
      VolatilityWindow < 2 ||
      InnerK <= 0.0 ||
      OuterK <= InnerK)
   {
      Print("[AS][CHANNEL01][ERROR] invalid inputs",
            " CenterPeriod=",CenterPeriod,
            " VolatilityWindow=",VolatilityWindow,
            " InnerK=",DoubleToString(InnerK,4),
            " OuterK=",DoubleToString(OuterK,4));
      return(INIT_PARAMETERS_INCORRECT);
   }
   IndicatorBuffers(5);
   SetIndexBuffer(0,BufCenter);
   SetIndexBuffer(1,BufInnerHigh);
   SetIndexBuffer(2,BufInnerLow);
   SetIndexBuffer(3,BufOuterHigh);
   SetIndexBuffer(4,BufOuterLow);
   ArraySetAsSeries(BufCenter,true);
   ArraySetAsSeries(BufInnerHigh,true);
   ArraySetAsSeries(BufInnerLow,true);
   ArraySetAsSeries(BufOuterHigh,true);
   ArraySetAsSeries(BufOuterLow,true);
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,1,clrAqua);
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,2,clrGold);
   SetIndexStyle(2,DRAW_LINE,STYLE_SOLID,2,clrGold);
   SetIndexStyle(3,DRAW_LINE,STYLE_DOT,1,clrSilver);
   SetIndexStyle(4,DRAW_LINE,STYLE_DOT,1,clrSilver);
   IndicatorDigits(Digits);
   SetIndexLabel(0,"CENTER");
   SetIndexLabel(1,"INNER_HIGH");
   SetIndexLabel(2,"INNER_LOW");
   SetIndexLabel(3,"OUTER_HIGH");
   SetIndexLabel(4,"OUTER_LOW");
   for(int i=0;i<5;i++)
      SetIndexEmptyValue(i,EMPTY_VALUE);
   IndicatorShortName(
      "AS_Channel_01 EMA"+
      IntegerToString(CenterPeriod)+
      " V"+
      IntegerToString(VolatilityWindow));
   Print("[AS][CHANNEL01] INIT",
         " CenterPeriod=",CenterPeriod,
         " VolatilityWindow=",VolatilityWindow,
         " InnerK=",DoubleToString(InnerK,4),
         " OuterK=",DoubleToString(OuterK,4));
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
   Print("[AS][CHANNEL01][CALC_ENTER]",
         " rates_total=",rates_total,
         " prev_calculated=",prev_calculated);
   int minimum=CenterPeriod+VolatilityWindow-1;
   if(rates_total < minimum)
      return(0);
   int limit;
   if(prev_calculated==0)
   {
      ArrayInitialize(BufCenter,EMPTY_VALUE);
      ArrayInitialize(BufInnerHigh,EMPTY_VALUE);
      ArrayInitialize(BufInnerLow,EMPTY_VALUE);
      ArrayInitialize(BufOuterHigh,EMPTY_VALUE);
      ArrayInitialize(BufOuterLow,EMPTY_VALUE);
      limit=rates_total-VolatilityWindow-CenterPeriod+1;
   }
   else
   {
      // Recalculate current bar and previous closed bar.
      limit=1;
   }
   for(int b=limit; b>=0; b--)
   {
      double sigma=0.0;
      if(!ResidualStdDev(b,rates_total,sigma))
      {
         BufCenter[b]    =EMPTY_VALUE;
         BufInnerHigh[b] =EMPTY_VALUE;
         BufInnerLow[b]  =EMPTY_VALUE;
         BufOuterHigh[b] =EMPTY_VALUE;
         BufOuterLow[b]  =EMPTY_VALUE;
         continue;
      }
      double center=iMA(NULL,0,
                        CenterPeriod,
                        0,
                        MODE_EMA,
                        PRICE_CLOSE,
                        b);
      BufCenter[b]=center;
      BufInnerHigh[b]=center + InnerK*sigma;
      BufInnerLow[b] =center - InnerK*sigma;
      BufOuterHigh[b]=center + OuterK*sigma;
      BufOuterLow[b] =center - OuterK*sigma;
   }
   if(prev_calculated==0)
   {
      double testSigma=0.0;
      bool testOk=ResidualStdDev(1,rates_total,testSigma);
      double testCenter=iMA(NULL,0,
                            CenterPeriod,
                            0,
                            MODE_EMA,
                            PRICE_CLOSE,
                            1);
      Print("[AS][CHANNEL01][DIAG]",
            " rates_total=",rates_total,
            " minimum=",minimum,
            " test_ok=",testOk,
            " center=",DoubleToString(testCenter,8),
            " sigma=",DoubleToString(testSigma,8),
            " B0=",DoubleToString(BufCenter[1],8),
            " B1=",DoubleToString(BufInnerHigh[1],8),
            " B2=",DoubleToString(BufInnerLow[1],8),
            " B3=",DoubleToString(BufOuterHigh[1],8),
            " B4=",DoubleToString(BufOuterLow[1],8));
   }
   return(rates_total);
}




