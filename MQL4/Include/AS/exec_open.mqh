#ifndef AS_EXEC_OPEN_MQH
#define AS_EXEC_OPEN_MQH
int AS_OpenMarket(string symbol,int cmd,double lots,double sl,double tp,
                  int slippage,int magic,string comment_text)
{
   if(cmd!=OP_BUY && cmd!=OP_SELL) return -1;
   int digits=(int)MarketInfo(symbol,MODE_DIGITS);
   double price=(cmd==OP_BUY)?MarketInfo(symbol,MODE_ASK):MarketInfo(symbol,MODE_BID);
   if(price<=0.0 || lots<=0.0) return -1;
   if(sl>0.0) sl=NormalizeDouble(sl,digits);
   if(tp>0.0) tp=NormalizeDouble(tp,digits);
   ResetLastError();
   return OrderSend(symbol,cmd,lots,NormalizeDouble(price,digits),slippage,sl,tp,
                    comment_text,magic,0,clrNONE);
}
#endif
