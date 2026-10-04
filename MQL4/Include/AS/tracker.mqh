#ifndef AS_TRACKER_MQH
#define AS_TRACKER_MQH
#include <AS/contracts.mqh>
#include <AS/val_risk.mqh>
void AS_TrackPositions(string symbol,int magic,bool include_manual,AS_PositionStats &s)
{
   s.buys=0; s.sells=0; s.buy_lots=0.0; s.sell_lots=0.0;
   s.total_lots=0.0; s.floating_profit=0.0; s.stop_risk_money=0.0;
   for(int i=OrdersTotal()-1;i>=0;i--)
   {
      if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) continue;
      if(OrderSymbol()!=symbol) continue;
      if(!include_manual && OrderMagicNumber()!=magic) continue;
      int type=OrderType();
      if(type!=OP_BUY && type!=OP_SELL) continue;
      if(type==OP_BUY) { s.buys++; s.buy_lots+=OrderLots(); }
      else { s.sells++; s.sell_lots+=OrderLots(); }
      s.total_lots+=OrderLots();
      s.floating_profit+=OrderProfit()+OrderSwap()+OrderCommission();
      double r=AS_StopRiskMoney(symbol,type,OrderLots(),OrderOpenPrice(),OrderStopLoss());
      if(r>0.0) s.stop_risk_money+=r;
   }
}
#endif
