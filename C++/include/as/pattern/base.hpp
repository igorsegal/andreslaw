#pragma once
#include "as/core/types.hpp"
namespace as {
inline Direction base_pattern(Direction hourly,Direction iday,Direction daily){
 return hourly!=Direction::None&&hourly==iday&&iday==daily?hourly:Direction::None;
}
}
