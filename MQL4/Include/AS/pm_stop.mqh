#ifndef AS_PM_STOP_MQH
#define AS_PM_STOP_MQH
#include <AS/exec_modify.mqh>
bool AS_TightenChannelStop(int ticket,double candidate_stop)
{
   if(candidate_stop<=0.0 || !OrderSelect(ticket,SELECT_BY_TICKET)) return false;
   int type=OrderType();
   double old=OrderStopLoss();
   double bid=MarketInfo(OrderSymbol(),MODE_BID);
   double ask=MarketInfo(OrderSymbol(),MODE_ASK);
   if(type==OP_BUY)
   {
      if(candidate_stop>=bid) return false;
      if(old>0.0 && candidate_stop<=old) return true;
   }
   else if(type==OP_SELL)
   {
      if(candidate_stop<=ask) return false;
      if(old>0.0 && candidate_stop>=old) return true;
   }
   else return false;
   return AS_ModifyStops(ticket,candidate_stop,OrderTakeProfit());
}
#endif
