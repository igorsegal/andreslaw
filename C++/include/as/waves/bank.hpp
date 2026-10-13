#pragma once
#include "as/waves/filter.hpp"
#include <array>
namespace as::waves {
struct Config {
  std::array<int,5> periods{{12,60,288,1440,7200}};
  double quality{0.7};
};
struct Bank {
  std::array<Filter,5> filters{};
  explicit Bank(Config cfg={}) {for(size_t i=0;i<5;++i) filters[i].init(cfg.periods[i],cfg.quality);}
  void reset(){for(auto &f:filters) f.reset();}
  std::array<double,5> step(double close){
    std::array<double,5> out{};
    for(size_t i=0;i<5;++i)out[i]=filters[i].step(close);
    return out;
  }
};
}
