#pragma once
#include <string>
namespace as {
enum class Status { Ok, Rejected, NotImplemented, InvalidInput };
struct Diagnostic { Status status{Status::NotImplemented}; std::string reason; };
}
