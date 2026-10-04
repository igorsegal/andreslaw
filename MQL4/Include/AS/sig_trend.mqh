#ifndef AS_SIG_TREND_MQH
#define AS_SIG_TREND_MQH
#include <AS/contracts.mqh>
#include <AS/cfg_defaults.mqh>
#include <AS/wave_hierarchy.mqh>

int AS_TrendDirection(AS_TrendHierarchy &h,AS_Config &c,bool &dominant_correction_block)
{
   dominant_correction_block=false;
   int top=AS_ClampTrendVector(c.trend_vector);
   int dir=AS_DIR_NO;

   if(!c.adaptive_mode)
   {
      for(int level1=4; level1<=top; level1++)
      {
         AS_TrendState s;
         if(!AS_GetTrendByLevel(h,level1,s) || s.direction==AS_DIR_NO) return AS_DIR_NO;
         if(dir==AS_DIR_NO) dir=s.direction;
         else if(dir!=s.direction) return AS_DIR_NO;
      }
   }
   else
   {
      int dominant_level=0;
      for(int level2=top; level2>=4; level2--)
      {
         AS_TrendState s;
         if(!AS_GetTrendByLevel(h,level2,s)) continue;
         if(!s.correction && s.direction!=AS_DIR_NO)
         { dir=s.direction; dominant_level=level2; break; }
      }
      // SWT rule: if all senior trends are corrective, Weekly determines direction.
      if(dir==AS_DIR_NO)
      {
         AS_TrendState w;
         if(!AS_GetTrendByLevel(h,4,w)) return AS_DIR_NO;
         dir=w.direction; dominant_level=4;
      }

      if(c.dominant_correction && dominant_level>4 && dir!=AS_DIR_NO)
      {
         for(int level3=dominant_level-1; level3>=4; level3--)
         {
            AS_TrendState s;
            if(!AS_GetTrendByLevel(h,level3,s)) continue;
            if(!s.correction && s.direction!=AS_DIR_NO && s.direction!=dir)
            { dominant_correction_block=true; break; }
         }
      }
   }

   if(c.contra_trend) dir=-dir;
   return dir;
}
#endif
