#pragma once
#include "as/core/types.hpp"
namespace as {
inline Signal w2_turn(double older,double previous,double current){
 if(older>previous&&previous>0&&current>previous)return Signal::Buy;
 if(older<previous&&previous<0&&current<previous)return Signal::Sell;
 return Signal::None;
}
}
