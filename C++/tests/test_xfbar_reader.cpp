#include "as/data/xfbar_reader.hpp"
#include <cstring>
#include <iostream>
#include <fstream>
#include <filesystem>
#include <array>
#include <cmath>
#include <stdexcept>
#include <string>
namespace {
void check(bool condition, const char* message) { if (!condition) throw std::runtime_error(message); }
void put32(unsigned char* p,std::uint32_t u){for(int i=0;i<4;++i)p[i]=static_cast<unsigned char>(u>>(8*i));}
void put64(unsigned char* p,std::uint64_t u){for(int i=0;i<8;++i)p[i]=static_cast<unsigned char>(u>>(8*i));}
void putd(unsigned char* p,double v){std::uint64_t x;std::memcpy(&x,&v,8);put64(p,x);}
void write(const std::filesystem::path& file, bool bad_time=false, bool bad_magic=false){
 std::ofstream f(file,std::ios::binary|std::ios::trunc);check(bool(f),"fixture open failed"); std::array<unsigned char,60> h{};
 std::memcpy(h.data(),bad_magic?"BADBAR00":"XFBAR001",8);put32(h.data()+8,1);
 f.write(reinterpret_cast<const char*>(h.data()),60);f.write("EURUSD",6);
 for(int j=0;j<2;++j){std::array<unsigned char,60> b{};put64(b.data(),bad_time?100:100+j*3600);putd(b.data()+8,1.1);putd(b.data()+16,1.2);putd(b.data()+24,1.0);putd(b.data()+32,1.15);put64(b.data()+40,100);put32(b.data()+48,2);put64(b.data()+52,0);f.write(reinterpret_cast<const char*>(b.data()),60);}
 check(bool(f),"fixture write failed");
}
}
int main(){
 try {
  using namespace as;
  const auto p=std::filesystem::temp_directory_path()/"as_xfbar_reader_test.bin";
  write(p);const auto a=read_xfbar_records(p,"EURUSD");
  check(a.diagnostic.status==Status::Ok,"valid payload rejected");
  check(a.records.size()==2,"bad bar count");
  check(a.header_bytes==66,"bad payload offset");
  check(std::abs(a.records[0].bar.close-1.15)<1e-12,"bad decoded close");
  check(a.records[0].spread==2,"bad spread");
  check(read_xfbar_records(p,"GBPUSD").diagnostic.status==Status::InvalidInput,"symbol mismatch accepted");
  check(read_xfbar_records(p,"EURUSD",1).diagnostic.status==Status::InvalidInput,"limit ignored");
  write(p,true);check(read_xfbar_records(p,"EURUSD").diagnostic.status==Status::InvalidInput,"bad time accepted");
  write(p,false,true);check(read_xfbar_records(p,"EURUSD").diagnostic.status==Status::InvalidInput,"bad magic accepted");
  std::filesystem::remove(p);
  std::cout<<"XFBAR_READER_TESTS=PASS\n";
  return 0;
 } catch(const std::exception& e) { std::cerr<<"XFBAR_READER_TESTS=FAIL "<<e.what()<<"\n"; return 1; }
}
