#property strict

input int BarsToScan = 500;

double SWT_R(int shift)
{
   ResetLastError();
   return iCustom(NULL,PERIOD_H1,"SWTsr",true,false,34,shift);
}

double SWT_S(int shift)
{
   ResetLastError();
   return iCustom(NULL,PERIOD_H1,"SWTsr",true,false,35,shift);
}

bool ValidPrice(double v)
{
   return(v!=EMPTY_VALUE && MathIsValidNumber(v) && v>0.0);
}

bool ValidPair(double r,double s)
{
   return(ValidPrice(r) && ValidPrice(s) && r>s);
}

bool Changed(double a,double b)
{
   return(MathAbs(a-b)>Point*0.1);
}

bool SWTChangedAt(int shift)
{
   if(shift<1 || shift>=Bars-1)
      return false;

   double oldR=SWT_R(shift+1);
   double oldS=SWT_S(shift+1);
   double newR=SWT_R(shift);
   double newS=SWT_S(shift);

   if(!ValidPair(oldR,oldS) || !ValidPair(newR,newS))
      return false;

   return(Changed(oldR,newR) || Changed(oldS,newS));
}

double BodyHigh(int shift)
{
   return MathMax(
      iOpen(NULL,PERIOD_H1,shift),
      iClose(NULL,PERIOD_H1,shift)
   );
}

double BodyLow(int shift)
{
   return MathMin(
      iOpen(NULL,PERIOD_H1,shift),
      iClose(NULL,PERIOD_H1,shift)
   );
}

bool Near(double a,double b)
{
   return(MathAbs(a-b)<=Point*0.5);
}

