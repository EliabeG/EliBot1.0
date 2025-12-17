//+------------------------------------------------------------------+
//|                                                      Inputs.mqh  |
//|   MAAbot v2.3.1 - Inputs e Configurações                         |
//|                                     Autor: Eliabe N Oliveira     |
//+------------------------------------------------------------------+
#ifndef __MAABOT_INPUTS_MQH__
#define __MAABOT_INPUTS_MQH__

#include "Enums.mqh"

//============================= INPUTS BÁSICOS ===============================//
input group "=== CONFIGURAÇÕES BÁSICAS ==="
input string   InpSymbol             = "XAUUSD";
input ENUM_TIMEFRAMES InpTF          = PERIOD_M15;

input group "=== HORÁRIO DE OPERAÇÃO ==="
input int      StartHour             = 15;
input int      EndHour               = 20;
input bool     BlockRollover         = true;
input int      RolloverStartMin      = 23*60+55;
input int      RolloverEndMin        = 0*60+10;

input group "=== GESTÃO DE RISCO ==="
input double   RiskPercent           = 1.0;
input int      StopLossPoints        = 100;
input int      TakeProfitPoints      = 100;
input int      DeviationPoints       = 20;
input int      MaxSpreadPoints       = 200;
input int      MinSecondsBetweenTrades= 10;

//============================= SL/TP AVANÇADOS ==============================//
input group "=== SL/TP AVANÇADOS ==="
input SLMode   SL_Mode               = SL_HYBRID_MAX;
input double   SL_ATR_Mult_Trend     = 2.5;
input double   SL_ATR_Mult_Range     = 1.8;
input int      SL_Struct_Lookback_Trend = 40;
input int      SL_Struct_Lookback_Range = 24;
input int      SL_Struct_BufferPts   = 30;

input TPMode   TP_Mode               = TP_ATR_MULT;
input double   TP_R_Mult_Trend       = 1.6;
input double   TP_R_Mult_Range       = 0.8;
input double   TP_ATR_Mult_Trend     = 2.0;
input double   TP_ATR_Mult_Range     = 1.2;

input bool     TP_ClampToDonchian    = true;
input int      TP_Donchian_Lookback  = 20;
input int      TP_Donchian_BufferPts = 20;

input bool     ExitOnVWAPCross       = true;
input int      MaxBarsInTrade        = 96;
input bool     UseATRTrailing        = true;
input int      ATR_Period            = 14;
input double   ATR_TrailMult         = 2.0;
input bool     UseBreakEven          = true;
input double   BE_Lock_R_Fraction    = 0.30;

//==================== TRAILING STOP AVANÇADO (TRADING STOP) ===================//
input group "=== TRAILING STOP AVANÇADO ==="
input TrailingMode AdvTrail_Mode     = TRAIL_HYBRID;    // Modo de Trailing Principal
input ProfitLockMode ProfitLock_Mode = LOCK_SCALED;     // Modo de Travamento de Lucro

// --- CHANDELIER EXIT ---
input group "=== CHANDELIER EXIT ==="
input int      Chandelier_Period     = 22;              // Período para HH/LL
input double   Chandelier_ATRMult    = 3.0;             // Multiplicador ATR
input bool     Chandelier_UseClose   = false;           // Usar Close ao invés de High/Low

// --- PARABOLIC SAR ---
input group "=== PARABOLIC SAR ==="
input double   PSAR_Step             = 0.02;            // Passo do SAR
input double   PSAR_Maximum          = 0.2;             // Máximo do SAR
input bool     PSAR_FilterTrend      = true;            // Só usar em tendência

