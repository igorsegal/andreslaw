#ifndef __AS_SR_STATE_MQH__
#define __AS_SR_STATE_MQH__
#include <AS\AS_sr_geometry.mqh>
enum AS_sr_Phase
{
   AS_SR_ACTIVE    = 0,
   AS_SR_SEEK_HIGH = 1,
   AS_SR_SEEK_LOW  = 2
};
struct AS_sr_State
{
   int    phase;
   double support;
   double resistance;
   double candidate;
   double peakRange;
};
void AS_sr_StateInit(
   AS_sr_State &st,
   double support,
   double resistance)
{
   st.phase      = AS_SR_ACTIVE;
   st.support    = support;
   st.resistance = resistance;
   st.candidate  = 0.0;
   st.peakRange  = 0.0;
}
void AS_sr_UpdatePeak(
   AS_sr_State &st,
   double high,
   double low)
{
   if(!MathIsValidNumber(high) ||
      !MathIsValidNumber(low) ||
      high < low)
      return;
   double range=high-low;
   if(range>st.peakRange)
      st.peakRange=range;
}
void AS_sr_StateStep(
   AS_sr_State &st,
   double open,
   double high,
   double low,
   double close)
{
   if(st.phase==AS_SR_ACTIVE)
   {
      int br=AS_sr_DetectBreak(
         open,high,low,close,
         st.support,st.resistance
      );
      if(br==1)
      {
         st.phase     =AS_SR_SEEK_HIGH;
         st.candidate =AS_sr_BodyHigh(open,close);
         st.peakRange =0.0;
         AS_sr_UpdatePeak(st,high,low);
         return;
      }
      if(br==-1)
      {
         st.phase     =AS_SR_SEEK_LOW;
         st.candidate =AS_sr_BodyLow(open,close);
         st.peakRange =0.0;
         AS_sr_UpdatePeak(st,high,low);
         return;
      }
      return;
   }
   AS_sr_UpdatePeak(st,high,low);
   if(st.phase==AS_SR_SEEK_HIGH)
   {
      double bodyHigh=AS_sr_BodyHigh(open,close);
      if(bodyHigh>st.candidate)
      {
         st.candidate=bodyHigh;
         return;
      }
      double newS=0.0;
      double newR=0.0;
      if(AS_sr_BuildPair(
            1,
            st.candidate,
            st.peakRange,
            newS,
            newR))
      {
         st.support=newS;
         st.resistance=newR;
         st.phase=AS_SR_ACTIVE;
      }
      return;
   }
   if(st.phase==AS_SR_SEEK_LOW)
   {
      double bodyLow=AS_sr_BodyLow(open,close);
      if(bodyLow<st.candidate)
      {
         st.candidate=bodyLow;
         return;
      }
      double newS=0.0;
      double newR=0.0;
      if(AS_sr_BuildPair(
            -1,
            st.candidate,
            st.peakRange,
            newS,
            newR))
      {
         st.support=newS;
         st.resistance=newR;
         st.phase=AS_SR_ACTIVE;
      }
      return;
   }
}
#endif
