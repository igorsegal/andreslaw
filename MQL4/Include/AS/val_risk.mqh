#ifndef AS_VAL_RISK_MQH
#define AS_VAL_RISK_MQH

double AS_StopRiskMoney(string symbol,int cmd,double lots,double open_price,double stop_price)
{
   if(lots<=0.0 || stop_price<=0.0) return -1.0;
   double tick_size=MarketInfo(symbol,MODE_TICKSIZE);
   double tick_value=MarketInfo(symbol,MODE_TICKVALUE);
   if(tick_size<=0.0 || tick_value<=0.0) return -1.0;
   double distance=MathAbs(open_price-stop_price);
   if(distance<=0.0) return 0.0;
   return (distance/tick_size)*tick_value*lots;
}

double AS_CurrentStopRiskMoney(string symbol,int magic,bool include_manual,bool &complete)
{
   complete=true;
   double total=0.0;
   for(int i=OrdersTotal()-1;i>=0;i--)
   {
      if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) continue;
      if(OrderSymbol()!=symbol) continue;
      if(!include_manual && OrderMagicNumber()!=magic) continue;
      int type=OrderType();
      if(type!=OP_BUY && type!=OP_SELL) continue;
      double r=AS_StopRiskMoney(symbol,type,OrderLots(),OrderOpenPrice(),OrderStopLoss());
      if(r<0.0) { complete=false; continue; }
      total+=r;
   }
   return total;
}

bool AS_CheckRiskLimit(string symbol,int magic,bool include_manual,
                       double proposed_risk_money,double risk_limit_percent,
                       double &risk_after_percent)
{
   bool complete=true;
   double current=AS_CurrentStopRiskMoney(symbol,magic,include_manual,complete);
   double equity=AccountEquity();
   if(equity<=0.0) { risk_after_percent=0.0; return false; }
   if(!complete && risk_limit_percent>0.0) { risk_after_percent=0.0; return false; }
   double total=current+MathMax(0.0,proposed_risk_money);
   risk_after_percent=100.0*total/equity;
   if(risk_limit_percent<=0.0) return true;
   return (risk_after_percent<=risk_limit_percent);
}
#endif
