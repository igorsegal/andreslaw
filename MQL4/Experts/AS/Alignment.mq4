#property strict
input int BarsToScan = 500;
input int WindowBars = 5;
int g_phase=0;
// AS_Waves v8 raw buffers:
// AS2 = 8
// AS3 = 9
// AS4 = 10
double WaveValue(int waveIndex,int shift)
{
   int buffer=6+waveIndex;
   ResetLastError();
   return iCustom(
      NULL,
      PERIOD_H1,
      "AS\\Waves",
      12,60,288,1440,7200,
      0.7,
      2000,
      0.25,
      1.0,
      1.0,
      buffer,
      shift
   );
}
double SWT_R(int shift)
{
   return iCustom(
      NULL,PERIOD_H1,"SWTsr",
      true,false,
      34,shift
   );
}
double SWT_S(int shift)
{
   return iCustom(
      NULL,PERIOD_H1,"SWTsr",
      true,false,
      35,shift
   );
}
bool Valid(double v)
{
   return(v!=EMPTY_VALUE &&
          MathIsValidNumber(v));
}
bool SWTChanged(int shift)
{
   double oldR=SWT_R(shift+1);
   double oldS=SWT_S(shift+1);
   double newR=SWT_R(shift);
   double newS=SWT_S(shift);
   if(!Valid(oldR) || !Valid(oldS) ||
      !Valid(newR) || !Valid(newS))
      return false;
   return(
      MathAbs(newR-oldR)>Point*0.1 ||
      MathAbs(newS-oldS)>Point*0.1
   );
}
bool ZeroCrossAt(int waveIndex,int shift)
{
   if(shift<1)
      return false;
   double older=WaveValue(waveIndex,shift+1);
   double newer=WaveValue(waveIndex,shift);
   if(!Valid(older) || !Valid(newer))
      return false;
   bool up=
      (older<=0.0 && newer>0.0);
   bool down=
      (older>=0.0 && newer<0.0);
   return(up || down);
}
// delta:
// negative = wave cross BEFORE SWTsr change
// zero     = same bar
// positive = wave cross AFTER SWTsr change
int NearestCrossDelta(
   int waveIndex,
   int eventShift,
   bool &found)
{
   found=false;
   int bestDelta=0;
   int bestAbs=999999;
   for(int delta=-WindowBars;
       delta<=WindowBars;
       delta++)
   {
      int crossShift=eventShift-delta;
      // Never use forming bar 0.
      if(crossShift<1)
         continue;
      if(!ZeroCrossAt(waveIndex,crossShift))
         continue;
      int a=MathAbs(delta);
      if(a<bestAbs)
      {
         bestAbs=a;
         bestDelta=delta;
         found=true;
      }
   }
   return bestDelta;
}
void PrintBins(
   string waveName,
   int &bins[],
   int matched,
   int noMatch)
{
   Print(
      "[AS][WAVE_SWTSR_ALIGN] ",
      waveName,
      " matched=",matched,
      " noMatch=",noMatch,
      " d-5=",bins[0],
      " d-4=",bins[1],
      " d-3=",bins[2],
      " d-2=",bins[3],
      " d-1=",bins[4],
      " d0=", bins[5],
      " d+1=",bins[6],
      " d+2=",bins[7],
      " d+3=",bins[8],
      " d+4=",bins[9],
      " d+5=",bins[10]
   );
}
void Analyze()
{
   int bins2[11];
   int bins3[11];
   int bins4[11];
   ArrayInitialize(bins2,0);
   ArrayInitialize(bins3,0);
   ArrayInitialize(bins4,0);
   int events=0;
   int matched2=0, matched3=0, matched4=0;
   int no2=0, no3=0, no4=0;
   for(int s=BarsToScan; s>=1; s--)
   {
      if(!SWTChanged(s))
         continue;
      events++;
      bool f2=false;
      bool f3=false;
      bool f4=false;
      int d2=NearestCrossDelta(2,s,f2);
      int d3=NearestCrossDelta(3,s,f3);
      int d4=NearestCrossDelta(4,s,f4);
      if(f2)
      {
         bins2[d2+5]++;
         matched2++;
      }
      else no2++;
      if(f3)
      {
         bins3[d3+5]++;
         matched3++;
      }
      else no3++;
      if(f4)
      {
         bins4[d4+5]++;
         matched4++;
      }
      else no4++;
      Print(
         "[AS][WAVE_SWTSR_ALIGN] EVENT",
         " time=",
         TimeToString(
            iTime(NULL,PERIOD_H1,s),
            TIME_DATE|TIME_MINUTES
         ),
         " AS2=",f2 ? d2 : 99,
         " AS3=",f3 ? d3 : 99,
         " AS4=",f4 ? d4 : 99
      );
   }
   Print(
      "[AS][WAVE_SWTSR_ALIGN] SUMMARY",
      " events=",events,
      " window=+/-",WindowBars
   );
   PrintBins("AS2",bins2,matched2,no2);
   PrintBins("AS3",bins3,matched3,no3);
   PrintBins("AS4",bins4,matched4,no4);
   Print("[AS][WAVE_SWTSR_ALIGN] DONE");
}
int OnInit()
{
   Print(
      "[AS][WAVE_SWTSR_ALIGN] INIT",
      " bars=",BarsToScan,
      " window=",WindowBars
   );
   EventSetTimer(3);
   return(INIT_SUCCEEDED);
}
void OnTimer()
{
   if(g_phase==0)
   {
      // Warm up both indicators.
      for(int s=1;
          s<=BarsToScan+WindowBars+2;
          s++)
      {
         SWT_R(s);
         SWT_S(s);
         WaveValue(2,s);
         WaveValue(3,s);
         WaveValue(4,s);
      }
      Print("[AS][WAVE_SWTSR_ALIGN] WARMUP_DONE");
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



