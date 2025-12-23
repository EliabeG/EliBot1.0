//+------------------------------------------------------------------+
//|                                                      Inputs.mqh  |
//|   MAAbot v2.6.0 - Entradas Reorganizadas para Otimização         |
//|                                     Autor: Eliabe N Oliveira     |
//+------------------------------------------------------------------+
#ifndef __MAABOT_INPUTS_MQH__
#define __MAABOT_INPUTS_MQH__

#include "Enums.mqh"

//╔══════════════════════════════════════════════════════════════════╗
//║              CONFIGURAÇÕES BÁSICAS DO ROBÔ                       ║
//╚══════════════════════════════════════════════════════════════════╝
input group "══════ CONFIGURAÇÕES BÁSICAS ══════"
input string   InpSymbol             = "XAUUSD";               // Símbolo para operar
input ENUM_TIMEFRAMES InpTF          = PERIOD_M15;             // Tempo gráfico principal
input long     Magic                 = 20250815;               // Número Mágico

input group "══════ HORÁRIO DE OPERAÇÃO ══════"
input int      StartHour             = 15;                     // Hora de início
input int      EndHour               = 20;                     // Hora de término
input bool     BlockRollover         = true;                   // Bloquear durante rollover
input int      RolloverStartMin      = 23*60+55;               // Início rollover (minutos)
input int      RolloverEndMin        = 0*60+10;                // Fim rollover (minutos)

input group "══════ GESTÃO DE RISCO BÁSICA ══════"
input double   RiskPercent           = 1.0;                    // Risco por operação (%)
input int      StopLossPoints        = 100;                    // Stop Loss (pontos)
input int      TakeProfitPoints      = 100;                    // Take Profit (pontos)
input int      DeviationPoints       = 20;                     // Desvio máximo (pontos)
input int      MaxSpreadPoints       = 200;                    // Spread máximo (pontos)
input int      MinSecondsBetweenTrades= 10;                    // Segundos entre trades

//╔══════════════════════════════════════════════════════════════════╗
//║     MODO DE OTIMIZAÇÃO - SELECIONE QUAL INDICADOR TESTAR         ║
//╠══════════════════════════════════════════════════════════════════╣
//║  Para otimizar um indicador individualmente:                     ║
//║  1. Ative apenas o indicador desejado (Enable = true)            ║
//║  2. Desative todos os outros (Enable = false)                    ║
//║  3. Otimize os parâmetros desse indicador no Strategy Tester     ║
//╚══════════════════════════════════════════════════════════════════╝

input group "══════ CONTROLE GERAL DOS INDICADORES ══════"
input int      MinAgreeSignals       = 3;                      // Mínimo de sinais concordantes
input PrecMode PrecisionMode         = MODE_BALANCED;          // Modo de precisão

//╔══════════════════════════════════════════════════════════════════╗
//║          INDICADOR 1: AKTE (Adaptive Kalman Trend Estimator)     ║
//╚══════════════════════════════════════════════════════════════════╝
input group "══════ 1. AKTE (Adaptive Kalman Trend Estimator) ══════"
input bool     Enable_AKTE           = true;                   // [ATIVAR] AKTE
input double   W_AKTE                = 1.0;                    // Peso do sinal
input double   AKTE_Q                = 0.011;                  // Q - Ruído do Processo (0.001-0.1)
input int      AKTE_ATRPeriod        = 64;                     // Período do ATR para R adaptativo
input double   AKTE_BandMultiplier   = 10.4;                   // Multiplicador das Bandas de Erro
input int      AKTE_StdDevPeriod     = 69;                     // Período para StdDev dos Resíduos
input double   AKTE_InitialP         = 8.5;                    // P Inicial (Incerteza Inicial)

//╔══════════════════════════════════════════════════════════════════╗
//║                    INDICADOR 2: RSI                              ║
//╚══════════════════════════════════════════════════════════════════╝
input group "══════ 2. RSI (Índice de Força Relativa) ══════"
input bool     Enable_RSI            = true;                   // [ATIVAR] RSI
input double   W_RSI                 = 1.0;                    // Peso do sinal
input int      RSI_Period            = 44;                     // RSI (período)
input int      RSI_Low               = 32;                     // RSI Sobrevendido
input int      RSI_High              = 70;                     // RSI Sobrecomprado

