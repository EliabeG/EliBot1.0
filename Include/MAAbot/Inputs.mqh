//+------------------------------------------------------------------+
//|                                                      Inputs.mqh  |
//|   MAAbot v2.5.2 - Entradas e Configurações                       |
//|                                     Autor: Eliabe N Oliveira     |
//+------------------------------------------------------------------+
#ifndef __MAABOT_INPUTS_MQH__
#define __MAABOT_INPUTS_MQH__

#include "Enums.mqh"

//============================= CONFIGURAÇÕES BÁSICAS ===============================//
input group "=== CONFIGURAÇÕES BÁSICAS ==="
input string   InpSymbol             = "XAUUSD";               // Símbolo para operar
input ENUM_TIMEFRAMES InpTF          = PERIOD_M15;             // Tempo gráfico principal

input group "=== HORÁRIO DE OPERAÇÃO ==="
input int      StartHour             = 15;                     // Hora de início
input int      EndHour               = 20;                     // Hora de término
input bool     BlockRollover         = true;                   // Bloquear durante rollover
input int      RolloverStartMin      = 23*60+55;               // Início do rollover (minutos)
input int      RolloverEndMin        = 0*60+10;                // Fim do rollover (minutos)

input group "=== GESTÃO DE RISCO ==="
input double   RiskPercent           = 1.0;                    // Risco por operação (%)
input int      StopLossPoints        = 100;                    // Stop Loss (pontos)
input int      TakeProfitPoints      = 100;                    // Take Profit (pontos)
input int      DeviationPoints       = 20;                     // Desvio máximo (pontos)
input int      MaxSpreadPoints       = 200;                    // Spread máximo (pontos)
input int      MinSecondsBetweenTrades= 10;                    // Segundos entre trades

//============================= SL/TP AVANÇADOS ==============================//
input group "=== STOP LOSS / TAKE PROFIT AVANÇADOS ==="
input SLMode   SL_Mode               = SL_HYBRID_MAX;          // Modo do Stop Loss
input double   SL_ATR_Mult_Trend     = 2.5;                    // SL ATR Mult. (Tendência)
input double   SL_ATR_Mult_Range     = 1.8;                    // SL ATR Mult. (Lateralizado)
input int      SL_Struct_Lookback_Trend = 40;                  // SL Lookback (Tendência)
input int      SL_Struct_Lookback_Range = 24;                  // SL Lookback (Lateralizado)
input int      SL_Struct_BufferPts   = 30;                     // SL Buffer (pontos)

input TPMode   TP_Mode               = TP_ATR_MULT;            // Modo do Take Profit
input double   TP_R_Mult_Trend       = 1.6;                    // TP R:R (Tendência)
input double   TP_R_Mult_Range       = 0.8;                    // TP R:R (Lateralizado)
input double   TP_ATR_Mult_Trend     = 2.0;                    // TP ATR Mult. (Tendência)
input double   TP_ATR_Mult_Range     = 1.2;                    // TP ATR Mult. (Lateralizado)

input bool     TP_ClampToDonchian    = true;                   // Limitar TP ao Donchian
input int      TP_Donchian_Lookback  = 20;                     // TP Donchian Lookback
input int      TP_Donchian_BufferPts = 20;                     // TP Donchian Buffer (pts)

input bool     ExitOnVWAPCross       = true;                   // Sair no cruzamento VWAP
input int      MaxBarsInTrade        = 96;                     // Máximo de barras na operação
input bool     UseATRTrailing        = true;                   // Usar Trailing ATR
input int      ATR_Period            = 14;                     // Período do ATR
input double   ATR_TrailMult         = 2.0;                    // Multiplicador ATR Trailing
input bool     UseBreakEven          = true;                   // Usar Break Even
input double   BE_Lock_R_Fraction    = 0.30;                   // Fração R para Break Even

//==================== TRAILING STOP AVANÇADO ===================//
input group "=== TRAILING STOP AVANÇADO ==="
input TrailingMode AdvTrail_Mode     = TRAIL_HYBRID;           // Modo de Trailing Principal
input ProfitLockMode ProfitLock_Mode = LOCK_SCALED;            // Modo de Travamento de Lucro

