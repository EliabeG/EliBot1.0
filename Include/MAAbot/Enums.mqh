//+------------------------------------------------------------------+
//|                                                       Enums.mqh  |
//|   MAAbot v2.4.0 - Enumerações                                    |
//|                                     Autor: Eliabe N Oliveira     |
//+------------------------------------------------------------------+
#ifndef __MAABOT_ENUMS_MQH__
#define __MAABOT_ENUMS_MQH__

//============================= ENUMS ==============================//
enum SLMode { SL_FIXED=0, SL_ATR=1, SL_STRUCTURE=2, SL_HYBRID_MAX=3 };
enum TPMode { TP_FIXED_RATIO=0, TP_ATR_MULT=1 };
enum PrecMode { MODE_AGGRESSIVE=0, MODE_BALANCED=1, MODE_CONSERVATIVE=2 };
enum MGMode { MG_OFF=0, MG_PER_TRADE=1, MG_GRID=2 };

//==================== TRAILING STOP BASEADO NO ESTUDO =====================//
// Referência: "Otimização Algorítmica e Precisão Estocástica na Formulação
// de Estratégias de Trailing Stop: Uma Análise Exaustiva"
//==========================================================================//

// Modo Principal de Trailing Stop
enum TrailingMode {
   TRAIL_OFF              = 0,  // Desligado
   TRAIL_CHANDELIER       = 1,  // Chandelier Exit (ATR + HH/LL) - Muito Alta Precisão
   TRAIL_MARKET_STRUCTURE = 2,  // Market Structure (Pivôs + ATR Buffer) - Alta Precisão
   TRAIL_PSAR             = 3,  // Parabolic SAR (Aceleração) - Alta em Parabólicas
   TRAIL_STEP_ATR         = 4,  // Step ATR (Degraus) - Alta, Filtra Ruído
   TRAIL_HYBRID_STUDY     = 5   // Híbrido do Estudo (Chandelier + Structure) - MÁXIMA
};

// Modo de Atualização do Stop (Contínuo vs Step)
enum TrailUpdateMode {
   UPDATE_CONTINUOUS      = 0,  // Contínuo (cada tick/barra)
   UPDATE_STEP            = 1   // Em Degraus (só move após N ATR de avanço)
};

// Regime de Mercado (para adaptação dinâmica)
enum MarketRegime {
   REGIME_AUTO            = 0,  // Detectar automaticamente via ADX
   REGIME_TRENDING        = 1,  // Forçar modo Tendência (stops mais soltos)
   REGIME_RANGING         = 2,  // Forçar modo Range (stops mais apertados)
   REGIME_VOLATILE        = 3   // Forçar modo Volátil (multiplicador alto)
};

// Tipo de Ativo (para calibração de multiplicador)
enum AssetType {
   ASSET_CONSERVATIVE     = 0,  // Blue Chips / Índices (2.5-3.0x ATR)
   ASSET_VOLATILE         = 1,  // Cripto / Forex Exótico (3.5-4.0x ATR)
   ASSET_INTRADAY         = 2,  // Day Trading (1.5-2.0x ATR)
   ASSET_GOLD_XAUUSD      = 3   // Ouro XAUUSD (3.0-3.5x ATR) - Otimizado
};

// Modo de Ativação Atrasada (Delayed Activation)
enum ActivationMode {
   ACTIVATE_IMMEDIATE     = 0,  // Ativar imediatamente
   ACTIVATE_AFTER_1R      = 1,  // Ativar após lucro > 1R (1x risco inicial)
   ACTIVATE_AFTER_1_5R    = 2,  // Ativar após lucro > 1.5R
   ACTIVATE_AFTER_2R      = 3,  // Ativar após lucro > 2R
   ACTIVATE_AFTER_2ATR    = 4,  // Ativar após lucro > 2 ATR
   ACTIVATE_BREAKEVEN     = 5   // Ativar após break-even atingido
};

#endif // __MAABOT_ENUMS_MQH__
//+------------------------------------------------------------------+
