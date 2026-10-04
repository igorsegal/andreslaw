#ifndef AS_PM_DISPATCH_MQH
#define AS_PM_DISPATCH_MQH
#include <AS/contracts.mqh>
#include <AS/exec_close.mqh>
#include <AS/pm_stop.mqh>
#include <AS/pm_take.mqh>
#include <AS/pm_trail.mqh>
// Dispatcher only. SWT channel levels and reversal flags MUST be supplied by
// verified providers; this module does not invent SWTsr formulas.
void AS_ManageOpenPositions(string symbol,int magic,bool include_manual,
                            AS_ManageContext &ctx,int slippage)
{
   for(int i=OrdersTotal()-1;i>=0;i--)
   {
      if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) continue;
      if(OrderSymbol()!=symbol) continue;
      if(!include_manual && OrderMagicNumber()!=magic) continue;
      int type=OrderType();
      if(type!=OP_BUY && type!=OP_SELL) continue;
      int ticket=OrderTicket();
      bool close_now=(type==OP_BUY)?ctx.close_buys_by_reversal:ctx.close_sells_by_reversal;
      if(close_now) { AS_CloseTicket(ticket,slippage); continue; }
      double sl=(type==OP_BUY)?ctx.channel_stop_buy:ctx.channel_stop_sell;
      double tp=(type==OP_BUY)?ctx.channel_take_buy:ctx.channel_take_sell;
      if(sl>0.0) AS_TightenChannelStop(ticket,sl);
      if(tp>0.0) AS_SetChannelTakeProfit(ticket,tp);
      if(ctx.trailing_factor>0.0 && ctx.grid_step_price>0.0)
         AS_ApplyAdaptiveTrail(ticket,ctx.grid_step_price,ctx.trailing_factor);
   }
}
#endif
