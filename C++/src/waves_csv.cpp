#include "as/data/xfbar_reader.hpp"
#include "as/waves/history.hpp"
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <string>
#include <vector>
#include <cmath>

int main(int argc,char** argv) {
  if (argc!=4) {
    std::cerr << "Usage: as_waves_csv <absolute-XFBAR-bin> <symbol> <output.csv>\n";
    return 2;
  }
  try {
    const std::filesystem::path source(argv[1]), target(argv[3]);
    const std::string symbol(argv[2]);
    if (!source.is_absolute() || source.extension()!=".bin" || target.empty() ||
        std::filesystem::absolute(source).lexically_normal() == std::filesystem::absolute(target).lexically_normal()) {
      std::cerr << "INPUT=FAIL invalid source or destination\n";return 2;
    }
    const auto data=as::read_xfbar_records(source,symbol);
    if(data.diagnostic.status!=as::Status::Ok || data.records.empty()) {
      std::cerr << "READER=FAIL " << data.diagnostic.reason << "\n";return 1;
    }
    std::vector<as::Bar> bars;
    bars.reserve(data.records.size());
    for(const auto& rec:data.records) bars.push_back(rec.bar);
    as::waves::Engine engine;
    const auto waves=as::waves::calculate_closed_history(bars,engine);
    if (waves.size()!=bars.size()) {std::cerr<<"ROWS=FAIL\n";return 1;}
    for (const auto& row:waves) {
      for(double v:row.waves.raw) if(!std::isfinite(v)) {std::cerr<<"RAW=FAIL\n";return 1;}
      for(double v:row.waves.normalized) if(!std::isfinite(v)) {std::cerr<<"NORMALIZED=FAIL\n";return 1;}
    }
    // Never silently overwrite an existing report. The canonical BIN is read-only.
    if(std::filesystem::exists(target)){std::cerr<<"OUTPUT_EXISTS=FAIL\n";return 2;}
    std::ofstream out(target,std::ios::out|std::ios::trunc);
    if(!out) {std::cerr<<"OUTPUT_OPEN=FAIL\n";return 1;}
    out<<"utc,AS0,AS1,AS2,AS3,AS4,AS2_norm,AS3_norm,AS4_norm\n";
    out<<std::setprecision(17);
    for(const auto& row:waves){
      out<<row.utc;
      for(double v:row.waves.raw)out<<','<<v;
      for(double v:row.waves.normalized)out<<','<<v;
      out<<'\n';
    }
    out.close();
    if(!out) {std::cerr<<"OUTPUT_WRITE=FAIL\n";return 1;}
    std::cout<<"XFBAR_PAYLOAD=PASS\nBARS="<<bars.size()
             <<"\nWAVES_ROWS="<<waves.size()<<"\nCSV="<<target.string()
             <<"\nCSV_EXPORT=PASS\nMT4_PARITY=UNVERIFIED\n";
    return 0;
  } catch(const std::exception& e) {
    std::cerr<<"WAVES_CSV=FAIL reason="<<e.what()<<'\n';return 1;
  }
}
