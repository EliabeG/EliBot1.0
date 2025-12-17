//+------------------------------------------------------------------+
//|                                                 TrailingStop.mqh |
//|   MAAbot v2.4.0 - Trailing Stop Baseado no Estudo Acadêmico      |
//|                                     Autor: Eliabe N Oliveira     |
//+------------------------------------------------------------------+
//| Referência: "Otimização Algorítmica e Precisão Estocástica na   |
//| Formulação de Estratégias de Trailing Stop: Uma Análise Exaustiva"|
//|                                                                  |
//| Implementação completa das estratégias do estudo:                |
//| - Chandelier Exit (Seção 3.2)                                    |
//| - Market Structure com Buffer ATR (Seção 4.2)                    |
//| - Step Trailing (Seção 2.2.2)                                    |
//| - Parabolic SAR (Seção 5)                                        |
//| - Ativação Atrasada (Seção 7.2)                                  |
//| - Híbrido Inteligente (Seção 7.1)                                |
//| - Adaptação de Regime (Seção 6)                                  |
//+------------------------------------------------------------------+
#ifndef __MAABOT_TRAILINGSTOP_MQH__
#define __MAABOT_TRAILINGSTOP_MQH__

#include <Trade/Trade.mqh>
#include "Inputs.mqh"
#include "Globals.mqh"
#include "Utils.mqh"

//===================== HANDLES DE INDICADORES ========================//
int hPSAR = INVALID_HANDLE;
int hADX_Trail = INVALID_HANDLE;

//===================== ESTRUTURA DE ESTADO DO TRAILING ================//
// Armazena informações de cada posição para trailing preciso
struct TrailingState {
   ulong    ticket;              // Ticket da posição
   double   entryPrice;          // Preço de entrada
   double   initialSL;           // SL inicial
   double   initialRiskPts;      // Risco inicial em pontos
   double   highestPrice;        // Highest High desde entrada (BUY)
   double   lowestPrice;         // Lowest Low desde entrada (SELL)
   double   lastTrailStop;       // Último stop calculado pelo trailing
   double   lastStepPrice;       // Último preço de referência do step
   double   mfePrice;            // Maximum Favorable Excursion (preço)
   double   maePrice;            // Maximum Adverse Excursion (preço)
   bool     trailingActivated;   // Trailing já foi ativado?
   bool     breakEvenReached;    // Break-even já atingido?
   int      currentRegime;       // Regime detectado (0=range, 1=trend, 2=strong, 3=volatile)
   datetime lastUpdate;          // Última atualização
   int      barsInTrade;         // Barras desde entrada
};

// Array global de estados
TrailingState g_trailStates[];

//===================== INICIALIZAÇÃO/DESINICIALIZAÇÃO ================//
void InitTrailingIndicators() {
   // Parabolic SAR
   if(hPSAR == INVALID_HANDLE)
      hPSAR = iSAR(InpSymbol, InpTF, PSAR_Step, PSAR_Maximum);

   // ADX para detecção de regime
   if(hADX_Trail == INVALID_HANDLE)
      hADX_Trail = iADX(InpSymbol, InpTF, 14);

   ArrayFree(g_trailStates);
}

void DeinitTrailingIndicators() {
   if(hPSAR != INVALID_HANDLE) { IndicatorRelease(hPSAR); hPSAR = INVALID_HANDLE; }
   if(hADX_Trail != INVALID_HANDLE) { IndicatorRelease(hADX_Trail); hADX_Trail = INVALID_HANDLE; }
   ArrayFree(g_trailStates);
}

//===================== GERENCIAMENTO DE ESTADOS =======================//
int FindTrailingState(ulong ticket) {
   for(int i = 0; i < ArraySize(g_trailStates); i++) {
      if(g_trailStates[i].ticket == ticket) return i;
   }
   return -1;
}

