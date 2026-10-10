#property strict

input int BarsToScan = 500;
int g_phase = 0;

// Proven SWTsr W4 buffers:
// 34 = srw4:R
// 35 = srw4:S
double SWT_R(int shift)
{
   ResetLastError();
   return iCustom(
      NULL,
      PERIOD_H1,
      "SWTsr",
      true,
      false,
      34,
      shift
   );
}

double SWT_S(int shift)
{
   ResetLastError();
   return iCustom(
      NULL,
      PERIOD_H1,
      "SWTsr",
      true,
      false,
      35,
      shift
   );
}

// AS_sr buffers:
// 0 = confirmed Resistance
// 1 = confirmed Support
// 2 = Resistance guide during SEEK
// 3 = Support guide during SEEK
double AS_R(int shift)
{
   ResetLastError();
   return iCustom(
      NULL,
      PERIOD_H1,
      "AS\\sr",
      0,
      shift
   );
}

double AS_S(int shift)
{
   ResetLastError();
   return iCustom(
      NULL,
      PERIOD_H1,
      "AS\\sr",
      1,
      shift
   );
}

double AS_RG(int shift)
{
   ResetLastError();
   return iCustom(
      NULL,
      PERIOD_H1,
      "AS\\sr",
      2,
      shift
   );
}

double AS_SG(int shift)
{
   ResetLastError();
   return iCustom(
      NULL,
      PERIOD_H1,
      "AS\\sr",
      3,
      shift
   );
}

bool ValidPrice(double v)
{
   return(
      v != EMPTY_VALUE &&
      MathIsValidNumber(v) &&
      v > 0.0
   );
}

bool ValidPair(double r,double s)
{
   return(
      ValidPrice(r) &&
      ValidPrice(s) &&
      r > s
   );
}

void Push(double &arr[],int &count,double value)
{
   count++;
   ArrayResize(arr,count);
   arr[count-1]=value;
}

double QuantileSorted(double &arr[],int count,double q)
{
   if(count<=0)
      return 0.0;

   if(count==1)
      return arr[0];

   double pos=q*(count-1);
   int lo=(int)MathFloor(pos);
   int hi=(int)MathCeil(pos);

   if(lo==hi)
      return arr[lo];

   double w=pos-lo;
   return arr[lo]*(1.0-w)+arr[hi]*w;
}

void PrintRatioStats(
   string tag,
   double &ratios[],
   int count)
{
   if(count<=0)
   {
      Print("[AS][SWTSR_ASSR_WIDTH] ",tag," NO_DATA");
      return;
   }

   ArraySort(ratios,WHOLE_ARRAY,0,MODE_ASCEND);

   double sum=0.0;
   for(int i=0;i<count;i++)
      sum+=ratios[i];

   Print(
      "[AS][SWTSR_ASSR_WIDTH] ",tag,
      " n=",count,
      " mean=",DoubleToString(sum/count,6),
      " min=",DoubleToString(ratios[0],6),
      " p25=",DoubleToString(QuantileSorted(ratios,count,0.25),6),
      " median=",DoubleToString(QuantileSorted(ratios,count,0.50),6),
      " p75=",DoubleToString(QuantileSorted(ratios,count,0.75),6),
      " max=",DoubleToString(ratios[count-1],6)
   );
}