//╔══════════════════════════════════════════════════════════════════╗
//║          INDICADOR 3: PVP (Polynomial Velocity Predictor)        ║
//╚══════════════════════════════════════════════════════════════════╝
input group "══════ 3. PVP (Polynomial Velocity Predictor) ══════"
input bool     Enable_PVP            = true;                   // [ATIVAR] PVP
input double   W_PVP                 = 1.0;                    // Peso do sinal
input int      PVP_LookbackPeriod    = 308;                    // Período de Lookback (n velas)
input double   PVP_Sensitivity       = 4.5;                    // Constante de Sensibilidade (k)
input double   PVP_ProbBuyThresh     = 4.875;                  // Limiar Prob. Compra
input double   PVP_ProbSellThresh    = 0.3;                    // Limiar Prob. Venda

//╔══════════════════════════════════════════════════════════════════╗
//║          INDICADOR 4: IAE (Integral Arc Efficiency)              ║
//╚══════════════════════════════════════════════════════════════════╝
input group "══════ 4. IAE (Integral Arc Efficiency) ══════"
input bool     Enable_IAE            = true;                   // [ATIVAR] IAE
input double   W_IAE                 = 1.3;                    // Peso do sinal
input int      IAE_Period            = 35;                     // Período da Janela Móvel (n)
input int      IAE_EMA_Period        = 86;                     // Período da EMA base
input double   IAE_EffThreshold      = 0.5;                    // Limiar de Eficiência (η)
input double   IAE_ScaleFactor       = 2.9;                    // Fator de Escala (λ)
input int      IAE_StdDevPeriod      = 130;                    // Período para Desvio Padrão
input double   IAE_StdDevMult        = 15.4;                   // Multiplicador do Desvio Padrão

//╔══════════════════════════════════════════════════════════════════╗
//║          INDICADOR 5: SCP (Spectral Cycle Phaser - Fourier)      ║
//╚══════════════════════════════════════════════════════════════════╝
input group "══════ 5. SCP (Spectral Cycle Phaser) ══════"
input bool     Enable_SCP            = true;                   // [ATIVAR] SCP
input double   W_SCP                 = 1.2;                    // Peso do sinal
input int      SCP_WindowSize        = 100;                    // Tamanho da Janela (N) para DFT
input int      SCP_MinPeriod         = 30;                     // Período Mínimo do Ciclo (T min)
input int      SCP_MaxPeriod         = 100;                    // Período Máximo do Ciclo (T max)
input double   SCP_SignalThreshold   = 0.8;                    // Limiar para Sinal (-0.8/+0.8)
input int      SCP_PowerMAPeriod     = 10;                     // Período da Média de Power

//╔══════════════════════════════════════════════════════════════════╗
//║                 INDICADOR 6: HEIKIN ASHI                         ║
//╚══════════════════════════════════════════════════════════════════╝
input group "══════ 6. HEIKIN ASHI ══════"
input bool     Enable_HeikinAshi     = true;                   // [ATIVAR] Heikin Ashi
input double   W_Heikin              = 1.0;                    // Peso do sinal
input int      HA_Period             = 10;                     // Período de lookback

//╔══════════════════════════════════════════════════════════════════╗
//║          INDICADOR 7: FHMI (Fractal Hurst Memory Index)          ║
//╚══════════════════════════════════════════════════════════════════╝
input group "══════ 7. FHMI (Fractal Hurst Memory Index) ══════"
input bool     Enable_FHMI           = true;                   // [ATIVAR] FHMI
input double   W_FHMI                = 1.1;                    // Peso do sinal
input int      FHMI_Period           = 121;                    // Período para cálculo R/S
input int      FHMI_MomentumPeriod   = 66;                     // Período do Momentum
input double   FHMI_TrendThreshold   = 4.5;                    // Limiar H para Tendência
input double   FHMI_RevertThreshold  = 1.0;                    // Limiar H para Reversão
input double   FHMI_ExtremeHigh      = 1.12;                   // H extremo alto
input double   FHMI_ExtremeLow       = 0.54;                   // H extremo baixo

