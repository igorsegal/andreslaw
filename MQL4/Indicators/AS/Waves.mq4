// =============================================================================
//  AS :: Waves.mq4
//  Three waves, six buffers: plus / minus per wave.
//  Colors editable in indicator properties.
// =============================================================================
#property strict
#property indicator_separate_window
#property indicator_buffers 6

#property indicator_color1 clrDodgerBlue
#property indicator_color2 clrRed
#property indicator_width1 2
#property indicator_width2 2

#property indicator_color3 clrLime
#property indicator_color4 clrMaroon
#property indicator_width3 2
#property indicator_width4 2

#property indicator_color5 clrDeepSkyBlue
#property indicator_color6 clrOrange
#property indicator_width5 2
#property indicator_width6 2

#include <AS/contracts.mqh>
#include <AS/wave_bank.mqh>

input int    Period_AS0 = 12;
input int    Period_AS1 = 60;
input int    Period_AS2 = 288;
input int    Period_AS3 = 1440;
input int    Period_AS4 = 7200;
input double Quality_Q  = 0.7;
input int    StdWindow  = 2000;

input double Scale_AS4 = 0.25;
input double Scale_AS3 = 1.0;
input double Scale_AS2 = 1.0;

double BufAS2P[];
double BufAS2N[];
double BufAS3P[];
double BufAS3N[];
double BufAS4P[];
double BufAS4N[];

double RawAS0[], RawAS1[], RawAS2[], RawAS3[], RawAS4[];

AS_WaveBankImpl g_bank;
double g_s2, g_s22, g_s3, g_s23, g_s4, g_s24;

int OnInit()
{
    IndicatorBuffers(11);

    SetIndexBuffer(0, BufAS2P);
    SetIndexBuffer(1, BufAS2N);
    SetIndexBuffer(2, BufAS3P);
    SetIndexBuffer(3, BufAS3N);
    SetIndexBuffer(4, BufAS4P);
    SetIndexBuffer(5, BufAS4N);
    SetIndexBuffer(6, RawAS0);
    SetIndexBuffer(7, RawAS1);
    SetIndexBuffer(8, RawAS2);
    SetIndexBuffer(9, RawAS3);
    SetIndexBuffer(10, RawAS4);

    SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 2);
    SetIndexStyle(1, DRAW_LINE, STYLE_SOLID, 2);
    SetIndexStyle(2, DRAW_LINE, STYLE_SOLID, 2);
    SetIndexStyle(3, DRAW_LINE, STYLE_SOLID, 2);
    SetIndexStyle(4, DRAW_LINE, STYLE_SOLID, 2);
    SetIndexStyle(5, DRAW_LINE, STYLE_SOLID, 2);

    SetIndexLabel(0, "AS2+");
    SetIndexLabel(1, "AS2-");
    SetIndexLabel(2, "AS3+");
    SetIndexLabel(3, "AS3-");
    SetIndexLabel(4, "AS4+");
    SetIndexLabel(5, "AS4-");

    for (int i = 0; i < 6; i++)
        SetIndexEmptyValue(i, EMPTY_VALUE);

    IndicatorShortName("AS_Waves");
    IndicatorDigits(3);

    AS_Periods p;
    p.as0 = Period_AS0;
    p.as1 = Period_AS1;
    p.as2 = Period_AS2;
    p.as3 = Period_AS3;
    p.as4 = Period_AS4;

    wave_bank_init(g_bank, p, Quality_Q);

    Print("AS_Waves v8: scales AS4=", Scale_AS4,
          " AS3=", Scale_AS3, " AS2=", Scale_AS2);
    return(INIT_SUCCEEDED);
}

double std_from_sums(double sum, double sum2, int count)
{
    if (count < 10) return 1.0;
    double mean = sum / count;
    double var  = sum2 / count - mean * mean;
    if (var < 0.0) var = 0.0;
    double s = MathSqrt(var);
    if (s < 1e-12) s = 1.0;
    return s;
}

void process_bar(int b, int rates_total)
{
    double as0, as1, as2, as3, as4;
    wave_bank_step(g_bank, iClose(NULL, 0, b), as0, as1, as2, as3, as4);

    RawAS0[b] = as0;
    RawAS1[b] = as1;
    RawAS2[b] = as2;
    RawAS3[b] = as3;
    RawAS4[b] = as4;

    g_s2  += as2;   g_s22 += as2 * as2;
    g_s3  += as3;   g_s23 += as3 * as3;
    g_s4  += as4;   g_s24 += as4 * as4;

    int old = b + StdWindow + 1;
    if (old <= rates_total - 1)
    {
        double o2 = RawAS2[old];
        double o3 = RawAS3[old];
        double o4 = RawAS4[old];
        g_s2  -= o2;  g_s22 -= o2 * o2;
        g_s3  -= o3;  g_s23 -= o3 * o3;
        g_s4  -= o4;  g_s24 -= o4 * o4;
    }

    int count = rates_total - b;
    if (count > StdWindow) count = StdWindow;

    double sig2 = std_from_sums(g_s2, g_s22, count);
    double sig3 = std_from_sums(g_s3, g_s23, count);
    double sig4 = std_from_sums(g_s4, g_s24, count);

    double v2 = (as2 / sig2) * Scale_AS2;
    double v3 = (as3 / sig3) * Scale_AS3;
    double v4 = (as4 / sig4) * Scale_AS4;

    BufAS2P[b] = EMPTY_VALUE; BufAS2N[b] = EMPTY_VALUE;
    BufAS3P[b] = EMPTY_VALUE; BufAS3N[b] = EMPTY_VALUE;
    BufAS4P[b] = EMPTY_VALUE; BufAS4N[b] = EMPTY_VALUE;

    if (v2 >= 0.0) BufAS2P[b] = v2; else BufAS2N[b] = v2;
    if (v3 >= 0.0) BufAS3P[b] = v3; else BufAS3N[b] = v3;
    if (v4 >= 0.0) BufAS4P[b] = v4; else BufAS4N[b] = v4;
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
    if (rates_total < 50) return(0);

    if (prev_calculated == 0)
    {
        wave_bank_reset(g_bank);
        g_s2 = 0; g_s22 = 0;
        g_s3 = 0; g_s23 = 0;
        g_s4 = 0; g_s24 = 0;

        for (int b = rates_total - 1; b >= 1; b--)
            process_bar(b, rates_total);
        return(rates_total);
    }

    if (rates_total > prev_calculated)
    {
        int first_new = rates_total - prev_calculated;
        if (first_new < 1) first_new = 1;
        for (int b = first_new; b >= 1; b--)
            process_bar(b, rates_total);
        return(rates_total);
    }

    return(rates_total);
}
