//+------------------------------------------------------------------+
//|                                                 TrailingStop.mqh |
//|   MAAbot v2.6.0 - Estratégias Avançadas de Trailing Stop         |
//|                                     Autor: Eliabe N Oliveira     |
//|   Implementação: Claude AI - Trailing Stop Profissional          |
//+------------------------------------------------------------------+
#ifndef __MAABOT_TRAILINGSTOP_MQH__
#define __MAABOT_TRAILINGSTOP_MQH__

#include <Trade/Trade.mqh>
#include "Inputs.mqh"
#include "Globals.mqh"
#include "Utils.mqh"

//-------------------------- HANDLES PARA TRAILING -----------------------------//
int hPSAR = INVALID_HANDLE;
int hMomentum = INVALID_HANDLE;

//-------------------------- ESTRUTURA DE ESTADO DO TRAILING -------------------//
struct TrailingState {
   ulong    ticket;           // Ticket da posição
   double   entryPrice;       // Preço de entrada
   double   initialSL;        // SL inicial (para calcular R)
   double   initialRisk;      // Risco inicial em pontos
   double   highestPrice;     // Maior preço desde entrada (para buy)
   double   lowestPrice;      // Menor preço desde entrada (para sell)
   int      currentLevel;     // Nível atual do multi-level
   datetime lastUpdate;       // Última atualização
   int      barsInTrade;      // Barras desde entrada
};

// Array para armazenar estados das posições
TrailingState g_trailStates[];

//-------------------------- INICIALIZAÇÃO ------------------------------------//
void InitTrailingIndicators() {
   if(AdvTrail_Mode == TRAIL_PSAR || AdvTrail_Mode == TRAIL_HYBRID) {
      if(hPSAR == INVALID_HANDLE)
         hPSAR = iSAR(InpSymbol, InpTF, PSAR_Step, PSAR_Maximum);
   }
   if(AdvTrail_Mode == TRAIL_HYBRID && Hybrid_UseMomentum) {
      if(hMomentum == INVALID_HANDLE)
         hMomentum = iMomentum(InpSymbol, InpTF, Hybrid_MomPeriod, PRICE_CLOSE);
   }
}

void DeinitTrailingIndicators() {
   if(hPSAR != INVALID_HANDLE) { IndicatorRelease(hPSAR); hPSAR = INVALID_HANDLE; }
   if(hMomentum != INVALID_HANDLE) { IndicatorRelease(hMomentum); hMomentum = INVALID_HANDLE; }
   ArrayFree(g_trailStates);
}

//-------------------------- GERENCIAMENTO DE ESTADOS -------------------------//
int FindTrailingState(ulong ticket) {
   for(int i = 0; i < ArraySize(g_trailStates); i++) {
      if(g_trailStates[i].ticket == ticket) return i;
   }
   return -1;
}

