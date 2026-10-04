#ifndef AS_VAL_SPREAD_MQH
#define AS_VAL_SPREAD_MQH
bool AS_CheckSpread(string symbol,double max_points,double &spread_points)
{
   spread_points=MarketInfo(symbol,MODE_SPREAD);
   if(max_points<=0.0) return true;
   return (spread_points<=max_points);
}
#endif
