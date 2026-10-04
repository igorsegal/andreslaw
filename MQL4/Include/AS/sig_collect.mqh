#ifndef AS_SIG_COLLECT_MQH
#define AS_SIG_COLLECT_MQH
#include <AS/contracts.mqh>
int AS_CollectTrade(int trend,int pattern,int signal,AS_Config &c,
                    bool block_dominant_correction,bool block_risk,
                    bool block_margin,bool block_spread)
{
   if(!c.enabled) return AS_SIG_NONE;
   if(block_dominant_correction || block_risk || block_margin || block_spread) return AS_SIG_NONE;
   if(trend==AS_DIR_UP && pattern==AS_DIR_UP && signal==AS_SIG_BUY && c.permit_long)
      return AS_SIG_BUY;
   if(trend==AS_DIR_DN && pattern==AS_DIR_DN && signal==AS_SIG_SELL && c.permit_short)
      return AS_SIG_SELL;
   return AS_SIG_NONE;
}
#endif
