// =============================================================================
// AS :: PATTERN CONTEXT SELF-TEST
// Synthetic verification only.
// NO TRADING. NO PRODUCTION PATTERN LOGIC.
// =============================================================================
#property strict
#include <AS/contracts.mqh>
struct PC_WaveFeatures
{
   bool valid;
   int sign_current;
   int sign_previous;
   int slope_current;
   int slope_previous;
   bool cross_up;
   bool cross_down;
   bool turn_up;
   bool turn_down;
};
int g_pass = 0;
int g_fail = 0;
int PC_Sign(double v)
{
   if(v > 0.0) return AS_DIR_UP;
   if(v < 0.0) return AS_DIR_DN;
   return AS_DIR_NO;
}
void PC_Clear(PC_WaveFeatures &f)
{
   f.valid=false;
   f.sign_current=0;
   f.sign_previous=0;
   f.slope_current=0;
   f.slope_previous=0;
   f.cross_up=false;
   f.cross_down=false;
   f.turn_up=false;
   f.turn_down=false;
}
bool PC_Build(double older,
              double previous,
              double current,
              bool history_valid,
              PC_WaveFeatures &f)
{
   PC_Clear(f);
   if(!history_valid)
      return false;
   if(!MathIsValidNumber(older) ||
      !MathIsValidNumber(previous) ||
      !MathIsValidNumber(current))
      return false;
   f.valid=true;
   f.sign_current  = PC_Sign(current);
   f.sign_previous = PC_Sign(previous);
   f.slope_current  = PC_Sign(current-previous);
   f.slope_previous = PC_Sign(previous-older);
   f.cross_up   = (previous <= 0.0 && current > 0.0);
   f.cross_down = (previous >= 0.0 && current < 0.0);
   // Direction change includes FLAT -> direction.
   f.turn_up   = (f.slope_previous <= 0 && f.slope_current > 0);
   f.turn_down = (f.slope_previous >= 0 && f.slope_current < 0);
   return true;
}
void PC_CheckWave(string id,
                  double older,
                  double previous,
                  double current,
                  bool history_valid,
                  int sign_current,
                  int sign_previous,
                  int slope_current,
                  int slope_previous,
                  bool cross_up,
                  bool cross_down,
                  bool turn_up,
                  bool turn_down)
{
   PC_WaveFeatures f;
   bool got_valid=PC_Build(older,previous,current,history_valid,f);
   bool ok =
      (got_valid == history_valid) &&
      (f.sign_current == sign_current) &&
      (f.sign_previous == sign_previous) &&
      (f.slope_current == slope_current) &&
      (f.slope_previous == slope_previous) &&
      (f.cross_up == cross_up) &&
      (f.cross_down == cross_down) &&
      (f.turn_up == turn_up) &&
      (f.turn_down == turn_down);
   if(ok)
   {
      g_pass++;
      Print("[AS][PATTERN_CONTEXT][PASS] ",id);
   }
   else
   {
      g_fail++;
      Print("[AS][PATTERN_CONTEXT][FAIL] ",id,
            " valid=",got_valid,
            " sign=",f.sign_current,"/",f.sign_previous,
            " slope=",f.slope_current,"/",f.slope_previous,
            " cross=",f.cross_up,"/",f.cross_down,
            " turn=",f.turn_up,"/",f.turn_down);
   }
}
void PC_CheckContext(string id,
                     bool hourly_valid,
                     bool iday_valid,
                     bool daily_valid,
                     bool expected_valid)
{
   bool got = hourly_valid && iday_valid && daily_valid;
   if(got == expected_valid)
   {
      g_pass++;
      Print("[AS][PATTERN_CONTEXT][PASS] ",id,
            " context_valid=",got);
   }
   else
   {
      g_fail++;
      Print("[AS][PATTERN_CONTEXT][FAIL] ",id,
            " context_valid=",got,
            " expected=",expected_valid);
   }
}
int OnInit()
{
   Print("[AS][PATTERN_CONTEXT] SELF-TEST START");
   PC_CheckWave("AS-PC-001", 1, 2, 3,true, 1, 1, 1, 1,false,false,false,false);
   PC_CheckWave("AS-PC-002", 3, 2, 1,true, 1, 1,-1,-1,false,false,false,false);
   PC_CheckWave("AS-PC-003",-3,-2,-1,true,-1,-1, 1, 1,false,false,false,false);
   PC_CheckWave("AS-PC-004",-1,-2,-3,true,-1,-1,-1,-1,false,false,false,false);
   PC_CheckWave("AS-PC-005",-1,-0.5, 0.5,true, 1,-1, 1, 1,true ,false,false,false);
   PC_CheckWave("AS-PC-006", 1, 0.5,-0.5,true,-1, 1,-1,-1,false,true ,false,false);
   PC_CheckWave("AS-PC-007",-1,-0.5,0,true, 0,-1, 1, 1,false,false,false,false);
   PC_CheckWave("AS-PC-008",-0.5,0,0.5,true,1,0,1,1,true,false,false,false);
   PC_CheckWave("AS-PC-009",0.5,0,-0.5,true,-1,0,-1,-1,false,true,false,false);
   PC_CheckWave("AS-PC-010", 3, 2, 2.5,true, 1, 1, 1,-1,false,false,true ,false);
   PC_CheckWave("AS-PC-011", 1, 2, 1.5,true, 1, 1,-1, 1,false,false,false,true);
   PC_CheckWave("AS-PC-012",-1,-2,-1.5,true,-1,-1, 1,-1,false,false,true ,false);
   PC_CheckWave("AS-PC-013",-3,-2,-2.5,true,-1,-1,-1, 1,false,false,false,true);
   PC_CheckWave("AS-PC-014",1,1,2,true,1,1,1,0,false,false,true,false);
   PC_CheckWave("AS-PC-015",1,2,2,true,1,1,0,1,false,false,false,false);
   PC_CheckWave("AS-PC-016",0,0,0,false,0,0,0,0,false,false,false,false);
   PC_CheckContext("AS-PC-017",true ,true ,true ,true);
   PC_CheckContext("AS-PC-018",false,true ,true ,false);
   PC_CheckContext("AS-PC-019",true ,false,true ,false);
   PC_CheckContext("AS-PC-020",true ,true ,false,false);
   Print("[AS][PATTERN_CONTEXT][SUMMARY] PASS=",g_pass,
         " FAIL=",g_fail,
         " TOTAL=",g_pass+g_fail);
   if(g_fail > 0)
      return(INIT_FAILED);
   return(INIT_SUCCEEDED);
}
void OnTick()
{
}
