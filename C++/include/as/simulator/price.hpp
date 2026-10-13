#pragma once
#include "as/core/types.hpp"
#include "as/simulator/policy.hpp"
namespace as {
inline double entry_price(const Bar& b,Signal side,const SimulationPolicy& p){
  return b.open+(side==Signal::Buy?p.spread_price/2+p.slippage_price:-p.spread_price/2-p.slippage_price);
}
inline double close_price(double mid,Signal side,const SimulationPolicy& p){
  return mid+(side==Signal::Buy?-p.spread_price/2-p.slippage_price:p.spread_price/2+p.slippage_price);
}
}
