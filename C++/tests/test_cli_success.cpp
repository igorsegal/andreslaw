#include <array>
#include <cstdint>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <string>
#ifdef _WIN32
#include <process.h>
#else
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#endif

namespace {
void put32(unsigned char* p, std::uint32_t v) { for (int i=0;i<4;++i) p[i]=static_cast<unsigned char>(v>>(8*i)); }
void put64(unsigned char* p, std::uint64_t v) { for (int i=0;i<8;++i) p[i]=static_cast<unsigned char>(v>>(8*i)); }
void putd(unsigned char* p, double d) { std::uint64_t v; std::memcpy(&v,&d,8); put64(p,v); }
int run_cli(const char* exe, const std::string& input) {
  const char* args[] = {exe, "inspect-xfbar", input.c_str(), "EURUSD", nullptr};
#ifdef _WIN32
  return _spawnv(_P_WAIT, exe, args); // Direct argv; never call cmd.exe.
#else
  const pid_t pid=fork();
  if(pid<0) return -1;
  if(pid==0) { execv(exe,const_cast<char* const*>(args)); _exit(127); }
  int status=0;
  if(waitpid(pid,&status,0)<0 || !WIFEXITED(status)) return -1;
  return WEXITSTATUS(status);
#endif
}
}
int main(int argc, char** argv) {
 if(argc!=2) return 2;
 const auto file=std::filesystem::temp_directory_path()/"as_cli_success_fixture.bin";
 {
  std::ofstream out(file,std::ios::binary|std::ios::trunc);
  if(!out) return 3;
  std::array<unsigned char,60> hdr{};
  std::memcpy(hdr.data(),"XFBAR001",8);put32(hdr.data()+8,1);
  out.write(reinterpret_cast<const char*>(hdr.data()),60);
  out.write("EURUSD",6);
  std::array<unsigned char,60> bar{};
  put64(bar.data(),1700000000);putd(bar.data()+8,1.1);putd(bar.data()+16,1.2);
  putd(bar.data()+24,1.0);putd(bar.data()+32,1.15);
  put64(bar.data()+40,100);put32(bar.data()+48,2);put64(bar.data()+52,0);
  out.write(reinterpret_cast<const char*>(bar.data()),60);
  if(!out) return 4;
 }
 const int status=run_cli(argv[1],file.string());
 std::error_code ec;std::filesystem::remove(file,ec);
 if(status!=0) {std::cerr<<"CLI_VALID_XFBAR=FAIL exit="<<status<<"\n";return 1;}
 std::cout<<"CLI_VALID_XFBAR=PASS\n";
 return 0;
}
