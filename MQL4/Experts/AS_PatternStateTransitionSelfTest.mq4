// =============================================================================
// AS :: PATTERN STATE TRANSITION SELF-TEST
// Tests ONLY objectively provable READY transitions.
// NO production Pattern logic. NO trading.
// =============================================================================
#property strict
#include <AS/contracts.mqh>
#define PST_NEUTRAL              0
#define PST_REVERSAL_CANDIDATE   1
#define PST_REVERSAL_CONFIRMED   2
#define PST_RECOVERY             3
#define EVT_INVALID_CONTEXT            1
#define EVT_CONFIRM_UP                  2
#define EVT_CONFIRM_DOWN                3
#define EVT_RETURN_ORIGINAL_SIDE        4
#define EVT_W4_RESUME_ORIGINAL          5
int g_pass = 0;
int g_fail = 0;
void PST_Resolve(int from_state,
                 int from_direction,
                 bool context_valid,
                 int event,
                 int &out_state,
                 int &out_direction)
{
   // Fail closed from ANY state.
   if(!context_valid || event == EVT_INVALID_CONTEXT)
   {
      out_state     = PST_NEUTRAL;
      out_direction = AS_DIR_NO;
      return;
   }
   out_state     = from_state;
   out_direction = from_direction;
   // No direct NEUTRAL -> CONFIRMED / RECOVERY.
   if(from_state == PST_NEUTRAL)
   {
      out_state     = PST_NEUTRAL;
      out_direction = AS_DIR_NO;
      return;
   }
   if(from_state == PST_REVERSAL_CANDIDATE)
   {
      if(from_direction == AS_DIR_UP && event == EVT_CONFIRM_UP)
      {
         out_state     = PST_REVERSAL_CONFIRMED;
         out_direction = AS_DIR_UP;
         return;
      }
      if(from_direction == AS_DIR_DN && event == EVT_CONFIRM_DOWN)
      {
         out_state     = PST_REVERSAL_CONFIRMED;
         out_direction = AS_DIR_DN;
         return;
      }
      if(from_direction == AS_DIR_UP &&
         (event == EVT_RETURN_ORIGINAL_SIDE ||
          event == EVT_W4_RESUME_ORIGINAL))
      {
         out_state     = PST_RECOVERY;
         out_direction = AS_DIR_DN;
         return;
      }
      if(from_direction == AS_DIR_DN &&
         (event == EVT_RETURN_ORIGINAL_SIDE ||
          event == EVT_W4_RESUME_ORIGINAL))
      {
         out_state     = PST_RECOVERY;
         out_direction = AS_DIR_UP;
         return;
      }
   }
}
void PST_Check(string id,
               int from_state,
               int from_direction,
               bool context_valid,
               int event,
               int expected_state,
               int expected_direction)
{
   int got_state;
   int got_direction;
   PST_Resolve(from_state,
               from_direction,
               context_valid,
               event,
               got_state,
               got_direction);
   if(got_state == expected_state &&
      got_direction == expected_direction)
   {
      g_pass++;
      Print("[AS][PATTERN_STATE][PASS] ",id);
   }
   else
   {
      g_fail++;
      Print("[AS][PATTERN_STATE][FAIL] ",id,
            " got_state=",got_state,
            " got_dir=",got_direction,
            " expected_state=",expected_state,
            " expected_dir=",expected_direction);
   }
}
int OnInit()
{
   Print("[AS][PATTERN_STATE] SELF-TEST START");
   // AS-PS-001: invalid context fail-closed from arbitrary active state.
   PST_Check("AS-PS-001",
             PST_REVERSAL_CONFIRMED,AS_DIR_UP,
             false,EVT_INVALID_CONTEXT,
             PST_NEUTRAL,AS_DIR_NO);
   // AS-PS-004 / 005: candidate -> confirmed.
   PST_Check("AS-PS-004",
             PST_REVERSAL_CANDIDATE,AS_DIR_UP,
             true,EVT_CONFIRM_UP,
             PST_REVERSAL_CONFIRMED,AS_DIR_UP);
   PST_Check("AS-PS-005",
             PST_REVERSAL_CANDIDATE,AS_DIR_DN,
             true,EVT_CONFIRM_DOWN,
             PST_REVERSAL_CONFIRMED,AS_DIR_DN);
   // AS-PS-006 / 007: W2/W3 return to original side.
   PST_Check("AS-PS-006",
             PST_REVERSAL_CANDIDATE,AS_DIR_UP,
             true,EVT_RETURN_ORIGINAL_SIDE,
             PST_RECOVERY,AS_DIR_DN);
   PST_Check("AS-PS-007",
             PST_REVERSAL_CANDIDATE,AS_DIR_DN,
             true,EVT_RETURN_ORIGINAL_SIDE,
             PST_RECOVERY,AS_DIR_UP);
   // AS-PS-008 / 009: W4 resumes original direction.
   PST_Check("AS-PS-008",
             PST_REVERSAL_CANDIDATE,AS_DIR_UP,
             true,EVT_W4_RESUME_ORIGINAL,
             PST_RECOVERY,AS_DIR_DN);
   PST_Check("AS-PS-009",
             PST_REVERSAL_CANDIDATE,AS_DIR_DN,
             true,EVT_W4_RESUME_ORIGINAL,
             PST_RECOVERY,AS_DIR_UP);
   // AS-PS-010 / 011: no direct NEUTRAL -> CONFIRMED.
   PST_Check("AS-PS-010",
             PST_NEUTRAL,AS_DIR_NO,
             true,EVT_CONFIRM_UP,
             PST_NEUTRAL,AS_DIR_NO);
   PST_Check("AS-PS-011",
             PST_NEUTRAL,AS_DIR_NO,
             true,EVT_CONFIRM_DOWN,
             PST_NEUTRAL,AS_DIR_NO);
   // AS-PS-012 / 013: no RECOVERY without previous reversal scenario.
   PST_Check("AS-PS-012",
             PST_NEUTRAL,AS_DIR_NO,
             true,EVT_RETURN_ORIGINAL_SIDE,
             PST_NEUTRAL,AS_DIR_NO);
   PST_Check("AS-PS-013",
             PST_NEUTRAL,AS_DIR_NO,
             true,EVT_W4_RESUME_ORIGINAL,
             PST_NEUTRAL,AS_DIR_NO);
   Print("[AS][PATTERN_STATE][SUMMARY] PASS=",g_pass,
         " FAIL=",g_fail,
         " TOTAL=",g_pass+g_fail);
   if(g_fail > 0)
      return(INIT_FAILED);
   return(INIT_SUCCEEDED);
}
void OnTick()
{
}