// --- MULTI-LEVEL TRAILING ---
input group "=== MULTI-LEVEL TRAILING ==="
input double   ML_Level1_R           = 1.0;             // Nível 1: Após 1R de lucro
input double   ML_Trail1_R           = 0.5;             // Trail 1: Move SL para 0.5R
input double   ML_Level2_R           = 2.0;             // Nível 2: Após 2R de lucro
input double   ML_Trail2_R           = 1.0;             // Trail 2: Move SL para 1R
input double   ML_Level3_R           = 3.0;             // Nível 3: Após 3R de lucro
input double   ML_Trail3_R           = 2.0;             // Trail 3: Move SL para 2R
input double   ML_Level4_R           = 4.0;             // Nível 4: Após 4R de lucro
input double   ML_Trail4_ATR         = 1.5;             // Trail 4: ATR trailing apertado

// --- TIME DECAY (APERTO POR TEMPO) ---
input group "=== TIME DECAY STOP ==="
input bool     TimeDecay_Enable      = true;            // Ativar aperto por tempo
input int      TimeDecay_StartBars   = 20;              // Começar após N barras
input int      TimeDecay_FullBars    = 80;              // Máximo aperto após N barras
input double   TimeDecay_MinATRMult  = 1.0;             // ATR mínimo no aperto máximo
input double   TimeDecay_MaxATRMult  = 3.0;             // ATR inicial

// --- PROFIT LOCK ESCALADO ---
input group "=== PROFIT LOCK ESCALADO ==="
input double   Lock_Trigger1_R       = 1.0;             // Gatilho 1: Após 1R
input double   Lock_Amount1          = 0.25;            // Travar 25% do lucro
input double   Lock_Trigger2_R       = 2.0;             // Gatilho 2: Após 2R
input double   Lock_Amount2          = 0.50;            // Travar 50% do lucro
input double   Lock_Trigger3_R       = 3.0;             // Gatilho 3: Após 3R
input double   Lock_Amount3          = 0.70;            // Travar 70% do lucro

// --- TRAILING HÍBRIDO INTELIGENTE ---
input group "=== TRAILING HÍBRIDO ==="
input bool     Hybrid_UseTrendAdapt  = true;            // Adaptar à tendência
input double   Hybrid_TrendLoose     = 1.3;             // Multiplicador em tendência forte
input double   Hybrid_RangeTight     = 0.8;             // Multiplicador em range
input bool     Hybrid_UseMomentum    = true;            // Usar momentum para ajustar
input int      Hybrid_MomPeriod      = 10;              // Período do momentum
input double   Hybrid_MomThreshold   = 0.001;           // Threshold do momentum

//==================== PORCENTAGEM AO DIA (DAILY TARGET) ====================//
// Sistema de meta diária com juros compostos e modo agressivo
//============================================================================//

input group "=== META DIÁRIA - CONFIGURAÇÃO PRINCIPAL ==="
input DailyTargetMode    DT_Mode              = DTARGET_AGGRESSIVE; // Modo da Meta Diária
input double             DT_TargetPercent     = 1.0;                // Meta diária em % (ex: 1.0 = 1%)
input BalanceBaseMode    DT_BalanceBase       = BALANCE_START_DAY;  // Base para cálculo da banca
input double             DT_FixedBalance      = 1000.0;             // Banca fixa (se BALANCE_FIXED)
input bool               DT_CompoundDaily     = true;               // Usar juros compostos diários
input bool               DT_CompoundOnTarget  = true;               // Só compor se bateu meta anterior

input group "=== META DIÁRIA - COMPORTAMENTO AUTOMÁTICO ==="
input bool               DT_CloseOnTarget     = true;               // FECHAR operações ao atingir meta
input bool               DT_BlockAfterTarget  = true;               // BLOQUEAR novas operações após meta
input bool               DT_OnlyInTimeWindow  = true;               // Meta só vale dentro do horário
input double             DT_TargetTolerance   = 0.05;               // Tolerância % (0.05 = fecha com 0.95%)

