#include "as/waves/engine.hpp"
#include <cmath>
#include <cstdio>
#include <vector>
#include <cstdlib>
static void require(bool v,const char* message){if(!v){std::fprintf(stderr,"FAIL: %s\n",message);std::exit(1);}}
static bool near(double a,double b,double rel=1e-12){return std::fabs(a-b)<=rel*(1+std::fabs(a)+std::fabs(b));}
// Independent index-based translation of MQL4 process_bar() for chronological samples.
static double mql_sd_reference(const std::vector<double>& all,size_t W){
  double sum=0.0,sum2=0.0;
  for(size_t k=0;k<all.size();++k){
    const double v=all[k];sum+=v;sum2+=v*v;
    if(k>=W+1){const double old=all[k-W-1];sum-=old;sum2-=old*old;}
  }
  const size_t count=all.size()<W?all.size():W;
  return as::waves::std_from_sums(sum,sum2,count);
}
int main(){
  as::waves::Filter f;f.init(12,0.7);
  require(near(f.b1,0.0),"b1");require(near(f.b2,-f.b0),"b2");
  require(near(f.step(1.2345),f.b0*1.2345),"filter first sample");
  as::waves::Engine eng;
  as::waves::Bank independent_bank;
  const double scales[3]={1.0,1.0,0.25};
  std::vector<double> history[3];
  for(int i=0;i<4200;++i){
    const double c=1.1+std::sin(i*0.01)*0.03+std::cos(i*0.0007)*0.008;
    const auto got=eng.step_closed(c);
    const auto raw=independent_bank.step(c);
    for(int j=0;j<5;++j) require(near(got.raw[j],raw[j]),"raw bank recurrence");
    for(int j=0;j<3;++j){
      history[j].push_back(raw[j+2]);
      // Compare C++ normalization to independently indexed MQL recurrence,
      // including the first bar crossing the normalization window.
      if(i==0||i==8||i==9||i==1998||i==1999||i==2000||i==2001||i==2002||i==4199){
        const double sd=mql_sd_reference(history[j],2000);
        require(near(got.normalized[j],raw[j+2]/sd*scales[j],1e-10),"MQL normalization parity");
      }
    }
  }
  eng.reset();const auto first=eng.step_closed(1.2345);
  as::waves::Engine fresh;const auto same=fresh.step_closed(1.2345);
  for(int j=0;j<5;++j) require(near(first.raw[j],same.raw[j]),"raw reset");
  for(int j=0;j<3;++j) require(near(first.normalized[j],same.normalized[j]),"normalized reset");
  as::waves::RollingStd st(10);std::vector<double> small;
  for(int i=0;i<25;++i){
    small.push_back(static_cast<double>(i));
    const double got=st.step(static_cast<double>(i));
    require(near(got,mql_sd_reference(small,10)),"window boundary W+1 original MQL");
  }
  std::puts("AS_WAVES_01_TESTS=PASS");
}
