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

bool Near(double a,double b,double tolPoints)
{
   return(MathAbs(a-b)<=Point*tolPoints);
}

void Analyze()
{
   int bars=MathMin(BarsToScan,Bars-3);
   if(bars<20)
   {
      Print("[AS][SWTSR_RESET_RULE] FAIL insufficient_history bars=",bars);
      return;
   }

   int changes=0;
   int down=0;
   int supportAtBreakLow=0;
   int widthSame_01=0;
   int widthSame_1=0;
   int widthSame_5=0;
   int upperFromLowOldW_01=0;
   int upperFromLowOldW_1=0;
   int upperFromLowOldW_5=0;

   double sumWidthDeltaPts=0.0;
   double maxWidthDeltaPts=0.0;
   double sumUpperRuleDeltaPts=0.0;
   double maxUpperRuleDeltaPts=0.0;

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
      double breakL=iLow(NULL,PERIOD_H1,breakShift);

      if(breakL<oldS)
         down++;

      if(Near(newS,breakL,0.5))
         supportAtBreakLow++;

      double widthDeltaPts=MathAbs(newW-oldW)/Point;
      sumWidthDeltaPts+=widthDeltaPts;
      if(widthDeltaPts>maxWidthDeltaPts)
         maxWidthDeltaPts=widthDeltaPts;

      if(widthDeltaPts<=0.1) widthSame_01++;
      if(widthDeltaPts<=1.0) widthSame_1++;
      if(widthDeltaPts<=5.0) widthSame_5++;

      double predictedR=breakL+oldW;
      double upperRuleDeltaPts=MathAbs(newR-predictedR)/Point;
      sumUpperRuleDeltaPts+=upperRuleDeltaPts;
      if(upperRuleDeltaPts>maxUpperRuleDeltaPts)
         maxUpperRuleDeltaPts=upperRuleDeltaPts;

      if(upperRuleDeltaPts<=0.1) upperFromLowOldW_01++;
      if(upperRuleDeltaPts<=1.0) upperFromLowOldW_1++;
      if(upperRuleDeltaPts<=5.0) upperFromLowOldW_5++;

      Print(
         "[AS][SWTSR_RESET_RULE] EVENT",
         " time=",TimeToString(iTime(NULL,PERIOD_H1,s),TIME_DATE|TIME_MINUTES),
         " oldW=",DoubleToString(oldW,Digits),
         " newW=",DoubleToString(newW,Digits),
         " dW_pts=",DoubleToString(widthDeltaPts,2),
         " newS=",DoubleToString(newS,Digits),
         " breakL=",DoubleToString(breakL,Digits),
         " newR=",DoubleToString(newR,Digits),
         " predR=",DoubleToString(predictedR,Digits),
         " dR_pts=",DoubleToString(upperRuleDeltaPts,2)
      );
   }

   Print(
      "[AS][SWTSR_RESET_RULE] SUMMARY",
      " changes=",changes,
      " down=",down,
      " supportAtBreakLow=",supportAtBreakLow
   );

   Print(
      "[AS][SWTSR_RESET_RULE] WIDTH_INHERIT",
      " <=0.1pt=",widthSame_01,
      " <=1pt=",widthSame_1,
      " <=5pt=",widthSame_5,
      " meanDeltaPts=",DoubleToString(changes>0 ? sumWidthDeltaPts/changes : 0.0,3),
      " maxDeltaPts=",DoubleToString(maxWidthDeltaPts,3)
   );

   Print(
      "[AS][SWTSR_RESET_RULE] UPPER_RULE",
      " newR=breakLow+oldW",
      " <=0.1pt=",upperFromLowOldW_01,
      " <=1pt=",upperFromLowOldW_1,
      " <=5pt=",upperFromLowOldW_5,
      " meanDeltaPts=",DoubleToString(changes>0 ? sumUpperRuleDeltaPts/changes : 0.0,3),
      " maxDeltaPts=",DoubleToString(maxUpperRuleDeltaPts,3)
   );

   Print("[AS][SWTSR_RESET_RULE] DONE");
}

int OnInit()
{
   Print("[AS][SWTSR_RESET_RULE] INIT bars=",BarsToScan);

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
