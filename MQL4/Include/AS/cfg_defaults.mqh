#ifndef AS_CFG_DEFAULTS_MQH
#define AS_CFG_DEFAULTS_MQH
#include <AS/contracts.mqh>

// Conservative recovery defaults. enabled=false is an Andreslav safety gate,
// so merely installing this module can never enable live trading.
void AS_ConfigSafeDefaults(AS_Config &c)
{
   c.enabled=false;
   c.trend_vector=4;
   c.adaptive_mode=false;
   c.dominant_correction=true;
   c.contra_trend=false;
   c.permit_long=true;
   c.permit_short=true;
   c.stop_loss_level=5;
   c.take_profit_level=3;
   c.risk_trade_percent=1.0;
   c.risk_limit_percent=10.0;
   c.leverage_limit=0.0;
   c.lots_manual=0.0;
   c.profit_risk_percent=0.0;
   c.adaptive_trailing_stop=0.0;
   c.safe_mode_close=false;
   c.manual_position_control=false;
   c.timeout_minutes=10;
   c.magic=112358;
   c.daily_profit_target_percent=0.0;
   c.daily_loss_limit_percent=0.0;
   c.max_spread_points=0.0;
}

int AS_ClampTrendVector(int v)
{
   if(v<4) return 4;
   if(v>8) return 8;
   return v;
}
#endif
