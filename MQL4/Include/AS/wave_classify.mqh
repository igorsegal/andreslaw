// =============================================================================
//  AS :: AS/wave_classify.mqh
//  Rules: R1 (wave by ref), R4 (values by value).
// =============================================================================
#ifndef AS_WAVE_CLASSIFY_MQH
#define AS_WAVE_CLASSIFY_MQH

#include <AS/contracts.mqh>

void wave_classify_update(AS_Wave &w, double value, double prev_value)
{
    w.prev_value = prev_value;
    w.value      = value;

    double eps = 1e-10;

    if (value >  eps)      w.sign =  1;
    else if (value < -eps) w.sign = -1;
    else                   w.sign =  0;

    double diff = value - prev_value;
    if (diff >  eps)      w.slope =  1;
    else if (diff < -eps) w.slope = -1;
    else                  w.slope =  0;

    int s = w.sign;
    int d = w.slope;

    if (s > 0 && d > 0)       w.state = AS_WS_BULL_TREND;
    else if (s < 0 && d < 0)  w.state = AS_WS_BEAR_TREND;
    else if (s > 0 && d < 0)  w.state = AS_WS_BULL_CORR;
    else if (s < 0 && d > 0)  w.state = AS_WS_BEAR_CORR;
    else if (s == 0 && d > 0) w.state = AS_WS_REVERSAL_UP;
    else if (s == 0 && d < 0) w.state = AS_WS_REVERSAL_DOWN;
    else                      w.state = AS_WS_NEUTRAL;
}

#endif
