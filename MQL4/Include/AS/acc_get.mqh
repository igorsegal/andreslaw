#ifndef AS_ACC_GET_MQH
#define AS_ACC_GET_MQH
#include <AS/contracts.mqh>
void AS_GetAccountSnapshot(AS_AccountSnapshot &a)
{
   a.balance=AccountBalance();
   a.equity=AccountEquity();
   a.free_margin=AccountFreeMargin();
   a.margin=AccountMargin();
   a.leverage=AccountLeverage();
}
#endif
