#pragma once
#include "as/core/types.hpp"
#include "as/data/bar_validate.hpp"
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
namespace as {
inline bool load_csv_fixture(const std::string& file,std::vector<Bar>& out){
 std::ifstream in(file); if(!in)return false; std::string line; out.clear();
 while(std::getline(in,line)) {if(line.empty()||line[0]=='#')continue;
  Bar b{}; char c=0; std::istringstream ss(line);
  if(!(ss>>b.utc>>c)||c!=',')return false;
  if(!(ss>>b.open>>c)||c!=',')return false;
  if(!(ss>>b.high>>c)||c!=',')return false;
  if(!(ss>>b.low>>c)||c!=',')return false;
  if(!(ss>>b.close)||!valid_bar(b))return false;
  if(!out.empty()&&b.utc<=out.back().utc)return false;
  out.push_back(b);
 }return !out.empty();
}
}
