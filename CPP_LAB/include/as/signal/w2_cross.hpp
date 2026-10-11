#pragma once
#include "as/core/types.hpp"
namespace as {
inline Signal w2_cross(double previous,double current){return previous<=0&&current>0?Signal::Buy:previous>=0&&current<0?Signal::Sell:Signal::None;}
}
