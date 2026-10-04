//+------------------------------------------------------------------+
//|                                                 Andreslav_AS.mq4 |
//|              RECOVERY STAGE 6 / MTF SOURCE SMOKE                 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, AS Project"
#property version   "1.05"
#property strict

// Recovered SWT/Andreslav core
#include <AS/contracts.mqh>
#include <AS/cfg_defaults.mqh>
#include <AS/cfg_load.mqh>
#include <AS/log.mqh>
#include <AS/bar_get.mqh>
#include <AS/acc_get.mqh>
#include <AS/wave_provider.mqh>
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

input double InpHysteresis = 0.0000; // diagnostic only
input bool   InpVerboseLog = true;

// -------------------------------------------------------------------
// HARD SAFETY LOCK.
// Stage 6 remains observation-only. No order operation is permitted.
// This is deliberately NOT an input.
// -------------------------------------------------------------------
#define AS_STAGE6_TRADING_LOCK 1

AS_WaveProvider *g_provider = NULL;
AS_Config         g_cfg;
AS_DailyState     g_daily;
datetime          g_lastBarTime = 0;

bool AS_Stage6LibrarySelfCheck()
{
   // Exercise recovered signal contracts without creating a trade.
   AS_TrendHierarchy h;
   AS_ClearTrendHierarchy(h);

   bool dominant_block=false;
   int trend=AS_TrendDirection(h,g_cfg,dominant_block);
   int pattern=AS_PatternDirection(h);
   int signal=AS_W2Signal(0.0,0.0,0.0);
   int trade=AS_CollectTrade(trend,pattern,signal,g_cfg,
                             dominant_block,false,false,false);

   if(trend!=AS_DIR_NO) return false;
   if(pattern!=AS_DIR_NO) return false;
   if(signal!=AS_SIG_NONE) return false;
   if(trade!=AS_SIG_NONE) return false;
   if(AS_ValidateTradeSignal(trade,g_cfg)) return false;

   return true;
}

int OnInit()
{
   AS_ConfigSafeDefaults(g_cfg);

   // Absolute safety invariant.
   g_cfg.enabled=false;

   if(InpHysteresis<0.0)
   {
      Print("[AS][STAGE6][ERROR] InpHysteresis must be >= 0");
      return(INIT_PARAMETERS_INCORRECT);
   }

   g_provider=new AS_WaveProvider();
   if(g_provider==NULL)
   {
      Print("[AS][STAGE6][ERROR] Wave provider allocation failed");
      return(INIT_FAILED);
   }

   if(!g_provider.Init(3))
   {
      Print("[AS][STAGE6][ERROR] Wave provider initialization failed");
      delete g_provider;
      g_provider=NULL;
      return(INIT_FAILED);
   }

   AS_DailyInit(g_daily);

   if(!AS_Stage6LibrarySelfCheck())
   {
      Print("[AS][STAGE6][ERROR] Recovered library self-check failed");
      delete g_provider;
      g_provider=NULL;
      return(INIT_FAILED);
   }

   AS_AccountSnapshot a;
   AS_GetAccountSnapshot(a);

   Print("[AS][STAGE6] MTF-capable safe core initialized. trading_lock=",
         AS_STAGE6_TRADING_LOCK,
         " cfg.enabled=",g_cfg.enabled,
         " equity=",DoubleToString(a.equity,2));

   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   if(g_provider!=NULL)
   {
      delete g_provider;
      g_provider=NULL;
   }

   Print("[AS][STAGE6] Deinitialized. reason=",reason);
}

