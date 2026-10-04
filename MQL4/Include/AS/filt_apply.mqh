// =============================================================================
//  AS :: AS/filt_apply.mqh
// =============================================================================
#ifndef AS_FILT_APPLY_MQH
#define AS_FILT_APPLY_MQH

#include <AS/contracts.mqh>

double filt_apply(AS_FilterState &f, double x)
{
    double y = f.b0 * x
             + f.b1 * f.x1
             + f.b2 * f.x2
             - f.a1 * f.y1
             - f.a2 * f.y2;

    f.x2 = f.x1; f.x1 = x;
    f.y2 = f.y1; f.y1 = y;

    return y;
}

#endif
