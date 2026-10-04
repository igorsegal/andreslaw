#ifndef AS_CFG_LOAD_MQH
#define AS_CFG_LOAD_MQH
#include <AS/contracts.mqh>
#include <AS/cfg_defaults.mqh>

bool AS_ParseBool(string v)
{
   return (v=="1" || v=="true" || v=="TRUE" || v=="yes" || v=="YES");
}

void AS_ApplyConfigKV(AS_Config &c, string key, string value)
{
   if(key=="Enabled") c.enabled=AS_ParseBool(value);
   else if(key=="TrendVector") c.trend_vector=AS_ClampTrendVector((int)StringToInteger(value));
   else if(key=="AdaptiveMode") c.adaptive_mode=AS_ParseBool(value);
   else if(key=="DominantCorrection") c.dominant_correction=AS_ParseBool(value);
   else if(key=="ContrTrend") c.contra_trend=AS_ParseBool(value);
   else if(key=="PermitLong") c.permit_long=AS_ParseBool(value);
   else if(key=="PermitShort") c.permit_short=AS_ParseBool(value);
   else if(key=="StopLossLevel") c.stop_loss_level=(int)StringToInteger(value);
   else if(key=="TakeProfitLevel") c.take_profit_level=(int)StringToInteger(value);
   else if(key=="RiskTradePercent") c.risk_trade_percent=StringToDouble(value);
   else if(key=="RiskLimitPercent") c.risk_limit_percent=StringToDouble(value);
   else if(key=="LeverageLimit") c.leverage_limit=StringToDouble(value);
   else if(key=="LotsManual") c.lots_manual=StringToDouble(value);
   else if(key=="ProfitRiskPerc") c.profit_risk_percent=StringToDouble(value);
   else if(key=="AdaptiveTrailingStop") c.adaptive_trailing_stop=StringToDouble(value);
   else if(key=="SafeModeClose") c.safe_mode_close=AS_ParseBool(value);
   else if(key=="ManualPositionControl") c.manual_position_control=AS_ParseBool(value);
   else if(key=="TimeOutMinutes") c.timeout_minutes=(int)StringToInteger(value);
   else if(key=="Magic") c.magic=(int)StringToInteger(value);
   else if(key=="DailyProfitTargetPerc") c.daily_profit_target_percent=StringToDouble(value);
   else if(key=="DailyLossLimitPerc") c.daily_loss_limit_percent=StringToDouble(value);
   else if(key=="MaxSpreadPoints") c.max_spread_points=StringToDouble(value);
}

bool AS_LoadConfig(string file_name, AS_Config &c)
{
   AS_ConfigSafeDefaults(c);
   int h=FileOpen(file_name,FILE_READ|FILE_TXT|FILE_ANSI);
   if(h<0) return false;
   while(!FileIsEnding(h))
   {
      string line=FileReadString(h);
      StringTrimLeft(line); StringTrimRight(line);
      if(StringLen(line)==0) continue;
      string first=StringSubstr(line,0,1);
      if(first=="#" || first==";") continue;
      int p=StringFind(line,"=");
      if(p<=0) continue;
      string key=StringSubstr(line,0,p);
      string value=StringSubstr(line,p+1);
      StringTrimLeft(key); StringTrimRight(key);
      StringTrimLeft(value); StringTrimRight(value);
      AS_ApplyConfigKV(c,key,value);
   }
   FileClose(h);
   if(c.timeout_minutes<10) c.timeout_minutes=10;
   c.trend_vector=AS_ClampTrendVector(c.trend_vector);
   return true;
}
#endif