void AddTrailingState(ulong ticket, double entry, double sl, int type) {
   int idx = FindTrailingState(ticket);
   if(idx >= 0) return;

   int newSize = ArraySize(g_trailStates) + 1;
   ArrayResize(g_trailStates, newSize);

   TrailingState state;
   ZeroMemory(state);
   state.ticket = ticket;
   state.entryPrice = entry;
   state.initialSL = sl;
   state.initialRiskPts = (sl > 0) ? MathAbs(entry - sl) / Pt() : StopLossPoints;
   state.highestPrice = entry;
   state.lowestPrice = entry;
   state.lastTrailStop = sl;
   state.lastStepPrice = entry;
   state.mfePrice = entry;
   state.maePrice = entry;
   state.trailingActivated = false;
   state.breakEvenReached = false;
   state.currentRegime = 0;
   state.lastUpdate = TimeCurrent();
   state.barsInTrade = 0;

   g_trailStates[newSize-1] = state;
}

void RemoveTrailingState(ulong ticket) {
   int idx = FindTrailingState(ticket);
   if(idx < 0) return;
   int last = ArraySize(g_trailStates) - 1;
   if(idx != last) g_trailStates[idx] = g_trailStates[last];
   ArrayResize(g_trailStates, last);
}

void CleanupClosedPositions() {
   for(int i = ArraySize(g_trailStates) - 1; i >= 0; i--) {
      if(!PositionSelectByTicket(g_trailStates[i].ticket)) {
         RemoveTrailingState(g_trailStates[i].ticket);
      }
   }
}

//===================== DETECÇÃO DE REGIME (Seção 6) ===================//
// Detecta automaticamente se estamos em tendência, range ou volatilidade alta
int DetectMarketRegime(double &adxValue) {
   if(Trail_Regime != REGIME_AUTO) {
      adxValue = 0;
      return (int)Trail_Regime;
   }

   if(hADX_Trail == INVALID_HANDLE) return 0;

   double adx[1];
   if(CopyBuffer(hADX_Trail, 0, 0, 1, adx) <= 0) return 0;
   adxValue = adx[0];

   // Regime baseado em ADX
   if(adx[0] >= Regime_ADX_StrongThreshold) return 2;      // Tendência Forte/Parabólica
   if(adx[0] >= Regime_ADX_TrendThreshold) return 1;       // Tendência Normal
   return 0;                                                // Range/Consolidação
}

// Obtém multiplicador ATR baseado no regime e tipo de ativo
double GetRegimeMultiplier(int regime) {
   double baseMult = 3.0;

   // Multiplicador base por tipo de ativo (Seção 3.2.1)
   switch(Trail_AssetType) {
      case ASSET_CONSERVATIVE:  baseMult = 2.75; break;  // 2.5-3.0
      case ASSET_VOLATILE:      baseMult = 3.75; break;  // 3.5-4.0
      case ASSET_INTRADAY:      baseMult = 1.75; break;  // 1.5-2.0
      case ASSET_GOLD_XAUUSD:   baseMult = 3.25; break;  // 3.0-3.5 (otimizado)
   }

   // Ajuste por regime (Seção 6.1)
   switch(regime) {
      case 0: return baseMult * Regime_RangeMultiplier;      // Range: mais apertado
      case 1: return baseMult * Regime_TrendMultiplier;      // Tendência: mais solto
      case 2: return baseMult * Regime_VolatileMultiplier;   // Forte/Volátil: ainda mais solto
      default: return baseMult;
   }
}

