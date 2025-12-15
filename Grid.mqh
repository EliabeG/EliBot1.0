//+------------------------------------------------------------------+
//|                                                        Grid.mqh  |
//|   MAAbot v2.3.1 - Sistema Grid/Martingale                        |
//|                                     Autor: Eliabe N Oliveira     |
//+------------------------------------------------------------------+
#ifndef __MAABOT_GRID_MQH__
#define __MAABOT_GRID_MQH__

#include "Inputs.mqh"
#include "Globals.mqh"
#include "Utils.mqh"
#include "Basket.mqh"
#include "Signals.mqh"
#include "RiskManagement.mqh"

//-------------------------- GRID HELPERS (Trend-Aware) ----------------------//
void GridReset(int dir) { 
   if(dir > 0) { gridBuy.active = false; gridBuy.adds = 0; gridBuy.basePrice = 0; gridBuy.lastAddPrice = 0; gridBuy.baseLot = 0; }
   else { gridSell.active = false; gridSell.adds = 0; gridSell.basePrice = 0; gridSell.lastAddPrice = 0; gridSell.baseLot = 0; } 
}

int GridTargetPts() { 
   if(MG_Grid_TargetATRMult > 0.0) { 
      double atr = 0.0; 
      if(hATR == INVALID_HANDLE) hATR = iATR(InpSymbol, InpTF, ATR_Period);
      if(GetBuf(hATR, 0, atr, 0)) { 
         double pt = Pt();
         if(pt > 0) { int v = (int)MathRound((atr * MG_Grid_TargetATRMult) / pt); if(v > 0) return v; }
      } 
   } 
   return MG_Grid_TargetPoints; 
}

int GridMaxAdversePts() { 
   if(MG_Grid_MaxAdvATRMult > 0.0) { 
      double atr = 0.0; 
      if(hATR == INVALID_HANDLE) hATR = iATR(InpSymbol, InpTF, ATR_Period);
      if(GetBuf(hATR, 0, atr, 0)) { 
         double pt = Pt();
         if(pt > 0) { int v = (int)MathRound((atr * MG_Grid_MaxAdvATRMult) / pt); if(v > 0) return v; }
      } 
   } 
   return MG_Grid_MaxAdversePoints; 
}

double LotCapByRiskSum() { 
   if(MG_Grid_MaxRiskPercentSum <= 0.0) return SymbolInfoDouble(InpSymbol, SYMBOL_VOLUME_MAX); 
   return LotsForRiskPercent(MG_Grid_MaxRiskPercentSum, StopLossPoints); 
}

int AllowedAddsForDir(int dir) {
   if(g_isNewsBehavior) return (dir == g_trendDir) ? MG_Grid_News_MaxAdds_InTrend : MG_Grid_News_MaxAdds_Counter;
   if(!MG_Grid_TrendAware || !g_trending) return MathMax(MG_Grid_MaxAdds_InTrend, MG_Grid_MaxAdds_Counter);
   return (dir == g_trendDir) ? MG_Grid_MaxAdds_InTrend : MG_Grid_MaxAdds_Counter; 
}

double VolMultForDir(int dir) {
   if(g_isNewsBehavior) return (dir == g_trendDir) ? MG_Grid_News_VolMult_InTrend : MG_Grid_News_VolMult_Counter;
   if(!MG_Grid_TrendAware || !g_trending) return MG_Grid_VolMult_InTrend;
   return (dir == g_trendDir) ? MG_Grid_VolMult_InTrend : MG_Grid_VolMult_Counter; 
}

int StepPtsForDir(int dir) {
   int stepPts = MG_Grid_StepPoints; 
   double mult;
   if(g_isNewsBehavior) mult = (dir == g_trendDir) ? MG_Grid_News_ATRMult_InTrend : MG_Grid_News_ATRMult_Counter;
   else {
      mult = MG_Grid_ATRMult;
      if(MG_Grid_TrendAware && g_trending) mult = (dir == g_trendDir) ? MG_Grid_ATRMult_InTrend : MG_Grid_ATRMult_Counter;
   }
   
   if(MG_Grid_UseATR) {
      double atr = 0.0; 
      if(hATR == INVALID_HANDLE) hATR = iATR(InpSymbol, InpTF, ATR_Period); 
      if(GetBuf(hATR, 0, atr, 0)) {
         double pt = Pt();
         if(pt > 0) { int v = (int)MathRound((atr * mult) / pt); if(v > 0) stepPts = v; }
      } 
   }
   return MathMax(1, stepPts); 
}

