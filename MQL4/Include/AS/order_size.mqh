#ifndef AS_ORDER_SIZE_MQH
#define AS_ORDER_SIZE_MQH
int AS_LotDigits(double step)
{
   int d=0;
   while(d<8 && MathAbs(step-NormalizeDouble(step,d))>1e-12) d++;
   return d;
}

double AS_NormalizeLots(string symbol,double lots)
{
   double minlot=MarketInfo(symbol,MODE_MINLOT);
   double maxlot=MarketInfo(symbol,MODE_MAXLOT);
   double step=MarketInfo(symbol,MODE_LOTSTEP);
   if(step<=0.0) step=minlot;
   if(step<=0.0) return 0.0;
   double v=MathFloor(lots/step+1e-10)*step;
   if(v<minlot) return 0.0;
   if(v>maxlot) v=maxlot;
   return NormalizeDouble(v,AS_LotDigits(step));
}

double AS_CalcLotsByRisk(string symbol,double entry,double stop,double risk_percent)
{
   if(risk_percent<=0.0 || entry<=0.0 || stop<=0.0) return 0.0;
   double tick_size=MarketInfo(symbol,MODE_TICKSIZE);
   double tick_value=MarketInfo(symbol,MODE_TICKVALUE);
   if(tick_size<=0.0 || tick_value<=0.0) return 0.0;
   double distance=MathAbs(entry-stop);
   if(distance<=0.0) return 0.0;
   double risk_money=AccountEquity()*risk_percent/100.0;
   double money_per_lot=(distance/tick_size)*tick_value;
   if(money_per_lot<=0.0) return 0.0;
   return AS_NormalizeLots(symbol,risk_money/money_per_lot);
}
#endif
