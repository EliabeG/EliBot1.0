//+------------------------------------------------------------------+
//|                                         MAAbot_v2_Visual.mq5     |
//|   XAUUSD M15 - Ensemble + Trend-Aware + TP/SL Precisos + Hedge   |
//|   v2.5.1 - META DIÁRIA APRIMORADA + TRAILING AVANÇADO            |
//|                                     Autor: Eliabe N Oliveira     |
//|                                      Data: 17/12/2025            |
//+------------------------------------------------------------------+
//| NOVIDADES v2.5.1:                                                 |
//| - Monitoramento de saldo INDEPENDENTE a cada tick                |
//| - Fechamento AUTOMÁTICO ao atingir meta (garante 1% exato)       |
//| - Bloqueio TOTAL de operações após meta (só opera amanhã)        |
//| - Gráfico de backtest: linha crescente 1% ao dia                 |
//| - Respeito total ao horário de operação definido                 |
//+------------------------------------------------------------------+
#property strict
#property description "XAUUSD M15 — v2.5.1 - Meta Diária Aprimorada"
#property version  "2.51"

//+------------------------------------------------------------------+
//|                    INCLUDES - MÓDULOS DO EA                       |
//+------------------------------------------------------------------+
#include <Trade/Trade.mqh>

// Módulos Base
#include <MAAbot/Enums.mqh>
#include <MAAbot/Inputs.mqh>
#include <MAAbot/Structs.mqh>
#include <MAAbot/Globals.mqh>

// Módulos de Funcionalidade
#include <MAAbot/Utils.mqh>
#include <MAAbot/Indicators.mqh>
#include <MAAbot/RiskManagement.mqh>
#include <MAAbot/Signals.mqh>
#include <MAAbot/Trend.mqh>
#include <MAAbot/Filters.mqh>
#include <MAAbot/Basket.mqh>
#include <MAAbot/Grid.mqh>
#include <MAAbot/Hedge.mqh>
#include <MAAbot/TradeManagement.mqh>
#include <MAAbot/TradeExecution.mqh>
#include <MAAbot/Panel.mqh>

//+------------------------------------------------------------------+
//|                    OBJETO DE TRADE GLOBAL                         |
//+------------------------------------------------------------------+
CTrade trade;

