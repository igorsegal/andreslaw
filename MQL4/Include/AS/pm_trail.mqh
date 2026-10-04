#ifndef AS_PM_TRAIL_MQH
#define AS_PM_TRAIL_MQH
#include <AS/pm_stop.mqh>
bool AS_ApplyAdaptiveTrail(int ticket,double grid_step_price,double factor)
{
   if(grid_step_price<=0.0 || factor<=0.0 || !OrderSelect(ticket,SELECT_BY_TICKET)) return false;
   double distance=grid_step_price*factor;
   int type=OrderType();
   double candidate=0.0;
   if(type==OP_BUY) candidate=MarketInfo(OrderSymbol(),MODE_BID)-distance;
   else if(type==OP_SELL) candidate=MarketInfo(OrderSymbol(),MODE_ASK)+distance;
   else return false;
   return AS_TightenChannelStop(ticket,candidate);
}
#endif
