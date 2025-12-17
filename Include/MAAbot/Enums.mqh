//+------------------------------------------------------------------+
//|                                                       Enums.mqh  |
//|   MAAbot v2.3.1 - Enumerações                                    |
//|                                     Autor: Eliabe N Oliveira     |
//+------------------------------------------------------------------+
#ifndef __MAABOT_ENUMS_MQH__
#define __MAABOT_ENUMS_MQH__

//============================= ENUMS ==============================//
enum SLMode { SL_FIXED=0, SL_ATR=1, SL_STRUCTURE=2, SL_HYBRID_MAX=3 };
enum TPMode { TP_FIXED_RATIO=0, TP_ATR_MULT=1 };
enum PrecMode { MODE_AGGRESSIVE=0, MODE_BALANCED=1, MODE_CONSERVATIVE=2 };
enum MGMode { MG_OFF=0, MG_PER_TRADE=1, MG_GRID=2 };

#endif // __MAABOT_ENUMS_MQH__
//+------------------------------------------------------------------+
