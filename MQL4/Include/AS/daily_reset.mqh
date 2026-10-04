#ifndef AS_DAILY_RESET_MQH
#define AS_DAILY_RESET_MQH
#include <AS/contracts.mqh>
int AS_DayKey(datetime t) { return TimeYear(t)*1000+TimeDayOfYear(t); }
void AS_DailyInit(AS_DailyState &s)
{
   s.day_key=AS_DayKey(TimeCurrent());
   s.start_equity=AccountEquity();
   s.pnl_money=0.0; s.pnl_percent=0.0;
   s.profit_target_hit=false; s.loss_limit_hit=false; s.trading_blocked=false;
}
void AS_DailyUpdate(AS_DailyState &s,double profit_target_percent,double loss_limit_percent)
{
   int key=AS_DayKey(TimeCurrent());
   if(s.day_key!=key || s.start_equity<=0.0) AS_DailyInit(s);
   s.pnl_money=AccountEquity()-s.start_equity;
   s.pnl_percent=(s.start_equity>0.0)?100.0*s.pnl_money/s.start_equity:0.0;
   s.profit_target_hit=(profit_target_percent>0.0 && s.pnl_percent>=profit_target_percent);
   s.loss_limit_hit=(loss_limit_percent>0.0 && s.pnl_percent<=-loss_limit_percent);
   s.trading_blocked=(s.profit_target_hit || s.loss_limit_hit);
}
#endif
