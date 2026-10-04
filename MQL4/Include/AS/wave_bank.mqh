// =============================================================================
//  AS :: AS/wave_bank.mqh
//  5 filters as separate fields (no arrays of structs inside struct).
// =============================================================================
#ifndef AS_WAVE_BANK_MQH
#define AS_WAVE_BANK_MQH

#include <AS/contracts.mqh>
#include <AS/filt_butterworth.mqh>
#include <AS/filt_apply.mqh>

struct AS_WaveBankImpl {
    AS_FilterState f0;
    AS_FilterState f1;
    AS_FilterState f2;
    AS_FilterState f3;
    AS_FilterState f4;
    AS_Periods     periods;
    double         q;
    int            initialized;
};

void wave_bank_init(AS_WaveBankImpl &bank, AS_Periods &p, double q)
{
    bank.periods     = p;
    bank.q           = q;
    bank.initialized = 1;

    filt_butterworth_init(bank.f0, p.as0, q);
    filt_butterworth_init(bank.f1, p.as1, q);
    filt_butterworth_init(bank.f2, p.as2, q);
    filt_butterworth_init(bank.f3, p.as3, q);
    filt_butterworth_init(bank.f4, p.as4, q);
}

void wave_bank_reset(AS_WaveBankImpl &bank)
{
    filt_butterworth_reset(bank.f0);
    filt_butterworth_reset(bank.f1);
    filt_butterworth_reset(bank.f2);
    filt_butterworth_reset(bank.f3);
    filt_butterworth_reset(bank.f4);
}

void wave_bank_step(AS_WaveBankImpl &bank, double close_price,
                    double &as0, double &as1, double &as2,
                    double &as3, double &as4)
{
    as0 = filt_apply(bank.f0, close_price);
    as1 = filt_apply(bank.f1, close_price);
    as2 = filt_apply(bank.f2, close_price);
    as3 = filt_apply(bank.f3, close_price);
    as4 = filt_apply(bank.f4, close_price);
}

#endif
