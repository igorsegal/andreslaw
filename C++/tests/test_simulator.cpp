#include "as/simulator/engine.hpp"
#include <cassert>
#include <cmath>
#include <iostream>
using namespace as;
int main(){
  const std::vector<Bar> b={{1,100,101,99,100},{2,100,103,97,101},{3,101,102,99,100}};
  {auto x=simulate(b,{{0,Signal::Buy,2,2,1}},{});assert(x.diagnostic.status==Status::Ok);assert(x.trades.size()==1);assert(x.trades[0].reason==ExitReason::Stop);assert(x.trades[0].pnl==-2);}
  {auto x=simulate(b,{{0,Signal::Sell,2,2,1}},{});assert(x.trades[0].reason==ExitReason::Stop);assert(x.trades[0].pnl==-2);}
  {SimulationPolicy p;p.spread_price=.2;p.slippage_price=.1;p.fee_per_trade=.3;auto x=simulate(b,{{0,Signal::Buy,2,2,1}},p);assert(std::abs(x.trades[0].pnl-(-2.7))<1e-9);}
  {auto x=simulate(b,{{0,Signal::Buy,2,2,1},{0,Signal::Buy,2,2,1}},{});assert(x.skipped==1);}
  {auto bad=b;bad[1].utc=1;auto x=simulate(bad,{},{});assert(x.diagnostic.status==Status::InvalidInput);}
  {auto x=simulate(b,{{0,Signal::Buy,0,2,1}},{});assert(x.diagnostic.status==Status::InvalidInput);}
  {auto x=simulate(b,{{0,Signal::Buy,20,20,1}},{});assert(x.trades[0].reason==ExitReason::EndOfData);}
  std::cout<<"SIMULATOR_CONTRACTS=PASS\n";
}
