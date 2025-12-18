//+------------------------------------------------------------------+
//|                                            RiskManagement.mqh    |
//|   MAAbot v2.5.0 - Gestão de Risco                                |
//|                                     Autor: Eliabe N Oliveira     |
//+------------------------------------------------------------------+
#ifndef __MAABOT_RISKMANAGEMENT_MQH__
#define __MAABOT_RISKMANAGEMENT_MQH__

#include "Inputs.mqh"
#include "Globals.mqh"
#include "Utils.mqh"

// Forward declaration para evitar dependência circular
double CalculateAggressiveLot(double baseLot);
bool IsAggressiveModeActive();

//-------------------------- HISTÓRICO / RISCO ------------------------------//
double TodayPL() { 
   datetime from = DayStart(TimeCurrent()), to = TimeCurrent(); 
   if(!HistorySelect(from, to)) return 0.0;
   
   double pl = 0.0; uint deals = HistoryDealsTotal();
   
   for(uint i = 0; i < deals; i++) { 
      ulong tk = HistoryDealGetTicket(i);
      if(tk == 0) continue;
      if((string)HistoryDealGetString(tk, DEAL_SYMBOL) != InpSymbol) continue;
      long mg = (long)HistoryDealGetInteger(tk, DEAL_MAGIC); 
      if(mg != Magic) continue;
      int entry = (int)HistoryDealGetInteger(tk, DEAL_ENTRY);
      if(entry == DEAL_ENTRY_IN || entry == DEAL_ENTRY_OUT)
         pl += HistoryDealGetDouble(tk, DEAL_PROFIT) + HistoryDealGetDouble(tk, DEAL_SWAP) + HistoryDealGetDouble(tk, DEAL_COMMISSION); 
   }
   return pl; 
}

int TodayTradesOpened() { 
   datetime from = DayStart(TimeCurrent()), to = TimeCurrent(); 
   if(!HistorySelect(from, to)) return 0;
   
   int cnt = 0; uint deals = HistoryDealsTotal();
   
   for(uint i = 0; i < deals; i++) { 
      ulong tk = HistoryDealGetTicket(i);
      if(tk == 0) continue;
      if((string)HistoryDealGetString(tk, DEAL_SYMBOL) != InpSymbol) continue;
      long mg = (long)HistoryDealGetInteger(tk, DEAL_MAGIC); 
      if(mg != Magic) continue;
      int entry = (int)HistoryDealGetInteger(tk, DEAL_ENTRY); 
      if(entry == DEAL_ENTRY_IN) cnt++; 
   }
   return cnt; 
}

bool DailyRiskOK() { 
   double eq = AccountInfoDouble(ACCOUNT_EQUITY), pl = TodayPL(); 
   double ddp = (eq <= 0.0) ? 0.0 : (-pl / eq) * 100.0;
   
   if(ddp >= DailyLossLimitPercent) {
      g_statusMsg = "Limite diario atingido";
      return false; 
   }
   
   if(TodayTradesOpened() >= MaxTradesPerDay) {
      g_statusMsg = "Max trades/dia atingido";
      return false; 
   }
   return true; 
}

double LotsForRiskPercent(double percent, int sl_points) {
   double eq = AccountInfoDouble(ACCOUNT_EQUITY);
   double risk_money = eq * (percent / 100.0);
   double pt = Pt(), tick_size = SymbolInfoDouble(InpSymbol, SYMBOL_TRADE_TICK_SIZE);
   double tick_value = SymbolInfoDouble(InpSymbol, SYMBOL_TRADE_TICK_VALUE);
   double step = SymbolInfoDouble(InpSymbol, SYMBOL_VOLUME_STEP);
   double minlot = SymbolInfoDouble(InpSymbol, SYMBOL_VOLUME_MIN);
   double maxlot = SymbolInfoDouble(InpSymbol, SYMBOL_VOLUME_MAX);

   if(tick_size <= 0.0 || tick_value <= 0.0 || pt <= 0.0) return minlot;

   double money_per_lot = (sl_points * pt) * (tick_value / tick_size);
   if(money_per_lot <= 0.0) return minlot;

   double lots = risk_money / money_per_lot;
   int k = (int)MathFloor(lots / step);
   lots = k * step;

   double baseLot = MathMax(minlot, MathMin(maxlot, lots));

   // ======== INTEGRAÇÃO META DIÁRIA ========
   // Aplica multiplicador do modo agressivo se ativo
   if(IsDailyTargetEnabled() && IsAggressiveModeActive()) {
      baseLot = CalculateAggressiveLot(baseLot);
   }

   return baseLot;
}

