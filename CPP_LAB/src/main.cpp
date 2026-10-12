#include "as/data/xfbar_reader.hpp"
#include <filesystem>
#include <iostream>
#include <string>

int main(int argc, char** argv) {
  if (argc != 4 || std::string(argv[1]) != "inspect-xfbar") {
    std::cerr << "Usage: as_lab inspect-xfbar <absolute-bin-path> <symbol>\n";
    std::cerr << "DATA01_GATEWAY=FAIL reason=missing-command-or-arguments\n";
    return 2;
  }
  const std::filesystem::path file(argv[2]);
  const std::string symbol(argv[3]);
  if (!file.is_absolute() || file.extension() != ".bin") {
    std::cerr << "DATA01_GATEWAY=FAIL reason=absolute-bin-file-required\n";
    return 2;
  }
  const auto r = as::read_xfbar_records(file, symbol);
  if (r.diagnostic.status != as::Status::Ok || r.records.empty()) {
    std::cerr << "XFBAR_PAYLOAD=FAIL reason=" << r.diagnostic.reason << "\n";
    std::cerr << "DATA01_GATEWAY=FAIL\n";
    return 1;
  }
  std::cout << "XFBAR_PAYLOAD=PASS\n"
            << "SYMBOL=" << symbol << "\n"
            << "BARS=" << r.records.size() << "\n"
            << "FIRST_TIME=" << r.records.front().bar.utc << "\n"
            << "LAST_TIME=" << r.records.back().bar.utc << "\n"
            << "HEADER_METADATA=UNVERIFIED\n"
            << "MT4_PARITY=UNVERIFIED\n"
            << "DATA01_GATEWAY=PARTIAL\n";
  // Successful payload decoding is not the same as full gateway acceptance.
  // Exit 0 communicates only command success; DATA01_GATEWAY remains PARTIAL.
  return 0;
}
