#ifndef AS_SIG_REVERSAL_MQH
#define AS_SIG_REVERSAL_MQH
#include <AS/contracts.mqh>
// SWT trading signal from intrahour W2 (closed bars):
// 1) zero-line crossing; 2) turn away from zero while remaining on same side.
int AS_W2Signal(double current_closed,double prev_closed,double older_closed)
{
   if(prev_closed<=0.0 && current_closed>0.0) return AS_SIG_BUY;
   if(prev_closed>=0.0 && current_closed<0.0) return AS_SIG_SELL;
   if(prev_closed>0.0 && older_closed>prev_closed && current_closed>prev_closed)
      return AS_SIG_BUY;
   if(prev_closed<0.0 && older_closed<prev_closed && current_closed<prev_closed)
      return AS_SIG_SELL;
   return AS_SIG_NONE;
}
#endif
