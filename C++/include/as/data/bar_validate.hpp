#pragma once
#include "as/core/types.hpp"
#include <cmath>
namespace as {
inline bool valid_bar(const Bar& b) {return std::isfinite(b.open)&&std::isfinite(b.high)&&std::isfinite(b.low)&&std::isfinite(b.close)&&b.high>=b.low&&b.high>=b.open&&b.high>=b.close&&b.low<=b.open&&b.low<=b.close;}
}
