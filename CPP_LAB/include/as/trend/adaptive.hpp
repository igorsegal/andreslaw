#pragma once
#include "as/trend/trend_state.hpp"
#include <array>
namespace as {
inline Direction adaptive(const std::array<TrendLevel,5>& levels,unsigned max_level){
 if(max_level<4||max_level>8)return Direction::None;
 for(unsigned i=4;i<=max_level;i++)if(!levels[i-4].valid)return Direction::None;
 for(int i=static_cast<int>(max_level);i>=4;--i){const auto& x=levels[i-4];
  if(!x.correction && x.dir!=Direction::None)return x.dir;
 }
 return levels[0].dir; // Weekly fallback only after mandatory sources validated
}
}
