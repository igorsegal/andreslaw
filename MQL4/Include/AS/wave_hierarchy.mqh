#ifndef AS_WAVE_HIERARCHY_MQH
#define AS_WAVE_HIERARCHY_MQH
#include <AS/contracts.mqh>
void AS_SetTrendState(AS_TrendState &s,int direction,bool correction,bool valid)
{ s.direction=direction; s.correction=correction; s.valid=valid; }
void AS_ClearTrendHierarchy(AS_TrendHierarchy &h)
{
   AS_SetTrendState(h.hourly,AS_DIR_NO,false,false);
   AS_SetTrendState(h.iday,AS_DIR_NO,false,false);
   AS_SetTrendState(h.daily,AS_DIR_NO,false,false);
   AS_SetTrendState(h.weekly,AS_DIR_NO,false,false);
   AS_SetTrendState(h.short_trend,AS_DIR_NO,false,false);
   AS_SetTrendState(h.medium_trend,AS_DIR_NO,false,false);
   AS_SetTrendState(h.long_trend,AS_DIR_NO,false,false);
   AS_SetTrendState(h.basic,AS_DIR_NO,false,false);
}
bool AS_GetTrendByLevel(AS_TrendHierarchy &h,int level,AS_TrendState &out)
{
   if(level==1) out=h.hourly;
   else if(level==2) out=h.iday;
   else if(level==3) out=h.daily;
   else if(level==4) out=h.weekly;
   else if(level==5) out=h.short_trend;
   else if(level==6) out=h.medium_trend;
   else if(level==7) out=h.long_trend;
   else if(level==8) out=h.basic;
   else return false;
   return out.valid;
}
#endif
