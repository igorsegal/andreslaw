//+------------------------------------------------------------------+
//|                                                 Andreslav.mq4 |
//|        RECOVERY STAGE 8 / LOCKED DECISION RUNTIME               |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, AS Project"
#property version   "1.06"
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
// Runtime remains observation-only. No order operation is permitted.
// This is deliberately NOT an input.
// -------------------------------------------------------------------
#define AS_TRADING_LOCK 1

AS_WaveProvider *g_provider = NULL;
AS_Config         g_cfg;
AS_DailyState     g_daily;
datetime          g_lastBarTime = 0;

int AS_DirFromValue(double v)
{
   if(v>0.0) return AS_DIR_UP;
   if(v<0.0) return AS_DIR_DN;
   return AS_DIR_NO;
}

string AS_DirText(int d)
{
   if(d==AS_DIR_UP) return "UP";
   if(d==AS_DIR_DN) return "DN";
   return "NO";
}

string AS_SigText(int s)
{
   if(s==AS_SIG_BUY) return "BUY";
   if(s==AS_SIG_SELL) return "SELL";
   return "NONE";
}

void AS_LogLockedDecision(double h1_as3,double d1_as3,double w1_as3)
{
   double as2_now=0.0;
   double as2_prev=0.0;
   double as2_old=0.0;

   bool as2_ok=
      g_provider.GetWaveValueTF(PERIOD_H1,2,1,as2_now) &&
      g_provider.GetWaveValueTF(PERIOD_H1,2,2,as2_prev) &&
      g_provider.GetWaveValueTF(PERIOD_H1,2,3,as2_old);

   if(!as2_ok)
   {
      Print("[AS][CORE][WARN] H1 AS2 series unavailable");
      return;
   }

   AS_TrendHierarchy h;
   AS_ClearTrendHierarchy(h);

   AS_SetTrendState(h.hourly,AS_DirFromValue(h1_as3),false,true);
   AS_SetTrendState(h.iday,AS_DirFromValue(d1_as3),false,true);
   AS_SetTrendState(h.daily,AS_DirFromValue(w1_as3),false,true);

   // Andreslaw project profile for the locked demo pipeline:
   // Weekly trend source = closed W1 AS3.
   // This is a project mapping, not a claim of exact SWT reconstruction.
   AS_SetTrendState(h.weekly,AS_DirFromValue(w1_as3),false,true);

   AS_Config decision_cfg;
   AS_ConfigSafeDefaults(decision_cfg);

   // Candidate calculation only. The production config remains disabled
   // and the hard trading lock remains active.
   decision_cfg.enabled=true;
   decision_cfg.trend_vector=4;
   decision_cfg.adaptive_mode=false;
   decision_cfg.dominant_correction=false;
   decision_cfg.contra_trend=false;

   bool dominant_block=false;
   int trend=AS_TrendDirection(h,decision_cfg,dominant_block);
   int pattern=AS_PatternDirection(h);
   int signal=AS_W2Signal(as2_now,as2_prev,as2_old);

   int candidate=AS_CollectTrade(
      trend,
      pattern,
      signal,
      decision_cfg,
      dominant_block,
      false,
      false,
      false
   );

   Print("[AS][CORE][DECISION]",
         " H1=",AS_DirText(AS_DirFromValue(h1_as3)),
         " D1=",AS_DirText(AS_DirFromValue(d1_as3)),
         " W1=",AS_DirText(AS_DirFromValue(w1_as3)),
         " trend=",AS_DirText(trend),
         " pattern=",AS_DirText(pattern),
         " signal=",AS_SigText(signal),
         " candidate=",AS_SigText(candidate),
         " AS2=",DoubleToString(as2_now,8),
         " trading_lock=",AS_TRADING_LOCK);
}

