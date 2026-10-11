#pragma once
#include "as/core/types.hpp"
#include "as/simulator/orders.hpp"
#include <algorithm>
namespace as {
struct ExitHit {bool hit{false}; double mid{0}; ExitReason reason{ExitReason::Stop};};
inline ExitHit evaluate_exit(const Bar& b, Signal side, double stop_mid, double target_mid){
  const bool stop=side==Signal::Buy?b.low<=stop_mid:b.high>=stop_mid;
  const bool target=side==Signal::Buy?b.high>=target_mid:b.low<=target_mid;
  if(stop) return {true,stop_mid,ExitReason::Stop}; // stop first, including both touched
  if(target) return {true,target_mid,ExitReason::Target};
  return {};
}
}
