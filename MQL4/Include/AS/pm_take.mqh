#ifndef AS_PM_TAKE_MQH
#define AS_PM_TAKE_MQH
#include <AS/exec_modify.mqh>
bool AS_SetChannelTakeProfit(int ticket,double target_price)
{
   if(target_price<=0.0 || !OrderSelect(ticket,SELECT_BY_TICKET)) return false;
   int type=OrderType();
   double bid=MarketInfo(OrderSymbol(),MODE_BID);
   double ask=MarketInfo(OrderSymbol(),MODE_ASK);
   if(type==OP_BUY && target_price<=ask) return false;
   if(type==OP_SELL && target_price>=bid) return false;
   if(type!=OP_BUY && type!=OP_SELL) return false;
   return AS_ModifyStops(ticket,OrderStopLoss(),target_price);
}
#endif