void OnTick()
{
   if(g_provider==NULL) return;

   // Run once per newly opened chart bar.
   datetime currentBarTime=iTime(Symbol(),Period(),0);
   if(currentBarTime<=0) return;
   if(g_lastBarTime==0)
   {
      g_lastBarTime=currentBarTime;
      return;
   }
   if(currentBarTime==g_lastBarTime) return;
   g_lastBarTime=currentBarTime;

   if(iBars(Symbol(),Period())<4) return;

   // ----------------------------------------------------------------
   // CURRENT-TF PIPELINE
   // Single source of truth: AS_Waves indicator, closed bars only.
   // ----------------------------------------------------------------
   double as3_now=0.0;
   double as3_prev=0.0;
   double as3_old=0.0;

   if(!g_provider.GetClosedAS3SeriesTF(PERIOD_CURRENT,
                                       as3_now,as3_prev,as3_old))
   {
      Print("[AS][STAGE6][WARN] Current-TF AS3 closed-bar series unavailable");
      return;
   }

   // ----------------------------------------------------------------
   // STAGE 6 MTF SOURCE SMOKE.
   // H1 / D1 / W1 are explicit source contexts only.
   // They are NOT yet assigned to short/medium/long/basic hierarchy.
   // ----------------------------------------------------------------
   double as3_h1=0.0;
   double as3_d1=0.0;
   double as3_w1=0.0;

   bool h1_ok=g_provider.GetClosedAS3TF(PERIOD_H1,as3_h1);
   bool d1_ok=g_provider.GetClosedAS3TF(PERIOD_D1,as3_d1);
   bool w1_ok=g_provider.GetClosedAS3TF(PERIOD_W1,as3_w1);

   if(InpVerboseLog)
   {
      if(h1_ok && d1_ok && w1_ok)
      {
         Print("[AS][STAGE6][MTF] source=AS_Waves",
               " H1_bar=",TimeToString(iTime(Symbol(),PERIOD_H1,1),TIME_DATE|TIME_MINUTES),
               " H1_AS3=",DoubleToString(as3_h1,8),
               " D1_bar=",TimeToString(iTime(Symbol(),PERIOD_D1,1),TIME_DATE|TIME_MINUTES),
               " D1_AS3=",DoubleToString(as3_d1,8),
               " W1_bar=",TimeToString(iTime(Symbol(),PERIOD_W1,1),TIME_DATE|TIME_MINUTES),
               " W1_AS3=",DoubleToString(as3_w1,8),
               " trading_lock=",AS_STAGE6_TRADING_LOCK);
      }
      else
      {
         Print("[AS][STAGE6][WARN] MTF source unavailable",
               " H1_ok=",h1_ok,
               " D1_ok=",d1_ok,
               " W1_ok=",w1_ok,
               " trading_lock=",AS_STAGE6_TRADING_LOCK);
      }
   }

   // Update only non-trading infrastructure.
   AS_DailyUpdate(g_daily,
                  g_cfg.daily_profit_target_percent,
                  g_cfg.daily_loss_limit_percent);

   AS_PositionStats p;
   AS_TrackPositions(Symbol(),g_cfg.magic,
                     g_cfg.manual_position_control,p);

   double spread_points=0.0;
   bool spread_ok=AS_CheckSpread(Symbol(),
                                g_cfg.max_spread_points,
                                spread_points);

   int as3_sign=AS_DIR_NO;
   if(as3_now> InpHysteresis) as3_sign=AS_DIR_UP;
   if(as3_now<-InpHysteresis) as3_sign=AS_DIR_DN;

   if(InpVerboseLog)
   {
      Print("[AS][STAGE6] bar=",
            TimeToString(iTime(Symbol(),Period(),1),TIME_DATE|TIME_MINUTES),
            " AS3=",DoubleToString(as3_now,8),
            " prev=",DoubleToString(as3_prev,8),
            " old=",DoubleToString(as3_old,8),
            " sign=",as3_sign,
            " spread=",DoubleToString(spread_points,1),
            " spread_ok=",spread_ok,
            " open_positions=",p.buys+p.sells,
            " daily_block=",g_daily.trading_blocked,
            " trading_lock=",AS_STAGE6_TRADING_LOCK);
   }

   // IMPORTANT:
   // No OrderSend / OrderModify / OrderClose call exists here.
   // No AS_TrendHierarchy field is populated from guessed TF mappings.
}
