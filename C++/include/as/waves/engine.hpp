#pragma once
#include "as/waves/bank.hpp"
#include "as/waves/normalize.hpp"
#include <array>
namespace as::waves {
struct Output {
  std::array<double,5> raw{};
  std::array<double,3> normalized{}; // AS2, AS3, AS4
};
struct Engine {
  Bank bank;
  std::array<RollingStd,3> sd;
  std::array<double,3> scale;
  explicit Engine(Config c={},size_t std_window=2000,
                  std::array<double,3> scales={{1.0,1.0,0.25}})
      :bank(c),sd{RollingStd(std_window),RollingStd(std_window),RollingStd(std_window)},scale(scales){}
  void reset(){bank.reset();for(auto &x:sd)x.reset();}
  Output step_closed(double close){
    Output out;out.raw=bank.step(close);
    for(size_t i=0;i<3;++i){double s=sd[i].step(out.raw[i+2]);out.normalized[i]=out.raw[i+2]/s*scale[i];}
    return out;
  }
};
}
