#ifndef AS_SIG_PATTERN_MQH
#define AS_SIG_PATTERN_MQH
#include <AS/contracts.mqh>
int AS_PatternDirection(AS_TrendHierarchy &h)
{
   if(!h.hourly.valid || !h.iday.valid || !h.daily.valid) return AS_DIR_NO;
   int d=h.hourly.direction;
   if(d==AS_DIR_NO) return AS_DIR_NO;
   if(h.iday.direction!=d || h.daily.direction!=d) return AS_DIR_NO;
   return d;
}
#endif
