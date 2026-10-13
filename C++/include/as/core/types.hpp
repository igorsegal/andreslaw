#pragma once
#include <cstdint>
namespace as {
enum class Direction { Down=-1, None=0, Up=1 };
enum class Signal { Sell=-1, None=0, Buy=1 };
struct Bar { std::int64_t utc{0}; double open{0},high{0},low{0},close{0}; };
struct TradeIntent { Signal side{Signal::None}; double stop{0}; double target{0}; };
}