//╔══════════════════════════════════════════════════════════════════╗
//║                  INDICADOR 8: MOMENTUM (ROC)                     ║
//╚══════════════════════════════════════════════════════════════════╝
input group "══════ 8. MOMENTUM (Rate of Change) ══════"
input bool     Enable_Momentum       = true;                   // [ATIVAR] Momentum
input double   W_Momentum            = 1.0;                    // Peso do sinal
input int      ROC_Period            = 77;                     // Período
input double   ROC_Threshold         = 0.019;                  // Limiar

//╔══════════════════════════════════════════════════════════════════╗
//║                     INDICADOR 9: QQE                             ║
//╚══════════════════════════════════════════════════════════════════╝
input group "══════ 9. QQE (Qualitative Quantitative Estimation) ══════"
input bool     Enable_QQE            = true;                   // [ATIVAR] QQE
input bool     UseQQEFilter          = true;                   // Usar como filtro adicional
input double   W_QQE                 = 1.5;                    // Peso do sinal
input int      QQE_RSI_Period        = 15;                     // RSI (período)
input int      QQE_SmoothingFactor   = 39;                     // Suavização

//╔══════════════════════════════════════════════════════════════════╗
//║              FILTROS ADICIONAIS DE ENTRADA                       ║
//╚══════════════════════════════════════════════════════════════════╝

input group "══════ FILTRO: ANÁLISE DE TENDÊNCIA (MTF) ══════"
input bool     UseTrendFilter        = true;                   // [ATIVAR] Filtro de tendência
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
input double   Trend_Pull_ATRMultMax = 0.8;                    // ATR máx pullback
input bool     Trend_AllowBreakout   = true;                   // Permitir rompimentos
input int      Trend_Donchian_Lookback= 20;                    // Lookback Donchian

input group "══════ FILTRO: DETECTOR DE NOTÍCIAS ══════"
input bool     UseNewsDetector       = true;                   // [ATIVAR] Detector de notícias
input bool     News_UseStdDev        = true;                   // Usar desvio padrão
input double   News_StdDev_Ratio     = 2.8;                    // Razão do desvio padrão
input double   News_BodyToRange_Ratio = 0.5;                   // Razão corpo/range
input int      News_Lookback_Window  = 2;                      // Janela de lookback
input double   News_CandleToAvg_Ratio = 3.0;                   // Razão candle/média
input double   News_VolumeToAvg_Ratio = 2.5;                   // Razão volume/média
input int      News_AvgLookback      = 20;                     // Lookback da média

input group "══════ FILTRO: FALHA RÁPIDA ══════"
input bool     UseFailedEntryFilter  = true;                   // [ATIVAR] Filtro de falha
input int      FailedEntryBars       = 3;                      // Barras para detectar falha
input int      FailedEntryCooldownMin = 30;                    // Pausa após falha (min)

input group "══════ FILTRO: CORRELAÇÃO (ANCHOR) ══════"
input bool     UseAnchor             = false;                  // [ATIVAR] Correlação
input string   AnchorSymbol          = "GC";                   // Símbolo correlacionado
input ENUM_TIMEFRAMES AnchorTF       = PERIOD_M15;             // Tempo gráfico
input int      BasisLookback         = 100;                    // Lookback da base
input double   ZEntry                = 0.8;                    // Z de entrada
input int      Anchor_EMA_Fast       = 20;                     // EMA Rápida
input int      Anchor_EMA_Slow       = 50;                     // EMA Lenta
input double   AnchorBoost           = 0.12;                   // Boost de correlação
input double   AnchorPenalty         = 0.50;                   // Penalidade

input double   ThrBoost_Anchor       = 0.03;                   // Boost threshold Anchor
input double   ThrBoost_Struct       = 0.03;                   // Boost threshold Estrutura

