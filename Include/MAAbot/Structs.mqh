//+------------------------------------------------------------------+
//|                                                     Structs.mqh  |
//|   MAAbot v2.3.1 - Estruturas                                     |
//|                                     Autor: Eliabe N Oliveira     |
//+------------------------------------------------------------------+
#ifndef __MAABOT_STRUCTS_MQH__
#define __MAABOT_STRUCTS_MQH__

//============================= ESTRUTURAS ==============================//
struct GridState { 
   bool active; 
   int adds; 
   double basePrice; 
   double lastAddPrice; 
   double baseLot; 
};

struct Signals { 
   int mac, rsi, bb, st, ama, ha, vwap, mom, qqe; 
   double emaF, emaS, vwapv, c0; 
};

struct BasketInfo { 
   double avg, vol; 
   int cnt; 
   double profit; 
};

#endif // __MAABOT_STRUCTS_MQH__
//+------------------------------------------------------------------+
