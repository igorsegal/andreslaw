#pragma once
#include "as/core/status.hpp"
namespace as {inline Diagnostic margin_check(){return {Status::NotImplemented,"MT4 AccountFreeMarginCheck and live broker margin model cannot be emulated yet"};}}
