// =============================================================================
// AS :: contracts.mqh
// Recovery Stage 3. Existing Stage-1 contracts preserved; SWT orchestration
// contracts added without changing the wave/filter ABI.
// =============================================================================
#ifndef AS_CONTRACTS_MQH
#define AS_CONTRACTS_MQH

#define AS_VERSION_MAJOR   1
#define AS_VERSION_MINOR   1
#define AS_VERSION_PATCH   0

#define AS0   0
#define AS1   1
#define AS2   2
#define AS3   3
#define AS4   4
#define ASCOUNT   5

#define AS_WS_NEUTRAL        0
#define AS_WS_BULL_TREND     1
#define AS_WS_BEAR_TREND     2
#define AS_WS_BULL_CORR      3
#define AS_WS_BEAR_CORR      4
#define AS_WS_REVERSAL_UP    5
#define AS_WS_REVERSAL_DOWN  6

#define AS_DIR_DN  -1
#define AS_DIR_NO   0
#define AS_DIR_UP   1

#define AS_SIG_SELL -1
#define AS_SIG_NONE  0
#define AS_SIG_BUY   1

struct AS_FilterState {
    double b0; double b1; double b2;
    double a1; double a2;
    double x1; double x2;
    double y1; double y2;
};

struct AS_Wave {
    double value;
    double prev_value;
    int    slope;
    int    sign;
    int    state;
};

struct AS_Periods {
    int as0; int as1; int as2; int as3; int as4;
};

// State of one SWT trend level. The caller/provider is responsible for
// obtaining it from the corresponding SWT indicator/timeframe.
struct AS_TrendState {
    int  direction;   // AS_DIR_UP / AS_DIR_DN / AS_DIR_NO
    bool correction;  // true = correction, false = directed trend
    bool valid;
};

struct AS_TrendHierarchy {
    AS_TrendState hourly;
    AS_TrendState iday;
    AS_TrendState daily;
    AS_TrendState weekly;
    AS_TrendState short_trend;
    AS_TrendState medium_trend;
    AS_TrendState long_trend;
    AS_TrendState basic;
};

struct AS_Config {
    bool   enabled;                 // project safety gate; not an SWT parameter
    int    trend_vector;            // 4..8
    bool   adaptive_mode;
    bool   dominant_correction;
    bool   contra_trend;
    bool   permit_long;
    bool   permit_short;
    int    stop_loss_level;         // 1..7
    int    take_profit_level;       // 1..8
    double risk_trade_percent;
    double risk_limit_percent;
    double leverage_limit;
    double lots_manual;
    double profit_risk_percent;
    double adaptive_trailing_stop;
    bool   safe_mode_close;
    bool   manual_position_control;
    int    timeout_minutes;
    int    magic;
    double daily_profit_target_percent;
    double daily_loss_limit_percent;
    double max_spread_points;       // project guardrail; <=0 disables
};

struct AS_TradeDecision {
    int  trend;
    int  pattern;
    int  signal;
    int  trade;
    bool blocked_dominant_correction;
    bool blocked_risk;
    bool blocked_margin;
    bool blocked_spread;
};

struct AS_AccountSnapshot {
    double balance;
    double equity;
    double free_margin;
    double margin;
    int    leverage;
};

struct AS_PositionStats {
    int    buys;
    int    sells;
    double buy_lots;
    double sell_lots;
    double total_lots;
    double floating_profit;
    double stop_risk_money;
};

struct AS_DailyState {
    int    day_key;
    double start_equity;
    double pnl_money;
    double pnl_percent;
    bool   profit_target_hit;
    bool   loss_limit_hit;
    bool   trading_blocked;
};

struct AS_ManageContext {
    double channel_stop_buy;
    double channel_stop_sell;
    double channel_take_buy;
    double channel_take_sell;
    double grid_step_price;
    double trailing_factor;
    bool   close_buys_by_reversal;
    bool   close_sells_by_reversal;
};

#endif
