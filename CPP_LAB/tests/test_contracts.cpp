#include "as/trend/nonadaptive.hpp"
#include "as/trend/adaptive.hpp"
#include "as/trend/contra.hpp"
#include "as/pattern/base.hpp"
#include "as/signal/w2.hpp"
#include "as/decision/conjunction.hpp"
#include "as/data/xfbar_format.hpp"
#include "as/execution/fills.hpp"
#include <array>
#include <cassert>
#include <iostream>
int main(){using namespace as;
 std::array<TrendLevel,5> x{};for(auto& t:x)t={Direction::Up,true,false};
 assert(nonadaptive(x,8)==Direction::Up);
 x[3].valid=false;assert(nonadaptive(x,8)==Direction::None); assert(adaptive(x,8)==Direction::None);
 x[3].valid=true;assert(adaptive(x,8)==Direction::Up);
 assert(contra(Direction::Up,true)==Direction::Down);
 assert(base_pattern(Direction::Up,Direction::Up,Direction::Up)==Direction::Up);
 assert(base_pattern(Direction::Up,Direction::Down,Direction::Up)==Direction::None);
 assert(w2_signal(-1.,-0.1,0.2)==Signal::Buy);
 assert(w2_signal(1.,0.2,-0.2)==Signal::Sell);
 assert(w2_signal(3.,2.,2.5)==Signal::Buy);
 assert(w2_signal(-3.,-2.,-2.5)==Signal::Sell);
 Gates g{true,true,true,true,true,true};assert(decide(Direction::Up,Direction::Up,Signal::Buy,g)==Signal::Buy);
 g.trading_enabled=false;assert(decide(Direction::Up,Direction::Up,Signal::Buy,g)==Signal::None);
 std::vector<Bar> bars;assert(load_xfbar("nonexistent",{},bars).status==Status::NotImplemented);
 assert(fill_order().status==Status::NotImplemented);
 std::cout<<"AS_CONTRACTS=PASS\n";
}