input group "=== CHANDELIER EXIT ==="
input int      Chandelier_Period     = 22;                     // Período para máxima/mínima
input double   Chandelier_ATRMult    = 3.0;                    // Multiplicador ATR
input bool     Chandelier_UseClose   = false;                  // Usar Fechamento (não High/Low)

input group "=== PARABOLIC SAR ==="
input double   PSAR_Step             = 0.02;                   // Passo do SAR
input double   PSAR_Maximum          = 0.2;                    // Máximo do SAR
input bool     PSAR_FilterTrend      = true;                   // Usar apenas em tendência

input group "=== TRAILING MULTI-NÍVEL ==="
input double   ML_Level1_R           = 1.0;                    // Nível 1: Após 1R de lucro
input double   ML_Trail1_R           = 0.5;                    // Trail 1: Move SL para 0.5R
input double   ML_Level2_R           = 2.0;                    // Nível 2: Após 2R de lucro
input double   ML_Trail2_R           = 1.0;                    // Trail 2: Move SL para 1R
input double   ML_Level3_R           = 3.0;                    // Nível 3: Após 3R de lucro
input double   ML_Trail3_R           = 2.0;                    // Trail 3: Move SL para 2R
input double   ML_Level4_R           = 4.0;                    // Nível 4: Após 4R de lucro
input double   ML_Trail4_ATR         = 1.5;                    // Trail 4: ATR trailing apertado

input group "=== APERTO POR TEMPO ==="
input bool     TimeDecay_Enable      = true;                   // Ativar aperto por tempo
input int      TimeDecay_StartBars   = 20;                     // Iniciar após N barras
input int      TimeDecay_FullBars    = 80;                     // Aperto máximo após N barras
input double   TimeDecay_MinATRMult  = 1.0;                    // ATR mínimo (aperto máximo)
input double   TimeDecay_MaxATRMult  = 3.0;                    // ATR inicial

input group "=== TRAVAMENTO DE LUCRO ESCALADO ==="
input double   Lock_Trigger1_R       = 1.0;                    // Gatilho 1: Após 1R
input double   Lock_Amount1          = 0.25;                   // Travar 25% do lucro
input double   Lock_Trigger2_R       = 2.0;                    // Gatilho 2: Após 2R
input double   Lock_Amount2          = 0.50;                   // Travar 50% do lucro
input double   Lock_Trigger3_R       = 3.0;                    // Gatilho 3: Após 3R
input double   Lock_Amount3          = 0.70;                   // Travar 70% do lucro

input group "=== TRAILING HÍBRIDO INTELIGENTE ==="
input bool     Hybrid_UseTrendAdapt  = true;                   // Adaptar à tendência
input double   Hybrid_TrendLoose     = 1.3;                    // Mult. tendência forte
input double   Hybrid_RangeTight     = 0.8;                    // Mult. mercado lateral
input bool     Hybrid_UseMomentum    = true;                   // Usar momentum
input int      Hybrid_MomPeriod      = 10;                     // Período do momentum
input double   Hybrid_MomThreshold   = 0.001;                  // Limiar do momentum

//==================== META DIÁRIA (PORCENTAGEM AO DIA) ====================//
input group "=== META DIÁRIA - CONFIGURAÇÃO PRINCIPAL ==="
input DailyTargetMode    DT_Mode              = DTARGET_AGGRESSIVE; // Modo da Meta Diária
input double             DT_TargetPercent     = 1.0;                // Meta diária (%) - Ex: 1.0 = 1%
input BalanceBaseMode    DT_BalanceBase       = BALANCE_START_DAY;  // Base para cálculo do saldo
input double             DT_FixedBalance      = 1000.0;             // Saldo fixo (se usar FIXO)
input bool               DT_CompoundDaily     = true;               // Usar juros compostos diários
input bool               DT_CompoundOnTarget  = true;               // Compor só se bateu meta anterior

input group "=== META DIÁRIA - COMPORTAMENTO AUTOMÁTICO ==="
input bool               DT_CloseOnTarget     = true;               // FECHAR operações ao atingir meta
input bool               DT_BlockAfterTarget  = true;               // BLOQUEAR operações após meta
input bool               DT_OnlyInTimeWindow  = true;               // Meta só vale no horário
input double             DT_TargetTolerance   = 0.05;               // Tolerância (0.05 = fecha com 0.95%)

