#ifndef AS_EXEC_MODIFY_MQH
#define AS_EXEC_MODIFY_MQH
bool AS_ModifyStops(int ticket,double sl,double tp)
{
   if(!OrderSelect(ticket,SELECT_BY_TICKET)) return false;
   string symbol=OrderSymbol();
   int digits=(int)MarketInfo(symbol,MODE_DIGITS);
   if(sl>0.0) sl=NormalizeDouble(sl,digits);
   if(tp>0.0) tp=NormalizeDouble(tp,digits);
   if(MathAbs(OrderStopLoss()-sl)<MarketInfo(symbol,MODE_POINT)*0.1 &&
      MathAbs(OrderTakeProfit()-tp)<MarketInfo(symbol,MODE_POINT)*0.1) return true;
   ResetLastError();
   return OrderModify(ticket,OrderOpenPrice(),sl,tp,0,clrNONE);
}
#endif