void Analyze()
{
   int swtValid=0;
   int asActiveValid=0;
   int asGuideValid=0;
   int asInvalid=0;

   int pairedActive=0;
   int pairedEffective=0;

   double sumSwtActive=0.0;
   double sumAsActive=0.0;
   double sumSwtEffective=0.0;
   double sumAsEffective=0.0;

   double ratiosActive[];
   double ratiosEffective[];
   int activeCount=0;
   int effectiveCount=0;

   for(int s=BarsToScan; s>=1; s--)
   {
      double swtR=SWT_R(s);
      double swtS=SWT_S(s);

      bool swtOk=ValidPair(swtR,swtS);
      if(swtOk)
         swtValid++;

      double asR=AS_R(s);
      double asS=AS_S(s);
      double asRG=AS_RG(s);
      double asSG=AS_SG(s);

      bool activeOk=ValidPair(asR,asS);
      bool guideOk=ValidPair(asRG,asSG);

      if(activeOk)
         asActiveValid++;
      else if(guideOk)
         asGuideValid++;
      else
         asInvalid++;

      if(swtOk && activeOk)
      {
         double swtW=swtR-swtS;
         double asW=asR-asS;

         if(swtW>0.0 && asW>0.0)
         {
            pairedActive++;
            sumSwtActive+=swtW;
            sumAsActive+=asW;
            Push(ratiosActive,activeCount,swtW/asW);
         }
      }

      double effR=0.0;
      double effS=0.0;
      bool effectiveOk=false;

      if(activeOk)
      {
         effR=asR;
         effS=asS;
         effectiveOk=true;
      }
      else if(guideOk)
      {
         effR=asRG;
         effS=asSG;
         effectiveOk=true;
      }

      if(swtOk && effectiveOk)
      {
         double swtW=swtR-swtS;
         double asW=effR-effS;

         if(swtW>0.0 && asW>0.0)
         {
            pairedEffective++;
            sumSwtEffective+=swtW;
            sumAsEffective+=asW;
            Push(ratiosEffective,effectiveCount,swtW/asW);
         }
      }
   }

   Print(
      "[AS][SWTSR_ASSR_WIDTH] SUMMARY",
      " bars=",BarsToScan,
      " swtValid=",swtValid,
      " asActive=",asActiveValid,
      " asGuide=",asGuideValid,
      " asInvalid=",asInvalid,
      " pairedActive=",pairedActive,
      " pairedEffective=",pairedEffective
   );

   if(pairedActive>0)
   {
      double meanSwt=sumSwtActive/pairedActive;
      double meanAs=sumAsActive/pairedActive;

      Print(
         "[AS][SWTSR_ASSR_WIDTH] ACTIVE_MEAN",
         " SWT=",DoubleToString(meanSwt,8),
         " AS=",DoubleToString(meanAs,8),
         " SWT_DIV_AS=",
         DoubleToString(
            meanAs>0.0 ? meanSwt/meanAs : 0.0,
            6
         )
      );
   }

   if(pairedEffective>0)
   {
      double meanSwt=sumSwtEffective/pairedEffective;
      double meanAs=sumAsEffective/pairedEffective;

      Print(
         "[AS][SWTSR_ASSR_WIDTH] EFFECTIVE_MEAN",
         " SWT=",DoubleToString(meanSwt,8),
         " AS=",DoubleToString(meanAs,8),
         " SWT_DIV_AS=",
         DoubleToString(
            meanAs>0.0 ? meanSwt/meanAs : 0.0,
            6
         )
      );
   }

   PrintRatioStats(
      "ACTIVE_RATIO SWT_DIV_AS",
      ratiosActive,
      activeCount
   );

   PrintRatioStats(
      "EFFECTIVE_RATIO SWT_DIV_AS",
      ratiosEffective,
      effectiveCount
   );

   Print("[AS][SWTSR_ASSR_WIDTH] DONE");
}

int OnInit()
{
   Print(
      "[AS][SWTSR_ASSR_WIDTH] INIT bars=",
      BarsToScan
   );

   EventSetTimer(3);
   return(INIT_SUCCEEDED);
}

void OnTimer()
{
   if(g_phase==0)
   {
      // Warm up both indicators before historical scan.
      for(int s=1; s<=BarsToScan+2; s++)
      {
         SWT_R(s);
         SWT_S(s);
         AS_R(s);
         AS_S(s);
         AS_RG(s);
         AS_SG(s);
      }

      Print("[AS][SWTSR_ASSR_WIDTH] WARMUP_DONE");
      g_phase=1;
      return;
   }

   EventKillTimer();
   Analyze();
}

void OnDeinit(const int reason)
{
   EventKillTimer();
}

void OnTick()
{
}