input group "=== META DIÁRIA - HORÁRIOS ==="
input int                DT_StartHour         = 9;                  // Hora de início da operação
input int                DT_StartMinute       = 0;                  // Minuto de início
input int                DT_EndHour           = 17;                 // Hora de fim da operação
input int                DT_EndMinute         = 30;                 // Minuto de fim
input int                DT_AggressiveMinutes = 60;                 // Minutos antes do fim para modo agressivo
input EndOfDayBehavior   DT_EndOfDayAction    = EOD_AGGRESSIVE_PUSH;// Ação ao final do dia

input group "=== META DIÁRIA - MODO AGRESSIVO ==="
input bool               DT_EnableAggressive  = true;               // Ativar modo agressivo
input AggressiveLevel    DT_MaxAggressiveLevel= AGG_LEVEL_5;        // Nível máximo de agressividade
input double             DT_AggLotMultiplier  = 2.0;                // Multiplicador de lote por nível
input double             DT_AggThresholdReduce= 0.10;               // Redução de threshold por nível
input bool               DT_AggIgnoreFilters  = true;               // Ignorar filtros no nível máximo
input bool               DT_AggAllowAllIn     = true;               // Permitir all-in se necessário
input int                DT_AggMaxPositions   = 10;                 // Máximo de posições simultâneas
input double             DT_AggMaxRiskPercent = 100.0;              // Risco máximo % (100 = toda banca)

input group "=== META DIÁRIA - OPERAÇÃO OBRIGATÓRIA ==="
input bool               DT_ForceDailyTrade   = true;               // FORÇAR operação diária (obrigatório)
input int                DT_ForceAfterMinutes = 120;                // Forçar após N minutos sem trade
input int                DT_ForceAggressiveMin= 60;                 // Entra agressivo N min sem trade
input double             DT_ForceMinThreshold = 0.3;                // Threshold mínimo forçado (30%)
input int                DT_ForceMinSignals   = 1;                  // Mínimo de sinais forçado
input bool               DT_ForceIgnoreFilters= true;               // Ignorar filtros quando forçado
input double             DT_ForceProgressiveReduce = 0.05;          // Redução progressiva a cada 30min

input group "=== META DIÁRIA - PROTEÇÃO DE LUCRO ==="
input DailyProfitProtection DT_ProfitProtection = PROFIT_PROT_OFF; // Proteção após meta
input double             DT_LockProfitPercent = 50.0;               // % do lucro a proteger
input double             DT_TrailProfitStep   = 0.25;               // Step do trailing de lucro em %
input bool               DT_StopOnExtraProfit = false;              // Parar se lucro extra > meta

input group "=== META DIÁRIA - CONTROLE DE PERDA ==="
input double             DT_MaxDailyLoss      = 50.0;               // Perda máxima diária em % (50 = metade)
input bool               DT_StopOnMaxLoss     = false;              // Parar se atingir perda máxima
input bool               DT_RecoverOnAggressive = true;             // Tentar recuperar no modo agressivo
input double             DT_RecoveryMultiplier= 1.5;                // Multiplicador para recuperação

input group "=== META DIÁRIA - ESTATÍSTICAS ==="
input bool               DT_SaveDailyStats    = true;               // Salvar estatísticas diárias
input bool               DT_ShowDailyPanel    = true;               // Mostrar painel de meta diária
input bool               DT_AlertOnTarget     = true;               // Alertar ao atingir meta
input bool               DT_AlertOnAggressive = true;               // Alertar ao entrar em modo agressivo

//============================= LIMITES & DD GUARD ===========================//
input group "=== LIMITES E PROTEÇÃO ==="
input double   DailyLossLimitPercent = 3.0;
input int      MaxTradesPerDay       = 8;

input double   MaxEquityDDPercent    = 20.0;
input bool     DD_CloseAllOnBreach   = true;
input int      DD_CooldownMinutes    = 60;
input bool     UseRiskThrottle       = true;
input double   RT_L1                 = 5.0;   input double RT_F1=0.75;
input double   RT_L2                 = 10.0;  input double RT_F2=0.50;
input double   RT_L3                 = 15.0;  input double RT_F3=0.25;

