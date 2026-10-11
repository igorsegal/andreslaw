#pragma once
#include "as/core/status.hpp"
#include "as/core/types.hpp"
#include <vector>
#include <filesystem>
namespace as {
struct XfbarSchema { unsigned record_bytes{0}; bool little_endian{true}; bool epoch_seconds{true}; };
inline Diagnostic load_xfbar(const std::filesystem::path&, const XfbarSchema&, std::vector<Bar>& out) {
  out.clear(); return {Status::NotImplemented,"XFBAR binary layout not verified: header, field offsets, types, endian and timestamps required"};
}
}
