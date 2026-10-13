#pragma once
#include "as/waves/engine.hpp"
#include <vector>
#include <stdexcept>
#include <cmath>
#include <cstdint>

namespace as::waves {
struct HistoryRow {
  std::int64_t utc;
  Output waves;
};
// Requires strictly ascending timestamps: oldest closed bar first.
// One Engine per input series/timeframe, no forming bar, no hidden resets.
template <typename BarLike>
std::vector<HistoryRow> calculate_closed_history(const std::vector<BarLike>& bars,
                                                    Engine& engine) {
  std::vector<HistoryRow> out;
  out.reserve(bars.size());
  engine.reset();
  std::int64_t last = 0;
  bool first = true;
  for (const auto& bar : bars) {
    if ((!first && bar.utc <= last) || !std::isfinite(bar.close))
      throw std::invalid_argument("non-ascending timestamps or invalid close");
    out.push_back({bar.utc, engine.step_closed(bar.close)});
    last = bar.utc;
    first = false;
  }
  return out;
}
}