input group "=== META DIÁRIA - HORÁRIOS DE OPERAÇÃO ==="
input int                DT_StartHour         = 9;                  // Hora de início
input int                DT_StartMinute       = 0;                  // Minuto de início
input int                DT_EndHour           = 17;                 // Hora de término
input int                DT_EndMinute         = 30;                 // Minuto de término
input int                DT_AggressiveMinutes = 60;                 // Minutos antes do fim (agressivo)
input EndOfDayBehavior   DT_EndOfDayAction    = EOD_AGGRESSIVE_PUSH;// Ação ao final do dia

input group "=== META DIÁRIA - MODO AGRESSIVO ==="
input bool               DT_EnableAggressive  = true;               // Ativar modo agressivo
input AggressiveLevel    DT_MaxAggressiveLevel= AGG_LEVEL_5;        // Nível máximo de agressividade
input double             DT_AggLotMultiplier  = 2.0;                // Multiplicador de lote/nível
input double             DT_AggThresholdReduce= 0.10;               // Redução de threshold/nível
input bool               DT_AggIgnoreFilters  = true;               // Ignorar filtros (nível máx)
input bool               DT_AggAllowAllIn     = true;               // Permitir ALL-IN se necessário
input int                DT_AggMaxPositions   = 10;                 // Máx. posições simultâneas
input double             DT_AggMaxRiskPercent = 100.0;              // Risco máximo % (100=tudo)

input group "=== META DIÁRIA - OPERAÇÃO OBRIGATÓRIA ==="
input bool               DT_ForceDailyTrade   = true;               // FORÇAR operação diária
input int                DT_ForceAfterMinutes = 120;                // Forçar após N min sem trade
input int                DT_ForceAggressiveMin= 60;                 // Agressivo após N min sem trade
input double             DT_ForceMinThreshold = 0.3;                // Threshold mínimo (30%)
input int                DT_ForceMinSignals   = 1;                  // Mínimo de sinais
input bool               DT_ForceIgnoreFilters= true;               // Ignorar filtros (forçado)
input double             DT_ForceProgressiveReduce = 0.05;          // Redução progressiva/30min

input group "=== META DIÁRIA - PROTEÇÃO DE LUCRO ==="
input DailyProfitProtection DT_ProfitProtection = PROFIT_PROT_OFF;  // Proteção após meta
input double             DT_LockProfitPercent = 50.0;               // % do lucro a proteger
input double             DT_TrailProfitStep   = 0.25;               // Passo do trailing (%)
input bool               DT_StopOnExtraProfit = false;              // Parar se lucro > meta

input group "=== META DIÁRIA - CONTROLE DE PERDA ==="
input double             DT_MaxDailyLoss      = 50.0;               // Perda máxima diária (%)
input bool               DT_StopOnMaxLoss     = false;              // Parar ao atingir perda máx
input bool               DT_RecoverOnAggressive = true;             // Recuperar no modo agressivo
input double             DT_RecoveryMultiplier= 1.5;                // Multiplicador recuperação

input group "=== META DIÁRIA - ESTATÍSTICAS ==="
input bool               DT_SaveDailyStats    = true;               // Salvar estatísticas
input bool               DT_ShowDailyPanel    = true;               // Mostrar painel da meta
input bool               DT_AlertOnTarget     = true;               // Alerta ao atingir meta
input bool               DT_AlertOnAggressive = true;               // Alerta modo agressivo

//============================= LIMITES E PROTEÇÃO ===========================//
input group "=== LIMITES E PROTEÇÃO ==="
input double   DailyLossLimitPercent = 3.0;                    // Limite de perda diária (%)
input int      MaxTradesPerDay       = 8;                      // Máximo de trades por dia

input double   MaxEquityDDPercent    = 20.0;                   // Drawdown máximo (%)
input bool     DD_CloseAllOnBreach   = true;                   // Fechar tudo se DD excedido
input int      DD_CooldownMinutes    = 60;                     // Pausa após DD (minutos)
input bool     UseRiskThrottle       = true;                   // Usar redutor de risco

