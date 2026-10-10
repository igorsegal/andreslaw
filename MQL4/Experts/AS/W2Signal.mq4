// =============================================================================
// AS :: W2 SIGNAL SELF-TEST
// Tests zero crossing + turn away from zero.
// NO TRADING FUNCTIONS. NO ORDER OPERATIONS.
// =============================================================================
#property strict
#include <AS/contracts.mqh>
#include <AS/sig_reversal.mqh>
int g_pass = 0;
int g_fail = 0;
void AS_Check(string id,
              double older,
              double prev,
              double current,
              int expected)
{
   int got = AS_W2Signal(current,prev,older);
   if(got == expected)
   {
      g_pass++;
      Print("[AS][W2][PASS] ",id,
            " got=",got);
   }
   else
   {
      g_fail++;
      Print("[AS][W2][FAIL] ",id,
            " older=",DoubleToString(older,4),
            " prev=",DoubleToString(prev,4),
            " current=",DoubleToString(current,4),
            " got=",got,
            " expected=",expected);
   }
}
int OnInit()
{
   Print("[AS][W2] SELF-TEST START");
   AS_Check("AS-W2-001",-2.0,-1.0, 0.5,AS_SIG_BUY);
   AS_Check("AS-W2-002",-2.0, 0.0, 0.5,AS_SIG_BUY);
   AS_Check("AS-W2-003", 2.0, 1.0,-0.5,AS_SIG_SELL);
   AS_Check("AS-W2-004", 2.0, 0.0,-0.5,AS_SIG_SELL);
   AS_Check("AS-W2-005", 3.0, 2.0, 2.5,AS_SIG_BUY);
   AS_Check("AS-W2-006",-3.0,-2.0,-2.5,AS_SIG_SELL);
   AS_Check("AS-W2-007", 1.0, 2.0, 3.0,AS_SIG_NONE);
   AS_Check("AS-W2-008", 3.0, 2.0, 1.0,AS_SIG_NONE);
   AS_Check("AS-W2-009",-1.0,-2.0,-3.0,AS_SIG_NONE);
   AS_Check("AS-W2-010",-3.0,-2.0,-1.0,AS_SIG_NONE);
   AS_Check("AS-W2-011", 2.0, 1.0, 1.0,AS_SIG_NONE);
   AS_Check("AS-W2-012",-2.0,-1.0,-1.0,AS_SIG_NONE);
   AS_Check("AS-W2-013",-1.0,-0.5, 0.0,AS_SIG_NONE);
   AS_Check("AS-W2-014", 1.0, 0.5, 0.0,AS_SIG_NONE);
   Print("[AS][W2][SUMMARY] PASS=",g_pass,
         " FAIL=",g_fail,
         " TOTAL=",g_pass+g_fail);
   if(g_fail > 0)
      return(INIT_FAILED);
   return(INIT_SUCCEEDED);
}
void OnTick()
{
}