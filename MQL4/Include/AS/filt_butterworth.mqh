// =============================================================================
//  AS :: AS/filt_butterworth.mqh
// =============================================================================
#ifndef AS_FILT_BUTTERWORTH_MQH
#define AS_FILT_BUTTERWORTH_MQH

#include <AS/contracts.mqh>

void filt_butterworth_init(AS_FilterState &f, int W, double Q)
{
    if (W < 3)    W = 3;
    if (Q <= 0.0) Q = 1.0;

    double K    = MathTan(M_PI / (double)W);
    double K2   = K * K;
    double norm = 1.0 / (1.0 + K / Q + K2);

    f.b0 =  (K / Q) * norm;
    f.b1 =   0.0;
    f.b2 = -(K / Q) * norm;
    f.a1 =  2.0 * (K2 - 1.0) * norm;
    f.a2 =  (1.0 - K / Q + K2) * norm;

    f.x1 = 0.0; f.x2 = 0.0;
    f.y1 = 0.0; f.y2 = 0.0;
}

void filt_butterworth_reset(AS_FilterState &f)
{
    f.x1 = 0.0; f.x2 = 0.0;
    f.y1 = 0.0; f.y2 = 0.0;
}

#endif
