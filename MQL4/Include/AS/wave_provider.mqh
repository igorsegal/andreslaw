// =============================================================================
//  AS :: wave_provider.mqh
//  RECOVERY STAGE 2
//  Single source of truth: compiled indicator Indicators\AS\AS_Waves.ex4
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

   bool GetWaveValue(const int waveIndex, const int shift, double &outValue)
   {
      if(waveIndex < 0 || waveIndex > 4 || shift < 0)
         return false;

      ResetLastError();

      // IMPORTANT: these inputs exactly match AS_Waves v8 defaults recovered in Stage 1.
      // Keeping the wave math in one place avoids a second, divergent Butterworth engine.
      double value = iCustom(NULL, 0, m_indicatorName,
                             12, 60, 288, 1440, 7200,
                             0.7, 2000,
                             0.25, 1.0, 1.0,
                             RawBufferForWave(waveIndex), shift);

      int err = GetLastError();
      if(err != 0)
      {
         Print("[AS][WAVE_PROVIDER][ERROR] iCustom failed, err=", err,
               " wave=", waveIndex, " shift=", shift);
         return false;
      }

      if(value == EMPTY_VALUE || !MathIsValidNumber(value))
         return false;

      outValue = value;
      return true;
   }

   bool GetCurrentAS3(double &outValue)
   {
      // Closed bar only: no use of the forming bar.
      return GetWaveValue(3, 1, outValue);
   }
};

#endif
