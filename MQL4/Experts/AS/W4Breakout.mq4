#property strict
input int BarsToScan = 500;
int g_phase = 0;
// Proven SWTsr W4 buffers:
// mode 34 = srw4:R
// mode 35 = srw4:S
double SWT_R(int shift)
{
   ResetLastError();
   return iCustom(NULL,PERIOD_H1,"SWTsr",
                  true,false,
                  34,shift);
}
double SWT_S(int shift)
{
   ResetLastError();
   return iCustom(NULL,PERIOD_H1,"SWTsr",
                  true,false,
                  35,shift);
}
bool Valid(double v)
{
   return(v != EMPTY_VALUE &&
          MathIsValidNumber(v) &&
          v != 0.0);
}
bool LevelChanged(double a,double b)
{
   return(MathAbs(a-b) > Point*0.1);
}
void Analyze()
{
   int validPairs=0;
   int invalidPairs=0;
   int flatPairs=0;
   int changePairs=0;
   int rChanges=0;
   int sChanges=0;
   int bothChanges=0;
   int changeSameBarStrictBreak=0;
   int changePrevBarStrictBreak=0;
   int changeTwoBarStrictBreak=0;
   int changeSameBarTouch=0;
   int changePrevBarTouch=0;
   int changeTwoBarTouch=0;
   int flatSameBarStrictBreak=0;
   int flatSameBarTouch=0;
   for(int s=BarsToScan; s>=1; s--)
   {
      // Older state = shift s+1
      // Newer/current state = shift s
      double oldR=SWT_R(s+1);
      double oldS=SWT_S(s+1);
      double newR=SWT_R(s);
      double newS=SWT_S(s);
      if(!Valid(oldR) || !Valid(oldS) ||
         !Valid(newR) || !Valid(newS))
      {
         invalidPairs++;
         continue;
      }
      validPairs++;
      bool rChanged=LevelChanged(newR,oldR);
      bool sChanged=LevelChanged(newS,oldS);
      bool anyChanged=(rChanged || sChanged);
      double hNow=iHigh(NULL,PERIOD_H1,s);
      double lNow=iLow(NULL,PERIOD_H1,s);
      double hPrev=iHigh(NULL,PERIOD_H1,s+1);
      double lPrev=iLow(NULL,PERIOD_H1,s+1);
      bool sameRStrict=(hNow > oldR);
      bool sameSStrict=(lNow < oldS);
      bool sameStrict=(sameRStrict || sameSStrict);
      bool prevRStrict=(hPrev > oldR);
      bool prevSStrict=(lPrev < oldS);
      bool prevStrict=(prevRStrict || prevSStrict);
      bool sameRTouch=(hNow >= oldR);
      bool sameSTouch=(lNow <= oldS);
      bool sameTouch=(sameRTouch || sameSTouch);
      bool prevRTouch=(hPrev >= oldR);
      bool prevSTouch=(lPrev <= oldS);
      bool prevTouch=(prevRTouch || prevSTouch);
      if(anyChanged)
      {
         changePairs++;
         if(rChanged) rChanges++;
         if(sChanged) sChanges++;
         if(rChanged && sChanged) bothChanges++;
         if(sameStrict) changeSameBarStrictBreak++;
         if(prevStrict) changePrevBarStrictBreak++;
         if(sameStrict || prevStrict) changeTwoBarStrictBreak++;
         if(sameTouch) changeSameBarTouch++;
         if(prevTouch) changePrevBarTouch++;
         if(sameTouch || prevTouch) changeTwoBarTouch++;
         Print("[AS][SWTSR_W4_BREAKOUT] CHANGE",
               " time=",TimeToString(iTime(NULL,PERIOD_H1,s),
                                     TIME_DATE|TIME_MINUTES),
               " oldR=",DoubleToString(oldR,Digits),
               " oldS=",DoubleToString(oldS,Digits),
               " newR=",DoubleToString(newR,Digits),
               " newS=",DoubleToString(newS,Digits),
               " H=",DoubleToString(hNow,Digits),
               " L=",DoubleToString(lNow,Digits),
               " rChanged=",rChanged,
               " sChanged=",sChanged,
               " sameStrict=",sameStrict,
               " prevStrict=",prevStrict,
               " sameTouch=",sameTouch,
               " prevTouch=",prevTouch);
      }
      else
      {
         flatPairs++;
         if(sameStrict)
            flatSameBarStrictBreak++;
         if(sameTouch)
            flatSameBarTouch++;
      }
   }
   Print("[AS][SWTSR_W4_BREAKOUT] SUMMARY",
         " validPairs=",validPairs,
         " invalidPairs=",invalidPairs,
         " flatPairs=",flatPairs,
         " changePairs=",changePairs);
   Print("[AS][SWTSR_W4_BREAKOUT] CHANGES",
         " R=",rChanges,
         " S=",sChanges,
         " BOTH=",bothChanges);
   Print("[AS][SWTSR_W4_BREAKOUT] CHANGE_STRICT",
         " sameBar=",changeSameBarStrictBreak,
         " prevBar=",changePrevBarStrictBreak,
         " twoBar=",changeTwoBarStrictBreak);
   Print("[AS][SWTSR_W4_BREAKOUT] CHANGE_TOUCH",
         " sameBar=",changeSameBarTouch,
         " prevBar=",changePrevBarTouch,
         " twoBar=",changeTwoBarTouch);
   Print("[AS][SWTSR_W4_BREAKOUT] FLAT",
         " strictBreakWhileUnchanged=",flatSameBarStrictBreak,
         " touchWhileUnchanged=",flatSameBarTouch);
   Print("[AS][SWTSR_W4_BREAKOUT] DONE");
}
int OnInit()
{
   Print("[AS][SWTSR_W4_BREAKOUT] INIT bars=",BarsToScan);
   EventSetTimer(3);
   return(INIT_SUCCEEDED);
}
void OnTimer()
{
   if(g_phase==0)
   {
      // Warm-up original SWTsr historical buffers
      for(int s=1; s<=BarsToScan+2; s++)
      {
         SWT_R(s);
         SWT_S(s);
      }
      Print("[AS][SWTSR_W4_BREAKOUT] WARMUP_DONE");
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
