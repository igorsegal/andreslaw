#property strict

#include <AS/order_size.mqh>
#include <AS/val_risk.mqh>

input double RiskPercent = 1.0;
input int    StopDistancePoints = 1000;

int g_pass=0;
int g_fail=0;

void RS_Check(string id,bool ok,string details="")
{
   if(ok)
   {
      g_pass++;
      Print("[AS][RISK_SIZE][PASS] ",id,
            (details=="" ? "" : " "),details);
   }
   else
   {
      g_fail++;
      Print("[AS][RISK_SIZE][FAIL] ",id,
            (details=="" ? "" : " "),details);
   }
}

int OnInit()
{
   Print("[AS][RISK_SIZE] SELF-TEST START");

   string symbol=Symbol();
   double point=MarketInfo(symbol,MODE_POINT);
   double ask=MarketInfo(symbol,MODE_ASK);
   double minlot=MarketInfo(symbol,MODE_MINLOT);
   double maxlot=MarketInfo(symbol,MODE_MAXLOT);
   double lotstep=MarketInfo(symbol,MODE_LOTSTEP);
   double ticksize=MarketInfo(symbol,MODE_TICKSIZE);
   double tickvalue=MarketInfo(symbol,MODE_TICKVALUE);
   double equity=AccountEquity();

   RS_Check("RS-001_MARKET_META",
      point>0.0 && ask>0.0 && minlot>0.0 && maxlot>=minlot &&
      lotstep>0.0 && ticksize>0.0 && tickvalue>0.0 && equity>0.0);

   RS_Check("RS-002_INVALID_RISK_ZERO",
      AS_CalcLotsByRisk(symbol,ask,ask-point*StopDistancePoints,0.0)==0.0);

   RS_Check("RS-003_INVALID_ENTRY_ZERO",
      AS_CalcLotsByRisk(symbol,0.0,ask-point*StopDistancePoints,RiskPercent)==0.0);

   RS_Check("RS-004_INVALID_STOP_ZERO",
      AS_CalcLotsByRisk(symbol,ask,0.0,RiskPercent)==0.0);

   RS_Check("RS-005_BELOW_MIN_NORMALIZES_ZERO",
      AS_NormalizeLots(symbol,minlot*0.5)==0.0);

   double aboveMax=AS_NormalizeLots(symbol,maxlot+MathMax(lotstep,1.0));
   RS_Check("RS-006_ABOVE_MAX_CLAMPS",
      MathAbs(aboveMax-maxlot)<=lotstep*0.1,
      "got="+DoubleToString(aboveMax,4)+" max="+DoubleToString(maxlot,4));

   double stop=ask-point*StopDistancePoints;
   double lots=AS_CalcLotsByRisk(symbol,ask,stop,RiskPercent);

   RS_Check("RS-007_LIVE_CALC_NONNEGATIVE",
      lots>=0.0,
      "lots="+DoubleToString(lots,4));

   if(lots>0.0)
   {
      double actualRisk=AS_StopRiskMoney(symbol,OP_BUY,lots,ask,stop);
      double targetRisk=equity*RiskPercent/100.0;

      RS_Check("RS-008_ACTUAL_RISK_VALID",
         actualRisk>=0.0,
         "actual="+DoubleToString(actualRisk,2));

      RS_Check("RS-009_ACTUAL_RISK_NOT_ABOVE_TARGET",
         actualRisk<=targetRisk+0.01,
         "actual="+DoubleToString(actualRisk,2)+
         " target="+DoubleToString(targetRisk,2));

      double nextLots=AS_NormalizeLots(symbol,lots+lotstep);
      if(nextLots>lots)
      {
         double nextRisk=AS_StopRiskMoney(symbol,OP_BUY,nextLots,ask,stop);
         RS_Check("RS-010_FLOOR_BEHAVIOR",
            nextRisk>targetRisk-0.01,
            "nextRisk="+DoubleToString(nextRisk,2)+
            " target="+DoubleToString(targetRisk,2));
      }
      else
      {
         RS_Check("RS-010_FLOOR_BEHAVIOR",true,"at_max_lot");
      }
   }
   else
   {
      Print("[AS][RISK_SIZE] INFO calculated lot is below broker minimum for this test geometry");
      RS_Check("RS-008_ACTUAL_RISK_VALID",true,"skipped_below_min");
      RS_Check("RS-009_ACTUAL_RISK_NOT_ABOVE_TARGET",true,"skipped_below_min");
      RS_Check("RS-010_FLOOR_BEHAVIOR",true,"skipped_below_min");
   }

   Print("[AS][RISK_SIZE] META",
         " symbol=",symbol,
         " equity=",DoubleToString(equity,2),
         " riskPercent=",DoubleToString(RiskPercent,2),
         " stopPoints=",StopDistancePoints,
         " minLot=",DoubleToString(minlot,4),
         " lotStep=",DoubleToString(lotstep,4),
         " tickSize=",DoubleToString(ticksize,Digits),
         " tickValue=",DoubleToString(tickvalue,6),
         " calcLots=",DoubleToString(lots,4));

   Print("[AS][RISK_SIZE][SUMMARY] PASS=",g_pass,
         " FAIL=",g_fail,
         " TOTAL=",g_pass+g_fail);

   if(g_fail>0)
      return(INIT_FAILED);

   return(INIT_SUCCEEDED);
}

void OnTick()
{
}
