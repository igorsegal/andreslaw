#pragma once
#include "as/core/types.hpp"
namespace as {
struct Gates {bool permit_buy{false},permit_sell{false},risk_ok{false},margin_ok{false},spread_ok{false},trading_enabled{false};};
inline Signal decide(Direction trend,Direction pattern,Signal w2,const Gates& g){
 if(!g.risk_ok||!g.margin_ok||!g.spread_ok||!g.trading_enabled)return Signal::None;
 if(w2==Signal::Buy&&trend==Direction::Up&&pattern==Direction::Up&&g.permit_buy)return Signal::Buy;
 if(w2==Signal::Sell&&trend==Direction::Down&&pattern==Direction::Down&&g.permit_sell)return Signal::Sell;
 return Signal::None;
}
}
