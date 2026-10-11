#pragma once
#include "as/core/status.hpp"
namespace as {
inline Diagnostic validate_scale_map() {return {Status::NotImplemented,"MT4 AS level/timeframe mapping requires golden-vector parity"};}
}
