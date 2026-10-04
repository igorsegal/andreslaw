#ifndef AS_VAL_MARGIN_MQH
#define AS_VAL_MARGIN_MQH
bool AS_CheckMargin(string symbol,int cmd,double lots,double leverage_limit,double &margin_after)
{
   margin_after=AccountFreeMarginCheck(symbol,cmd,lots);
   if(margin_after<=0.0) return false;
   if(leverage_limit>0.0 && AccountLeverage()>leverage_limit) return false;
   return true;
}
#endif
