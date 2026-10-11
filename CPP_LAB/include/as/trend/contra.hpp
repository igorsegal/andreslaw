#pragma once
#include "as/core/types.hpp"
namespace as {
inline Direction contra(Direction d,bool enabled){return !enabled?d:(d==Direction::Up?Direction::Down:d==Direction::Down?Direction::Up:Direction::None);}
}