//===================== CHANDELIER EXIT (Seção 3.2) ====================//
// Fórmula: CE_long = HH_n - (ATR_n × M)
// "A superioridade do Chandelier Exit reside na sua capacidade de reagir
// instantaneamente a novos topos"
double CalcChandelierExit(int type, double atr, int regime) {
   MqlRates r[];
   ArraySetAsSeries(r, true);
   int bars = Chandelier_Period + 2;
   if(CopyRates(InpSymbol, InpTF, 0, bars, r) < bars) return 0.0;

   // Seleciona multiplicador baseado no regime
   double mult;
   switch(regime) {
      case 0: mult = Chandelier_ATRMult_Range; break;
      case 1: mult = Chandelier_ATRMult_Trend; break;
      case 2:
      case 3: mult = Chandelier_ATRMult_Volatile; break;
      default: mult = Chandelier_ATRMult_Trend;
   }

   double chandelierDist = atr * mult;

   if(type == POSITION_TYPE_BUY) {
      // Highest High dos últimos N períodos
      double hh = r[1].high;
      for(int i = 1; i <= Chandelier_Period; i++) {
         double val = Chandelier_UseClose ? r[i].close : r[i].high;
         if(val > hh) hh = val;
      }
      return hh - chandelierDist;
   }
   else {
      // Lowest Low dos últimos N períodos
      double ll = r[1].low;
      for(int i = 1; i <= Chandelier_Period; i++) {
         double val = Chandelier_UseClose ? r[i].close : r[i].low;
         if(val < ll) ll = val;
      }
      return ll + chandelierDist;
   }
}

//===================== MARKET STRUCTURE (Seção 4.2) ===================//
// "A colocação mais lógica e precisa para um trailing stop é logo abaixo
// do último Fundo Ascendente (Swing Low) confirmado"
// Fórmula: Stop = Swing Low - (1.0 × ATR)
double CalcStructureStop(int type, double atr) {
   MqlRates r[];
   ArraySetAsSeries(r, true);
   int bars = Structure_PivotLookback * 3 + 5;
   if(CopyRates(InpSymbol, InpTF, 0, bars, r) < bars) return 0.0;

   int lookback = Structure_PivotLookback;
   int minBars = Structure_MinBarsConfirm;
   double bufferDist = atr * Structure_ATRBuffer;

   if(type == POSITION_TYPE_BUY) {
      // Encontrar Swing Low confirmado (Pivô de Baixa)
      // Um pivô é confirmado quando tem pelo menos minBars de cada lado
      double swingLow = 0;
      bool found = false;

      for(int i = lookback; i < bars - lookback; i++) {
         bool isPivot = true;
         double candidate = r[i].low;

         // Verificar se é o menor ponto na janela
         for(int j = i - minBars; j <= i + minBars; j++) {
            if(j != i && r[j].low < candidate) {
               isPivot = false;
               break;
            }
         }

         if(isPivot) {
            swingLow = candidate;
            found = true;
            break;
         }
      }

      if(!found) return 0.0;

      // Stop abaixo do Swing Low com buffer ATR (proteção contra stop hunting)
      return swingLow - bufferDist;
   }
   else {
      // Encontrar Swing High confirmado (Pivô de Alta)
      double swingHigh = 0;
      bool found = false;

      for(int i = lookback; i < bars - lookback; i++) {
         bool isPivot = true;
         double candidate = r[i].high;

         for(int j = i - minBars; j <= i + minBars; j++) {
            if(j != i && r[j].high > candidate) {
               isPivot = false;
               break;
            }
         }

         if(isPivot) {
            swingHigh = candidate;
            found = true;
            break;
         }
      }

      if(!found) return 0.0;

      return swingHigh + bufferDist;
   }
}

//===================== PARABOLIC SAR (Seção 5) ========================//
// "O indicador Parabolic SAR foca no tempo e na aceleração"
// Usar apenas quando ADX > 40 (tendência forte/parabólica)
double CalcPSARStop(int type, double adxValue) {
   if(hPSAR == INVALID_HANDLE) return 0.0;

   // Só usar SAR em tendências fortes (Seção 5.2)
   if(PSAR_UseInClimaxOnly && adxValue < PSAR_ADX_Threshold) return 0.0;

   double sar[1];
   if(CopyBuffer(hPSAR, 0, 0, 1, sar) <= 0) return 0.0;

   // Validar que SAR está na direção correta
   if(type == POSITION_TYPE_BUY && sar[0] > Bid()) return 0.0;
   if(type == POSITION_TYPE_SELL && sar[0] < Ask()) return 0.0;

   return sar[0];
}