void Analyze()
{
   int bars=MathMin(BarsToScan,Bars-3);
   if(bars<20)
   {
      Print("[AS][SWTSR_RESET] FAIL insufficient_history bars=",bars);
      return;
   }

   int changes=0;
   int upBreak=0;
   int downBreak=0;
   int bothBreak=0;
   int noDirectionalBreak=0;
   int completeSegments=0;

   int newR_eq_segHigh=0;
   int newR_eq_segBodyHigh=0;
   int newS_eq_segLow=0;
   int newS_eq_segBodyLow=0;

   int newR_eq_breakHigh=0;
   int newR_eq_breakBodyHigh=0;
   int newS_eq_breakLow=0;
   int newS_eq_breakBodyLow=0;

   int width_eq_maxBarRange=0;
   int width_eq_segWickRange=0;
   int width_eq_segBodyRange=0;

   double sumWidthDivOldWidth=0.0;
   int nWidthDivOldWidth=0;

   double sumWidthDivMaxBarRange=0.0;
   int nWidthDivMaxBarRange=0;

   double sumWidthDivSegWickRange=0.0;
   int nWidthDivSegWickRange=0;

   double sumWidthDivSegBodyRange=0.0;
   int nWidthDivSegBodyRange=0;

   for(int s=bars; s>=1; s--)
   {
      if(!SWTChangedAt(s))
         continue;

      changes++;

      double oldR=SWT_R(s+1);
      double oldS=SWT_S(s+1);
      double newR=SWT_R(s);
      double newS=SWT_S(s);

      double oldW=oldR-oldS;
      double newW=newR-newS;

      int breakShift=s+1;
      double breakH=iHigh(NULL,PERIOD_H1,breakShift);
      double breakL=iLow(NULL,PERIOD_H1,breakShift);
      double breakBH=BodyHigh(breakShift);
      double breakBL=BodyLow(breakShift);

      bool brokeUp=(breakH>oldR);
      bool brokeDown=(breakL<oldS);

      if(brokeUp && brokeDown) bothBreak++;
      else if(brokeUp) upBreak++;
      else if(brokeDown) downBreak++;
      else noDirectionalBreak++;

      if(Near(newR,breakH)) newR_eq_breakHigh++;
      if(Near(newR,breakBH)) newR_eq_breakBodyHigh++;
      if(Near(newS,breakL)) newS_eq_breakLow++;
      if(Near(newS,breakBL)) newS_eq_breakBodyLow++;

      if(oldW>0.0 && newW>0.0)
      {
         sumWidthDivOldWidth += newW/oldW;
         nWidthDivOldWidth++;
      }

      // Find the previous (older) SWTsr change.  The old pair spans
      // from that change through the breakout bar s+1.
      int prevChange=-1;
      for(int p=s+1; p<=bars+1 && p<Bars-1; p++)
      {
         if(SWTChangedAt(p))
         {
            prevChange=p;
            break;
         }
      }

      if(prevChange<0)
      {
         Print(
            "[AS][SWTSR_RESET] CHANGE",
            " time=",TimeToString(iTime(NULL,PERIOD_H1,s),TIME_DATE|TIME_MINUTES),
            " dir=",(brokeUp && !brokeDown ? 1 : (brokeDown && !brokeUp ? -1 : 0)),
            " oldW=",DoubleToString(oldW,Digits),
            " newW=",DoubleToString(newW,Digits),
            " segment=INCOMPLETE"
         );
         continue;
      }

      completeSegments++;

      double segHigh=-DBL_MAX;
      double segLow=DBL_MAX;
      double segBodyHigh=-DBL_MAX;
      double segBodyLow=DBL_MAX;
      double maxBarRange=0.0;

      for(int b=s+1; b<=prevChange; b++)
      {
         double h=iHigh(NULL,PERIOD_H1,b);
         double l=iLow(NULL,PERIOD_H1,b);
         double bh=BodyHigh(b);
         double bl=BodyLow(b);

         if(h>segHigh) segHigh=h;
         if(l<segLow) segLow=l;
         if(bh>segBodyHigh) segBodyHigh=bh;
         if(bl<segBodyLow) segBodyLow=bl;

         double barRange=h-l;
         if(barRange>maxBarRange)
            maxBarRange=barRange;
      }

      double segWickRange=segHigh-segLow;
      double segBodyRange=segBodyHigh-segBodyLow;

      if(Near(newR,segHigh)) newR_eq_segHigh++;
      if(Near(newR,segBodyHigh)) newR_eq_segBodyHigh++;
      if(Near(newS,segLow)) newS_eq_segLow++;
      if(Near(newS,segBodyLow)) newS_eq_segBodyLow++;

      if(Near(newW,maxBarRange)) width_eq_maxBarRange++;
      if(Near(newW,segWickRange)) width_eq_segWickRange++;
      if(Near(newW,segBodyRange)) width_eq_segBodyRange++;

      if(maxBarRange>0.0)
      {
         sumWidthDivMaxBarRange += newW/maxBarRange;
         nWidthDivMaxBarRange++;
      }

      if(segWickRange>0.0)
      {
         sumWidthDivSegWickRange += newW/segWickRange;
         nWidthDivSegWickRange++;
      }

      if(segBodyRange>0.0)
      {
         sumWidthDivSegBodyRange += newW/segBodyRange;
         nWidthDivSegBodyRange++;
      }

      Print(
         "[AS][SWTSR_RESET] CHANGE",
         " time=",TimeToString(iTime(NULL,PERIOD_H1,s),TIME_DATE|TIME_MINUTES),
         " dir=",(brokeUp && !brokeDown ? 1 : (brokeDown && !brokeUp ? -1 : 0)),
         " spanBars=",(prevChange-s),
         " oldR=",DoubleToString(oldR,Digits),
         " oldS=",DoubleToString(oldS,Digits),
         " newR=",DoubleToString(newR,Digits),
         " newS=",DoubleToString(newS,Digits),
         " oldW=",DoubleToString(oldW,Digits),
         " newW=",DoubleToString(newW,Digits),
         " maxBarRange=",DoubleToString(maxBarRange,Digits),
         " segWickRange=",DoubleToString(segWickRange,Digits),
         " segBodyRange=",DoubleToString(segBodyRange,Digits)
      );
   }

   Print(
      "[AS][SWTSR_RESET] SUMMARY",
      " changes=",changes,
      " completeSegments=",completeSegments,
      " up=",upBreak,
      " down=",downBreak,
      " both=",bothBreak,
      " noDir=",noDirectionalBreak
   );

   Print(
      "[AS][SWTSR_RESET] BREAK_ANCHOR_MATCH",
      " newR=H:",newR_eq_breakHigh,
      " newR=BodyH:",newR_eq_breakBodyHigh,
      " newS=L:",newS_eq_breakLow,
      " newS=BodyL:",newS_eq_breakBodyLow
   );

   Print(
      "[AS][SWTSR_RESET] SEGMENT_ANCHOR_MATCH",
      " newR=segH:",newR_eq_segHigh,
      " newR=segBodyH:",newR_eq_segBodyHigh,
      " newS=segL:",newS_eq_segLow,
      " newS=segBodyL:",newS_eq_segBodyLow
   );

   Print(
      "[AS][SWTSR_RESET] WIDTH_EXACT_MATCH",
      " maxBarRange:",width_eq_maxBarRange,
      " segWickRange:",width_eq_segWickRange,
      " segBodyRange:",width_eq_segBodyRange
   );

   Print(
      "[AS][SWTSR_RESET] WIDTH_RATIOS",
      " newW/oldW=",
      DoubleToString(
         nWidthDivOldWidth>0 ? sumWidthDivOldWidth/nWidthDivOldWidth : 0.0,
         6
      ),
      " newW/maxBarRange=",
      DoubleToString(
         nWidthDivMaxBarRange>0 ? sumWidthDivMaxBarRange/nWidthDivMaxBarRange : 0.0,
         6
      ),
      " newW/segWickRange=",
      DoubleToString(
         nWidthDivSegWickRange>0 ? sumWidthDivSegWickRange/nWidthDivSegWickRange : 0.0,
         6
      ),
      " newW/segBodyRange=",
      DoubleToString(
         nWidthDivSegBodyRange>0 ? sumWidthDivSegBodyRange/nWidthDivSegBodyRange : 0.0,
         6
      )
   );

   Print("[AS][SWTSR_RESET] DONE");
}

int OnInit()
{
   Print("[AS][SWTSR_RESET] INIT bars=",BarsToScan);

   for(int s=1; s<=BarsToScan+3; s++)
   {
      SWT_R(s);
      SWT_S(s);
   }

   Analyze();
   return(INIT_SUCCEEDED);
}

void OnTick()
{
}
