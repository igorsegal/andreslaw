#pragma once
#include "as/trend/trend_state.hpp"
#include <array>
namespace as {
inline Direction nonadaptive(const std::array<TrendLevel,5>& levels,unsigned max_level){
 if(max_level<4||max_level>8)return Direction::None;
 Direction consensus=Direction::None;
 for(unsigned i=4;i<=max_level;i++){const auto& x=levels[i-4];
  if(!x.valid||x.dir==Direction::None)return Direction::None;
  if(consensus==Direction::None)consensus=x.dir;
  else if(consensus!=x.dir)return Direction::None;
 }return consensus;
}
}
