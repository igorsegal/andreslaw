// =============================================================================
// AS :: Trend 4..8 SELF-TEST
// Executes AS_TREND_4_8_TEST_MATRIX.csv READY cases only.
// NO TRADING FUNCTIONS. NO ORDER OPERATIONS.
// =============================================================================
#property strict
#include <AS/contracts.mqh>
#include <AS/cfg_defaults.mqh>
#include <AS/wave_hierarchy.mqh>
#include <AS/sig_trend.mqh>
int g_pass = 0;
int g_fail = 0;
string AS_BoolText(bool v)
{
   return v ? "true" : "false";
}
void AS_TestResult(string id,
                   int gotTrend,
                   int expectedTrend,
                   bool gotBlock,
                   bool expectedBlock)
{
   if(gotTrend == expectedTrend && gotBlock == expectedBlock)
   {
      g_pass++;
      Print("[AS][TREND48][PASS] ",id,
            " trend=",gotTrend,
            " dc=",AS_BoolText(gotBlock));
   }
   else
   {
      g_fail++;
      Print("[AS][TREND48][FAIL] ",id,
            " got_trend=",gotTrend,
            " expected_trend=",expectedTrend,
            " got_dc=",AS_BoolText(gotBlock),
            " expected_dc=",AS_BoolText(expectedBlock));
   }
}
void AS_TestClamp(string id,int testValue,int expected)
{
   int got=AS_ClampTrendVector(testValue);
   if(got==expected)
   {
      g_pass++;
      Print("[AS][TREND48][PASS] ",id,
            " clamp=",testValue," -> ",got);
   }
   else
   {
      g_fail++;
      Print("[AS][TREND48][FAIL] ",id,
            " clamp_input=",testValue,
            " got=",got,
            " expected=",expected);
   }
}
void AS_SetLevel(AS_TrendHierarchy &h,
                 int level,
                 int direction,
                 bool correction,
                 bool valid)
{
   if(level==4) AS_SetTrendState(h.weekly,direction,correction,valid);
   if(level==5) AS_SetTrendState(h.short_trend,direction,correction,valid);
   if(level==6) AS_SetTrendState(h.medium_trend,direction,correction,valid);
   if(level==7) AS_SetTrendState(h.long_trend,direction,correction,valid);
   if(level==8) AS_SetTrendState(h.basic,direction,correction,valid);
}
void AS_Reset(AS_Config &c,
              AS_TrendHierarchy &h,
              int trendVector,
              bool adaptive,
              bool dominantCorrection,
              bool contraTrend)
{
   AS_ConfigSafeDefaults(c);
   AS_ClearTrendHierarchy(h);
   c.trend_vector=trendVector;
   c.adaptive_mode=adaptive;
   c.dominant_correction=dominantCorrection;
   c.contra_trend=contraTrend;
}
void AS_Run(string id,
            AS_Config &c,
            AS_TrendHierarchy &h,
            int expectedTrend,
            bool expectedBlock)
{
   bool block=false;
   int trend=AS_TrendDirection(h,c,block);
   AS_TestResult(id,trend,expectedTrend,block,expectedBlock);
}
int OnInit()
{
   Print("[AS][TREND48] SELF-TEST START");
   // ---------------------------------------------------------------
   // CLAMP
   // ---------------------------------------------------------------
   AS_TestClamp("AS-TR-001",3,4);
   AS_TestClamp("AS-TR-002",4,4);
   AS_TestClamp("AS-TR-003",5,5);
   AS_TestClamp("AS-TR-004",8,8);
   AS_TestClamp("AS-TR-005",9,8);
   AS_Config c;
   AS_TrendHierarchy h;
   // ---------------------------------------------------------------
   // NON-ADAPTIVE
   // ---------------------------------------------------------------
   AS_Reset(c,h,4,false,false,false);
   AS_SetLevel(h,4,AS_DIR_UP,false,true);
   AS_Run("AS-TR-010",c,h,AS_DIR_UP,false);
   AS_Reset(c,h,5,false,false,false);
   AS_SetLevel(h,5,AS_DIR_UP,false,true);
   AS_SetLevel(h,4,AS_DIR_UP,false,true);
   AS_Run("AS-TR-011",c,h,AS_DIR_UP,false);
   AS_Reset(c,h,5,false,false,false);
   AS_SetLevel(h,5,AS_DIR_DN,false,true);
   AS_SetLevel(h,4,AS_DIR_DN,false,true);
   AS_Run("AS-TR-012",c,h,AS_DIR_DN,false);
   AS_Reset(c,h,5,false,false,false);
   AS_SetLevel(h,5,AS_DIR_UP,false,true);
   AS_SetLevel(h,4,AS_DIR_DN,false,true);
   AS_Run("AS-TR-013",c,h,AS_DIR_NO,false);
   AS_Reset(c,h,6,false,false,false);
   AS_SetLevel(h,6,AS_DIR_UP,true,true);
   AS_SetLevel(h,5,AS_DIR_UP,false,true);
   AS_SetLevel(h,4,AS_DIR_UP,false,true);
   AS_Run("AS-TR-014",c,h,AS_DIR_UP,false);
   AS_Reset(c,h,6,false,false,false);
   AS_SetLevel(h,6,AS_DIR_DN,true,true);
   AS_SetLevel(h,5,AS_DIR_DN,false,true);
   AS_SetLevel(h,4,AS_DIR_DN,false,true);
   AS_Run("AS-TR-015",c,h,AS_DIR_DN,false);
   AS_Reset(c,h,6,false,false,false);
   // level 6 intentionally INVALID
   AS_SetLevel(h,5,AS_DIR_UP,false,true);
   AS_SetLevel(h,4,AS_DIR_UP,false,true);
   AS_Run("AS-TR-016",c,h,AS_DIR_NO,false);
   // ---------------------------------------------------------------
   // ADAPTIVE v3.3
   // ---------------------------------------------------------------
   AS_Reset(c,h,8,true,false,false);
   AS_SetLevel(h,8,AS_DIR_UP,true,true);
   AS_SetLevel(h,7,AS_DIR_UP,false,true);
   AS_SetLevel(h,6,AS_DIR_DN,false,true);
   AS_SetLevel(h,5,AS_DIR_DN,false,true);
   AS_SetLevel(h,4,AS_DIR_DN,false,true);
   AS_Run("AS-TR-020",c,h,AS_DIR_UP,false);
   AS_Reset(c,h,8,true,false,false);
   AS_SetLevel(h,8,AS_DIR_DN,true,true);
   AS_SetLevel(h,7,AS_DIR_UP,true,true);
   AS_SetLevel(h,6,AS_DIR_UP,true,true);
   AS_SetLevel(h,5,AS_DIR_DN,true,true);
   AS_SetLevel(h,4,AS_DIR_UP,false,true);
   AS_Run("AS-TR-021",c,h,AS_DIR_UP,false);
   AS_Reset(c,h,8,true,false,false);
   AS_SetLevel(h,8,AS_DIR_DN,true,true);
   AS_SetLevel(h,7,AS_DIR_UP,true,true);
   AS_SetLevel(h,6,AS_DIR_UP,true,true);
   AS_SetLevel(h,5,AS_DIR_DN,true,true);
   AS_SetLevel(h,4,AS_DIR_DN,true,true);
   AS_Run("AS-TR-022",c,h,AS_DIR_DN,false);
   AS_Reset(c,h,7,true,false,false);
   AS_SetLevel(h,7,AS_DIR_DN,false,true);
   AS_SetLevel(h,6,AS_DIR_UP,false,true);
   AS_SetLevel(h,5,AS_DIR_UP,false,true);
   AS_SetLevel(h,4,AS_DIR_UP,false,true);
   AS_Run("AS-TR-023",c,h,AS_DIR_DN,false);
   AS_Reset(c,h,7,true,false,false);
   AS_SetLevel(h,7,AS_DIR_UP,true,true);
   AS_SetLevel(h,6,AS_DIR_DN,false,true);
   AS_SetLevel(h,5,AS_DIR_UP,false,true);
   AS_SetLevel(h,4,AS_DIR_UP,false,true);
   AS_Run("AS-TR-024",c,h,AS_DIR_DN,false);
   AS_Reset(c,h,7,true,true,false);
   AS_SetLevel(h,7,AS_DIR_UP,false,true);
   AS_SetLevel(h,6,AS_DIR_DN,false,true);
   AS_SetLevel(h,5,AS_DIR_UP,false,true);
   AS_SetLevel(h,4,AS_DIR_UP,false,true);
   AS_Run("AS-TR-025",c,h,AS_DIR_UP,true);
   AS_Reset(c,h,7,true,false,false);
   AS_SetLevel(h,7,AS_DIR_UP,false,true);
   AS_SetLevel(h,6,AS_DIR_DN,false,true);
   AS_SetLevel(h,5,AS_DIR_UP,false,true);
   AS_SetLevel(h,4,AS_DIR_UP,false,true);
   AS_Run("AS-TR-026",c,h,AS_DIR_UP,false);
   AS_Reset(c,h,7,true,true,false);
   AS_SetLevel(h,7,AS_DIR_UP,false,true);
   AS_SetLevel(h,6,AS_DIR_DN,true,true);
   AS_SetLevel(h,5,AS_DIR_UP,true,true);
   AS_SetLevel(h,4,AS_DIR_UP,false,true);
   AS_Run("AS-TR-027",c,h,AS_DIR_UP,false);
   AS_Reset(c,h,7,true,false,false);
   // level 7 intentionally INVALID
   AS_SetLevel(h,6,AS_DIR_UP,false,true);
   AS_SetLevel(h,5,AS_DIR_UP,false,true);
   AS_SetLevel(h,4,AS_DIR_UP,false,true);
   AS_Run("AS-TR-028",c,h,AS_DIR_NO,false);
   // ---------------------------------------------------------------
   // CONTRTREND
   // ---------------------------------------------------------------
   AS_Reset(c,h,5,false,false,true);
   AS_SetLevel(h,5,AS_DIR_UP,false,true);
   AS_SetLevel(h,4,AS_DIR_UP,false,true);
   AS_Run("AS-TR-030",c,h,AS_DIR_DN,false);
   AS_Reset(c,h,5,false,false,true);
   AS_SetLevel(h,5,AS_DIR_DN,false,true);
   AS_SetLevel(h,4,AS_DIR_DN,false,true);
   AS_Run("AS-TR-031",c,h,AS_DIR_UP,false);
   AS_Reset(c,h,5,false,false,true);
   AS_SetLevel(h,5,AS_DIR_UP,false,true);
   AS_SetLevel(h,4,AS_DIR_DN,false,true);
   AS_Run("AS-TR-032",c,h,AS_DIR_NO,false);
   Print("[AS][TREND48][SUMMARY] PASS=",g_pass,
         " FAIL=",g_fail,
         " TOTAL=",g_pass+g_fail);
   if(g_fail>0)
      return(INIT_FAILED);
   return(INIT_SUCCEEDED);
}
void OnTick()
{
}