//=================== FILTRO DE FALHA RÁPIDA ====================//
input group "=== FILTRO DE FALHA RÁPIDA ==="
input bool     UseFailedEntryFilter   = true;
input int      FailedEntryBars        = 3;
input int      FailedEntryCooldownMin = 30;

//=================== FILTRO QQE (ADICIONAL) ====================//
input group "=== FILTRO QQE ==="
input bool     UseQQEFilter           = true;
input int      QQE_RSI_Period         = 14;
input int      QQE_SmoothingFactor    = 5;

//=================== DETECTOR DE NOTÍCIAS (COMPORTAMENTAL) ====================//
input group "=== DETECTOR DE NOTÍCIAS ==="
input bool     UseNewsDetector        = true;
input bool     News_UseStdDev         = true;
input double   News_StdDev_Ratio      = 2.8;
input double   News_BodyToRange_Ratio = 0.5;
input int      News_Lookback_Window   = 2;

input string   News_Old_Logic_Header  = "--- Lógica Antiga (Ratio Simples) ---";
input double   News_CandleToAvg_Ratio = 3.0;
input double   News_VolumeToAvg_Ratio = 2.5;
input int      News_AvgLookback       = 20;

//============================= TENDÊNCIA (MTF) ==============================//
input group "=== TENDÊNCIA MTF ==="
input bool     UseTrendFilter        = true;
input bool     Trend_Strict_Entries  = false;
input ENUM_TIMEFRAMES Trend_TF1      = PERIOD_H1;
input ENUM_TIMEFRAMES Trend_TF2      = PERIOD_H4;
input bool     Trend_UseTF2          = true;
input double   Trend_TF2_Weight      = 0.4;
input int      Trend_ADX_Period      = 14;
input double   Trend_ADX_Thr         = 18.0;
input int      Trend_EMA_Fast        = 50;
input int      Trend_EMA_Slow        = 200;
input double   TrendScore_Thr        = 0.60;

input bool     Trend_UsePullbackEntry = false;
input int      Trend_Pull_EMA        = 20;
input double   Trend_Pull_ATRMultMax = 0.8;
input bool     Trend_AllowBreakout   = true;
input int      Trend_Donchian_Lookback= 20;

//============================= HEDGE / ENSEMBLE =============================//
input group "=== HEDGE E ENSEMBLE ==="
input bool     AllowLong             = true;
input bool     AllowShort            = true;
input bool     CloseOnFlip           = true;

input PrecMode PrecisionMode         = MODE_BALANCED;
input int      MinAgreeSignals       = 3;
input bool     UseEntryTF            = false;
input ENUM_TIMEFRAMES EntryTF        = PERIOD_M5;
input int      EntryROC_Period       = 6;
input double   EntryROC_Threshold    = 0.0004;

input bool     UseStructureLock      = false;
input int      MinATRPoints          = 60;
input double   MinATRtoSpread        = 4.0;

input bool     Hedge_Enable          = true;
input bool     Hedge_AllowDoubleStart = true;
input bool     Hedge_OpenOnOppSignal = true;
input bool     Hedge_OpenOnAdverse   = true;
input bool     Hedge_Adverse_UseATR  = true;
input double   Hedge_Adverse_ATRMult = 1.0;
input int      Hedge_Adverse_Points  = 300;
input bool     Hedge_CloseOnNetProfit = true;
input double   Hedge_NetTP_Percent   = 0.20;
input double   Hedge_NetTP_Money     = 0.0;

//============================= MARTINGALE / GRID ============================//
input group "=== MARTINGALE / GRID ==="
input MGMode   MG_Mode               = MG_GRID;
input double   MG_Multiplier         = 1.6;
input int      MG_MaxSteps           = 3;
input double   MG_MaxRiskPercent     = 6.0;
input bool     MG_ResetOnProfit      = true;
input bool     MG_ResetDaily         = true;
input bool     MG_RespectLossPause   = false;

