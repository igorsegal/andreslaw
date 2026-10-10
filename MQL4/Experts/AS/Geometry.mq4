#property strict
#include <AS\AS_sr_geometry.mqh>
int g_checked=0;
int g_failed=0;
void Check(string name,int got,int expected)
{
   g_checked++;
   if(got==expected)
      Print("[PASS] ",name," got=",got);
   else
   {
      g_failed++;
      Print("[FAIL] ",name,
            " expected=",expected,
            " got=",got);
   }
}
int OnInit()
{
   Print("[AS][SR_GEOMETRY_TEST] START");
   double S=1.10000;
   double R=1.11000;
   // 1. Upper wick crosses resistance,
   //    but candle closes back inside.
   Check(
      "UPPER_WICK_ONLY_NO_BREAK",
      AS_sr_DetectBreak(
         1.10800,   // Open
         1.11200,   // High
         1.10600,   // Low
         1.10900,   // Close
         S,R),
      0
   );
   // 2. Closed body finishes above resistance.
   Check(
      "CLOSE_ABOVE_R_BREAK_UP",
      AS_sr_DetectBreak(
         1.10800,
         1.11300,
         1.10700,
         1.11100,
         S,R),
      1
   );
   // 3. Lower wick crosses support,
   //    but candle closes back inside.
   Check(
      "LOWER_WICK_ONLY_NO_BREAK",
      AS_sr_DetectBreak(
         1.10200,
         1.10400,
         1.09800,
         1.10100,
         S,R),
      0
   );
   // 4. Closed body finishes below support.
   Check(
      "CLOSE_BELOW_S_BREAK_DOWN",
      AS_sr_DetectBreak(
         1.10200,
         1.10300,
         1.09700,
         1.09900,
         S,R),
      -1
   );
   Check(
      "BODY_HIGH",
      (AS_sr_BodyHigh(1.10500,1.10800)==1.10800),
      true
   );
   Check(
      "BODY_LOW",
      (AS_sr_BodyLow(1.10500,1.10200)==1.10200),
      true
   );
   double ph[4];
   double pl[4];
   ph[0]=1.10100; pl[0]=1.09900; // range 0.00200
   ph[1]=1.10600; pl[1]=1.10200; // range 0.00400
   ph[2]=1.10400; pl[2]=1.09800; // range 0.00600
   ph[3]=1.11000; pl[3]=1.10300; // range 0.00700 <- peak
   Check(
      "PEAK_RANGE",
      (MathAbs(AS_sr_PeakRange(ph,pl,4)-0.00700)<0.0000000001),
      true
   );
   double eo[4];
   double ec[4];
   eo[0]=1.10000; ec[0]=1.10300; // body 1.10000 .. 1.10300
   eo[1]=1.10400; ec[1]=1.10100; // body 1.10100 .. 1.10400
   eo[2]=1.09900; ec[2]=1.10600; // body 1.09900 .. 1.10600
   eo[3]=1.10500; ec[3]=1.10200; // body 1.10200 .. 1.10500
   Check(
      "MAX_BODY_HIGH",
      (MathAbs(AS_sr_MaxBodyHigh(eo,ec,4)-1.10600)<0.0000000001),
      true
   );
   Check(
      "MIN_BODY_LOW",
      (MathAbs(AS_sr_MinBodyLow(eo,ec,4)-1.09900)<0.0000000001),
      true
   );
   double pairS=0.0;
   double pairR=0.0;
   bool upOK=AS_sr_BuildPair(
      1,          // UP
      1.12000,    // active resistance extremum
      0.01000,    // peak range
      pairS,
      pairR
   );
   Check("PAIR_UP_OK",upOK,true);
   Check("PAIR_UP_R",
         (MathAbs(pairR-1.12000)<0.0000000001),
         true);
   Check("PAIR_UP_S",
         (MathAbs(pairS-1.11000)<0.0000000001),
         true);
   bool downOK=AS_sr_BuildPair(
      -1,         // DOWN
      1.10000,    // active support extremum
      0.01000,    // peak range
      pairS,
      pairR
   );
   Check("PAIR_DOWN_OK",downOK,true);
   Check("PAIR_DOWN_S",
         (MathAbs(pairS-1.10000)<0.0000000001),
         true);
   Check("PAIR_DOWN_R",
         (MathAbs(pairR-1.11000)<0.0000000001),
         true);
   // One-bar body-extremum confirmation.
   // Equal body extremum is NOT a new extreme.
   Check(
      "HIGH_NEW_NOT_CONFIRMED",
      AS_sr_IsBodyHighConfirmed(
         1.11000,   // candidate
         1.10900,   // next Open
         1.11200    // next Close -> new BodyHigh
      ),
      false
   );
   Check(
      "HIGH_LOWER_CONFIRMED",
      AS_sr_IsBodyHighConfirmed(
         1.11000,
         1.10800,
         1.10900
      ),
      true
   );
   Check(
      "LOW_NEW_NOT_CONFIRMED",
      AS_sr_IsBodyLowConfirmed(
         1.10000,   // candidate
         1.10100,
         1.09800    // new BodyLow
      ),
      false
   );
   Check(
      "LOW_HIGHER_CONFIRMED",
      AS_sr_IsBodyLowConfirmed(
         1.10000,
         1.10200,
         1.10100
      ),
      true
   );
   Print("[AS][SR_GEOMETRY_TEST] SUMMARY checked=",
         g_checked,
         " failed=",
         g_failed);
   if(g_failed==0)
      Print("[AS][SR_GEOMETRY_TEST] PASS");
   else
      Print("[AS][SR_GEOMETRY_TEST] FAIL");
   return(INIT_SUCCEEDED);
}
void OnTick()
{
}





