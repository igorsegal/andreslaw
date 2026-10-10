#property strict

#include <AS/contracts.mqh>
#include <AS/cfg_defaults.mqh>
#include <AS/wave_provider.mqh>
#include <AS/wave_hierarchy.mqh>
#include <AS/sig_trend.mqh>
#include <AS/sig_pattern.mqh>
#include <AS/sig_reversal.mqh>
#include <AS/sig_collect.mqh>

#define AS_DECISION_RUNTIME_TRADING_LOCK 1

AS_WaveProvider *g_provider=NULL;
datetime g_lastH1Bar=0;

int Dir(double v)
{
   if(v>0.0) return AS_DIR_UP;
   if(v<0.0) return AS_DIR_DN;
   return AS_DIR_NO;
}

string DirText(int d)
{
   if(d==AS_DIR_UP) return "UP";
   if(d==AS_DIR_DN) return "DN";
   return "NO";
}

string SigText(int s)
{
   if(s==AS_SIG_BUY) return "BUY";
   if(s==AS_SIG_SELL) return "SELL";
   return "NONE";
}

bool ReadAS3(int tf,double &v)
{
   return g_provider.GetWaveValueTF(tf,3,1,v);
}

bool ReadH1AS2(double &now,double &prev,double &old)
{
   if(!g_provider.GetWaveValueTF(PERIOD_H1,2,1,now)) return false;
   if(!g_provider.GetWaveValueTF(PERIOD_H1,2,2,prev)) return false;
   if(!g_provider.GetWaveValueTF(PERIOD_H1,2,3,old)) return false;
   return true;
}

void Evaluate()
{
   double h1_as3=0.0;
   double d1_as3=0.0;
   double w1_as3=0.0;
   double as2_now=0.0;
   double as2_prev=0.0;
   double as2_old=0.0;

   bool h1ok=ReadAS3(PERIOD_H1,h1_as3);
   bool d1ok=ReadAS3(PERIOD_D1,d1_as3);
   bool w1ok=ReadAS3(PERIOD_W1,w1_as3);
   bool as2ok=ReadH1AS2(as2_now,as2_prev,as2_old);

   if(!h1ok || !d1ok || !w1ok || !as2ok)
   {
      Print("[AS][DECISION_RUNTIME] DATA_UNAVAILABLE",
            " H1=",h1ok,
            " D1=",d1ok,
            " W1=",w1ok,
            " AS2=",as2ok,
            " trading_lock=",AS_DECISION_RUNTIME_TRADING_LOCK);
      return;
   }

   AS_TrendHierarchy h;
   AS_ClearTrendHierarchy(h);

   AS_SetTrendState(h.hourly,Dir(h1_as3),false,true);
   AS_SetTrendState(h.iday,Dir(d1_as3),false,true);
   AS_SetTrendState(h.daily,Dir(w1_as3),false,true);

   // Project demo profile:
   // Weekly trend source = closed W1 AS3.
   // This is an explicit Andreslaw project mapping, not a claim of exact SWT recovery.
   AS_SetTrendState(h.weekly,Dir(w1_as3),false,true);

   AS_Config c;
   AS_ConfigSafeDefaults(c);

   // Simulation-only decision gate.
   // No order module is included in this file.
   c.enabled=true;
   c.trend_vector=4;
   c.adaptive_mode=false;
   c.dominant_correction=false;
   c.contra_trend=false;
   c.permit_long=true;
   c.permit_short=true;

   bool dominant_block=false;
   int trend=AS_TrendDirection(h,c,dominant_block);
   int pattern=AS_PatternDirection(h);
   int signal=AS_W2Signal(as2_now,as2_prev,as2_old);

   int trade=AS_CollectTrade(
      trend,
      pattern,
      signal,
      c,
      dominant_block,
      false,
      false,
      false
   );

   Print(
      "[AS][DECISION_RUNTIME] RESULT",
      " H1=",DirText(Dir(h1_as3)),
      " D1=",DirText(Dir(d1_as3)),
      " W1=",DirText(Dir(w1_as3)),
      " trend=",DirText(trend),
      " pattern=",DirText(pattern),
      " signal=",SigText(signal),
      " trade=",SigText(trade),
      " AS2=",DoubleToString(as2_now,8),
      " trading_lock=",AS_DECISION_RUNTIME_TRADING_LOCK
   );
}

int OnInit()
{
   g_provider=new AS_WaveProvider();
   if(g_provider==NULL)
   {
      Print("[AS][DECISION_RUNTIME][FAIL] provider allocation");
      return INIT_FAILED;
   }

   if(!g_provider.Init(3))
   {
      Print("[AS][DECISION_RUNTIME][FAIL] provider init");
      delete g_provider;
      g_provider=NULL;
      return INIT_FAILED;
   }

   Print("[AS][DECISION_RUNTIME] INIT trading_lock=",AS_DECISION_RUNTIME_TRADING_LOCK);

   // Run once immediately, then once per new H1 bar.
   Evaluate();
   g_lastH1Bar=iTime(Symbol(),PERIOD_H1,0);

   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   if(g_provider!=NULL)
   {
      delete g_provider;
      g_provider=NULL;
   }
}

void OnTick()
{
   datetime t=iTime(Symbol(),PERIOD_H1,0);
   if(t<=0) return;
   if(t==g_lastH1Bar) return;
   g_lastH1Bar=t;
   Evaluate();
}
