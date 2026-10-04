// =============================================================================
//  AS :: AS_Targets.mq4
//  Step channels following price. Upper/lower shift together.
// =============================================================================
#property strict
#property indicator_chart_window
#property indicator_buffers 6

#property indicator_color1 clrLightCoral
#property indicator_color2 clrLightCoral
#property indicator_style1 STYLE_DOT
#property indicator_style2 STYLE_DOT
#property indicator_width1 1
#property indicator_width2 1

#property indicator_color3 clrOrange
#property indicator_color4 clrOrange
#property indicator_style3 STYLE_DASH
#property indicator_style4 STYLE_DASH
#property indicator_width3 1
#property indicator_width4 1

#property indicator_color5 clrDodgerBlue
#property indicator_color6 clrDodgerBlue
#property indicator_style5 STYLE_SOLID
#property indicator_style6 STYLE_SOLID
#property indicator_width5 1
#property indicator_width6 1

input int    Period_AS2 = 288;
input int    Period_AS3 = 1440;
input int    Period_AS4 = 7200;
input double WidthK2    = 1.0;
input double WidthK3    = 1.5;
input double WidthK4    = 2.5;
input int    AtrPeriod  = 20;
input bool   Show_AS2   = true;
input bool   Show_AS3   = true;
input bool   Show_AS4   = true;

double BufTop2[], BufBot2[];
double BufTop3[], BufBot3[];
double BufTop4[], BufBot4[];

// Persistent channel state
double g_top2 = 0, g_bot2 = 0;
double g_top3 = 0, g_bot3 = 0;
double g_top4 = 0, g_bot4 = 0;
int    g_init2 = 0, g_init3 = 0, g_init4 = 0;

int OnInit()
{
    IndicatorBuffers(6);
    SetIndexBuffer(0, BufTop2); SetIndexBuffer(1, BufBot2);
    SetIndexBuffer(2, BufTop3); SetIndexBuffer(3, BufBot3);
    SetIndexBuffer(4, BufTop4); SetIndexBuffer(5, BufBot4);

    SetIndexStyle(0, DRAW_LINE, STYLE_DOT,   1, clrLightCoral);
    SetIndexStyle(1, DRAW_LINE, STYLE_DOT,   1, clrLightCoral);
    SetIndexStyle(2, DRAW_LINE, STYLE_DASH,  1, clrOrange);
    SetIndexStyle(3, DRAW_LINE, STYLE_DASH,  1, clrOrange);
    SetIndexStyle(4, DRAW_LINE, STYLE_SOLID, 1, clrDodgerBlue);
    SetIndexStyle(5, DRAW_LINE, STYLE_SOLID, 1, clrDodgerBlue);

    SetIndexLabel(0, "AS2 top"); SetIndexLabel(1, "AS2 bot");
    SetIndexLabel(2, "AS3 top"); SetIndexLabel(3, "AS3 bot");
    SetIndexLabel(4, "AS4 top"); SetIndexLabel(5, "AS4 bot");

    for (int i = 0; i < 6; i++) SetIndexEmptyValue(i, EMPTY_VALUE);

    IndicatorShortName("AS_Targets");
    IndicatorDigits(_Digits);
    Print("AS_Targets v8: step channels");
    return(INIT_SUCCEEDED);
}

// Step-update: given new price, current top/bot, half-width hw.
// Return new top/bot.
void step_update(double price, double hw, double &top, double &bot, int &inited)
{
    if (!inited)
    {
        top = price + hw;
        bot = price - hw;
        inited = 1;
        return;
    }
    if (price > top)
    {
        top = price + hw;
        bot = top - 2.0 * hw;
    }
    else if (price < bot)
    {
        bot = price - hw;
        top = bot + 2.0 * hw;
    }
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

    int start;
    if (prev_calculated == 0)
    {
        start = rates_total - 1;
        g_init2 = g_init3 = g_init4 = 0;
    }
    else
    {
        start = prev_calculated - 1;
        if (start < 0) start = 0;
    }

    double p = MarketInfo(_Symbol, MODE_POINT);

    for (int b = start; b >= 0; b--)
    {
        double atr = iATR(_Symbol, _Period, AtrPeriod, b);
        if (atr <= 0.0) atr = 100.0 * p;

        double hw2 = atr * WidthK2;
        double hw3 = atr * WidthK3;
        double hw4 = atr * WidthK4;

        double mid = (high[b] + low[b]) * 0.5;

        if (Show_AS2)
        {
            step_update(mid, hw2, g_top2, g_bot2, g_init2);
            BufTop2[b] = g_top2;
            BufBot2[b] = g_bot2;
        }
        else { BufTop2[b] = EMPTY_VALUE; BufBot2[b] = EMPTY_VALUE; }

        if (Show_AS3)
        {
            step_update(mid, hw3, g_top3, g_bot3, g_init3);
            BufTop3[b] = g_top3;
            BufBot3[b] = g_bot3;
        }
        else { BufTop3[b] = EMPTY_VALUE; BufBot3[b] = EMPTY_VALUE; }

        if (Show_AS4)
        {
            step_update(mid, hw4, g_top4, g_bot4, g_init4);
            BufTop4[b] = g_top4;
            BufBot4[b] = g_bot4;
        }
        else { BufTop4[b] = EMPTY_VALUE; BufBot4[b] = EMPTY_VALUE; }
    }

    return(rates_total);
}
