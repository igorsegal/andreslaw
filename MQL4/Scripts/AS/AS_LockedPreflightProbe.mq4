//+------------------------------------------------------------------+
//| AS_LockedPreflightProbe.mq4                                      |
//| Observation-only broker preflight: never sends/modifies orders. |
//+------------------------------------------------------------------+
#property strict
#property script_show_inputs
#include <AS/val_risk.mqh>
#include <AS/val_margin.mqh>
#include <AS/val_spread.mqh>
#include <AS/order_size.mqh>

input double ProbeLots=0.01;
input int ProbeStopDistancePoints=500;
input double ProbeRiskLimitPercent=2.0;
input double ProbeMaxSpreadPoints=30.0;
input double ProbeMaxLeverage=500.0;
input int ProbeMagic=260010;

void ProbeSide(int cmd)
{
   string side=(cmd==OP_BUY)?"BUY":"SELL";
   string symbol=Symbol();
   RefreshRates();
   double entry=(cmd==OP_BUY)?MarketInfo(symbol,MODE_ASK):MarketInfo(symbol,MODE_BID);
   double point=MarketInfo(symbol,MODE_POINT);
   double minStop=MarketInfo(symbol,MODE_STOPLEVEL);
   double lots=AS_NormalizeLots(symbol,ProbeLots);
   if(entry<=0.0 || point<=0.0 || lots<=0.0 || ProbeStopDistancePoints<=0)
   {
      Print("[AS][PROBE] side=",side," result=BLOCK reason=INVALID_MARKET_OR_LOTS");
      return;
   }
   double stop=NormalizeDouble(entry+((cmd==OP_BUY)?-1.0:1.0)*ProbeStopDistancePoints*point,
                               (int)MarketInfo(symbol,MODE_DIGITS));
   bool stop_side=(cmd==OP_BUY)?(stop<entry):(stop>entry);
   bool stop_distance=(ProbeStopDistancePoints>minStop);
   double riskMoney=AS_StopRiskMoney(symbol,cmd,lots,entry,stop);
   double riskAfter=0.0;
   // Reject unavailable risk valuation even if the limit is disabled.
   bool riskOk=(riskMoney>=0.0) &&
      AS_CheckRiskLimit(symbol,ProbeMagic,false,riskMoney,ProbeRiskLimitPercent,riskAfter);
   double freeMarginAfter=0.0;
   bool marginOk=AS_CheckMargin(symbol,cmd,lots,ProbeMaxLeverage,freeMarginAfter);
   double spread=0.0;
   bool spreadOk=AS_CheckSpread(symbol,ProbeMaxSpreadPoints,spread) && spread>=0.0;
   bool ready=stop_side && stop_distance && riskOk && marginOk && spreadOk;
   Print("[AS][PROBE] side=",side,
         " result=",(ready?"CHECKS_PASS":"BLOCK"),
         " entry=",DoubleToString(entry,Digits),
         " stop=",DoubleToString(stop,Digits),
         " lots=",DoubleToString(lots,2),
         " stop_level_points=",DoubleToString(minStop,1),
         " stop_distance_ok=",stop_distance,
         " risk_money=",DoubleToString(riskMoney,2),
         " risk_after_pct=",DoubleToString(riskAfter,2),
         " risk_ok=",riskOk,
         " margin_after=",DoubleToString(freeMarginAfter,2),
         " margin_ok=",marginOk,
         " spread=",DoubleToString(spread,1),
         " spread_ok=",spreadOk,
         " trade_sent=NO");
}

void OnStart()
{
   Print("[AS][PROBE] START observation_only=1 orders_disabled=1");
   ProbeSide(OP_BUY);
   ProbeSide(OP_SELL);
   Print("[AS][PROBE] END orders_sent=0");
}
