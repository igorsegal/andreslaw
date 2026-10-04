#ifndef AS_EXEC_CLOSE_MQH
#define AS_EXEC_CLOSE_MQH
#include <AS/contracts.mqh>
bool AS_CloseTicket(int ticket,int slippage)
{
   if(!OrderSelect(ticket,SELECT_BY_TICKET)) return false;
   int type=OrderType();
   if(type!=OP_BUY && type!=OP_SELL) return false;
   string symbol=OrderSymbol();
   int digits=(int)MarketInfo(symbol,MODE_DIGITS);
   double price=(type==OP_BUY)?MarketInfo(symbol,MODE_BID):MarketInfo(symbol,MODE_ASK);
   ResetLastError();
   return OrderClose(ticket,OrderLots(),NormalizeDouble(price,digits),slippage,clrNONE);
}

int AS_ClosePositions(string symbol,int magic,bool include_manual,int direction,int slippage)
{
   int closed=0;
   for(int i=OrdersTotal()-1;i>=0;i--)
   {
      if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) continue;
      if(OrderSymbol()!=symbol) continue;
      if(!include_manual && OrderMagicNumber()!=magic) continue;
      int type=OrderType();
      if(type!=OP_BUY && type!=OP_SELL) continue;
      if(direction==AS_SIG_BUY && type!=OP_BUY) continue;
      if(direction==AS_SIG_SELL && type!=OP_SELL) continue;
      int ticket=OrderTicket();
      if(AS_CloseTicket(ticket,slippage)) closed++;
   }
   return closed;
}
#endif
