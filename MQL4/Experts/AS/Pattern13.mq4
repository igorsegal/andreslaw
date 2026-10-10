// =============================================================================
// AS :: Pattern 1..3 SELF-TEST
// Tests Hourly + IDay + Daily base Pattern.
// NO TRADING FUNCTIONS. NO ORDER OPERATIONS.
// =============================================================================
#property strict
#include <AS/contracts.mqh>
#include <AS/wave_hierarchy.mqh>
#include <AS/sig_pattern.mqh>
int g_pass = 0;
int g_fail = 0;
void AS_Check(string id,
              int hDir, bool hCorr, bool hValid,
              int iDir, bool iCorr, bool iValid,
              int dDir, bool dCorr, bool dValid,
              int expected)
{
   AS_TrendHierarchy h;
   AS_ClearTrendHierarchy(h);
   AS_SetTrendState(h.hourly,hDir,hCorr,hValid);
   AS_SetTrendState(h.iday,iDir,iCorr,iValid);
   AS_SetTrendState(h.daily,dDir,dCorr,dValid);
   int got=AS_PatternDirection(h);
   if(got==expected)
   {
      g_pass++;
      Print("[AS][PATTERN13][PASS] ",id,
            " pattern=",got);
   }
   else
   {
      g_fail++;
      Print("[AS][PATTERN13][FAIL] ",id,
            " got=",got,
            " expected=",expected);
   }
}
int OnInit()
{
   Print("[AS][PATTERN13] SELF-TEST START");
   AS_Check("AS-PT-001",
            AS_DIR_UP,false,true,
            AS_DIR_UP,false,true,
            AS_DIR_UP,false,true,
            AS_DIR_UP);
   AS_Check("AS-PT-002",
            AS_DIR_DN,false,true,
            AS_DIR_DN,false,true,
            AS_DIR_DN,false,true,
            AS_DIR_DN);
   AS_Check("AS-PT-003",
            AS_DIR_DN,false,true,
            AS_DIR_UP,false,true,
            AS_DIR_UP,false,true,
            AS_DIR_NO);
   AS_Check("AS-PT-004",
            AS_DIR_UP,false,true,
            AS_DIR_DN,false,true,
            AS_DIR_UP,false,true,
            AS_DIR_NO);
   AS_Check("AS-PT-005",
            AS_DIR_UP,false,true,
            AS_DIR_UP,false,true,
            AS_DIR_DN,false,true,
            AS_DIR_NO);
   AS_Check("AS-PT-006",
            AS_DIR_UP,false,false,
            AS_DIR_UP,false,true,
            AS_DIR_UP,false,true,
            AS_DIR_NO);
   AS_Check("AS-PT-007",
            AS_DIR_UP,false,true,
            AS_DIR_UP,false,false,
            AS_DIR_UP,false,true,
            AS_DIR_NO);
   AS_Check("AS-PT-008",
            AS_DIR_UP,false,true,
            AS_DIR_UP,false,true,
            AS_DIR_UP,false,false,
            AS_DIR_NO);
   AS_Check("AS-PT-009",
            AS_DIR_NO,false,true,
            AS_DIR_UP,false,true,
            AS_DIR_UP,false,true,
            AS_DIR_NO);
   AS_Check("AS-PT-010",
            AS_DIR_UP,false,true,
            AS_DIR_NO,false,true,
            AS_DIR_UP,false,true,
            AS_DIR_NO);
   AS_Check("AS-PT-011",
            AS_DIR_UP,false,true,
            AS_DIR_UP,false,true,
            AS_DIR_NO,false,true,
            AS_DIR_NO);
   AS_Check("AS-PT-012",
            AS_DIR_UP,true,true,
            AS_DIR_UP,false,true,
            AS_DIR_UP,false,true,
            AS_DIR_UP);
   AS_Check("AS-PT-013",
            AS_DIR_DN,false,true,
            AS_DIR_DN,true,true,
            AS_DIR_DN,false,true,
            AS_DIR_DN);
   AS_Check("AS-PT-014",
            AS_DIR_UP,true,true,
            AS_DIR_UP,true,true,
            AS_DIR_UP,true,true,
            AS_DIR_UP);
   Print("[AS][PATTERN13][SUMMARY] PASS=",g_pass,
         " FAIL=",g_fail,
         " TOTAL=",g_pass+g_fail);
   if(g_fail>0)
      return(INIT_FAILED);
   return(INIT_SUCCEEDED);
}
void OnTick()
{
}