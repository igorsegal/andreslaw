// =============================================================================
// AS :: SWTch CHANNEL ENTRY + HISTORICAL D1 AS3 TURN PROBE
//
// For every historical H1 W4-channel entry:
//   1. locate the information time = H1 bar close
//   2. locate the latest D1 bar CLOSED by that time
//   3. read three historical closed D1 AS3 values
//   4. calculate D1 turn using the already tested PatternContext definition
//
// NO TRADING.
// NO PRODUCTION CHANGES.
// NO LOOK-AHEAD.
// =============================================================================
#property strict
#include <AS/wave_provider.mqh>
#define SCAN_BARS 500
AS_WaveProvider g_provider;
bool g_done=false;
// -----------------------------------------------------------------------------
// SWTch exported buffer
// -----------------------------------------------------------------------------
double SWTchValue(int mode,int shift)
{
   ResetLastError();
   double v=iCustom(
      NULL,
      PERIOD_H1,
      "SWTch",
      false,   // W2_CH
      false,   // W3_SR
      true,    // W4_SR
      false,   // ShowCenterLine
      mode,
      shift
   );
   if(GetLastError()!=0)
      return EMPTY_VALUE;
   return v;
}
bool ValidChannel(double v)
{
   return(v!=EMPTY_VALUE &&
          MathIsValidNumber(v) &&
          v>0.0);
}
int SignOf(double v)
{
   if(v>0.0) return 1;
   if(v<0.0) return -1;
   return 0;
}
// -----------------------------------------------------------------------------
// Return the most recent D1 bar that was CLOSED at H1 decision time.
//
// Normally iBarShift() points to the currently-forming D1 bar -> +1.
// Across a weekend there may be no new D1 bar, therefore a Friday bar can
// already be closed although iBarShift still points to it.
// -----------------------------------------------------------------------------
int ClosedD1ShiftAt(datetime decision_time)
{
   int s=iBarShift(NULL,PERIOD_D1,decision_time,false);
   if(s<0)
      return -1;
   datetime d1_open=iTime(NULL,PERIOD_D1,s);
   if(d1_open<=0)
      return -1;
   // If a full 24h has elapsed since this D1 bar opened,
   // that bar itself is already closed.
   if(decision_time >= d1_open + 86400)
      return s;
   // Otherwise the containing D1 bar is still forming.
   return s+1;
}
// -----------------------------------------------------------------------------
bool ReadHistoricalD1Turn(datetime h1_bar_open,
                          double &nowValue,
                          double &prevValue,
                          double &oldValue,
                          bool &turn_up,
                          bool &turn_down,
                          int &closed_d1_shift)
{
   // Signal becomes knowable only after the H1 bar has closed.
   datetime decision_time=h1_bar_open+3600;
   closed_d1_shift=ClosedD1ShiftAt(decision_time);
   if(closed_d1_shift<1)
      return false;
   if(!g_provider.GetWaveValueTF(PERIOD_D1,3,
                                 closed_d1_shift,nowValue))
      return false;
   if(!g_provider.GetWaveValueTF(PERIOD_D1,3,
                                 closed_d1_shift+1,prevValue))
      return false;
   if(!g_provider.GetWaveValueTF(PERIOD_D1,3,
                                 closed_d1_shift+2,oldValue))
      return false;
   int slope_current =SignOf(nowValue-prevValue);
   int slope_previous=SignOf(prevValue-oldValue);
   turn_up   =(slope_previous<=0 && slope_current>0);
   turn_down =(slope_previous>=0 && slope_current<0);
   return true;
}
// -----------------------------------------------------------------------------
void RunProbe()
{
   int total=iBars(NULL,PERIOD_H1);
   int max_shift=MathMin(SCAN_BARS,total-2);
   int valid_channel=0;
   int invalid_channel=0;
   int upper_entries=0;
   int lower_entries=0;
   int d1_valid=0;
   int d1_invalid=0;
   int d1_turn_up=0;
   int d1_turn_down=0;
   int aligned_upper_turn_down=0;
   int aligned_lower_turn_up=0;
   Print("[AS][SWTCH_D1TURN] START symbol=",Symbol(),
         " tf=H1 scan=",max_shift);
   for(int shift=max_shift; shift>=1; shift--)
   {
      double h     =SWTchValue(14,shift);
      double l     =SWTchValue(15,shift);
      double prev_h=SWTchValue(14,shift+1);
      double prev_l=SWTchValue(15,shift+1);
      if(!ValidChannel(h) ||
         !ValidChannel(l) ||
         !ValidChannel(prev_h) ||
         !ValidChannel(prev_l))
      {
         invalid_channel++;
         continue;
      }
      valid_channel++;
      double high     =iHigh(NULL,PERIOD_H1,shift);
      double low      =iLow(NULL,PERIOD_H1,shift);
      double prev_high=iHigh(NULL,PERIOD_H1,shift+1);
      double prev_low =iLow(NULL,PERIOD_H1,shift+1);
      bool upper_entry=(prev_high<prev_h && high>=h);
      bool lower_entry=(prev_low >prev_l && low <=l);
      if(!upper_entry && !lower_entry)
         continue;
      if(upper_entry) upper_entries++;
      if(lower_entry) lower_entries++;
      datetime event_time=iTime(NULL,PERIOD_H1,shift);
      double d1_now=0.0;
      double d1_prev=0.0;
      double d1_old=0.0;
      bool turn_up=false;
      bool turn_down=false;
      int d1_shift=-1;
      if(!ReadHistoricalD1Turn(event_time,
                               d1_now,d1_prev,d1_old,
                               turn_up,turn_down,
                               d1_shift))
      {
         d1_invalid++;
         Print("[AS][SWTCH_D1TURN][D1_INVALID]",
               " event=",TimeToString(event_time,
                                     TIME_DATE|TIME_MINUTES));
         continue;
      }
      d1_valid++;
      if(turn_up)   d1_turn_up++;
      if(turn_down) d1_turn_down++;
      bool aligned_up=(lower_entry && turn_up);
      bool aligned_dn=(upper_entry && turn_down);
      if(aligned_up) aligned_lower_turn_up++;
      if(aligned_dn) aligned_upper_turn_down++;
      Print("[AS][SWTCH_D1TURN][EVENT]",
            " H1=",TimeToString(event_time,
                               TIME_DATE|TIME_MINUTES),
            " upper_entry=",upper_entry,
            " lower_entry=",lower_entry,
            " D1bar=",TimeToString(iTime(NULL,PERIOD_D1,d1_shift),
                                  TIME_DATE),
            " old=",DoubleToString(d1_old,8),
            " prev=",DoubleToString(d1_prev,8),
            " now=",DoubleToString(d1_now,8),
            " turn_up=",turn_up,
            " turn_down=",turn_down,
            " aligned=",aligned_up||aligned_dn);
   }
   Print("[AS][SWTCH_D1TURN][SUMMARY]",
         " valid_channel=",valid_channel,
         " invalid_channel=",invalid_channel,
         " upper_entries=",upper_entries,
         " lower_entries=",lower_entries,
         " total_entries=",upper_entries+lower_entries,
         " d1_valid=",d1_valid,
         " d1_invalid=",d1_invalid,
         " d1_turn_up=",d1_turn_up,
         " d1_turn_down=",d1_turn_down,
         " aligned_lower_turn_up=",aligned_lower_turn_up,
         " aligned_upper_turn_down=",aligned_upper_turn_down,
         " aligned_total=",
         aligned_lower_turn_up+aligned_upper_turn_down);
   Print("[AS][SWTCH_D1TURN] END");
}
// -----------------------------------------------------------------------------
int OnInit()
{
   if(!g_provider.Init(3))
   {
      Print("[AS][SWTCH_D1TURN][ERROR] provider init failed");
      return(INIT_FAILED);
   }
   // Trigger both EX4 calculations before historical scan.
   SWTchValue(14,1);
   SWTchValue(15,1);
   double warm=0.0;
   g_provider.GetWaveValueTF(PERIOD_D1,3,1,warm);
   EventSetTimer(3);
   Print("[AS][SWTCH_D1TURN] WARMUP D1_BARS=",iBars(NULL,PERIOD_D1),
         " D1_SHIFT1_TIME=",TimeToString(iTime(NULL,PERIOD_D1,1),TIME_DATE));
   return(INIT_SUCCEEDED);
}
void OnTimer()
{
   Print("[AS][SWTCH_D1TURN][TIMER_ENTER]");
   if(g_done)
      return;
   Print("[AS][SWTCH_D1TURN][TRACE] BEFORE_H");
   double h=SWTchValue(14,1);
   Print("[AS][SWTCH_D1TURN][TRACE] AFTER_H");
   Print("[AS][SWTCH_D1TURN][TRACE] BEFORE_L");
   double l=SWTchValue(15,1);
   Print("[AS][SWTCH_D1TURN][TRACE] AFTER_L");
   double d1a=0.0,d1b=0.0,d1c=0.0;
   bool h_ok=ValidChannel(h);
   bool l_ok=ValidChannel(l);
   Print("[AS][SWTCH_D1TURN][TRACE] BEFORE_D1_1");
   bool d1a_ok=g_provider.GetWaveValueTF(PERIOD_D1,3,1,d1a);
   Print("[AS][SWTCH_D1TURN][TRACE] AFTER_D1_1");
   Print("[AS][SWTCH_D1TURN][TRACE] BEFORE_D1_2");
   bool d1b_ok=g_provider.GetWaveValueTF(PERIOD_D1,3,2,d1b);
   Print("[AS][SWTCH_D1TURN][TRACE] AFTER_D1_2");
   Print("[AS][SWTCH_D1TURN][TRACE] BEFORE_D1_3");
   bool d1c_ok=g_provider.GetWaveValueTF(PERIOD_D1,3,3,d1c);
   Print("[AS][SWTCH_D1TURN][TRACE] AFTER_D1_3");
   bool ready=h_ok && l_ok && d1a_ok && d1b_ok && d1c_ok;
   if(!ready)
   {
      Print("[AS][SWTCH_D1TURN][WAIT]",
            " H=",h_ok,"/",DoubleToString(h,8),
            " L=",l_ok,"/",DoubleToString(l,8),
            " D1_1=",d1a_ok,"/",DoubleToString(d1a,8),
            " D1_2=",d1b_ok,"/",DoubleToString(d1b,8),
            " D1_3=",d1c_ok,"/",DoubleToString(d1c,8));
      return;
   }
   g_done=true;
   EventKillTimer();
   RunProbe();
}
void OnDeinit(const int reason)
{
   EventKillTimer();
}
void OnTick()
{
}




