#property strict
input int BarsToScan = 500;
int g_phase = 0;
bool ValidPrice(double v)
{
   if(v == EMPTY_VALUE) return false;
   if(v <= 0.0) return false;
   return true;
}
double SWT_H(int shift)
{
   return iCustom(NULL,PERIOD_H1,"SWTch",
                  false,   // W2_CH
                  false,   // W3_SR
                  true,    // W4_SR
                  false,   // ShowCenterLine
                  14,shift);
}
double SWT_L(int shift)
{
   return iCustom(NULL,PERIOD_H1,"SWTch",
                  false,
                  false,
                  true,
                  false,
                  15,shift);
}
double SWT_C(int shift)
{
   return iCustom(NULL,PERIOD_H1,"SWTch",
                  false,
                  false,
                  true,
                  false,
                  20,shift);
}double OUR_H(int shift)
{
   return iCustom(NULL,0,"AS\\AS_Channel_01",
                  20,50,2.0,3.0,
                  1,shift);
}
double OUR_L(int shift)
{
   return iCustom(NULL,0,"AS\\AS_Channel_01",
                  20,50,2.0,3.0,
                  2,shift);
}
int OnInit()
{
   Print("[AS][CHANNEL_COMPARE] INIT bars=",BarsToScan);
   EventSetTimer(3);
   return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason)
{
   EventKillTimer();
}
void OnTimer()
{
   if(g_phase == 0)
   {
      // SWTch historically needs warm-up before a reliable historical scan.
      for(int b=1; b<=BarsToScan+2; b++)
      {
         double a=SWT_H(b);
         double c=SWT_L(b);
         double d=OUR_H(b);
         double e=OUR_L(b);
      }
      Print("[AS][CHANNEL_COMPARE] WARMUP_DONE");
      g_phase=1;
      return;
   }
   EventKillTimer();
   int valid=0;
   int invalid=0;
   int stepPairs=0;
   double sumSwtWidth=0.0;
   double sumOurWidth=0.0;
   double sumSwtUpperFromCenter=0.0;
   double sumSwtLowerFromCenter=0.0;
   int swtShapeValid=0;
   int swtCenterOutside=0;
   double sumCenterAbsDelta=0.0;
   double sumHighAbsDelta=0.0;
   double sumLowAbsDelta=0.0;
   double sumSwtHighStep=0.0;
   double sumSwtLowStep=0.0;
   double sumOurHighStep=0.0;
   double sumOurLowStep=0.0;
   double sumSwtCenterStep=0.0;
   double sumOurCenterStep=0.0;
   double sumSwtHalfWidthStep=0.0;
   double sumOurHalfWidthStep=0.0;
   for(int b=1; b<=BarsToScan; b++)
   {
      double sh=SWT_H(b);
      double sl=SWT_L(b);
      double sc=SWT_C(b);
      double oh=OUR_H(b);
      double ol=OUR_L(b);
      if(b==1)
      {
         Print("[AS][CHANNEL_COMPARE][RAW]",
               " SWT_H=",DoubleToString(sh,8),
               " SWT_L=",DoubleToString(sl,8),
               " OUR_H=",DoubleToString(oh,8),
               " OUR_L=",DoubleToString(ol,8),
               " err=",GetLastError());
      }
      if(!ValidPrice(sh) || !ValidPrice(sl) ||
         !ValidPrice(sc) ||
         !ValidPrice(oh) || !ValidPrice(ol) ||
         sh<=sl || oh<=ol)
      {
         invalid++;
         continue;
      }
      valid++;
      double sw = sh-sl;
      double ow = oh-ol;
      double oc = (oh+ol)/2.0;
      if(sc>=sl && sc<=sh)
      {
         swtShapeValid++;
         sumSwtUpperFromCenter += (sh-sc);
         sumSwtLowerFromCenter += (sc-sl);
      }
      else
      {
         swtCenterOutside++;
      }
      sumSwtWidth += sw;
      sumOurWidth += ow;
      sumCenterAbsDelta += MathAbs(oc-sc);
      sumHighAbsDelta   += MathAbs(oh-sh);
      sumLowAbsDelta    += MathAbs(ol-sl);
      if(b < BarsToScan)
      {
         double sh2=SWT_H(b+1);
         double sl2=SWT_L(b+1);
         double sc2=SWT_C(b+1);
         double oh2=OUR_H(b+1);
         double ol2=OUR_L(b+1);
         if(ValidPrice(sh2) && ValidPrice(sl2) &&
            ValidPrice(sc2) &&
            ValidPrice(oh2) && ValidPrice(ol2))
         {
            stepPairs++;
            sumSwtHighStep += MathAbs(sh-sh2);
            sumSwtLowStep  += MathAbs(sl-sl2);
            sumOurHighStep += MathAbs(oh-oh2);
            sumOurLowStep  += MathAbs(ol-ol2);
            double oc2=(oh2+ol2)/2.0;
            sumSwtCenterStep += MathAbs(sc-sc2);
            sumOurCenterStep += MathAbs(oc-oc2);
            double swHalf =(sh-sl)/2.0;
            double swHalf2=(sh2-sl2)/2.0;
            double owHalf =(oh-ol)/2.0;
            double owHalf2=(oh2-ol2)/2.0;
            sumSwtHalfWidthStep += MathAbs(swHalf-swHalf2);
            sumOurHalfWidthStep += MathAbs(owHalf-owHalf2);
         }
      }
   }
   Print("[AS][CHANNEL_COMPARE] SUMMARY",
         " valid=",valid,
         " invalid=",invalid);
   if(valid > 0)
   {
      double meanSwtWidth = sumSwtWidth/valid;
      double meanOurWidth = sumOurWidth/valid;
      Print("[AS][CHANNEL_COMPARE] WIDTH",
            " SWT=",DoubleToString(meanSwtWidth,8),
            " OUR=",DoubleToString(meanOurWidth,8),
            " OUR_DIV_SWT=",
            DoubleToString(
               (meanSwtWidth>0.0 ? meanOurWidth/meanSwtWidth : 0.0),4));
      if(swtShapeValid > 0)
      {
         double meanUpper=sumSwtUpperFromCenter/swtShapeValid;
         double meanLower=sumSwtLowerFromCenter/swtShapeValid;
         Print("[AS][CHANNEL_COMPARE] SWT_SHAPE",
               " valid=",swtShapeValid,
               " center_outside=",swtCenterOutside,
               " upper_from_CL=",DoubleToString(meanUpper,8),
               " lower_from_CL=",DoubleToString(meanLower,8),
               " U_DIV_L=",
               DoubleToString((meanLower>0.0 ? meanUpper/meanLower : 0.0),4));
      }
      Print("[AS][CHANNEL_COMPARE] POSITION",
            " center_MAE=",DoubleToString(sumCenterAbsDelta/valid,8),
            " high_MAE=",DoubleToString(sumHighAbsDelta/valid,8),
            " low_MAE=",DoubleToString(sumLowAbsDelta/valid,8));
   }
   if(stepPairs > 0)
   {
      Print("[AS][CHANNEL_COMPARE] CENTER_STEP",
            " SWT=",DoubleToString(sumSwtCenterStep/stepPairs,8),
            " OUR=",DoubleToString(sumOurCenterStep/stepPairs,8));
      Print("[AS][CHANNEL_COMPARE] HALF_WIDTH_STEP",
            " SWT=",DoubleToString(sumSwtHalfWidthStep/stepPairs,8),
            " OUR=",DoubleToString(sumOurHalfWidthStep/stepPairs,8));
      Print("[AS][CHANNEL_COMPARE] STEP",
            " pairs=",stepPairs,
            " SWT_H=",DoubleToString(sumSwtHighStep/stepPairs,8),
            " SWT_L=",DoubleToString(sumSwtLowStep/stepPairs,8),
            " OUR_H=",DoubleToString(sumOurHighStep/stepPairs,8),
            " OUR_L=",DoubleToString(sumOurLowStep/stepPairs,8));
   }
   Print("[AS][CHANNEL_COMPARE] DONE");
}