bool AS_LibrarySelfCheck()
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
      Print("[AS][CORE][ERROR] InpHysteresis must be >= 0");
      return(INIT_PARAMETERS_INCORRECT);
   }

   g_provider=new AS_WaveProvider();
   if(g_provider==NULL)
   {
      Print("[AS][CORE][ERROR] Wave provider allocation failed");
      return(INIT_FAILED);
   }

   if(!g_provider.Init(3))
   {
      Print("[AS][CORE][ERROR] Wave provider initialization failed");
      delete g_provider;
      g_provider=NULL;
      return(INIT_FAILED);
   }

   AS_DailyInit(g_daily);

   if(!AS_LibrarySelfCheck())
   {
      Print("[AS][CORE][ERROR] Recovered library self-check failed");
      delete g_provider;
      g_provider=NULL;
      return(INIT_FAILED);
   }

   AS_AccountSnapshot a;
   AS_GetAccountSnapshot(a);

   Print("[AS][CORE] MTF-capable safe core initialized. trading_lock=",
         AS_TRADING_LOCK,
         " cfg.enabled=",g_cfg.enabled,
         " equity=",DoubleToString(a.equity,2));

   // Produce one decision snapshot immediately; do not wait for the next H1 bar.
   double init_h1=0.0;
   double init_d1=0.0;
   double init_w1=0.0;
   bool init_h1_ok=g_provider.GetClosedAS3TF(PERIOD_H1,init_h1);
   bool init_d1_ok=g_provider.GetClosedAS3TF(PERIOD_D1,init_d1);
   bool init_w1_ok=g_provider.GetClosedAS3TF(PERIOD_W1,init_w1);

   if(init_h1_ok && init_d1_ok && init_w1_ok)
      AS_LogLockedDecision(init_h1,init_d1,init_w1);
   else
      Print("[AS][CORE][WARN] Initial MTF decision source unavailable",
            " H1_ok=",init_h1_ok,
            " D1_ok=",init_d1_ok,
            " W1_ok=",init_w1_ok,
            " trading_lock=",AS_TRADING_LOCK);

   g_lastBarTime=iTime(Symbol(),Period(),0);

   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   if(g_provider!=NULL)
   {
      delete g_provider;
      g_provider=NULL;
   }

   Print("[AS][CORE] Deinitialized. reason=",reason);
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
      Print("[AS][CORE][WARN] Current-TF AS3 closed-bar series unavailable");
      return;
   }

   // ----------------------------------------------------------------
   // MTF SOURCE CONTEXT.
   // H1 / D1 / W1 are explicit source contexts only.
   // H1/D1/W1 feed the explicit Andreslaw project decision profile.
   // ----------------------------------------------------------------
   double as3_h1=0.0;
   double as3_d1=0.0;
   double as3_w1=0.0;

   bool h1_ok=g_provider.GetClosedAS3TF(PERIOD_H1,as3_h1);
   bool d1_ok=g_provider.GetClosedAS3TF(PERIOD_D1,as3_d1);
   bool w1_ok=g_provider.GetClosedAS3TF(PERIOD_W1,as3_w1);

   if(h1_ok && d1_ok && w1_ok)
      AS_LogLockedDecision(as3_h1,as3_d1,as3_w1);

   if(InpVerboseLog)
   {
      if(h1_ok && d1_ok && w1_ok)
      {
         Print("[AS][CORE][MTF] source=AS_Waves",
               " H1_bar=",TimeToString(iTime(Symbol(),PERIOD_H1,1),TIME_DATE|TIME_MINUTES),
               " H1_AS3=",DoubleToString(as3_h1,8),
               " D1_bar=",TimeToString(iTime(Symbol(),PERIOD_D1,1),TIME_DATE|TIME_MINUTES),
               " D1_AS3=",DoubleToString(as3_d1,8),
               " W1_bar=",TimeToString(iTime(Symbol(),PERIOD_W1,1),TIME_DATE|TIME_MINUTES),
               " W1_AS3=",DoubleToString(as3_w1,8),
               " trading_lock=",AS_TRADING_LOCK);
      }
      else
      {
         Print("[AS][CORE][WARN] MTF source unavailable",
               " H1_ok=",h1_ok,
               " D1_ok=",d1_ok,
               " W1_ok=",w1_ok,
               " trading_lock=",AS_TRADING_LOCK);
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
      Print("[AS][CORE] bar=",
            TimeToString(iTime(Symbol(),Period(),1),TIME_DATE|TIME_MINUTES),
            " AS3=",DoubleToString(as3_now,8),
            " prev=",DoubleToString(as3_prev,8),
            " old=",DoubleToString(as3_old,8),
            " sign=",as3_sign,
            " spread=",DoubleToString(spread_points,1),
            " spread_ok=",spread_ok,
            " open_positions=",p.buys+p.sells,
            " daily_block=",g_daily.trading_blocked,
            " trading_lock=",AS_TRADING_LOCK);
   }

   // IMPORTANT:
   // No OrderSend / OrderModify / OrderClose call exists here.
   // No AS_TrendHierarchy field is populated from guessed TF mappings.
}
