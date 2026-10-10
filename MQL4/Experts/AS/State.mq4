#property strict
#include <AS\AS_sr_state.mqh>
int g_checked=0;
int g_failed=0;
void Check(string name,bool got,bool expected)
{
   g_checked++;
   if(got==expected)
      Print("[PASS] ",name," got=",got);
   else
   {
      g_failed++;
      Print("[FAIL] ",name,
            " expected=",expected,
            " got=",got);
   }
}
int OnInit()
{
   Print("[AS][SR_STATE_TEST] START");
   AS_sr_State st;
   AS_sr_StateInit(
      st,
      1.10000,   // Support
      1.11000    // Resistance
   );
   Check("INIT_ACTIVE",
         st.phase==AS_SR_ACTIVE,
         true);
   // Wick above R, but Close remains inside.
   AS_sr_StateStep(
      st,
      1.10800,1.11200,1.10600,1.10900
   );
   Check("WICK_DOES_NOT_SWITCH",
         st.phase==AS_SR_ACTIVE,
         true);
   // Confirmed Close breakout upward.
   AS_sr_StateStep(
      st,
      1.10800,1.11300,1.10700,1.11100
   );
   Check("UP_BREAK_STARTS_SEEK_HIGH",
         st.phase==AS_SR_SEEK_HIGH,
         true);
   // New higher body -> candidate must move.
   AS_sr_StateStep(
      st,
      1.11100,1.11600,1.11000,1.11400
   );
   Check("HIGH_CANDIDATE_MOVED",
         MathAbs(st.candidate-1.11400)<0.0000000001,
         true);
   // No new BodyHigh -> previous candidate confirmed,
   // pair becomes active again.
   AS_sr_StateStep(
      st,
      1.11300,1.11500,1.11100,1.11200
   );
   Check("HIGH_CONFIRMED_ACTIVE",
         st.phase==AS_SR_ACTIVE,
         true);
   Check("NEW_RESISTANCE",
         MathAbs(st.resistance-1.11400)<0.0000000001,
         true);
   Check("PAIR_VALID",
         st.support < st.resistance,
         true);
   AS_sr_State stDown;
   AS_sr_StateInit(
      stDown,
      1.10000,
      1.11000
   );
   Check("DOWN_INIT_ACTIVE",
         stDown.phase==AS_SR_ACTIVE,
         true);
   // Lower wick crosses S, Close returns inside.
   AS_sr_StateStep(
      stDown,
      1.10200,1.10400,1.09800,1.10100
   );
   Check("DOWN_WICK_DOES_NOT_SWITCH",
         stDown.phase==AS_SR_ACTIVE,
         true);
   // Confirmed Close below support.
   AS_sr_StateStep(
      stDown,
      1.10200,1.10300,1.09700,1.09900
   );
   Check("DOWN_BREAK_STARTS_SEEK_LOW",
         stDown.phase==AS_SR_SEEK_LOW,
         true);
   // New lower body -> candidate moves down.
   AS_sr_StateStep(
      stDown,
      1.09900,1.10000,1.09400,1.09600
   );
   Check("LOW_CANDIDATE_MOVED",
         MathAbs(stDown.candidate-1.09600)<0.0000000001,
         true);
   // No new BodyLow -> candidate confirmed.
   AS_sr_StateStep(
      stDown,
      1.09700,1.09900,1.09500,1.09800
   );
   Check("LOW_CONFIRMED_ACTIVE",
         stDown.phase==AS_SR_ACTIVE,
         true);
   Check("NEW_SUPPORT",
         MathAbs(stDown.support-1.09600)<0.0000000001,
         true);
   Check("DOWN_PAIR_VALID",
         stDown.support < stDown.resistance,
         true);
   Print("[AS][SR_STATE_TEST] SUMMARY checked=",
         g_checked,
         " failed=",
         g_failed);
   if(g_failed==0)
      Print("[AS][SR_STATE_TEST] PASS");
   else
      Print("[AS][SR_STATE_TEST] FAIL");
   return(INIT_SUCCEEDED);
}
void OnTick()
{
}

