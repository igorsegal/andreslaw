#pragma once
namespace as {
enum class AmbiguousExit { StopFirst }; // No optimistic path guesses
struct SimulationPolicy {
  AmbiguousExit ambiguous{AmbiguousExit::StopFirst};
  double spread_price{0.0}; // Full ask-bid spread in quote price units
  double slippage_price{0.0}; // Adverse per side, price units
  double fee_per_trade{0.0}; // Round-trip fee in quote-PnL units for one volume
};
}
