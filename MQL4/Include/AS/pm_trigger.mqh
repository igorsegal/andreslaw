#ifndef AS_PM_TRIGGER_MQH
#define AS_PM_TRIGGER_MQH
bool AS_CloseByProfitRisk(double floating_profit,double strategic_risk_money,double threshold_percent)
{
   if(threshold_percent<=0.0 || strategic_risk_money<=0.0) return false;
   return (100.0*floating_profit/strategic_risk_money >= threshold_percent);
}
#endif