input double   RT_L1                 = 5.0;                    // Nível 1 DD (%)
input double   RT_F1                 = 0.75;                   // Fator 1 (reduz para 75%)
input double   RT_L2                 = 10.0;                   // Nível 2 DD (%)
input double   RT_F2                 = 0.50;                   // Fator 2 (reduz para 50%)
input double   RT_L3                 = 15.0;                   // Nível 3 DD (%)
input double   RT_F3                 = 0.25;                   // Fator 3 (reduz para 25%)

//=================== FILTRO DE FALHA RÁPIDA ====================//
input group "=== FILTRO DE FALHA RÁPIDA ==="
input bool     UseFailedEntryFilter   = true;                  // Usar filtro de falha
input int      FailedEntryBars        = 3;                     // Barras para detectar falha
input int      FailedEntryCooldownMin = 30;                    // Pausa após falha (min)

//=================== FILTRO QQE ====================//
input group "=== FILTRO QQE ==="
input bool     UseQQEFilter           = true;                  // Usar filtro QQE
input int      QQE_RSI_Period         = 14;                    // Período RSI do QQE
input int      QQE_SmoothingFactor    = 5;                     // Suavização do QQE

//=================== DETECTOR DE NOTÍCIAS ====================//
input group "=== DETECTOR DE NOTÍCIAS ==="
input bool     UseNewsDetector        = true;                  // Usar detector de notícias
input bool     News_UseStdDev         = true;                  // Usar desvio padrão
input double   News_StdDev_Ratio      = 2.8;                   // Razão do desvio padrão
input double   News_BodyToRange_Ratio = 0.5;                   // Razão corpo/range
input int      News_Lookback_Window   = 2;                     // Janela de lookback

input string   News_Old_Logic_Header  = "--- Lógica Antiga ---";// Separador
input double   News_CandleToAvg_Ratio = 3.0;                   // Razão candle/média
input double   News_VolumeToAvg_Ratio = 2.5;                   // Razão volume/média
input int      News_AvgLookback       = 20;                    // Lookback da média

//============================= TENDÊNCIA (MTF) ==============================//
input group "=== ANÁLISE DE TENDÊNCIA (MTF) ==="
input bool     UseTrendFilter        = true;                   // Usar filtro de tendência
input bool     Trend_Strict_Entries  = false;                  // Entradas estritas
input ENUM_TIMEFRAMES Trend_TF1      = PERIOD_H1;              // Tempo gráfico 1
input ENUM_TIMEFRAMES Trend_TF2      = PERIOD_H4;              // Tempo gráfico 2
input bool     Trend_UseTF2          = true;                   // Usar tempo gráfico 2
input double   Trend_TF2_Weight      = 0.4;                    // Peso do TF2
input int      Trend_ADX_Period      = 14;                     // Período do ADX
input double   Trend_ADX_Thr         = 18.0;                   // Limiar do ADX
input int      Trend_EMA_Fast        = 50;                     // EMA Rápida
input int      Trend_EMA_Slow        = 200;                    // EMA Lenta
input double   TrendScore_Thr        = 0.60;                   // Limiar do score

input bool     Trend_UsePullbackEntry = false;                 // Entrada em pullback
input int      Trend_Pull_EMA        = 20;                     // EMA do pullback
input double   Trend_Pull_ATRMultMax = 0.8;                    // ATR máx do pullback
input bool     Trend_AllowBreakout   = true;                   // Permitir rompimentos
input int      Trend_Donchian_Lookback= 20;                    // Lookback Donchian

//============================= HEDGE / ENSEMBLE =============================//
input group "=== HEDGE E ENSEMBLE ==="
input bool     AllowLong             = true;                   // Permitir operações COMPRA
input bool     AllowShort            = true;                   // Permitir operações VENDA
input bool     CloseOnFlip           = true;                   // Fechar ao inverter sinal

input PrecMode PrecisionMode         = MODE_BALANCED;          // Modo de precisão
input int      MinAgreeSignals       = 3;                      // Mínimo de sinais concordantes
input bool     UseEntryTF            = false;                  // Usar TF de entrada
input ENUM_TIMEFRAMES EntryTF        = PERIOD_M5;              // TF de entrada
input int      EntryROC_Period       = 6;                      // Período ROC entrada
input double   EntryROC_Threshold    = 0.0004;                 // Limiar ROC entrada

