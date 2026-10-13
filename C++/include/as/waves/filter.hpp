#pragma once
#include <cmath>
#include <stdexcept>
namespace as::waves {
struct Filter {
  double b0{}, b1{}, b2{}, a1{}, a2{};
  double x1{}, x2{}, y1{}, y2{};
  void init(int period,double q) {
    if(period<3) period=3;
    if(q<=0) q=1;
    constexpr double pi=3.141592653589793238462643383279502884;
    const double k=std::tan(pi/static_cast<double>(period));
    const double k2=k*k;
    const double n=1/(1+k/q+k2);
    b0=(k/q)*n; b1=0; b2=-(k/q)*n;
    a1=2*(k2-1)*n; a2=(1-k/q+k2)*n;
    reset();
  }
  void reset(){x1=x2=y1=y2=0;}
  double step(double x){
    if(!std::isfinite(x)) throw std::invalid_argument("nonfinite close");
    const double y=b0*x+b1*x1+b2*x2-a1*y1-a2*y2;
    x2=x1; x1=x; y2=y1; y1=y;
    if(!std::isfinite(y)) throw std::overflow_error("nonfinite wave");
    return y;
  }
};
}