//╔══════════════════════════════════════════════════════════════════╗
//║                  STOP LOSS / TAKE PROFIT                         ║
//╚══════════════════════════════════════════════════════════════════╝
input group "══════ SL/TP AVANÇADOS ══════"
input SLMode   SL_Mode               = SL_HYBRID_MAX;          // Modo do Stop Loss
input double   SL_ATR_Mult_Trend     = 2.5;                    // SL ATR Mult. (Tendência)
input double   SL_ATR_Mult_Range     = 1.8;                    // SL ATR Mult. (Lateral)
input int      SL_Struct_Lookback_Trend = 40;                  // SL Lookback (Tendência)
input int      SL_Struct_Lookback_Range = 24;                  // SL Lookback (Lateral)
input int      SL_Struct_BufferPts   = 30;                     // SL Buffer (pontos)

input TPMode   TP_Mode               = TP_ATR_MULT;            // Modo do Take Profit
input double   TP_R_Mult_Trend       = 1.6;                    // TP R:R (Tendência)
input double   TP_R_Mult_Range       = 0.8;                    // TP R:R (Lateral)
input double   TP_ATR_Mult_Trend     = 2.0;                    // TP ATR Mult. (Tendência)
input double   TP_ATR_Mult_Range     = 1.2;                    // TP ATR Mult. (Lateral)

input bool     TP_ClampToDonchian    = true;                   // Limitar TP ao Donchian
input int      TP_Donchian_Lookback  = 20;                     // TP Donchian Lookback
input int      TP_Donchian_BufferPts = 20;                     // TP Donchian Buffer

input bool     ExitOnVWAPCross       = true;                   // Sair no cruzamento VWAP
input ENUM_TIMEFRAMES VWAP_TF        = PERIOD_M15;             // TF para cálculo VWAP
input bool     VWAP_UseRealVolume    = true;                   // Usar volume real (não tick)
input int      MaxBarsInTrade        = 96;                     // Máximo barras na operação
input int      ATR_Period            = 14;                     // Período do ATR

//╔══════════════════════════════════════════════════════════════════╗
//║                    TRAILING STOP                                 ║
//╠══════════════════════════════════════════════════════════════════╣
//║  Desative Enable_TrailingStop para usar apenas SL/TP fixos       ║
//╚══════════════════════════════════════════════════════════════════╝
input group "══════ TRAILING STOP - CONTROLE MESTRE ══════"
input bool     Enable_TrailingStop   = true;                   // ████ [ATIVAR] TRAILING STOP ████
input TrailingMode AdvTrail_Mode     = TRAIL_HYBRID;           // Modo de Trailing
input ProfitLockMode ProfitLock_Mode = LOCK_SCALED;            // Modo de Travamento
input bool     UseATRTrailing        = true;                   // Usar Trailing ATR
input double   ATR_TrailMult         = 2.0;                    // Multiplicador ATR
input bool     UseBreakEven          = true;                   // Usar Break Even
input double   BE_Lock_R_Fraction    = 0.30;                   // Fração R para BE

input group "══════ TRAILING: CHANDELIER EXIT ══════"
input int      Chandelier_Period     = 22;                     // Período máx/mín
input double   Chandelier_ATRMult    = 3.0;                    // Multiplicador ATR
input bool     Chandelier_UseClose   = false;                  // Usar Fechamento

input group "══════ TRAILING: PARABOLIC SAR ══════"
input double   PSAR_Step             = 0.02;                   // Passo do SAR
input double   PSAR_Maximum          = 0.2;                    // Máximo do SAR
input bool     PSAR_FilterTrend      = true;                   // Só em tendência

input group "══════ TRAILING: MULTI-NÍVEL ══════"
input double   ML_Level1_R           = 1.0;                    // Nível 1: Após 1R
input double   ML_Trail1_R           = 0.5;                    // Trail 1: SL para 0.5R
input double   ML_Level2_R           = 2.0;                    // Nível 2: Após 2R
input double   ML_Trail2_R           = 1.0;                    // Trail 2: SL para 1R
input double   ML_Level3_R           = 3.0;                    // Nível 3: Após 3R
input double   ML_Trail3_R           = 2.0;                    // Trail 3: SL para 2R
input double   ML_Level4_R           = 4.0;                    // Nível 4: Após 4R
input double   ML_Trail4_ATR         = 1.5;                    // Trail 4: ATR apertado

