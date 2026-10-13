#pragma once
#include <vector>
namespace as {struct Metrics {unsigned trades{0}; double net_pnl{0}; bool valid{false};};
inline Metrics summarize(const std::vector<double>& pnls){Metrics m; m.trades=static_cast<unsigned>(pnls.size()); for(auto x:pnls)m.net_pnl+=x; m.valid=!pnls.empty(); return m;}}
