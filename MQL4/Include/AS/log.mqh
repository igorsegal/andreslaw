#ifndef AS_LOG_MQH
#define AS_LOG_MQH
void AS_LogInfo(string s)  { Print("[AS][INFO] ",s); }
void AS_LogWarn(string s)  { Print("[AS][WARN] ",s); }
void AS_LogError(string s) { Print("[AS][ERROR] ",s," err=",GetLastError()); }
#endif
