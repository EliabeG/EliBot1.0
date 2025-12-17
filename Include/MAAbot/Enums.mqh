//+------------------------------------------------------------------+
//|                                                       Enums.mqh  |
//|   MAAbot v2.5.0 - Enumerações                                    |
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

//==================== PORCENTAGEM AO DIA (DAILY TARGET) ======================//
// Sistema de meta diária com juros compostos e modo agressivo

// Modo principal da estratégia
enum DailyTargetMode {
   DTARGET_OFF            = 0,  // Desligado
   DTARGET_CONSERVATIVE   = 1,  // Conservador - Para ao atingir meta
   DTARGET_MODERATE       = 2,  // Moderado - Continua até fim do horário
   DTARGET_AGGRESSIVE     = 3   // Agressivo - Meta obrigatória (arrisca tudo)
};

// Comportamento ao final do dia/horário
enum EndOfDayBehavior {
   EOD_CLOSE_ALL          = 0,  // Fechar todas as posições
   EOD_KEEP_WINNING       = 1,  // Manter apenas posições lucrativas
   EOD_KEEP_ALL           = 2,  // Manter todas as posições
   EOD_AGGRESSIVE_PUSH    = 3   // Modo agressivo para bater meta
};

// Modo de cálculo da banca base
enum BalanceBaseMode {
   BALANCE_START_DAY      = 0,  // Saldo no início do dia
   BALANCE_START_WEEK     = 1,  // Saldo no início da semana
   BALANCE_START_MONTH    = 2,  // Saldo no início do mês
   BALANCE_CURRENT        = 3,  // Saldo atual (equity)
   BALANCE_FIXED          = 4   // Valor fixo definido pelo usuário
};

// Nível de agressividade quando faltando tempo
enum AggressiveLevel {
   AGG_LEVEL_1            = 1,  // Leve (+25% lote, -10% threshold)
   AGG_LEVEL_2            = 2,  // Moderado (+50% lote, -20% threshold)
   AGG_LEVEL_3            = 3,  // Alto (+100% lote, -30% threshold)
   AGG_LEVEL_4            = 4,  // Muito Alto (+150% lote, ignora filtros)
   AGG_LEVEL_5            = 5   // Extremo (All-in, qualquer sinal)
};

// Modo de proteção de lucro durante o dia
enum DailyProfitProtection {
   PROFIT_PROT_OFF        = 0,  // Sem proteção
   PROFIT_PROT_HALF       = 1,  // Proteger 50% do lucro após meta
   PROFIT_PROT_TRAIL      = 2,  // Trailing da meta (sobe junto)
   PROFIT_PROT_LOCK       = 3   // Travar lucro total após meta
};

// Status do dia para relatório
enum DailyStatus {
   DAY_NOT_STARTED        = 0,  // Dia não iniciado
   DAY_TRADING            = 1,  // Em operação normal
   DAY_AGGRESSIVE         = 2,  // Modo agressivo ativo
   DAY_TARGET_HIT         = 3,  // Meta atingida
   DAY_TARGET_EXCEEDED    = 4,  // Meta ultrapassada
   DAY_STOPPED_LOSS       = 5,  // Parado por loss
   DAY_ENDED              = 6   // Dia encerrado
};

#endif // __MAABOT_ENUMS_MQH__
//+------------------------------------------------------------------+