//+------------------------------------------------------------------+
//|                           OnInit                                 |
//+------------------------------------------------------------------+
int OnInit() {
   if(!SymbolSelect(InpSymbol, true)) { 
      Print("Erro: nao foi possivel selecionar ", InpSymbol); 
      return INIT_FAILED; 
   }
   
   trade.SetExpertMagicNumber(Magic); 
   trade.SetDeviationInPoints(DeviationPoints);
   
   // Inicializar handles de indicadores
   hEMAfast = iMA(InpSymbol, InpTF, EMA_Fast, 0, MODE_EMA, PRICE_CLOSE);
   hEMAslow = iMA(InpSymbol, InpTF, EMA_Slow, 0, MODE_EMA, PRICE_CLOSE);
   hRSI = iRSI(InpSymbol, InpTF, RSI_Period, PRICE_CLOSE);
   hBB = iBands(InpSymbol, InpTF, BB_Period, 0, BB_Dev, PRICE_CLOSE);
   hATR = iATR(InpSymbol, InpTF, ATR_Period);
   hATR_ST_INP = iATR(InpSymbol, InpTF, ST_ATR_Period);
   hATR_ST_TF1 = iATR(InpSymbol, Trend_TF1, ST_ATR_Period);
   
   if(Trend_UseTF2) hATR_ST_TF2 = iATR(InpSymbol, Trend_TF2, ST_ATR_Period);
   
   if(UseQQEFilter) {
      hQQE_RSI = iRSI(InpSymbol, InpTF, QQE_RSI_Period, PRICE_CLOSE);
      if(hQQE_RSI == INVALID_HANDLE) Print("AVISO: Nao foi possivel criar handle para QQE RSI");
   }
   
   hTF1_EMAf = iMA(InpSymbol, Trend_TF1, Trend_EMA_Fast, 0, MODE_EMA, PRICE_CLOSE);
   hTF1_EMAs = iMA(InpSymbol, Trend_TF1, Trend_EMA_Slow, 0, MODE_EMA, PRICE_CLOSE);
   
   if(Trend_UseTF2) { 
      hTF2_EMAf = iMA(InpSymbol, Trend_TF2, Trend_EMA_Fast, 0, MODE_EMA, PRICE_CLOSE);
      hTF2_EMAs = iMA(InpSymbol, Trend_TF2, Trend_EMA_Slow, 0, MODE_EMA, PRICE_CLOSE); 
   }
   
   hADX_TF1 = iADX(InpSymbol, Trend_TF1, Trend_ADX_Period);
   if(Trend_UseTF2) hADX_TF2 = iADX(InpSymbol, Trend_TF2, Trend_ADX_Period);
   
   hEMAPull = iMA(InpSymbol, InpTF, Trend_Pull_EMA, 0, MODE_EMA, PRICE_CLOSE);
   
   lastBarTime = iTime(InpSymbol, InpTF, 0);
   GridReset(+1); GridReset(-1);
   
   eqPeak = AccountInfoDouble(ACCOUNT_EQUITY); 
   ddPausedUntil = 0;
   
   if(hEMAfast == INVALID_HANDLE || hEMAslow == INVALID_HANDLE || 
      hRSI == INVALID_HANDLE || hBB == INVALID_HANDLE || hATR == INVALID_HANDLE) {
      Print("Erro ao criar indicadores!");
      return INIT_FAILED;
   }
   
   // Inicializar indicadores do Trailing Stop Avançado
   InitTrailingIndicators();

   // Inicializar sistema de Meta Diária (Porcentagem ao Dia)
   InitDailyTargetManager();

   if(ShowPanel) {
      Signals S; ZeroMemory(S);
      UpdatePanel(S);
   }

   Print("=============================================================");
   Print("     MAABot v2.5.1 - META DIÁRIA APRIMORADA                  ");
   Print("=============================================================");
   Print(" Estrategias: MA Cross, RSI, BBands, SuperTrend, AMA/KAMA,");
   Print("              Heikin Ashi, VWAP, Momentum, QQE");
   Print("=============================================================");
   Print(" AllowLong=", AllowLong, " | AllowShort=", AllowShort);
   Print(" MinAgreeSignals=", MinAgreeSignals, " | Mode=", EnumToString(PrecisionMode));
   Print("=============================================================");
   Print(" TRAILING STOP: ", EnumToString(AdvTrail_Mode));
   Print(" PROFIT LOCK: ", EnumToString(ProfitLock_Mode));
   Print("=============================================================");
   if(DT_Mode != DTARGET_OFF) {
      Print(" >>>>>> SISTEMA META DIÁRIA v2.5.1 <<<<<<");
      Print(" META DIÁRIA: ", EnumToString(DT_Mode));
      Print(" META: ", DoubleToString(DT_TargetPercent, 2), "% ao dia");
      Print(" JUROS COMPOSTOS: ", DT_CompoundDaily ? "ATIVADO" : "DESATIVADO");
      Print(" MODO AGRESSIVO: ", DT_EnableAggressive ? "ATIVADO" : "DESATIVADO");
      Print(" ----------------------------------------");
      Print(" [NOVO] Monitoramento independente: ATIVO");
      Print(" [NOVO] Fecha ao atingir meta: ", DT_CloseOnTarget ? "SIM" : "NAO");
      Print(" [NOVO] Bloqueia após meta: ", DT_BlockAfterTarget ? "SIM" : "NAO");
      Print(" [NOVO] Horário: ", DT_StartHour, ":", DT_StartMinute, " - ", DT_EndHour, ":", DT_EndMinute);
      Print("=============================================================");
   }

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//|                           OnDeinit                               |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   // Finalizar sistema de Meta Diária
   DeinitDailyTargetManager();

   // Liberar indicadores do Trailing Stop Avançado
   DeinitTrailingIndicators();

   // Liberar handles de indicadores
   if(hEMAfast != INVALID_HANDLE) IndicatorRelease(hEMAfast);
   if(hEMAslow != INVALID_HANDLE) IndicatorRelease(hEMAslow);
   if(hRSI != INVALID_HANDLE) IndicatorRelease(hRSI);
   if(hBB != INVALID_HANDLE) IndicatorRelease(hBB);
   if(hATR != INVALID_HANDLE) IndicatorRelease(hATR);
   if(hATR_ST_INP != INVALID_HANDLE) IndicatorRelease(hATR_ST_INP);
   if(hATR_ST_TF1 != INVALID_HANDLE) IndicatorRelease(hATR_ST_TF1);
   if(hATR_ST_TF2 != INVALID_HANDLE) IndicatorRelease(hATR_ST_TF2);
   if(hTF1_EMAf != INVALID_HANDLE) IndicatorRelease(hTF1_EMAf);
   if(hTF1_EMAs != INVALID_HANDLE) IndicatorRelease(hTF1_EMAs);
   if(hTF2_EMAf != INVALID_HANDLE) IndicatorRelease(hTF2_EMAf);
   if(hTF2_EMAs != INVALID_HANDLE) IndicatorRelease(hTF2_EMAs);
   if(hADX_TF1 != INVALID_HANDLE) IndicatorRelease(hADX_TF1);
   if(hADX_TF2 != INVALID_HANDLE) IndicatorRelease(hADX_TF2);
   if(hEMAPull != INVALID_HANDLE) IndicatorRelease(hEMAPull);
   if(hAnchorEMAfast != INVALID_HANDLE) IndicatorRelease(hAnchorEMAfast);
   if(hAnchorEMAslow != INVALID_HANDLE) IndicatorRelease(hAnchorEMAslow);
   if(hQQE_RSI != INVALID_HANDLE) IndicatorRelease(hQQE_RSI);
   
   DeletePanelObjects();
   Print("MAABot v2.5.1 finalizado. Razao: ", reason);
}

