//+------------------------------------------------------------------+
//|                                            TradeManagement.mqh   |
//|   MAAbot v2.5.0 - Gestão de Trades                               |
//|                                     Autor: Eliabe N Oliveira     |
//+------------------------------------------------------------------+
#ifndef __MAABOT_TRADEMANAGEMENT_MQH__
#define __MAABOT_TRADEMANAGEMENT_MQH__

#include <Trade/Trade.mqh>
#include "Inputs.mqh"
#include "Globals.mqh"
#include "Utils.mqh"
#include "TrailingStop.mqh"
#include "DailyTargetManager.mqh"

//-------------------------- SL/TP STRUCTURE --------------------------------//
int SLPoints_Structure(int dir, int lookback) {
   int look = (lookback < 5) ? 5 : lookback; 
   MqlRates r[]; ArraySetAsSeries(r, true); 
   if(CopyRates(InpSymbol, InpTF, 0, look+5, r) < look+5) return StopLossPoints;
   double pt = Pt();
   
   if(dir > 0) { 
      double lo = r[1].low; 
      for(int i = 1; i <= look; i++) if(r[i].low < lo) lo = r[i].low; 
      double sl = lo - SL_Struct_BufferPts * pt; 
      int pts = (int)MathRound((Bid() - sl) / pt); 
      return MathMax(10, pts); 
   }
   else { 
      double hi = r[1].high; 
      for(int i = 1; i <= look; i++) if(r[i].high > hi) hi = r[i].high; 
      double sl = hi + SL_Struct_BufferPts * pt; 
      int pts = (int)MathRound((sl - Ask()) / pt); 
      return MathMax(10, pts); 
   }
}

int DonchianTPPoints(int dir, int lookback, int bufferPts) {
   int N = (lookback < 10) ? 10 : lookback; 
   double H[], L[], C[]; 
   ArraySetAsSeries(H, true); ArraySetAsSeries(L, true); ArraySetAsSeries(C, true);
   
   if(CopyHigh(InpSymbol, InpTF, 0, N+2, H) < N+2) return TakeProfitPoints; 
   if(CopyLow(InpSymbol, InpTF, 0, N+2, L) < N+2) return TakeProfitPoints; 
   if(CopyClose(InpSymbol, InpTF, 0, 1, C) < 1) return TakeProfitPoints;
   double pt = Pt();
   
   if(dir > 0) { 
      double maxH = H[1]; for(int i = 1; i <= N; i++) if(H[i] > maxH) maxH = H[i]; 
      int pts = (int)MathRound(((maxH + bufferPts * pt) - C[0]) / pt); 
      return MathMax(10, pts); 
   }
   else { 
      double minL = L[1]; for(int i = 1; i <= N; i++) if(L[i] < minL) minL = L[i]; 
      int pts = (int)MathRound((C[0] - (minL - bufferPts * pt)) / pt); 
      return MathMax(10, pts); 
   } 
}

void CalcStopsTP_Regime(int dir, bool trending, int &sl_pts_out, int &tp_pts_out) {
   double atr = 0.0; 
   if(hATR == INVALID_HANDLE) hATR = iATR(InpSymbol, InpTF, ATR_Period); 
   GetBuf(hATR, 0, atr, 0);
   double pt = Pt(); if(pt <= 0) pt = 0.00001;
   
   int sl_atr = (int)MathRound(((trending ? SL_ATR_Mult_Trend : SL_ATR_Mult_Range) * atr) / pt);
   int sl_str = SLPoints_Structure(dir, trending ? SL_Struct_Lookback_Trend : SL_Struct_Lookback_Range);
   
   int sl_pts = sl_atr; 
   if(SL_Mode == SL_ATR) sl_pts = sl_atr; 
   else if(SL_Mode == SL_STRUCTURE) sl_pts = sl_str; 
   else if(SL_Mode == SL_HYBRID_MAX) sl_pts = MathMax(sl_atr, sl_str);
   if(sl_pts < 10) sl_pts = StopLossPoints;
   
   int tp_pts = TakeProfitPoints;
   if(TP_Mode == TP_FIXED_RATIO) { 
      double r = (trending ? TP_R_Mult_Trend : TP_R_Mult_Range); 
      tp_pts = (int)MathRound(sl_pts * r); if(tp_pts < 1) tp_pts = 1; 
   }
   else { 
      double mult = (trending ? TP_ATR_Mult_Trend : TP_ATR_Mult_Range); 
      tp_pts = (int)MathRound((atr * mult) / pt); if(tp_pts < 1) tp_pts = 1; 
   }
   
   if(TP_ClampToDonchian) { int dch = DonchianTPPoints(dir, TP_Donchian_Lookback, TP_Donchian_BufferPts); tp_pts = MathMin(tp_pts, dch); }
   
   sl_pts_out = sl_pts; tp_pts_out = tp_pts;
}

