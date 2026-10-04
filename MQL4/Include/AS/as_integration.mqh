// =============================================================================
//  AS :: as_integration.mqh
//  RECOVERY STAGE 2 - BUILD/SMOKE BRIDGE
//
//  Purpose of this stage:
//    1) restore a coherent compile/runtime bridge;
//    2) verify the recovered SWT wave source inside the EA;
//    3) DO NOT open orders until the trading rules are reconstructed and tested.
// =============================================================================
#ifndef AS_INTEGRATION_MQH
#define AS_INTEGRATION_MQH

#property strict

class AS_IntegrationManager
{
private:
   double m_hysteresis;
   double m_slBuffer;
   double m_lotSize;
   double m_riskPercent;
   int    m_lastSign;

public:
   AS_IntegrationManager()
   {
      m_hysteresis  = 0.0;
      m_slBuffer    = 0.0005;
      m_lotSize     = 0.1;
      m_riskPercent = 1.0;
      m_lastSign    = 0;
   }

   bool Init(const double hysteresis,
             const double slBuffer,
             const double lotSize,
             const double riskPercent)
   {
      if(hysteresis < 0.0 || slBuffer < 0.0 || lotSize <= 0.0 || riskPercent < 0.0)
      {
         Print("[AS][INTEGRATION][ERROR] Invalid initialization parameters");
         return false;
      }

      m_hysteresis  = hysteresis;
      m_slBuffer    = slBuffer;
      m_lotSize     = lotSize;
      m_riskPercent = riskPercent;
      m_lastSign    = 0;
      return true;
   }

   void OnTickProcess(const double as3Value,
                      const double barHigh,
                      const double barLow,
                      const datetime barTime)
   {
      // Stage 2 intentionally observes only. No OrderSend/OrderModify/OrderClose.
      int sign = 0;
      if(as3Value >  m_hysteresis) sign =  1;
      if(as3Value < -m_hysteresis) sign = -1;

      if(sign == 0)
         return;

      if(sign != m_lastSign)
      {
         Print("[AS][SMOKE] AS3 sign change: ", m_lastSign, " -> ", sign,
               " time=", TimeToString(barTime, TIME_DATE|TIME_MINUTES),
               " AS3=", DoubleToString(as3Value, 8),
               " H=", DoubleToString(barHigh, Digits),
               " L=", DoubleToString(barLow, Digits));
         m_lastSign = sign;
      }
   }
};

#endif
