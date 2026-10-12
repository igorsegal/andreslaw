#pragma once
#include "as/core/types.hpp"
#include <cstdint>
#include <cstring>
namespace as {
struct XfbarRecord { Bar bar; std::int64_t tick_volume{}; std::int32_t spread{}; std::int64_t real_volume{}; };
inline std::uint32_t xf_u32(const unsigned char* p){return std::uint32_t(p[0])|(std::uint32_t(p[1])<<8)|(std::uint32_t(p[2])<<16)|(std::uint32_t(p[3])<<24);}
inline std::uint64_t xf_u64(const unsigned char* p){return std::uint64_t(xf_u32(p))|(std::uint64_t(xf_u32(p+4))<<32);}
inline std::int64_t xf_i64(const unsigned char* p){ std::uint64_t u=xf_u64(p); std::int64_t x;std::memcpy(&x,&u,8);return x; }
inline std::int32_t xf_i32(const unsigned char* p){std::uint32_t u=xf_u32(p);std::int32_t x;std::memcpy(&x,&u,4);return x;}
inline double xf_f64(const unsigned char* p){std::uint64_t u=xf_u64(p);double x;std::memcpy(&x,&u,8);return x;}
inline XfbarRecord decode_xfbar_record(const unsigned char* p) {
  XfbarRecord r;
  r.bar.utc=xf_i64(p);r.bar.open=xf_f64(p+8);r.bar.high=xf_f64(p+16);
  r.bar.low=xf_f64(p+24);r.bar.close=xf_f64(p+32);
  r.tick_volume=xf_i64(p+40);r.spread=xf_i32(p+48);r.real_volume=xf_i64(p+52);
  return r;
}
}