input group "══════ TRAILING: APERTO POR TEMPO ══════"
input bool     TimeDecay_Enable      = true;                   // Ativar aperto
input int      TimeDecay_StartBars   = 20;                     // Iniciar após N barras
input int      TimeDecay_FullBars    = 80;                     // Aperto máx após N barras
input double   TimeDecay_MinATRMult  = 1.0;                    // ATR mínimo
input double   TimeDecay_MaxATRMult  = 3.0;                    // ATR inicial

input group "══════ TRAILING: TRAVAMENTO ESCALADO ══════"
input double   Lock_Trigger1_R       = 1.0;                    // Gatilho 1: Após 1R
input double   Lock_Amount1          = 0.25;                   // Travar 25%
input double   Lock_Trigger2_R       = 2.0;                    // Gatilho 2: Após 2R
input double   Lock_Amount2          = 0.50;                   // Travar 50%
input double   Lock_Trigger3_R       = 3.0;                    // Gatilho 3: Após 3R
input double   Lock_Amount3          = 0.70;                   // Travar 70%

input group "══════ TRAILING: HÍBRIDO INTELIGENTE ══════"
input bool     Hybrid_UseTrendAdapt  = true;                   // Adaptar à tendência
input double   Hybrid_TrendLoose     = 1.3;                    // Mult. tendência forte
input double   Hybrid_RangeTight     = 0.8;                    // Mult. lateral
input bool     Hybrid_UseMomentum    = true;                   // Usar momentum
input int      Hybrid_MomPeriod      = 10;                     // Período momentum
input double   Hybrid_MomThreshold   = 0.001;                  // Limiar momentum

//╔══════════════════════════════════════════════════════════════════╗
//║                    META DIÁRIA                                   ║
//╠══════════════════════════════════════════════════════════════════╣
//║  Desative Enable_DailyTarget para desabilitar toda a meta diária ║
//╚══════════════════════════════════════════════════════════════════╝
input group "══════ META DIÁRIA - CONTROLE MESTRE ══════"
input bool               Enable_DailyTarget   = true;                 // ████ [ATIVAR] META DIÁRIA ████
input DailyTargetMode    DT_Mode              = DTARGET_AGGRESSIVE;   // Modo da Meta
input double             DT_TargetPercent     = 1.0;                // Meta diária (%)
input BalanceBaseMode    DT_BalanceBase       = BALANCE_START_DAY;  // Base do saldo
input double             DT_FixedBalance      = 1000.0;             // Saldo fixo
input bool               DT_CompoundDaily     = true;               // Juros compostos
input bool               DT_CompoundOnTarget  = true;               // Compor só se bateu meta

input group "══════ META DIÁRIA - COMPORTAMENTO ══════"
input bool               DT_CloseOnTarget     = true;               // Fechar ao atingir meta
input bool               DT_BlockAfterTarget  = true;               // Bloquear após meta
input bool               DT_OnlyInTimeWindow  = true;               // Só no horário
input double             DT_TargetTolerance   = 0.05;               // Tolerância

input group "══════ META DIÁRIA - HORÁRIOS ══════"
input int                DT_StartHour         = 9;                  // Hora início
input int                DT_StartMinute       = 0;                  // Minuto início
input int                DT_EndHour           = 17;                 // Hora término
input int                DT_EndMinute         = 30;                 // Minuto término
input int                DT_AggressiveMinutes = 60;                 // Min. antes (agressivo)
input EndOfDayBehavior   DT_EndOfDayAction    = EOD_AGGRESSIVE_PUSH;// Ação fim do dia

input group "══════ META DIÁRIA - MODO AGRESSIVO ══════"
input bool               DT_EnableAggressive  = true;               // Ativar agressivo
input AggressiveLevel    DT_MaxAggressiveLevel= AGG_LEVEL_5;        // Nível máximo
input double             DT_AggLotMultiplier  = 2.0;                // Mult. lote/nível
input double             DT_AggThresholdReduce= 0.10;               // Redução threshold
input bool               DT_AggIgnoreFilters  = true;               // Ignorar filtros
input bool               DT_AggAllowAllIn     = true;               // Permitir ALL-IN
input int                DT_AggMaxPositions   = 10;                 // Máx. posições
input double             DT_AggMaxRiskPercent = 100.0;              // Risco máximo (%)

