// =============================================================================
// AS :: TRADE CONJUNCTION SELF-TEST
// Verifies Trend + Pattern + W2 signal + permissions + blockers.
// Synthetic only. NO trading functions. NO order operations.
// =============================================================================
#property strict

#include <AS/contracts.mqh>
#include <AS/cfg_defaults.mqh>
#include <AS/sig_collect.mqh>
#include <AS/val_signal.mqh>

int g_pass=0;
int g_fail=0;

void TC_Check(string id,int got,int expected)
{
   if(got==expected)
   {
      g_pass++;
      Print("[AS][TRADE_CONJUNCTION][PASS] ",id," got=",got);
   }
   else
   {
      g_fail++;
      Print("[AS][TRADE_CONJUNCTION][FAIL] ",id,
            " got=",got," expected=",expected);
   }
}

void TC_CheckBool(string id,bool got,bool expected)
{
   if(got==expected)
   {
      g_pass++;
      Print("[AS][TRADE_CONJUNCTION][PASS] ",id," got=",got);
   }
   else
   {
      g_fail++;
      Print("[AS][TRADE_CONJUNCTION][FAIL] ",id,
            " got=",got," expected=",expected);
   }
}

AS_Config TC_Config(bool enabled=true,bool permitLong=true,bool permitShort=true)
{
   AS_Config c;
   AS_ConfigSafeDefaults(c);
   c.enabled=enabled;
   c.permit_long=permitLong;
   c.permit_short=permitShort;
   return c;
}

int OnInit()
{
   Print("[AS][TRADE_CONJUNCTION] SELF-TEST START");

   AS_Config c;

   // Safety gate.
   c=TC_Config(false,true,true);
   TC_Check("TC-001_DISABLED_BUY",
      AS_CollectTrade(AS_DIR_UP,AS_DIR_UP,AS_SIG_BUY,c,false,false,false,false),
      AS_SIG_NONE);

   // Happy paths.
   c=TC_Config(true,true,true);
   TC_Check("TC-002_BUY_PASS",
      AS_CollectTrade(AS_DIR_UP,AS_DIR_UP,AS_SIG_BUY,c,false,false,false,false),
      AS_SIG_BUY);

   TC_Check("TC-003_SELL_PASS",
      AS_CollectTrade(AS_DIR_DN,AS_DIR_DN,AS_SIG_SELL,c,false,false,false,false),
      AS_SIG_SELL);

   // Conjunction mismatches.
   TC_Check("TC-004_TREND_MISMATCH",
      AS_CollectTrade(AS_DIR_DN,AS_DIR_UP,AS_SIG_BUY,c,false,false,false,false),
      AS_SIG_NONE);

   TC_Check("TC-005_PATTERN_MISMATCH",
      AS_CollectTrade(AS_DIR_UP,AS_DIR_DN,AS_SIG_BUY,c,false,false,false,false),
      AS_SIG_NONE);

   TC_Check("TC-006_SIGNAL_NONE",
      AS_CollectTrade(AS_DIR_UP,AS_DIR_UP,AS_SIG_NONE,c,false,false,false,false),
      AS_SIG_NONE);

   TC_Check("TC-007_SIGNAL_DIRECTION_MISMATCH",
      AS_CollectTrade(AS_DIR_UP,AS_DIR_UP,AS_SIG_SELL,c,false,false,false,false),
      AS_SIG_NONE);

   // Permissions.
   c=TC_Config(true,false,true);
   TC_Check("TC-008_LONG_NOT_PERMITTED",
      AS_CollectTrade(AS_DIR_UP,AS_DIR_UP,AS_SIG_BUY,c,false,false,false,false),
      AS_SIG_NONE);

   c=TC_Config(true,true,false);
   TC_Check("TC-009_SHORT_NOT_PERMITTED",
      AS_CollectTrade(AS_DIR_DN,AS_DIR_DN,AS_SIG_SELL,c,false,false,false,false),
      AS_SIG_NONE);

   // Blocking gates.
   c=TC_Config(true,true,true);
   TC_Check("TC-010_DOMINANT_CORRECTION_BLOCK",
      AS_CollectTrade(AS_DIR_UP,AS_DIR_UP,AS_SIG_BUY,c,true,false,false,false),
      AS_SIG_NONE);

   TC_Check("TC-011_RISK_BLOCK",
      AS_CollectTrade(AS_DIR_UP,AS_DIR_UP,AS_SIG_BUY,c,false,true,false,false),
      AS_SIG_NONE);

   TC_Check("TC-012_MARGIN_BLOCK",
      AS_CollectTrade(AS_DIR_UP,AS_DIR_UP,AS_SIG_BUY,c,false,false,true,false),
      AS_SIG_NONE);

   TC_Check("TC-013_SPREAD_BLOCK",
      AS_CollectTrade(AS_DIR_UP,AS_DIR_UP,AS_SIG_BUY,c,false,false,false,true),
      AS_SIG_NONE);

   TC_Check("TC-014_MULTI_BLOCK",
      AS_CollectTrade(AS_DIR_DN,AS_DIR_DN,AS_SIG_SELL,c,true,true,true,true),
      AS_SIG_NONE);

   // Validator contract.
   c=TC_Config(true,true,true);
   TC_CheckBool("TC-015_VALIDATE_BUY",
      AS_ValidateTradeSignal(AS_SIG_BUY,c),true);

   TC_CheckBool("TC-016_VALIDATE_SELL",
      AS_ValidateTradeSignal(AS_SIG_SELL,c),true);

   TC_CheckBool("TC-017_VALIDATE_NONE",
      AS_ValidateTradeSignal(AS_SIG_NONE,c),false);

   c=TC_Config(false,true,true);
   TC_CheckBool("TC-018_VALIDATE_DISABLED",
      AS_ValidateTradeSignal(AS_SIG_BUY,c),false);

   Print("[AS][TRADE_CONJUNCTION][SUMMARY] PASS=",g_pass,
         " FAIL=",g_fail,
         " TOTAL=",g_pass+g_fail);

   if(g_fail>0)
      return(INIT_FAILED);

   return(INIT_SUCCEEDED);
}

void OnTick()
{
}