//-------------------------- GESTÃO PER-TRADE --------------------------------//
void ManagePerTrade(CTrade &trade) {
   if(MG_Mode == MG_GRID) return;

   // ======== META DIÁRIA (PORCENTAGEM AO DIA) ========
   // Gerencia o sistema de meta diária com juros compostos
   ManageDailyTarget();

   // ======== TRAILING STOP AVANÇADO ========
   // Se o modo avançado estiver ativo, usa o novo sistema
   if(AdvTrail_Mode != TRAIL_OFF) {
      ManageAdvancedTrailingStop(trade);
   }

   // ======== VERIFICAÇÃO DE FIM DO DIA ========
   // Executa ação configurada ao fim do horário
   ExecuteEndOfDayAction(trade);

   int total = PositionsTotal();
   for(int i = 0; i < total; i++) {
      ulong tk = PositionGetTicket(i);
      if(!PositionSelectByTicket(tk)) continue;
      string sym = PositionGetString(POSITION_SYMBOL);
      if(sym != InpSymbol) continue;
      long mg = (long)PositionGetInteger(POSITION_MAGIC);
      if(mg != Magic) continue;

      long type = (long)PositionGetInteger(POSITION_TYPE);
      double price = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl = PositionGetDouble(POSITION_SL);
      double tp = PositionGetDouble(POSITION_TP);
      datetime tOpen = (datetime)PositionGetInteger(POSITION_TIME);
      double bid = Bid(), ask = Ask(), pt = Pt();

      if(MaxBarsInTrade > 0) {
         long periodSec = PeriodSeconds(InpTF);
         if(periodSec > 0) {
            int bars = (int)((TimeCurrent() - tOpen) / periodSec);
            if(bars >= MaxBarsInTrade) {
               trade.PositionClose(tk);
               g_lastAction = "Saida por tempo"; g_lastActionTime = TimeCurrent();
               continue;
            }
         }
      }

      if(ExitOnVWAPCross) {
         double vwap = 0.0;
         if(GetSessionVWAP(InpSymbol, VWAP_TF, VWAP_UseRealVolume, vwap)) {
            if(type == POSITION_TYPE_BUY && bid < vwap) {
               trade.PositionClose(tk);
               g_lastAction = "Saida VWAP Buy"; g_lastActionTime = TimeCurrent();
               continue;
            }
            if(type == POSITION_TYPE_SELL && ask > vwap) {
               trade.PositionClose(tk);
               g_lastAction = "Saida VWAP Sell"; g_lastActionTime = TimeCurrent();
               continue;
            }
         }
      }

      double rPts = (sl > 0.0) ? MathAbs(price - sl) / pt : StopLossPoints;

      // ======== TRAILING SIMPLES (legado) ========
      // Só usa se o trailing avançado estiver desligado
      if(AdvTrail_Mode == TRAIL_OFF && UseATRTrailing) {
         double atr = 0.0; GetBuf(hATR, 0, atr, 0);
         if(atr > 0.0) {
            if(type == POSITION_TYPE_BUY) {
               double nsl = bid - ATR_TrailMult * atr;
               if(sl == 0.0 || nsl > sl) ModifyPositionByTicket(tk, nsl, tp, sym);
            }
            else {
               double nsl = ask + ATR_TrailMult * atr;
               if(sl == 0.0 || nsl < sl) ModifyPositionByTicket(tk, nsl, tp, sym);
            }
         }
      }

      // ======== BREAK-EVEN (legado) ========
      // Só usa se o profit lock avançado estiver desligado
      if(AdvTrail_Mode == TRAIL_OFF && UseBreakEven && rPts > 0.0) {
         if(type == POSITION_TYPE_BUY) {
            double gain = (bid - price) / pt;
            if(gain >= rPts) {
               double nsl = price + BE_Lock_R_Fraction * rPts * pt;
               if(sl == 0.0 || (nsl > sl && MathAbs(nsl - sl) > pt)) ModifyPositionByTicket(tk, nsl, tp, sym);
            }
         }
         else {
            double gain = (price - ask) / pt;
            if(gain >= rPts) {
               double nsl = price - BE_Lock_R_Fraction * rPts * pt;
               if(sl == 0.0 || (nsl < sl && MathAbs(nsl - sl) > pt)) ModifyPositionByTicket(tk, nsl, tp, sym);
            }
         }
      }
   }
}

#endif // __MAABOT_TRADEMANAGEMENT_MQH__
//+------------------------------------------------------------------+
