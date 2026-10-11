#pragma once
#include "as/signal/w2_cross.hpp"
#include "as/signal/w2_turn.hpp"
namespace as {
inline Signal w2_signal(double older,double previous,double current){Signal s=w2_cross(previous,current);return s!=Signal::None?s:w2_turn(older,previous,current);}
}