//+------------------------------------------------------------------+
//|                           OnTick                                 |
//+------------------------------------------------------------------+
void OnTick() {
   if(Symbol() != InpSymbol) return;

   datetime now = TimeCurrent();
   double eq = AccountInfoDouble(ACCOUNT_EQUITY);

   if(eqPeak <= 0.0 || eq > eqPeak) eqPeak = eq;

   //=====================================================================
   // PONTO 1: MONITORAMENTO DE SALDO INDEPENDENTE A CADA TICK
   // Esta chamada é INDEPENDENTE da estratégia de stops!
   // Verifica o saldo a cada tick e fecha automaticamente ao atingir meta
   //=====================================================================
   if(MonitorBalanceOnTick(trade)) {
      // Meta atingida! Trading bloqueado para hoje
      Signals S; ZeroMemory(S);
      g_statusMsg = "META ATINGIDA - Operações encerradas";
      UpdatePanel(S);
      return; // Não processa mais nada - só opera amanhã
   }

   // PONTO 2: Se trading está bloqueado após meta, não faz nada
   if(IsTradingBlockedAfterTarget()) {
      Signals S; ZeroMemory(S);
      g_statusMsg = "META BATIDA - Aguardando próximo dia";
      UpdatePanel(S);
      return;
   }
   //=====================================================================

   g_dailyPL = TodayPL();
   g_currentDD = CurrentDDPercent();
   g_todayTrades = TodayTradesOpened();
   g_statusMsg = "";
   g_blockReasonBuy = "";
   g_blockReasonSell = "";

   if(!DailyRiskOK()) {
      Signals S; ZeroMemory(S); GetSignals(S);
      UpdatePanel(S);
      return;
   }
   
   if(!SpreadOK()) {
      g_statusMsg = "Spread alto: " + IntegerToString(g_currentSpread);
      Signals S; ZeroMemory(S); GetSignals(S);
      UpdatePanel(S);
      return;
   }
   
   bool isTradingHours = InTradingWindow(now);
   
   CheckForFailedEntries();
   DetectNewsBehavior();
   g_trendDir = TrendDirection(g_trendScore, g_trending);
   
   GridInitIfNeed(+1); GridInitIfNeed(-1);
   ManagePerTrade(trade);
   
   Signals S; ZeroMemory(S); 
   if(!GetSignals(S)) {
      g_statusMsg = "Erro ao obter sinais";
      UpdatePanel(S);
      return;
   }
   
   double pL = 0.0, pS = 0.0; 
   Probabilities(S, pL, pS);
   g_probLong = pL; g_probShort = pS;
   g_signalsAgreeL = CountAgree(S, +1);
   g_signalsAgreeS = CountAgree(S, -1);
   
   int anchorSig = AnchorSignal();
   double thrL = EffThr(S, +1, anchorSig);
   double thrS = EffThr(S, -1, anchorSig);
   g_thrL = thrL; g_thrS = thrS;
   
   int atrpts = 0; 
   if(!VolQualityOK(atrpts)) {
      UpdatePanel(S);
      return;
   }
   
   if(MG_Mode == MG_GRID) {
      if(GridTPHit(+1)) { CloseBasket(+1, trade); GridReset(+1); g_lastAction = "Grid TP Buy"; g_lastActionTime = now; }
      if(GridTPHit(-1)) { CloseBasket(-1, trade); GridReset(-1); g_lastAction = "Grid TP Sell"; g_lastActionTime = now; }
      if(GridStopHit(+1)) { CloseBasket(+1, trade); GridReset(+1); g_lastAction = "Grid SL Buy"; g_lastActionTime = now; }
      if(GridStopHit(-1)) { CloseBasket(-1, trade); GridReset(-1); g_lastAction = "Grid SL Sell"; g_lastActionTime = now; }
   }
   
   HedgeRecoveryCheck(trade);
   
   if(MG_Mode == MG_GRID) {
      if(HasBasket(+1)) GridTryAdd(S, +1, trade);
      if(HasBasket(-1)) GridTryAdd(S, -1, trade);
   }
   
   if(CloseOnFlip && MG_Mode != MG_GRID) { 
      if(pS >= thrS && pS > pL) { CloseBasket(+1, trade); g_lastAction = "Flip Buy"; g_lastActionTime = now; }
      if(pL >= thrL && pL > pS) { CloseBasket(-1, trade); g_lastAction = "Flip Sell"; g_lastActionTime = now; }
   }
   else if(CloseOnFlip && MG_Mode == MG_GRID && !MG_Grid_DisableFlipClose) {
      if(pS >= thrS && pS > pL) { CloseBasket(+1, trade); GridReset(+1); g_lastAction = "Flip Buy Grid"; g_lastActionTime = now; }
      if(pL >= thrL && pL > pS) { CloseBasket(-1, trade); GridReset(-1); g_lastAction = "Flip Sell Grid"; g_lastActionTime = now; } 
   }
   
   if(isTradingHours) {
      // ======== INTEGRAÇÃO META DIÁRIA (PORCENTAGEM AO DIA) ========
      // Verifica se pode abrir novo trade baseado na meta diária
      bool canOpenDT = CanOpenNewTrade();

      // Ajusta thresholds se em modo agressivo
      double thrL_adj = thrL;
      double thrS_adj = thrS;
      int minSignals_adj = MinAgreeSignals;
      bool ignoreFilters = false;

      if(IsAggressiveModeActive()) {
         double aggMult = GetAggressiveThresholdMultiplier();
         thrL_adj = thrL * aggMult;
         thrS_adj = thrS * aggMult;
         minSignals_adj = GetAggressiveMinSignals();
         ignoreFilters = ShouldIgnoreFilters();

         // Atualiza status no painel
         g_statusMsg = GetDailyStatusText();
      }

      // Usa os valores ajustados para decisão
      bool wantBuy = AllowLong && (g_signalsAgreeL >= minSignals_adj) && (pL >= thrL_adj);
      bool wantSell = AllowShort && (g_signalsAgreeS >= minSignals_adj) && (pS >= thrS_adj);

      // Structure lock (pode ser ignorado no modo agressivo)
      if(UseStructureLock && !ignoreFilters) {
         wantBuy = wantBuy && StructureOK(S, +1);
         wantSell = wantSell && StructureOK(S, -1);
      }

      // Bloqueia se meta diária não permite
      if(!canOpenDT) {
         wantBuy = false;
         wantSell = false;
         if(g_blockReasonBuy == "") g_blockReasonBuy = GetDailyStatusText();
         if(g_blockReasonSell == "") g_blockReasonSell = GetDailyStatusText();
      }

      if(!wantBuy && AllowLong && canOpenDT) {
         if(g_signalsAgreeL < minSignals_adj) g_blockReasonBuy = StringFormat("Sinais %d < %d", g_signalsAgreeL, minSignals_adj);
         else if(pL < thrL_adj) g_blockReasonBuy = StringFormat("Prob %.0f%% < %.0f%%", pL*100, thrL_adj*100);
         else if(UseStructureLock && !ignoreFilters && !StructureOK(S, +1)) g_blockReasonBuy = "StructureLock";
      }

      if(!wantSell && AllowShort && canOpenDT) {
         if(g_signalsAgreeS < minSignals_adj) g_blockReasonSell = StringFormat("Sinais %d < %d", g_signalsAgreeS, minSignals_adj);
         else if(pS < thrS_adj) g_blockReasonSell = StringFormat("Prob %.0f%% < %.0f%%", pS*100, thrS_adj*100);
         else if(UseStructureLock && !ignoreFilters && !StructureOK(S, -1)) g_blockReasonSell = "StructureLock";
      }

      if(Hedge_Enable && Hedge_AllowDoubleStart) {
         if(wantBuy && !HasBasket(+1)) TryOpen(+1, S, pL, thrL_adj, now, trade);
         if(wantSell && !HasBasket(-1)) TryOpen(-1, S, pS, thrS_adj, now, trade);
      }
      else {
         if(wantBuy && wantSell) {
            if(pL >= pS && !HasBasket(+1)) TryOpen(+1, S, pL, thrL_adj, now, trade);
            else if(pS > pL && !HasBasket(-1)) TryOpen(-1, S, pS, thrS_adj, now, trade);
         }
         else if(wantBuy && !HasBasket(+1)) TryOpen(+1, S, pL, thrL_adj, now, trade);
         else if(wantSell && !HasBasket(-1)) TryOpen(-1, S, pS, thrS_adj, now, trade);
      }

      if(Hedge_Enable) {
         if(Hedge_OpenOnOppSignal) {
            if(HasBasket(+1) && wantSell && !HasBasket(-1)) TryOpen(-1, S, pS, thrS_adj, now, trade);
            if(HasBasket(-1) && wantBuy && !HasBasket(+1)) TryOpen(+1, S, pL, thrL_adj, now, trade);
         }
         if(Hedge_OpenOnAdverse) {
            if(HasBasket(+1) && !HasBasket(-1) && AdverseTrigger(+1)) TryOpen(-1, S, 1.0, 0.0, now, trade);
            if(HasBasket(-1) && !HasBasket(+1) && AdverseTrigger(-1)) TryOpen(+1, S, 1.0, 0.0, now, trade);
         }
      }
   }
   
   UpdatePanel(S);
}
//+------------------------------------------------------------------+
