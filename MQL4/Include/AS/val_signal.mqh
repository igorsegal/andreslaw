#ifndef AS_VAL_SIGNAL_MQH
#define AS_VAL_SIGNAL_MQH
#include <AS/contracts.mqh>
bool AS_ValidateTradeSignal(int trade,AS_Config &c)
{
   if(!c.enabled) return false;
   if(trade==AS_SIG_BUY) return c.permit_long;
   if(trade==AS_SIG_SELL) return c.permit_short;
   return false;
}
#endif