input bool     UseStructureLock      = false;                  // Trava de estrutura
input int      MinATRPoints          = 60;                     // ATR mínimo (pontos)
input double   MinATRtoSpread        = 4.0;                    // ATR/Spread mínimo

input bool     Hedge_Enable          = true;                   // Ativar Hedge
input bool     Hedge_AllowDoubleStart = true;                  // Permitir início duplo
input bool     Hedge_OpenOnOppSignal = true;                   // Abrir em sinal oposto
input bool     Hedge_OpenOnAdverse   = true;                   // Abrir se adverso
input bool     Hedge_Adverse_UseATR  = true;                   // Usar ATR para adverso
input double   Hedge_Adverse_ATRMult = 1.0;                    // Mult. ATR adverso
input int      Hedge_Adverse_Points  = 300;                    // Pontos adversos
input bool     Hedge_CloseOnNetProfit = true;                  // Fechar com lucro líquido
input double   Hedge_NetTP_Percent   = 0.20;                   // TP líquido (%)
input double   Hedge_NetTP_Money     = 0.0;                    // TP líquido ($)

//============================= MARTINGALE / GRID ============================//
input group "=== MARTINGALE / GRID ==="
input MGMode   MG_Mode               = MG_GRID;                // Modo Martingale/Grid
input double   MG_Multiplier         = 1.6;                    // Multiplicador
input int      MG_MaxSteps           = 3;                      // Máximo de passos
input double   MG_MaxRiskPercent     = 6.0;                    // Risco máximo (%)
input bool     MG_ResetOnProfit      = true;                   // Resetar com lucro
input bool     MG_ResetDaily         = true;                   // Resetar diariamente
input bool     MG_RespectLossPause   = false;                  // Respeitar pausa de perda

input bool     MG_Grid_UseATR        = true;                   // Grid: Usar ATR
input double   MG_Grid_ATRMult       = 1.2;                    // Grid: Mult. ATR
input int      MG_Grid_StepPoints    = 250;                    // Grid: Passos (pontos)
input double   MG_Grid_MaxRiskPercentSum=12.0;                 // Grid: Risco total máx (%)
input bool     MG_Grid_RespectStructure=false;                 // Grid: Respeitar estrutura
input bool     MG_Grid_DisableFlipClose=true;                  // Grid: Desativar fecha flip

input double   MG_Grid_TargetATRMult = 1.3;                    // Grid: Alvo ATR mult.
input double   MG_Grid_MaxAdvATRMult = 18.0;                   // Grid: Adverso máx ATR
input int      MG_Grid_TargetPoints  = 70;                     // Grid: Alvo (pontos)
input int      MG_Grid_MaxAdversePoints=1500;                  // Grid: Adverso máx (pts)

input bool     MG_Grid_TrendAware    = true;                   // Grid: Considerar tendência
input int      MG_Grid_MaxAdds_InTrend  = 4;                   // Grid: Máx adds (tendência)
input int      MG_Grid_MaxAdds_Counter  = 1;                   // Grid: Máx adds (contra)
input double   MG_Grid_VolMult_InTrend  = 1.7;                 // Grid: Vol mult (tendência)
input double   MG_Grid_VolMult_Counter  = 1.2;                 // Grid: Vol mult (contra)
input double   MG_Grid_ATRMult_InTrend  = 1.0;                 // Grid: ATR mult (tendência)
input double   MG_Grid_ATRMult_Counter  = 1.6;                 // Grid: ATR mult (contra)

input group "=== GRID EM MODO NOTÍCIA ==="
input int      MG_Grid_News_MaxAdds_InTrend  = 5;              // Grid News: Adds (tendência)
input int      MG_Grid_News_MaxAdds_Counter  = 0;              // Grid News: Adds (contra)
input double   MG_Grid_News_VolMult_InTrend  = 1.8;            // Grid News: Vol (tendência)
input double   MG_Grid_News_VolMult_Counter  = 1.0;            // Grid News: Vol (contra)
input double   MG_Grid_News_ATRMult_InTrend  = 0.8;            // Grid News: ATR (tendência)
input double   MG_Grid_News_ATRMult_Counter  = 3.0;            // Grid News: ATR (contra)

