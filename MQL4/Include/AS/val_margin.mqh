#ifndef AS_VAL_MARGIN_MQH
#define AS_VAL_MARGIN_MQH

// Portfolio safety invariant: do not accept an additional order when
// projected margin level would fall below 500 percent.
// AccountFreeMarginCheck returns remaining FREE MARGIN (account currency),
// not margin level. Margin levels are percentages.
#define AS_MIN_MARGIN_LEVEL_PERCENT 500.0

bool AS_CheckMarginLevel(string symbol,int cmd,double lots,
                         double leverage_limit,double min_level_percent,
                         double &free_margin_after,double &level_after_percent)
{
   free_margin_after=0.0;
   level_after_percent=0.0;

   if(lots<=0.0 || (cmd!=OP_BUY && cmd!=OP_SELL) ||
      min_level_percent<=0.0)
      return false;

   if(leverage_limit>0.0 && AccountLeverage()>leverage_limit)
      return false;

   double equity=AccountEquity();
   double used_before=AccountMargin();
   double free_before=AccountFreeMargin();
   if(equity<=0.0 || used_before<0.0 || free_before<0.0)
      return false;

   ResetLastError();
   double free_after=AccountFreeMarginCheck(symbol,cmd,lots);
   int check_error=GetLastError();
   free_margin_after=free_after;
   if(check_error!=0 || !MathIsValidNumber(free_after) ||
      free_after<=0.0 || free_after>equity)
      return false;

   // Incremental margin estimate from the broker's own preflight quote.
   // For hedged positions the broker may release margin. Do not count
   // a prospective release as available safety headroom.
   double added_margin=MathMax(0.0,free_before-free_after);
   double used_after=used_before+added_margin;
   if(used_after<=0.0) return false;  // unknown projected margin: fail closed

   level_after_percent=100.0*equity/used_after;
   return MathIsValidNumber(level_after_percent) &&
          level_after_percent>=min_level_percent;
}

// Preserve all existing callers; argument four remains a leverage ceiling.
// Independently enforce the new 500% margin-level floor.
bool AS_CheckMargin(string symbol,int cmd,double lots,
                    double leverage_limit,double &margin_after)
{
   double projected_level=0.0;
   return AS_CheckMarginLevel(symbol,cmd,lots,leverage_limit,
                               AS_MIN_MARGIN_LEVEL_PERCENT,
                               margin_after,projected_level);
}
#endif