void GridInitIfNeed(int dir) {
   BasketInfo b; BasketStats(dir, b);
   
   if(dir > 0) {
      if(!gridBuy.active && b.cnt > 0) {
         gridBuy.active = true;
         gridBuy.adds = (b.cnt > 0) ? b.cnt - 1 : 0;
         gridBuy.baseLot = b.vol;
         gridBuy.basePrice = b.avg;
         
         double last_price = 0; datetime last_time = 0;
         for(int i = PositionsTotal() - 1; i >= 0; i--) {
            ulong tk = PositionGetTicket(i);
            if(!PositionSelectByTicket(tk)) continue;
            if(PositionGetString(POSITION_SYMBOL) == InpSymbol && 
               (long)PositionGetInteger(POSITION_MAGIC) == Magic && 
               (long)PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
               datetime ptime = (datetime)PositionGetInteger(POSITION_TIME);
               if(ptime > last_time) { last_time = ptime; last_price = PositionGetDouble(POSITION_PRICE_OPEN); }
            }
         }
         gridBuy.lastAddPrice = (last_price > 0) ? last_price : Bid();
      }
      if(b.cnt == 0) GridReset(+1);
   }
   else {
      if(!gridSell.active && b.cnt > 0) {
         gridSell.active = true;
         gridSell.adds = (b.cnt > 0) ? b.cnt - 1 : 0;
         gridSell.baseLot = b.vol;
         gridSell.basePrice = b.avg;
         
         double last_price = 0; datetime last_time = 0;
         for(int i = PositionsTotal() - 1; i >= 0; i--) {
            ulong tk = PositionGetTicket(i);
            if(!PositionSelectByTicket(tk)) continue;
            if(PositionGetString(POSITION_SYMBOL) == InpSymbol && 
               (long)PositionGetInteger(POSITION_MAGIC) == Magic && 
               (long)PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
               datetime ptime = (datetime)PositionGetInteger(POSITION_TIME);
               if(ptime > last_time) { last_time = ptime; last_price = PositionGetDouble(POSITION_PRICE_OPEN); }
            }
         }
         gridSell.lastAddPrice = (last_price > 0) ? last_price : Ask();
      }
      if(b.cnt == 0) GridReset(-1);
   }
}

void GridTryAdd(const Signals &S, int dir) {
   if(MG_Mode != MG_GRID) return;
   
   int allowed = AllowedAddsForDir(dir);
   double volmult = VolMultForDir(dir);
   int stepPts = StepPtsForDir(dir); 
   double pt = Pt(); 
   double price = (dir > 0) ? Bid() : Ask();
   
   if(dir > 0) {
      if(!gridBuy.active || gridBuy.adds >= allowed) return;
      if(MG_Grid_RespectStructure && !StructureOK(S, +1)) return;
      
      bool trigger = (price <= gridBuy.lastAddPrice - stepPts * pt);
      if(!trigger) return;
      
      BasketInfo b; BasketStats(+1, b);
      
      double addLot = gridBuy.baseLot * MathPow(volmult, gridBuy.adds);
      double cap = LotCapByRiskSum(); 
      double stepVol = SymbolInfoDouble(InpSymbol, SYMBOL_VOLUME_STEP); 
      if(stepVol <= 0.0) stepVol = 0.01;
      
      double remain = cap - b.vol; 
      if(remain <= stepVol) return; 
      
      addLot = MathMin(addLot, remain); 
      int k = (int)MathFloor(addLot / stepVol); 
      addLot = k * stepVol; 
      if(addLot < stepVol) return;
      
      if(trade.Buy(addLot, InpSymbol, Ask(), 0.0, 0.0, "MG-ADD-BUY")) { 
         gridBuy.adds++; gridBuy.lastAddPrice = price;
         g_lastAction = "Grid ADD Buy"; g_lastActionTime = TimeCurrent();
      }
   }
   else {
      if(!gridSell.active || gridSell.adds >= allowed) return;
      if(MG_Grid_RespectStructure && !StructureOK(S, -1)) return;
      
      bool trigger = (price >= gridSell.lastAddPrice + stepPts * pt);
      if(!trigger) return;
      
      BasketInfo b; BasketStats(-1, b);
      
      double addLot = gridSell.baseLot * MathPow(volmult, gridSell.adds);
      double cap = LotCapByRiskSum(); 
      double stepVol = SymbolInfoDouble(InpSymbol, SYMBOL_VOLUME_STEP); 
      if(stepVol <= 0.0) stepVol = 0.01;
      
      double remain = cap - b.vol; 
      if(remain <= stepVol) return; 
      
      addLot = MathMin(addLot, remain); 
      int k = (int)MathFloor(addLot / stepVol); 
      addLot = k * stepVol; 
      if(addLot < stepVol) return;
      
      if(trade.Sell(addLot, InpSymbol, Bid(), 0.0, 0.0, "MG-ADD-SELL")) { 
         gridSell.adds++; gridSell.lastAddPrice = price;
         g_lastAction = "Grid ADD Sell"; g_lastActionTime = TimeCurrent();
      }
   }
}

bool GridTPHit(int dir) { 
   BasketInfo b; BasketStats(dir, b); 
   if(b.cnt <= 0) return false; 
   double pt = Pt(); int target = GridTargetPts(); 
   double price = (dir > 0) ? Bid() : Ask();
   if(dir > 0) return (price >= b.avg + target * pt); 
   return (price <= b.avg - target * pt); 
}

bool GridStopHit(int dir) { 
   int adv = GridMaxAdversePts(); 
   double pt = Pt(); 
   double price = (dir > 0) ? Bid() : Ask();
   if(dir > 0) { if(!gridBuy.active) return false; return (price <= gridBuy.basePrice - adv * pt); } 
   else { if(!gridSell.active) return false; return (price >= gridSell.basePrice + adv * pt); } 
}

#endif // __MAABOT_GRID_MQH__
//+------------------------------------------------------------------+
