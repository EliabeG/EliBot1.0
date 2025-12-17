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

//==================== TRAILING STOP AVANÇADO =====================//
enum TrailingMode {
   TRAIL_OFF           = 0,  // Desligado
   TRAIL_ATR           = 1,  // ATR Simples
   TRAIL_CHANDELIER    = 2,  // Chandelier Exit (ATR + HH/LL)
   TRAIL_PSAR          = 3,  // Parabolic SAR
   TRAIL_MULTILEVEL    = 4,  // Multi-Nível Escalonado
   TRAIL_TIME_DECAY    = 5,  // Aperto por Tempo
   TRAIL_HYBRID        = 6   // Híbrido Inteligente (Melhor de todos)
};

enum ProfitLockMode {
   LOCK_OFF            = 0,  // Desligado
   LOCK_BREAKEVEN      = 1,  // Apenas Break-Even
   LOCK_SCALED         = 2,  // Escalonado (25%, 50%, 75%)
   LOCK_AGGRESSIVE     = 3   // Agressivo (Trava 50% do ganho)
};

#endif // __MAABOT_ENUMS_MQH__
//+------------------------------------------------------------------+