input group "══════ META DIÁRIA - OPERAÇÃO FORÇADA ══════"
input bool               DT_ForceDailyTrade   = true;               // Forçar operação
input int                DT_ForceAfterMinutes = 120;                // Forçar após N min
input int                DT_ForceAggressiveMin= 60;                 // Agressivo após N min
input double             DT_ForceMinThreshold = 0.3;                // Threshold mínimo
input int                DT_ForceMinSignals   = 1;                  // Mín. sinais
input bool               DT_ForceIgnoreFilters= true;               // Ignorar filtros
input double             DT_ForceProgressiveReduce = 0.05;          // Redução/30min

input group "══════ META DIÁRIA - PROTEÇÃO ══════"
input DailyProfitProtection DT_ProfitProtection = PROFIT_PROT_OFF;  // Proteção após meta
input double             DT_LockProfitPercent = 50.0;               // % a proteger
input double             DT_TrailProfitStep   = 0.25;               // Passo trailing
input bool               DT_StopOnExtraProfit = false;              // Parar se lucro>meta

input group "══════ META DIÁRIA - CONTROLE DE PERDA ══════"
input double             DT_MaxDailyLoss      = 50.0;               // Perda máxima (%)
input bool               DT_StopOnMaxLoss     = false;              // Parar na perda máx
input bool               DT_RecoverOnAggressive = true;             // Recuperar agressivo
input double             DT_RecoveryMultiplier= 1.5;                // Mult. recuperação

input group "══════ META DIÁRIA - ESTATÍSTICAS ══════"
input bool               DT_SaveDailyStats    = true;               // Salvar estatísticas
input bool               DT_ShowDailyPanel    = true;               // Mostrar painel
input bool               DT_AlertOnTarget     = true;               // Alerta meta
input bool               DT_AlertOnAggressive = true;               // Alerta agressivo

//╔══════════════════════════════════════════════════════════════════╗
//║                  LIMITES E PROTEÇÃO                              ║
//╚══════════════════════════════════════════════════════════════════╝
input group "══════ LIMITES E PROTEÇÃO ══════"
input double   DailyLossLimitPercent = 3.0;                    // Limite perda diária (%)
input int      MaxTradesPerDay       = 8;                      // Máx. trades/dia
input double   MaxEquityDDPercent    = 20.0;                   // Drawdown máximo (%)
input bool     DD_CloseAllOnBreach   = true;                   // Fechar se DD excedido
input int      DD_CooldownMinutes    = 60;                     // Pausa após DD (min)

input group "══════ REDUTOR DE RISCO ══════"
input bool     UseRiskThrottle       = true;                   // Usar redutor
input double   RT_L1                 = 5.0;                    // Nível 1 DD (%)
input double   RT_F1                 = 0.75;                   // Fator 1 (75%)
input double   RT_L2                 = 10.0;                   // Nível 2 DD (%)
input double   RT_F2                 = 0.50;                   // Fator 2 (50%)
input double   RT_L3                 = 15.0;                   // Nível 3 DD (%)
input double   RT_F3                 = 0.25;                   // Fator 3 (25%)

//╔══════════════════════════════════════════════════════════════════╗
//║                    HEDGE E ENSEMBLE                              ║
//╚══════════════════════════════════════════════════════════════════╝
input group "══════ DIREÇÃO E HEDGE ══════"
input bool     AllowLong             = true;                   // Permitir COMPRA
input bool     AllowShort            = true;                   // Permitir VENDA
input bool     CloseOnFlip           = true;                   // Fechar ao inverter

input bool     UseEntryTF            = false;                  // Usar TF de entrada
input ENUM_TIMEFRAMES EntryTF        = PERIOD_M5;              // TF de entrada
input int      EntryROC_Period       = 6;                      // Período ROC
input double   EntryROC_Threshold    = 0.0004;                 // Limiar ROC

