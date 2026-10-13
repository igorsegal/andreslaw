#pragma once
#include "as/core/status.hpp"
namespace as {
struct WaveSnapshot { double older{0}, previous{0}, current{0}; bool valid{false}; };
struct WaveProvider { virtual ~WaveProvider()=default; virtual Diagnostic fetch(unsigned level,WaveSnapshot&)=0; };
// AS_Waves/Butterworth equivalence is not established in C++: no invented formulas.
}
