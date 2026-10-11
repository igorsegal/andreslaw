#pragma once
#include "as/core/status.hpp"
#include "as/core/types.hpp"
#include "as/data/sequence.hpp"
#include "as/simulator/orders.hpp"
#include "as/simulator/policy.hpp"
#include "as/simulator/price.hpp"
#include "as/simulator/exit.hpp"
#include <vector>
#include <string>
#include <cmath>
namespace as {
struct RunResult {Diagnostic diagnostic;std::vector<Trade> trades;unsigned skipped{0};};
inline RunResult simulate(const std::vector<Bar>& bars,const std::vector<EntryOrder>& orders,const SimulationPolicy& p){
  RunResult r{{Status::Ok,""},{},0};std::string why;
  if(!validate_sequence(bars,why))return {{Status::InvalidInput,why},{},0};
  if(!(std::isfinite(p.spread_price)&&p.spread_price>=0&&std::isfinite(p.slippage_price)&&p.slippage_price>=0&&std::isfinite(p.fee_per_trade)&&p.fee_per_trade>=0))
    return {{Status::InvalidInput,"invalid cost policy"},{},0};
  std::size_t last_signal=0;bool first=true; std::size_t free_after=0;
  for(const auto& o:orders){
    if(o.side==Signal::None||o.signal_bar>=bars.size()||o.signal_bar+1>=bars.size()||
       !std::isfinite(o.stop_distance)||o.stop_distance<=0||!std::isfinite(o.target_distance)||o.target_distance<=0||
       !std::isfinite(o.volume)||o.volume<=0||( !first && o.signal_bar<last_signal))
      return {{Status::InvalidInput,"invalid/unsorted order"},{},0};
    first=false;last_signal=o.signal_bar;
    const auto at=o.signal_bar+1; // signal at closed bar, fill at NEXT bar open
    if(at<free_after){++r.skipped;continue;}
    const auto side=o.side;
    const double entry=entry_price(bars[at],side,p);
    const double mid_entry=bars[at].open;
    const double stop_mid=mid_entry+(side==Signal::Buy?-o.stop_distance:o.stop_distance);
    const double target_mid=mid_entry+(side==Signal::Buy?o.target_distance:-o.target_distance);
    bool exited=false;
    for(std::size_t i=at;i<bars.size();++i){
      const ExitHit hit=evaluate_exit(bars[i],side,stop_mid,target_mid);
      if(!hit.hit)continue;
      // If the next bar gaps through stop/target, use its OPEN, never a better stop fill.
      double mid=hit.mid;
      if(i>at){
        if(side==Signal::Buy && hit.reason==ExitReason::Stop && bars[i].open<stop_mid) mid=bars[i].open;
        if(side==Signal::Sell && hit.reason==ExitReason::Stop && bars[i].open>stop_mid) mid=bars[i].open;
      }
      double exit=close_price(mid,side,p);
      r.trades.push_back({at,i,side,entry,exit,o.volume,(exit-entry)*(side==Signal::Buy?1:-1)*o.volume-p.fee_per_trade*o.volume,hit.reason});
      free_after=i+1;exited=true;break;
    }
    if(!exited){
      std::size_t i=bars.size()-1;
      const double exit=close_price(bars[i].close,side,p);
      r.trades.push_back({at,i,side,entry,exit,o.volume,(exit-entry)*(side==Signal::Buy?1:-1)*o.volume-p.fee_per_trade*o.volume,ExitReason::EndOfData});
      free_after=bars.size();
    }
  }
  return r;
}
}