input bool     UseStructureLock      = false;                  // Trava de estrutura
input int      MinATRPoints          = 60;                     // ATR mínimo (pts)
input double   MinATRtoSpread        = 4.0;                    // ATR/Spread mínimo

input group "══════ HEDGE AVANÇADO ══════"
input bool     Hedge_Enable          = true;                   // Ativar Hedge
input bool     Hedge_AllowDoubleStart = true;                  // Início duplo
input bool     Hedge_OpenOnOppSignal = true;                   // Abrir sinal oposto
input bool     Hedge_OpenOnAdverse   = true;                   // Abrir se adverso
input bool     Hedge_Adverse_UseATR  = true;                   // Usar ATR adverso
input double   Hedge_Adverse_ATRMult = 1.0;                    // Mult. ATR adverso
input int      Hedge_Adverse_Points  = 300;                    // Pontos adversos
input bool     Hedge_CloseOnNetProfit = true;                  // Fechar lucro líquido
input double   Hedge_NetTP_Percent   = 0.20;                   // TP líquido (%)
input double   Hedge_NetTP_Money     = 0.0;                    // TP líquido ($)

//╔══════════════════════════════════════════════════════════════════╗
//║                   MARTINGALE / GRID                              ║
//╚══════════════════════════════════════════════════════════════════╝
input group "══════ MARTINGALE / GRID ══════"
input MGMode   MG_Mode               = MG_GRID;                // Modo MG/Grid
input double   MG_Multiplier         = 1.6;                    // Multiplicador
input int      MG_MaxSteps           = 3;                      // Máx. passos
input double   MG_MaxRiskPercent     = 6.0;                    // Risco máximo (%)
input bool     MG_ResetOnProfit      = true;                   // Resetar com lucro
input bool     MG_ResetDaily         = true;                   // Resetar diário
input bool     MG_RespectLossPause   = false;                  // Respeitar pausa

input group "══════ GRID - CONFIGURAÇÕES ══════"
input bool     MG_Grid_UseATR        = true;                   // Usar ATR
input double   MG_Grid_ATRMult       = 1.2;                    // Mult. ATR
input int      MG_Grid_StepPoints    = 250;                    // Passos (pts)
input double   MG_Grid_MaxRiskPercentSum=12.0;                 // Risco total máx (%)
input bool     MG_Grid_RespectStructure=false;                 // Respeitar estrutura
input bool     MG_Grid_DisableFlipClose=true;                  // Desativar flip close

input double   MG_Grid_TargetATRMult = 1.3;                    // Alvo ATR mult.
input double   MG_Grid_MaxAdvATRMult = 18.0;                   // Adverso máx ATR
input int      MG_Grid_TargetPoints  = 70;                     // Alvo (pts)
input int      MG_Grid_MaxAdversePoints=1500;                  // Adverso máx (pts)

input group "══════ GRID - TENDÊNCIA ══════"
input bool     MG_Grid_TrendAware    = true;                   // Considerar tendência
input int      MG_Grid_MaxAdds_InTrend  = 4;                   // Máx adds tendência
input int      MG_Grid_MaxAdds_Counter  = 1;                   // Máx adds contra
input double   MG_Grid_VolMult_InTrend  = 1.7;                 // Vol mult tendência
input double   MG_Grid_VolMult_Counter  = 1.2;                 // Vol mult contra
input double   MG_Grid_ATRMult_InTrend  = 1.0;                 // ATR mult tendência
input double   MG_Grid_ATRMult_Counter  = 1.6;                 // ATR mult contra

input group "══════ GRID - MODO NOTÍCIA ══════"
input int      MG_Grid_News_MaxAdds_InTrend  = 5;              // Adds tendência
input int      MG_Grid_News_MaxAdds_Counter  = 0;              // Adds contra
input double   MG_Grid_News_VolMult_InTrend  = 1.8;            // Vol tendência
input double   MG_Grid_News_VolMult_Counter  = 1.0;            // Vol contra
input double   MG_Grid_News_ATRMult_InTrend  = 0.8;            // ATR tendência
input double   MG_Grid_News_ATRMult_Counter  = 3.0;            // ATR contra