//============================= PESOS DAS ESTRATÉGIAS ==============================//
input group "=== PESOS DAS ESTRATÉGIAS ==="
input double   W_MAcross=1.0;                                  // Peso: Cruzamento de Médias
input double   W_RSI=1.0;                                      // Peso: RSI
input double   W_BBands=1.0;                                   // Peso: Bandas de Bollinger
input double   W_Supertrend=1.3;                               // Peso: SuperTrend
input double   W_AMA=1.2;                                      // Peso: AMA/KAMA
input double   W_Heikin=1.0;                                   // Peso: Heikin Ashi
input double   W_VWAP=1.1;                                     // Peso: VWAP
input double   W_Momentum=1.0;                                 // Peso: Momentum
input double   W_QQE=1.5;                                      // Peso: QQE

input group "=== PARÂMETROS DOS INDICADORES ==="
input int      EMA_Fast=20;                                    // EMA Rápida (período)
input int      EMA_Slow=50;                                    // EMA Lenta (período)
input int      RSI_Period=14;                                  // RSI (período)
input int      RSI_Low=30;                                     // RSI Sobrevendido
input int      RSI_High=70;                                    // RSI Sobrecomprado
input int      BB_Period=20;                                   // Bollinger (período)
input double   BB_Dev=2.0;                                     // Bollinger (desvio)
input int      ST_ATR_Period=10;                               // SuperTrend ATR (período)
input double   ST_Mult=3.0;                                    // SuperTrend (mult.)
input int      AMA_ER_Period=10;                               // AMA ER (período)
input int      AMA_Fast=2;                                     // AMA Rápida
input int      AMA_Slow=30;                                    // AMA Lenta
input double   AMA_ATR_FilterMult=3.0;                         // AMA Filtro ATR (mult.)
input ENUM_TIMEFRAMES VWAP_TF=PERIOD_M1;                       // VWAP (tempo gráfico)
input bool     VWAP_UseRealVolume=false;                       // VWAP: Usar volume real
input int      ROC_Period=12;                                  // ROC (período)
input double   ROC_Threshold=0.002;                            // ROC (limiar)

input group "=== ATIVO DE CORRELAÇÃO (ANCHOR) ==="
input bool     UseAnchor=false;                                // Usar correlação
input string   AnchorSymbol="GC";                              // Símbolo de correlação
input ENUM_TIMEFRAMES AnchorTF=PERIOD_M15;                     // TF de correlação
input int      BasisLookback=100;                              // Lookback da base
input double   ZEntry=0.8;                                     // Z de entrada
input int      Anchor_EMA_Fast=20;                             // Anchor EMA Rápida
input int      Anchor_EMA_Slow=50;                             // Anchor EMA Lenta
input double   AnchorBoost=0.12;                               // Boost de correlação
input double   AnchorPenalty=0.50;                             // Penalidade correlação

input double   ThrBoost_Anchor=0.03;                           // Boost threshold Anchor
input double   ThrBoost_Struct=0.03;                           // Boost threshold Estrutura

//============================= PAINEL VISUAL ================================//
input group "=== PAINEL VISUAL ==="
input bool     ShowPanel             = true;                   // Mostrar painel
input int      PanelX                = 10;                     // Posição X
input int      PanelY                = 25;                     // Posição Y
input int      PanelWidth            = 550;                    // Largura
input color    PanelBgColor          = C'15,15,25';            // Cor de fundo 1
input color    PanelBgColor2         = C'25,25,40';            // Cor de fundo 2
input color    PanelTextColor        = clrWhite;               // Cor do texto
input color    PanelHeaderColor      = clrGold;                // Cor do cabeçalho
input color    PanelBuyColor         = C'0,255,127';           // Cor de COMPRA
input color    PanelSellColor        = C'255,80,80';           // Cor de VENDA
input color    PanelNeutralColor     = C'128,128,128';         // Cor neutra
input color    PanelAccentColor      = C'100,149,237';         // Cor de destaque
input int      PanelFontSize         = 9;                      // Tamanho da fonte
input string   PanelFontName         = "Consolas";             // Nome da fonte

input group "=== IDENTIFICAÇÃO ==="
input long     Magic=20250815;                                 // Número Mágico

#endif // __MAABOT_INPUTS_MQH__
//+------------------------------------------------------------------+
