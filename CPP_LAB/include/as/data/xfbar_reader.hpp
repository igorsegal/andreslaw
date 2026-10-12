#pragma once
#include "as/data/xfbar_record.hpp"
#include "as/data/bar_validate.hpp"
#include "as/core/status.hpp"
#include <filesystem>
#include <fstream>
#include <vector>
#include <array>
#include <limits>
#include <string>
namespace as {
struct XfbarReadResult { Diagnostic diagnostic; std::vector<XfbarRecord> records; std::size_t header_bytes{}; };
// Known contract: 60-byte fixed header, then ASCII symbol, then 60-byte records.
// Until the original header struct is imported, require caller-supplied symbol and
// do not claim to verify period, digits, point, count or first/last timestamps.
inline XfbarReadResult read_xfbar_records(const std::filesystem::path& filename, const std::string& symbol, std::size_t max_records=10000000) {
  XfbarReadResult out; auto fail=[&](std::string reason){out.records.clear();out.diagnostic={Status::InvalidInput,std::move(reason)};return out;};
  if(symbol.empty()||symbol.size()>64) return fail("symbol length invalid");
  std::ifstream f(filename,std::ios::binary|std::ios::ate);
  if(!f) return fail("cannot open file");
  auto end=f.tellg(); if(end<std::streamoff(60+symbol.size())) return fail("truncated header");
  auto total=static_cast<std::uint64_t>(end);
  const std::size_t offset=60+symbol.size();
  if((total-offset)%60!=0) return fail("record alignment mismatch");
  auto n=(total-offset)/60;
  if(n>max_records) return fail("record limit exceeded");
  f.seekg(0);std::array<unsigned char,60> hdr{};
  if(!f.read(reinterpret_cast<char*>(hdr.data()),hdr.size())) return fail("header read failed");
  if(std::memcmp(hdr.data(),"XFBAR001",8)!=0) return fail("invalid XFBAR001 signature");
  // Header offset 8 version is known, but the remainder of header is not asserted.
  if(xf_u32(hdr.data()+8)!=1) return fail("unsupported XFBAR version");
  std::string on_disk(symbol.size(),'\0');
  if(!f.read(on_disk.data(),static_cast<std::streamsize>(symbol.size())) || on_disk!=symbol) return fail("symbol mismatch");
  out.header_bytes=offset;out.records.reserve(static_cast<std::size_t>(n));
  std::array<unsigned char,60> buf{};
  std::int64_t previous=std::numeric_limits<std::int64_t>::min();
  for(std::uint64_t i=0;i<n;++i){
    if(!f.read(reinterpret_cast<char*>(buf.data()),buf.size()))return fail("truncated candle");
    auto r=decode_xfbar_record(buf.data());
    if(!valid_bar(r.bar)||r.bar.utc<=previous||r.tick_volume<0||r.spread<0||r.real_volume<0)
      return fail("invalid OHLC, volume, spread or non-increasing time at record "+std::to_string(i));
    previous=r.bar.utc;out.records.push_back(r);
  }
  out.diagnostic={Status::Ok,"payload decoded; extended header semantics NOT VERIFIED"};
  return out;
}
}
