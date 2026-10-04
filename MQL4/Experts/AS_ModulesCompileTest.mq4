// =============================================================================
// AS_ModulesCompileTest.mq4
// Compile-only / runtime-safe smoke harness. It NEVER sends orders.
// =============================================================================
#property strict
#include <AS/contracts.mqh>
#include <AS/cfg_defaults.mqh>
#include <AS/cfg_load.mqh>
#include <AS/log.mqh>
#include <AS/bar_get.mqh>
#include <AS/acc_get.mqh>
#include <AS/wave_hierarchy.mqh>
#include <AS/sig_trend.mqh>
#include <AS/sig_pattern.mqh>
#include <AS/sig_reversal.mqh>
#include <AS/sig_collect.mqh>
#include <AS/val_spread.mqh>
#include <AS/val_margin.mqh>
#include <AS/val_risk.mqh>
#include <AS/val_signal.mqh>
#include <AS/order_size.mqh>
#include <AS/exec_open.mqh>
#include <AS/exec_close.mqh>
#include <AS/exec_modify.mqh>
#include <AS/pm_stop.mqh>
#include <AS/pm_take.mqh>
#include <AS/pm_trail.mqh>
#include <AS/pm_trigger.mqh>
#include <AS/pm_dispatch.mqh>
#include <AS/tracker.mqh>
#include <AS/daily_reset.mqh>

int OnInit()
{
   AS_Config c; AS_ConfigSafeDefaults(c);
   AS_TrendHierarchy h; AS_ClearTrendHierarchy(h);
   AS_AccountSnapshot a; AS_GetAccountSnapshot(a);
   AS_DailyState d; AS_DailyInit(d);
   AS_PositionStats p; AS_TrackPositions(Symbol(),c.magic,false,p);
   Print("[AS][STAGE3] modules loaded; trading gate enabled=",c.enabled,
         " equity=",DoubleToString(a.equity,2));
   return(INIT_SUCCEEDED);
}
void OnTick() { }
