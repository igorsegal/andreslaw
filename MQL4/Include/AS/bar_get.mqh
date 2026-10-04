#ifndef AS_BAR_GET_MQH
#define AS_BAR_GET_MQH
bool AS_IsNewBar(string symbol,int timeframe,datetime &last_bar_time)
{
   datetime t=iTime(symbol,timeframe,0);
   if(t<=0) return false;
   if(last_bar_time==0) { last_bar_time=t; return false; }
   if(t!=last_bar_time) { last_bar_time=t; return true; }
   return false;
}
double AS_BarOpen(string s,int tf,int shift)  { return iOpen(s,tf,shift); }
double AS_BarHigh(string s,int tf,int shift)  { return iHigh(s,tf,shift); }
double AS_BarLow(string s,int tf,int shift)   { return iLow(s,tf,shift); }
double AS_BarClose(string s,int tf,int shift) { return iClose(s,tf,shift); }
datetime AS_BarTime(string s,int tf,int shift){ return iTime(s,tf,shift); }
#endif