input bool     MG_Grid_UseATR        = true;
input double   MG_Grid_ATRMult       = 1.2;
input int      MG_Grid_StepPoints    = 250;
input double   MG_Grid_MaxRiskPercentSum=12.0;
input bool     MG_Grid_RespectStructure=false;
input bool     MG_Grid_DisableFlipClose=true;

input double   MG_Grid_TargetATRMult = 1.3;
input double   MG_Grid_MaxAdvATRMult = 18.0;
input int      MG_Grid_TargetPoints  = 70;
input int      MG_Grid_MaxAdversePoints=1500;

input bool     MG_Grid_TrendAware    = true;
input int      MG_Grid_MaxAdds_InTrend  = 4;
input int      MG_Grid_MaxAdds_Counter  = 1;
input double   MG_Grid_VolMult_InTrend  = 1.7;
input double   MG_Grid_VolMult_Counter  = 1.2;
input double   MG_Grid_ATRMult_InTrend  = 1.0;
input double   MG_Grid_ATRMult_Counter  = 1.6;

input group "=== GRID EM MODO NOTÍCIA ==="
input int      MG_Grid_News_MaxAdds_InTrend  = 5;
input int      MG_Grid_News_MaxAdds_Counter  = 0;
input double   MG_Grid_News_VolMult_InTrend  = 1.8;
input double   MG_Grid_News_VolMult_Counter  = 1.0;
input double   MG_Grid_News_ATRMult_InTrend  = 0.8;
input double   MG_Grid_News_ATRMult_Counter  = 3.0;

//============================= ENSEMBLE PESOS ==============================//
input group "=== PESOS DO ENSEMBLE ==="
input double   W_MAcross=1.0, W_RSI=1.0, W_BBands=1.0, W_Supertrend=1.3, W_AMA=1.2, W_Heikin=1.0, W_VWAP=1.1, W_Momentum=1.0, W_QQE=1.5;
input int      EMA_Fast=20, EMA_Slow=50, RSI_Period=14, RSI_Low=30, RSI_High=70, BB_Period=20; 
input double   BB_Dev=2.0;
input int      ST_ATR_Period=10; 
input double   ST_Mult=3.0;
input int      AMA_ER_Period=10, AMA_Fast=2, AMA_Slow=30; 
input double   AMA_ATR_FilterMult=3.0;
input ENUM_TIMEFRAMES VWAP_TF=PERIOD_M1; 
input bool     VWAP_UseRealVolume=false;
input int      ROC_Period=12; 
input double   ROC_Threshold=0.002;

input group "=== ANCHOR (CORRELAÇÃO) ==="
input bool     UseAnchor=false; 
input string   AnchorSymbol="GC"; 
input ENUM_TIMEFRAMES AnchorTF=PERIOD_M15; 
input int      BasisLookback=100; 
input double   ZEntry=0.8;
input int      Anchor_EMA_Fast=20, Anchor_EMA_Slow=50; 
input double   AnchorBoost=0.12, AnchorPenalty=0.50;

input double   ThrBoost_Anchor=0.03, ThrBoost_Struct=0.03;

//============================= PAINEL VISUAL ================================//
input group "=== PAINEL VISUAL ==="
input bool     ShowPanel             = true;
input int      PanelX                = 10;
input int      PanelY                = 25;
input int      PanelWidth            = 550;
input color    PanelBgColor          = C'15,15,25';
input color    PanelBgColor2         = C'25,25,40';
input color    PanelTextColor        = clrWhite;
input color    PanelHeaderColor      = clrGold;
input color    PanelBuyColor         = C'0,255,127';
input color    PanelSellColor        = C'255,80,80';
input color    PanelNeutralColor     = C'128,128,128';
input color    PanelAccentColor      = C'100,149,237';
input int      PanelFontSize         = 9;
input string   PanelFontName         = "Consolas";

input long     Magic=20250815;

#endif // __MAABOT_INPUTS_MQH__
//+------------------------------------------------------------------+