//╔══════════════════════════════════════════════════════════════════╗
//║                    PAINEL VISUAL                                 ║
//╚══════════════════════════════════════════════════════════════════╝
input group "══════ PAINEL VISUAL ══════"
input bool     ShowPanel             = true;                   // Mostrar painel
input int      PanelX                = 10;                     // Posição X
input int      PanelY                = 25;                     // Posição Y
input int      PanelWidth            = 550;                    // Largura
input color    PanelBgColor          = C'15,15,25';            // Cor de fundo 1
input color    PanelBgColor2         = C'25,25,40';            // Cor de fundo 2
input color    PanelTextColor        = clrWhite;               // Cor do texto
input color    PanelHeaderColor      = clrGold;                // Cor cabeçalho
input color    PanelBuyColor         = C'0,255,127';           // Cor COMPRA
input color    PanelSellColor        = C'255,80,80';           // Cor VENDA
input color    PanelNeutralColor     = C'128,128,128';         // Cor neutra
input color    PanelAccentColor      = C'100,149,237';         // Cor destaque
input int      PanelFontSize         = 9;                      // Tamanho fonte
input string   PanelFontName         = "Consolas";             // Nome fonte

//╔══════════════════════════════════════════════════════════════════╗
//║              FUNÇÕES AUXILIARES PARA INDICADORES                 ║
//╚══════════════════════════════════════════════════════════════════╝

// Retorna o peso efetivo do indicador (0 se desativado)
double GetWeight_AKTE()       { return Enable_AKTE ? W_AKTE : 0.0; }
double GetWeight_RSI()        { return Enable_RSI ? W_RSI : 0.0; }
double GetWeight_PVP()        { return Enable_PVP ? W_PVP : 0.0; }
double GetWeight_IAE()        { return Enable_IAE ? W_IAE : 0.0; }
double GetWeight_SCP()        { return Enable_SCP ? W_SCP : 0.0; }
double GetWeight_Heikin()     { return Enable_HeikinAshi ? W_Heikin : 0.0; }
double GetWeight_FHMI()       { return Enable_FHMI ? W_FHMI : 0.0; }
double GetWeight_Momentum()   { return Enable_Momentum ? W_Momentum : 0.0; }
double GetWeight_QQE()        { return Enable_QQE ? W_QQE : 0.0; }

// Conta quantos indicadores estão ativos
int CountActiveIndicators() {
   int count = 0;
   if(Enable_AKTE) count++;
   if(Enable_RSI) count++;
   if(Enable_PVP) count++;
   if(Enable_IAE) count++;
   if(Enable_SCP) count++;
   if(Enable_HeikinAshi) count++;
   if(Enable_FHMI) count++;
   if(Enable_Momentum) count++;
   if(Enable_QQE) count++;
   return count;
}

// Retorna o mínimo de sinais ajustado (não pode ser maior que indicadores ativos)
int GetEffectiveMinSignals() {
   int active = CountActiveIndicators();
   if(active == 0) return 1;
   return MathMin(MinAgreeSignals, active);
}

//╔══════════════════════════════════════════════════════════════════╗
//║         FUNÇÕES AUXILIARES - MÓDULOS (TRAILING/META DIÁRIA)      ║
//╚══════════════════════════════════════════════════════════════════╝

// Verifica se o Trailing Stop está ativo
bool IsTrailingStopEnabled() {
   return Enable_TrailingStop;
}

// Verifica se a Meta Diária está ativa
bool IsDailyTargetEnabled() {
   return Enable_DailyTarget && (DT_Mode != DTARGET_OFF);
}

// Retorna o modo de trailing efetivo (OFF se desativado)
TrailingMode GetEffectiveTrailingMode() {
   if(!Enable_TrailingStop) return TRAIL_OFF;
   return AdvTrail_Mode;
}

// Retorna o modo de meta diária efetivo (OFF se desativado)
DailyTargetMode GetEffectiveDailyTargetMode() {
   if(!Enable_DailyTarget) return DTARGET_OFF;
   return DT_Mode;
}

#endif // __MAABOT_INPUTS_MQH__
//+------------------------------------------------------------------+