void AddTrailingState(ulong ticket, double entry, double sl, int type) {
   int idx = FindTrailingState(ticket);
   if(idx >= 0) return; // Já existe

   int newSize = ArraySize(g_trailStates) + 1;
   ArrayResize(g_trailStates, newSize);

   g_trailStates[newSize-1].ticket = ticket;
   g_trailStates[newSize-1].entryPrice = entry;
   g_trailStates[newSize-1].initialSL = sl;
   g_trailStates[newSize-1].initialRisk = MathAbs(entry - sl) / Pt();
   g_trailStates[newSize-1].highestPrice = (type == POSITION_TYPE_BUY) ? entry : 0;
   g_trailStates[newSize-1].lowestPrice = (type == POSITION_TYPE_SELL) ? entry : 999999;
   g_trailStates[newSize-1].currentLevel = 0;
   g_trailStates[newSize-1].lastUpdate = TimeCurrent();
   g_trailStates[newSize-1].barsInTrade = 0;
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

//========================== ESTRATÉGIA 1: CHANDELIER EXIT ===================//
// O Chandelier Exit é um dos trailing stops mais eficazes do mercado.
// Ele coloca o stop abaixo do Highest High (para compras) ou acima do
// Lowest Low (para vendas) usando um múltiplo do ATR como distância.
//==========================================================================//
double CalcChandelierStop(int type, double atr) {
   MqlRates r[];
   ArraySetAsSeries(r, true);
   int bars = Chandelier_Period + 2;
   if(CopyRates(InpSymbol, InpTF, 0, bars, r) < bars) return 0.0;

   double pt = Pt();
   double chandelierDist = Chandelier_ATRMult * atr;

   if(type == POSITION_TYPE_BUY) {
      // Para BUY: Stop abaixo do Highest High
      double highestHigh = r[1].high;
      for(int i = 1; i <= Chandelier_Period; i++) {
         double val = Chandelier_UseClose ? r[i].close : r[i].high;
         if(val > highestHigh) highestHigh = val;
      }
      return highestHigh - chandelierDist;
   }
   else {
      // Para SELL: Stop acima do Lowest Low
      double lowestLow = r[1].low;
      for(int i = 1; i <= Chandelier_Period; i++) {
         double val = Chandelier_UseClose ? r[i].close : r[i].low;
         if(val < lowestLow) lowestLow = val;
      }
      return lowestLow + chandelierDist;
   }
}

//========================== ESTRATÉGIA 2: PARABOLIC SAR ====================//
// O Parabolic SAR é excelente para trailing em tendências fortes.
// Ele acelera à medida que o preço se move a favor, protegendo lucros.
//==========================================================================//
double CalcPSARStop(int type) {
   if(hPSAR == INVALID_HANDLE) return 0.0;

   double sar[1];
   if(CopyBuffer(hPSAR, 0, 0, 1, sar) <= 0) return 0.0;

   // Filtro de tendência - só usa PSAR se estiver na direção certa
   if(PSAR_FilterTrend) {
      if(type == POSITION_TYPE_BUY && sar[0] > Bid()) return 0.0; // SAR acima = sinal de venda
      if(type == POSITION_TYPE_SELL && sar[0] < Ask()) return 0.0; // SAR abaixo = sinal de compra
   }

   return sar[0];
}

//========================== ESTRATÉGIA 3: MULTI-LEVEL TRAILING =============//
// Sistema escalonado que move o stop em níveis definidos de lucro (em R).
// Ideal para capturar movimentos maiores enquanto protege ganhos parciais.
//==========================================================================//
double CalcMultiLevelStop(int type, double entry, double currentSL, double riskPts, double atr, int &level) {
   double pt = Pt();
   double currentPrice = (type == POSITION_TYPE_BUY) ? Bid() : Ask();
   double profitPts = (type == POSITION_TYPE_BUY) ? (currentPrice - entry) / pt : (entry - currentPrice) / pt;
   double profitR = (riskPts > 0) ? profitPts / riskPts : 0;

   double newSL = currentSL;
   int newLevel = level;

   // Nível 4: Após ML_Level4_R, usa ATR trailing apertado
   if(profitR >= ML_Level4_R) {
      double atrTrail = atr * ML_Trail4_ATR;
      if(type == POSITION_TYPE_BUY) {
         double trailSL = currentPrice - atrTrail;
         if(trailSL > newSL) { newSL = trailSL; newLevel = 4; }
      }
      else {
         double trailSL = currentPrice + atrTrail;
         if(newSL == 0 || trailSL < newSL) { newSL = trailSL; newLevel = 4; }
      }
   }
   // Nível 3: Trava ML_Trail3_R do risco
   else if(profitR >= ML_Level3_R && level < 3) {
      if(type == POSITION_TYPE_BUY) {
         newSL = entry + (ML_Trail3_R * riskPts * pt);
      }
      else {
         newSL = entry - (ML_Trail3_R * riskPts * pt);
      }
      newLevel = 3;
   }
   // Nível 2: Trava ML_Trail2_R do risco
   else if(profitR >= ML_Level2_R && level < 2) {
      if(type == POSITION_TYPE_BUY) {
         newSL = entry + (ML_Trail2_R * riskPts * pt);
      }
      else {
         newSL = entry - (ML_Trail2_R * riskPts * pt);
      }
      newLevel = 2;
   }
   // Nível 1: Move para break-even + buffer
   else if(profitR >= ML_Level1_R && level < 1) {
      if(type == POSITION_TYPE_BUY) {
         newSL = entry + (ML_Trail1_R * riskPts * pt);
      }
      else {
         newSL = entry - (ML_Trail1_R * riskPts * pt);
      }
      newLevel = 1;
   }

   level = newLevel;
   return newSL;
}

//========================== ESTRATÉGIA 4: TIME DECAY STOP ==================//
// Stop que aperta progressivamente com o tempo. Isso evita que trades
// fiquem abertos por muito tempo sem ir a lugar algum.
//==========================================================================//
double CalcTimeDecayStop(int type, double entry, int barsInTrade, double atr) {
   if(!TimeDecay_Enable) return 0.0;
   if(barsInTrade < TimeDecay_StartBars) return 0.0;

   double pt = Pt();

   // Calcula fator de decaimento (0 = início, 1 = máximo aperto)
   double decayRange = TimeDecay_FullBars - TimeDecay_StartBars;
   double progress = MathMin(1.0, (barsInTrade - TimeDecay_StartBars) / decayRange);

   // Interpola entre ATR máximo e mínimo
   double currentMult = TimeDecay_MaxATRMult - (progress * (TimeDecay_MaxATRMult - TimeDecay_MinATRMult));
   double stopDist = atr * currentMult;

   if(type == POSITION_TYPE_BUY) {
      return Bid() - stopDist;
   }
   else {
      return Ask() + stopDist;
   }
}

//========================== ESTRATÉGIA 5: PROFIT LOCK ESCALADO =============//
// Trava uma porcentagem progressiva do lucro conforme o trade evolui.
//==========================================================================//
double CalcProfitLockStop(int type, double entry, double currentSL, double riskPts) {
   if(ProfitLock_Mode == LOCK_OFF) return currentSL;

   double pt = Pt();
   double currentPrice = (type == POSITION_TYPE_BUY) ? Bid() : Ask();
   double profitPts = (type == POSITION_TYPE_BUY) ? (currentPrice - entry) / pt : (entry - currentPrice) / pt;
   double profitR = (riskPts > 0) ? profitPts / riskPts : 0;

   double lockPercent = 0.0;

   if(ProfitLock_Mode == LOCK_BREAKEVEN) {
      // Apenas break-even após 1R
      if(profitR >= 1.0) lockPercent = 0.0; // SL no entry
   }
   else if(ProfitLock_Mode == LOCK_SCALED) {
      // Escalonado
      if(profitR >= Lock_Trigger3_R) lockPercent = Lock_Amount3;
      else if(profitR >= Lock_Trigger2_R) lockPercent = Lock_Amount2;
      else if(profitR >= Lock_Trigger1_R) lockPercent = Lock_Amount1;
   }
   else if(ProfitLock_Mode == LOCK_AGGRESSIVE) {
      // Agressivo: trava 50% de qualquer lucro após 0.5R
      if(profitR >= 0.5) lockPercent = 0.5;
   }

   if(lockPercent > 0) {
      double lockedProfit = profitPts * lockPercent;
      if(type == POSITION_TYPE_BUY) {
         double newSL = entry + (lockedProfit * pt);
         if(newSL > currentSL || currentSL == 0) return newSL;
      }
      else {
         double newSL = entry - (lockedProfit * pt);
         if(currentSL == 0 || newSL < currentSL) return newSL;
      }
   }

   return currentSL;
}

//========================== ESTRATÉGIA 6: HÍBRIDO INTELIGENTE ==============//
// Combina as melhores características de todas as estratégias.
// Adapta-se dinamicamente às condições do mercado.
//==========================================================================//
double CalcHybridStop(int type, double entry, double currentSL, double atr, int barsInTrade, double riskPts, int &level) {
   double pt = Pt();
   double currentPrice = (type == POSITION_TYPE_BUY) ? Bid() : Ask();
   double profitPts = (type == POSITION_TYPE_BUY) ? (currentPrice - entry) / pt : (entry - currentPrice) / pt;
   double profitR = (riskPts > 0) ? profitPts / riskPts : 0;

   // Fatores de ajuste baseados no mercado
   double trendFactor = 1.0;
   double momentumFactor = 1.0;

   // Adapta à tendência
   if(Hybrid_UseTrendAdapt) {
      if(g_trending && MathAbs(g_trendScore) > TrendScore_Thr) {
         trendFactor = Hybrid_TrendLoose; // Mais solto em tendência forte
      }
      else {
         trendFactor = Hybrid_RangeTight; // Mais apertado em range
      }
   }

   // Adapta ao momentum
   if(Hybrid_UseMomentum && hMomentum != INVALID_HANDLE) {
      double mom[1];
      if(CopyBuffer(hMomentum, 0, 0, 1, mom) > 0) {
         double momValue = (mom[0] - 100.0) / 100.0; // Normaliza momentum
         if(MathAbs(momValue) > Hybrid_MomThreshold) {
            // Momentum forte na direção do trade = trailing mais solto
            if((type == POSITION_TYPE_BUY && momValue > 0) ||
               (type == POSITION_TYPE_SELL && momValue < 0)) {
               momentumFactor = 1.2;
            }
            // Momentum contra = trailing mais apertado
            else {
               momentumFactor = 0.8;
            }
         }
      }
   }

   // Combina fatores
   double adjustedMult = trendFactor * momentumFactor;

   // Array para armazenar candidatos de SL
   double candidates[5];
   int numCandidates = 0;

   // Candidato 1: Chandelier Exit (ajustado)
   double chandelierSL = CalcChandelierStop(type, atr * adjustedMult);
   if(chandelierSL > 0) candidates[numCandidates++] = chandelierSL;

   // Candidato 2: PSAR (quando disponível)
   double psarSL = CalcPSARStop(type);
   if(psarSL > 0) candidates[numCandidates++] = psarSL;

   // Candidato 3: Multi-Level (para níveis de lucro)
   double mlSL = CalcMultiLevelStop(type, entry, currentSL, riskPts, atr * adjustedMult, level);
   if(mlSL > 0 && mlSL != currentSL) candidates[numCandidates++] = mlSL;

   // Candidato 4: Time Decay (após período inicial)
   double tdSL = CalcTimeDecayStop(type, entry, barsInTrade, atr * adjustedMult);
   if(tdSL > 0) candidates[numCandidates++] = tdSL;

   // Candidato 5: Profit Lock
   double plSL = CalcProfitLockStop(type, entry, currentSL, riskPts);
   if(plSL > 0 && plSL != currentSL) candidates[numCandidates++] = plSL;

   if(numCandidates == 0) return currentSL;

   // Seleciona o melhor SL baseado na fase do trade
   double bestSL = currentSL;

   if(type == POSITION_TYPE_BUY) {
      // Para BUY: queremos o SL mais alto (mais proteção)
      for(int i = 0; i < numCandidates; i++) {
         if(candidates[i] > bestSL) bestSL = candidates[i];
      }
      // Mas não pode ser maior que o preço atual menos um buffer
      double maxSL = currentPrice - (atr * 0.5);
      if(bestSL > maxSL) bestSL = maxSL;
   }
   else {
      // Para SELL: queremos o SL mais baixo (mais proteção)
      bestSL = (currentSL > 0) ? currentSL : 999999;
      for(int i = 0; i < numCandidates; i++) {
         if(candidates[i] < bestSL && candidates[i] > 0) bestSL = candidates[i];
      }
      // Mas não pode ser menor que o preço atual mais um buffer
      double minSL = currentPrice + (atr * 0.5);
      if(bestSL < minSL) bestSL = minSL;
      if(bestSL > 999990) bestSL = 0;
   }

   return bestSL;
}

//========================== FUNÇÃO PRINCIPAL DE TRAILING ===================//
// Gerencia o trailing stop de todas as posições abertas
//==========================================================================//
void ManageAdvancedTrailingStop(CTrade &trade) {
   // Verifica se o trailing stop está ativado globalmente
   if(!IsTrailingStopEnabled()) return;
   if(GetEffectiveTrailingMode() == TRAIL_OFF) return;
   if(MG_Mode == MG_GRID) return; // Grid tem sua própria gestão

   // Limpa estados de posições fechadas
   CleanupClosedPositions();

   // Obtém ATR atual
   double atr = 0.0;
   if(hATR != INVALID_HANDLE) GetBuf(hATR, 0, atr, 0);
   if(atr <= 0) return;

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

      // Encontra ou cria estado do trailing
      int stateIdx = FindTrailingState(tk);
      if(stateIdx < 0) {
         AddTrailingState(tk, entry, currentSL, (int)type);
         stateIdx = FindTrailingState(tk);
         if(stateIdx < 0) continue;
      }

      TrailingState state = g_trailStates[stateIdx];

      // Atualiza barras no trade
      long periodSec = PeriodSeconds(InpTF);
      if(periodSec > 0) {
         state.barsInTrade = (int)((TimeCurrent() - tOpen) / periodSec);
      }

      // Atualiza high/low
      double currentPrice = (type == POSITION_TYPE_BUY) ? Bid() : Ask();
      if(type == POSITION_TYPE_BUY && currentPrice > state.highestPrice) {
         state.highestPrice = currentPrice;
      }
      else if(type == POSITION_TYPE_SELL && currentPrice < state.lowestPrice) {
         state.lowestPrice = currentPrice;
      }

      // Calcula risco inicial se não tiver
      if(state.initialRisk <= 0 && currentSL > 0) {
         state.initialRisk = MathAbs(entry - currentSL) / pt;
      }
      else if(state.initialRisk <= 0) {
         state.initialRisk = StopLossPoints;
      }

      double newSL = currentSL;
      int level = state.currentLevel;

      // Aplica estratégia de trailing selecionada
      switch(AdvTrail_Mode) {
         case TRAIL_ATR:
            {
               double atrDist = atr * ATR_TrailMult;
               if(type == POSITION_TYPE_BUY) {
                  double trailSL = Bid() - atrDist;
                  if(trailSL > currentSL || currentSL == 0) newSL = trailSL;
               }
               else {
                  double trailSL = Ask() + atrDist;
                  if(currentSL == 0 || trailSL < currentSL) newSL = trailSL;
               }
            }
            break;

         case TRAIL_CHANDELIER:
            {
               double chanSL = CalcChandelierStop((int)type, atr);
               if(chanSL > 0) {
                  if(type == POSITION_TYPE_BUY && (chanSL > currentSL || currentSL == 0)) {
                     newSL = chanSL;
                  }
                  else if(type == POSITION_TYPE_SELL && (currentSL == 0 || chanSL < currentSL)) {
                     newSL = chanSL;
                  }
               }
            }
            break;

         case TRAIL_PSAR:
            {
               double psarSL = CalcPSARStop((int)type);
               if(psarSL > 0) {
                  if(type == POSITION_TYPE_BUY && (psarSL > currentSL || currentSL == 0)) {
                     newSL = psarSL;
                  }
                  else if(type == POSITION_TYPE_SELL && (currentSL == 0 || psarSL < currentSL)) {
                     newSL = psarSL;
                  }
               }
            }
            break;

         case TRAIL_MULTILEVEL:
            newSL = CalcMultiLevelStop((int)type, entry, currentSL, state.initialRisk, atr, level);
            break;

         case TRAIL_TIME_DECAY:
            {
               double tdSL = CalcTimeDecayStop((int)type, entry, state.barsInTrade, atr);
               if(tdSL > 0) {
                  if(type == POSITION_TYPE_BUY && (tdSL > currentSL || currentSL == 0)) {
                     newSL = tdSL;
                  }
                  else if(type == POSITION_TYPE_SELL && (currentSL == 0 || tdSL < currentSL)) {
                     newSL = tdSL;
                  }
               }
               // Também aplica profit lock no time decay
               newSL = CalcProfitLockStop((int)type, entry, newSL, state.initialRisk);
            }
            break;

         case TRAIL_HYBRID:
            newSL = CalcHybridStop((int)type, entry, currentSL, atr, state.barsInTrade, state.initialRisk, level);
            break;
      }

      // Valida e aplica novo SL
      if(newSL > 0 && newSL != currentSL) {
         // Garante que o SL só move na direção favorável
         bool shouldUpdate = false;

         if(type == POSITION_TYPE_BUY) {
            // Para BUY: SL só pode subir
            if(newSL > currentSL || currentSL == 0) {
               // Não pode ser maior que o preço atual - spread
               double maxSL = Bid() - (g_currentSpread * pt * 2);
               if(newSL < maxSL) shouldUpdate = true;
            }
         }
         else {
            // Para SELL: SL só pode descer
            if(currentSL == 0 || newSL < currentSL) {
               // Não pode ser menor que o preço atual + spread
               double minSL = Ask() + (g_currentSpread * pt * 2);
               if(newSL > minSL) shouldUpdate = true;
            }
         }

         // Aplica modificação se necessário
         if(shouldUpdate) {
            newSL = NormalizeToDigits(sym, newSL);
            if(MathAbs(newSL - currentSL) > pt) { // Só modifica se diferença > 1 pt
               ModifyPositionByTicket(tk, newSL, currentTP, sym);
               g_lastAction = StringFormat("Trail SL→%.2f", newSL);
               g_lastActionTime = TimeCurrent();
            }
         }
      }

      // Atualiza estado
      state.currentLevel = level;
      state.lastUpdate = TimeCurrent();
      g_trailStates[stateIdx] = state;
   }
}

//========================== FUNÇÃO DE EMERGÊNCIA ===========================//
// Stop de emergência baseado em perda máxima por trade
//==========================================================================//
void CheckEmergencyStop(CTrade &trade, double maxLossPercent) {
   if(maxLossPercent <= 0) return;

   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double maxLoss = equity * (maxLossPercent / 100.0);

   int total = PositionsTotal();
   for(int i = total - 1; i >= 0; i--) {
      ulong tk = PositionGetTicket(i);
      if(!PositionSelectByTicket(tk)) continue;

      string sym = PositionGetString(POSITION_SYMBOL);
      if(sym != InpSymbol) continue;

      long mg = (long)PositionGetInteger(POSITION_MAGIC);
      if(mg != Magic) continue;

      double profit = PositionGetDouble(POSITION_PROFIT);
      if(profit < -maxLoss) {
         trade.PositionClose(tk);
         g_lastAction = "EMERGENCY STOP!";
         g_lastActionTime = TimeCurrent();
      }
   }
}

#endif // __MAABOT_TRAILINGSTOP_MQH__
//+------------------------------------------------------------------+
