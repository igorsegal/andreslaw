#pragma once
#include <cmath>
#include <deque>
#include <stdexcept>
#include <cstddef>
namespace as::waves {
inline double std_from_sums(double sum,double sum2,size_t n){
  if(n<10) return 1.0;
  const double mean=sum/static_cast<double>(n);
  double var=sum2/static_cast<double>(n)-mean*mean;
  if(var<0.0) var=0.0;
  const double s=std::sqrt(var);
  return s<1e-12?1.0:s;
}
// Reproduces Waves.mq4 process_bar(): after adding sample n, remove
// sample n-(StdWindow+1) once n >= StdWindow+2, but divide by
// min(n,StdWindow). Consequently the running sums retain W+1 samples
// for n >= W+1. This is the ORIGINAL behavior, not a conventional SD.
class RollingStd {
  size_t window_;
  std::deque<double> values_{};
  double sum_{},sum2_{};
  size_t seen_{};
public:
  explicit RollingStd(size_t window=2000):window_(window){
    if(!window)throw std::invalid_argument("zero window");
  }
  void reset(){values_.clear();sum_=sum2_=0;seen_=0;}
  double step(double v){
    if(!std::isfinite(v))throw std::invalid_argument("nonfinite wave");
    ++seen_;
    values_.push_back(v);sum_+=v;sum2_+=v*v;
    if(values_.size()>window_+1){
      const double old=values_.front();values_.pop_front();
      sum_-=old;sum2_-=old*old;
    }
    const size_t divisor=seen_<window_?seen_:window_;
    return std_from_sums(sum_,sum2_,divisor);
  }
};
}