//-------------------------- DD GUARD / THROTTLE ----------------------------//
double CurrentDDPercent() { 
   double eq = AccountInfoDouble(ACCOUNT_EQUITY); 
   if(eqPeak <= 0.0) eqPeak = eq; 
   if(eq > eqPeak) eqPeak = eq; 
   if(eqPeak <= 0.0) return 0.0; 
   return ((eqPeak - eq) / eqPeak) * 100.0; 
}

double ApplyRiskThrottle(double baseRisk) { 
   if(!UseRiskThrottle) return baseRisk; 
   double dd = CurrentDDPercent();
   double f = 1.0; 
   if(dd >= RT_L3) f = RT_F3; 
   else if(dd >= RT_L2) f = RT_F2; 
   else if(dd >= RT_L1) f = RT_F1; 
   return baseRisk * f; 
}

//-------------------------- MARTINGALE PER-TRADE ----------------------------//
double EffectiveRiskPercentForNextTrade() {
   if(MG_Mode == MG_OFF) return ApplyRiskThrottle(RiskPercent);
   
   if(MG_ResetDaily) { 
      static datetime lastDay = 0; 
      datetime d0 = DayStart(TimeCurrent()); 
      if(d0 != lastDay) { lastDay = d0; return ApplyRiskThrottle(RiskPercent); } 
   }
   
   datetime from = DayStart(TimeCurrent()), to = TimeCurrent(); 
   if(!HistorySelect(from, to)) return ApplyRiskThrottle(RiskPercent);
   
   int cons = 0; int N = (int)HistoryDealsTotal(); 
   for(int i = N-1; i >= 0; i--) { 
      ulong tk = HistoryDealGetTicket(i);
      if(tk == 0) continue;
      if((string)HistoryDealGetString(tk, DEAL_SYMBOL) != InpSymbol) continue; 
      long mg = (long)HistoryDealGetInteger(tk, DEAL_MAGIC); 
      if(mg != Magic) continue;
      int e = (int)HistoryDealGetInteger(tk, DEAL_ENTRY); 
      if(e != DEAL_ENTRY_OUT) continue; 
      double pl = HistoryDealGetDouble(tk, DEAL_PROFIT) + HistoryDealGetDouble(tk, DEAL_SWAP) + HistoryDealGetDouble(tk, DEAL_COMMISSION);
      if(pl < 0.0) cons++; else break; 
   }
   
   int step = MathMin(cons, MG_MaxSteps); 
   double eff = RiskPercent * MathPow(MG_Multiplier, step); 
   if(MG_MaxRiskPercent > 0.0) eff = MathMin(eff, MG_MaxRiskPercent); 
   return ApplyRiskThrottle(eff); 
}

//-------------------------- VOL/ESTRUTURA/THRESH ---------------------------//
bool VolQualityOK(int &atr_pts_out) { 
   if(hATR == INVALID_HANDLE) hATR = iATR(InpSymbol, InpTF, ATR_Period);
   
   double atr = 0.0; 
   if(!GetBuf(hATR, 0, atr, 0)) return false; 
   
   double pt = Pt(); 
   if(pt <= 0.0) return false;
   
   int atr_pts = (int)MathRound(atr / pt); 
   int sprd = (int)SymbolInfoInteger(InpSymbol, SYMBOL_SPREAD);
   
   if(atr_pts < MinATRPoints) { g_statusMsg = "ATR muito baixo"; return false; }
   if(sprd <= 0) return false; 
   
   double ratio = (double)atr_pts / (double)sprd; 
   atr_pts_out = atr_pts; 
   
   if(ratio < MinATRtoSpread) { g_statusMsg = "ATR/Spread baixo"; return false; }
   return true;
}

double BaseThr() { 
   if(PrecisionMode == MODE_CONSERVATIVE) return 0.72; 
   if(PrecisionMode == MODE_BALANCED) return 0.66; 
   return 0.58; 
}

#endif // __MAABOT_RISKMANAGEMENT_MQH__
//+------------------------------------------------------------------+