//===================== STEP TRAILING (Seção 2.2.2) ====================//
// "O modelo em degraus introduz uma histerese intencional"
// "Este método é frequentemente superior em precisão para swing trading"
bool ShouldMoveStep(int type, double currentPrice, double lastStepPrice, double atr) {
   if(Trail_UpdateMode != UPDATE_STEP) return true;

   double stepSize = MathMax(atr * Step_ATRMultiple, Step_MinPoints * Pt());

   if(type == POSITION_TYPE_BUY) {
      return (currentPrice - lastStepPrice) >= stepSize;
   }
   else {
      return (lastStepPrice - currentPrice) >= stepSize;
   }
}

//===================== VERIFICAÇÃO DE ATIVAÇÃO (Seção 7.2) ============//
// "Trailing stops que ativam imediatamente após a entrada frequentemente
// resultam em saídas prematuras devido ao ruído inicial"
bool ShouldActivateTrailing(int type, double entry, double currentPrice,
                            double riskPts, double atr, bool &breakEvenReached) {
   if(Trail_Activation == ACTIVATE_IMMEDIATE) return true;

   double pt = Pt();
   double profitPts = (type == POSITION_TYPE_BUY) ?
                      (currentPrice - entry) / pt :
                      (entry - currentPrice) / pt;

   // Verificar break-even
   if(profitPts >= 0) breakEvenReached = true;

   double profitR = (riskPts > 0) ? profitPts / riskPts : 0;
   double profitATR = (atr > 0) ? (profitPts * pt) / atr : 0;

   switch(Trail_Activation) {
      case ACTIVATE_AFTER_1R:
         return profitR >= 1.0;
      case ACTIVATE_AFTER_1_5R:
         return profitR >= Activation_R_Threshold;
      case ACTIVATE_AFTER_2R:
         return profitR >= 2.0;
      case ACTIVATE_AFTER_2ATR:
         return profitATR >= Activation_ATR_Threshold;
      case ACTIVATE_BREAKEVEN:
         return breakEvenReached && Activation_RequireBE ? profitR >= 0 : profitR >= 0.5;
      default:
         return true;
   }
}

//===================== HÍBRIDO DO ESTUDO (Seção 7.1) ==================//
// Combina Chandelier + Structure + SAR com lógica de seleção
double CalcHybridStudyStop(int type, double entry, double currentSL,
                           double atr, double adxValue, int regime,
                           TrailingState &state) {
   double candidates[3];
   int numCandidates = 0;

   // Candidato 1: Chandelier Exit
   if(Hybrid_UseChandelier) {
      double chanStop = CalcChandelierExit(type, atr, regime);
      if(chanStop > 0) candidates[numCandidates++] = chanStop;
   }

   // Candidato 2: Market Structure
   if(Hybrid_UseStructure) {
      double structStop = CalcStructureStop(type, atr);
      if(structStop > 0) candidates[numCandidates++] = structStop;
   }

   // Candidato 3: Parabolic SAR (apenas em tendência forte)
   if(Hybrid_UsePSAR && regime >= 2) {
      double sarStop = CalcPSARStop(type, adxValue);
      if(sarStop > 0) candidates[numCandidates++] = sarStop;
   }

   if(numCandidates == 0) return currentSL;

   // Seleciona o stop (Seção 7.1: max para BUY, min para SELL)
   double bestStop = currentSL;

   if(type == POSITION_TYPE_BUY) {
      if(Hybrid_SelectHighest) {
         // Para BUY: queremos o SL MAIS ALTO (máxima proteção)
         bestStop = (currentSL > 0) ? currentSL : 0;
         for(int i = 0; i < numCandidates; i++) {
            if(candidates[i] > bestStop) bestStop = candidates[i];
         }
      }
      else {
         // Alternativa: média ponderada
         double sum = 0;
         for(int i = 0; i < numCandidates; i++) sum += candidates[i];
         bestStop = sum / numCandidates;
      }

      // Limite: não pode estar acima do preço atual menos buffer
      double maxSL = Bid() - (atr * 0.3);
      if(bestStop > maxSL) bestStop = maxSL;
   }
   else {
      if(Hybrid_SelectHighest) {
         // Para SELL: queremos o SL MAIS BAIXO (máxima proteção)
         bestStop = (currentSL > 0) ? currentSL : 999999;
         for(int i = 0; i < numCandidates; i++) {
            if(candidates[i] < bestStop && candidates[i] > 0) bestStop = candidates[i];
         }
         if(bestStop > 999990) bestStop = 0;
      }
      else {
         double sum = 0;
         for(int i = 0; i < numCandidates; i++) sum += candidates[i];
         bestStop = sum / numCandidates;
      }

      // Limite: não pode estar abaixo do preço atual mais buffer
      double minSL = Ask() + (atr * 0.3);
      if(bestStop > 0 && bestStop < minSL) bestStop = minSL;
   }

   // LÓGICA RATCHET (Seção 2.1): Stop NUNCA retrocede
   // "St = max(St-1, Pt - δ(vt))"
   if(Hybrid_ApplyRatchet) {
      if(type == POSITION_TYPE_BUY) {
         if(currentSL > 0 && bestStop < currentSL) bestStop = currentSL;
      }
      else {
         if(currentSL > 0 && bestStop > currentSL) bestStop = currentSL;
      }
   }

   return bestStop;
}

