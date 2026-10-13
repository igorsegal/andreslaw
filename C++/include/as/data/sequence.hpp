#pragma once
#include "as/core/types.hpp"
#include "as/data/bar_validate.hpp"
#include <vector>
#include <string>
namespace as {
inline bool validate_sequence(const std::vector<Bar>& bars, std::string& why) {
  if(bars.empty()) {why="empty history";return false;}
  for(std::size_t i=0;i<bars.size();++i){
    if(!valid_bar(bars[i])) {why="invalid OHLC at index "+std::to_string(i);return false;}
    if(i && bars[i].utc<=bars[i-1].utc){why="non-monotonic timestamps";return false;}
  }
  why.clear(); return true;
}
}
