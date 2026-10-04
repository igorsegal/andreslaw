// =============================================================================
//  AS :: wave_provider.mqh
//  RECOVERY STAGE 6 - MTF SOURCE BRIDGE
//
//  Single source of truth:
//    compiled indicator Indicators\AS\AS_Waves.ex4
//
//  Stage 6 adds explicit-timeframe access only.
//  It does NOT invent the mapping of SWT hierarchy names to timeframes.
// =============================================================================
#ifndef AS_WAVE_PROVIDER_MQH
#define AS_WAVE_PROVIDER_MQH

#property strict

class AS_WaveProvider
{
private:
   int    m_waveIndex;
   string m_indicatorName;

   int RawBufferForWave(const int waveIndex) const
   {
      // AS_Waves v8: RawAS0..RawAS4 are buffers 6..10.
      return 6 + waveIndex;
   }

public:
   AS_WaveProvider()
   {
      m_waveIndex     = 3;
      m_indicatorName = "AS\\AS_Waves";
   }

   bool Init(const int waveIndex)
   {
      if(waveIndex < 0 || waveIndex > 4)
      {
         Print("[AS][WAVE_PROVIDER][ERROR] Invalid wave index: ", waveIndex);
         return false;
      }

      m_waveIndex = waveIndex;
      return true;
   }

   bool GetWaveValue(const int waveIndex,
                     const int shift,
                     double &outValue)
   {
      // EXACT Stage-5 current-timeframe path.
      // Do not route this proven path through the MTF bridge.
      if(waveIndex < 0 || waveIndex > 4 || shift < 0)
         return false;

      ResetLastError();

      double value = iCustom(NULL, 0, m_indicatorName,
                             12, 60, 288, 1440, 7200,
                             0.7, 2000,
                             0.25, 1.0, 1.0,
                             RawBufferForWave(waveIndex), shift);

      int err = GetLastError();
      if(err != 0)
      {
         Print("[AS][WAVE_PROVIDER][ERROR] current-TF iCustom failed, err=", err,
               " wave=", waveIndex, " shift=", shift);
         return false;
      }

      if(value == EMPTY_VALUE || !MathIsValidNumber(value))
         return false;

      outValue = value;
      return true;
   }

   bool GetWaveValueTF(const int timeframe,
                       const int waveIndex,
                       const int shift,
                       double &outValue)
   {
      // PERIOD_CURRENT must use the exact Stage-5 path above.
      if(timeframe == PERIOD_CURRENT || timeframe == 0)
         return GetWaveValue(waveIndex, shift, outValue);

      if(timeframe < 0 || waveIndex < 0 || waveIndex > 4 || shift < 0)
         return false;

      ResetLastError();

      // Explicit higher-timeframe bridge. Wave math remains inside AS_Waves.
      double value = iCustom(NULL, timeframe, m_indicatorName,
                             12, 60, 288, 1440, 7200,
                             0.7, 2000,
                             0.25, 1.0, 1.0,
                             RawBufferForWave(waveIndex), shift);

      int err = GetLastError();
      if(err != 0)
      {
         Print("[AS][WAVE_PROVIDER][ERROR] MTF iCustom failed, err=", err,
               " tf=", timeframe,
               " wave=", waveIndex,
               " shift=", shift);
         return false;
      }

      if(value == EMPTY_VALUE || !MathIsValidNumber(value))
         return false;

      outValue = value;
      return true;
   }

   bool GetClosedAS3TF(const int timeframe, double &outValue)
   {
      // Closed bar only: no use of the forming bar.
      return GetWaveValueTF(timeframe, 3, 1, outValue);
   }

   bool GetClosedAS3SeriesTF(const int timeframe,
                             double &nowValue,
                             double &prevValue,
                             double &oldValue)
   {
      if(!GetWaveValueTF(timeframe, 3, 1, nowValue))  return false;
      if(!GetWaveValueTF(timeframe, 3, 2, prevValue)) return false;
      if(!GetWaveValueTF(timeframe, 3, 3, oldValue))  return false;
      return true;
   }

   bool GetCurrentAS3(double &outValue)
   {
      return GetClosedAS3TF(PERIOD_CURRENT, outValue);
   }
};

#endif