//===================== FUNÇÃO PRINCIPAL ===============================//
void ManageAdvancedTrailingStop(CTrade &trade) {
   if(AdvTrail_Mode == TRAIL_OFF) return;
   if(MG_Mode == MG_GRID) return;

   CleanupClosedPositions();

   // Obtém ATR e ADX
   double atr = 0.0;
   if(hATR != INVALID_HANDLE) GetBuf(hATR, 0, atr, 0);
   if(atr <= 0) return;

   double adxValue = 0;
   int regime = DetectMarketRegime(adxValue);

   double pt = Pt();

   // Percorre todas as posições
   int total = PositionsTotal();
   for(int i = 0; i < total; i++) {
      ulong tk = PositionGetTicket(i);
      if(!PositionSelectByTicket(tk)) continue;

      string sym = PositionGetString(POSITION_SYMBOL);
      if(sym != InpSymbol) continue;

      long mg = (long)PositionGetInteger(POSITION_MAGIC);
      if(mg != Magic) continue;

      long type = (long)PositionGetInteger(POSITION_TYPE);
      double entry = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentSL = PositionGetDouble(POSITION_SL);
      double currentTP = PositionGetDouble(POSITION_TP);
      datetime tOpen = (datetime)PositionGetInteger(POSITION_TIME);

      // Encontra ou cria estado
      int stateIdx = FindTrailingState(tk);
      if(stateIdx < 0) {
         AddTrailingState(tk, entry, currentSL, (int)type);
         stateIdx = FindTrailingState(tk);
         if(stateIdx < 0) continue;
      }

      TrailingState state = g_trailStates[stateIdx];
      double currentPrice = (type == POSITION_TYPE_BUY) ? Bid() : Ask();

      // Atualiza MFE/MAE para métricas (Seção 8)
      if(Track_MFE_MAE) {
         if(type == POSITION_TYPE_BUY) {
            if(currentPrice > state.mfePrice) state.mfePrice = currentPrice;
            if(currentPrice < state.maePrice) state.maePrice = currentPrice;
            if(currentPrice > state.highestPrice) state.highestPrice = currentPrice;
         }
         else {
            if(currentPrice < state.mfePrice) state.mfePrice = currentPrice;
            if(currentPrice > state.maePrice) state.maePrice = currentPrice;
            if(currentPrice < state.lowestPrice) state.lowestPrice = currentPrice;
         }
      }

      // Atualiza regime e barras
      state.currentRegime = regime;
      long periodSec = PeriodSeconds(InpTF);
      if(periodSec > 0) state.barsInTrade = (int)((TimeCurrent() - tOpen) / periodSec);

      // Verifica ativação atrasada (Seção 7.2)
      if(!state.trailingActivated) {
         state.trailingActivated = ShouldActivateTrailing(
            (int)type, entry, currentPrice,
            state.initialRiskPts, atr, state.breakEvenReached);

         if(!state.trailingActivated) {
            g_trailStates[stateIdx] = state;
            continue;  // Ainda não ativou, mantém SL original
         }
      }

      // Verifica se deve mover (Step Trailing)
      if(!ShouldMoveStep((int)type, currentPrice, state.lastStepPrice, atr)) {
         g_trailStates[stateIdx] = state;
         continue;  // Ainda não moveu o degrau mínimo
      }

      // Calcula novo stop baseado no modo
      double newSL = currentSL;

      switch(AdvTrail_Mode) {
         case TRAIL_CHANDELIER:
            newSL = CalcChandelierExit((int)type, atr, regime);
            break;

         case TRAIL_MARKET_STRUCTURE:
            newSL = CalcStructureStop((int)type, atr);
            break;

         case TRAIL_PSAR:
            newSL = CalcPSARStop((int)type, adxValue);
            break;

         case TRAIL_STEP_ATR:
            {
               double mult = GetRegimeMultiplier(regime);
               if(type == POSITION_TYPE_BUY) {
                  newSL = currentPrice - (atr * mult);
               }
               else {
                  newSL = currentPrice + (atr * mult);
               }
            }
            break;

         case TRAIL_HYBRID_STUDY:
            newSL = CalcHybridStudyStop((int)type, entry, currentSL,
                                        atr, adxValue, regime, state);
            break;
      }

      // Aplica lógica ratchet se não for híbrido (híbrido já aplica)
      if(AdvTrail_Mode != TRAIL_HYBRID_STUDY && Hybrid_ApplyRatchet) {
         if(type == POSITION_TYPE_BUY) {
            if(currentSL > 0 && newSL < currentSL) newSL = currentSL;
         }
         else {
            if(currentSL > 0 && newSL > currentSL) newSL = currentSL;
         }
      }

      // Validação final e aplicação
      if(newSL > 0 && newSL != currentSL) {
         bool shouldUpdate = false;

         if(type == POSITION_TYPE_BUY) {
            // Para BUY: SL só pode subir
            if(newSL > currentSL || currentSL == 0) {
               double maxSL = Bid() - (g_currentSpread * pt * 3);
               if(newSL < maxSL) shouldUpdate = true;
            }
         }
         else {
            // Para SELL: SL só pode descer
            if(currentSL == 0 || newSL < currentSL) {
               double minSL = Ask() + (g_currentSpread * pt * 3);
               if(newSL > minSL) shouldUpdate = true;
            }
         }

         // Aplica modificação
         if(shouldUpdate) {
            newSL = NormalizeToDigits(sym, newSL);
            double diff = MathAbs(newSL - currentSL);

            // Só modifica se diferença > spread (evita micro-ajustes)
            if(diff > (g_currentSpread * pt)) {
               ModifyPositionByTicket(tk, newSL, currentTP, sym);
               state.lastTrailStop = newSL;
               state.lastStepPrice = currentPrice;

               // Atualiza ação no painel
               string modeName = "";
               switch(AdvTrail_Mode) {
                  case TRAIL_CHANDELIER: modeName = "CE"; break;
                  case TRAIL_MARKET_STRUCTURE: modeName = "MS"; break;
                  case TRAIL_PSAR: modeName = "SAR"; break;
                  case TRAIL_STEP_ATR: modeName = "STEP"; break;
                  case TRAIL_HYBRID_STUDY: modeName = "HYB"; break;
               }
               g_lastAction = StringFormat("%s→%.2f (R%d)", modeName, newSL, regime);
               g_lastActionTime = TimeCurrent();
            }
         }
      }

      // Atualiza estado
      state.lastUpdate = TimeCurrent();
      g_trailStates[stateIdx] = state;
   }
}

#endif // __MAABOT_TRAILINGSTOP_MQH__
//+------------------------------------------------------------------+
