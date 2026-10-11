#pragma once
#include "as/core/types.hpp"
#include <cstddef>
namespace as {
struct EntryOrder {std::size_t signal_bar{0}; Signal side{Signal::None}; double stop_distance{0}; double target_distance{0}; double volume{1.0};};
enum class ExitReason {Stop, Target, EndOfData};
struct Trade {std::size_t entry_bar{0},exit_bar{0}; Signal side{Signal::None}; double entry{0},exit{0}, volume{0},pnl{0}; ExitReason reason{ExitReason::Stop};};
}
