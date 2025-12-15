//+------------------------------------------------------------------+
//|                                            TradeExecution.mqh    |
//|   MAAbot v2.3.1 - Execução de Trades                             |
//|                                     Autor: Eliabe N Oliveira     |
//+------------------------------------------------------------------+
#ifndef __MAABOT_TRADEEXECUTION_MQH__
#define __MAABOT_TRADEEXECUTION_MQH__

#include "Inputs.mqh"
#include "Globals.mqh"
#include "Utils.mqh"
#include "Signals.mqh"
#include "Trend.mqh"
#include "RiskManagement.mqh"
#include "TradeManagement.mqh"
#include "Grid.mqh"
#include "Basket.mqh"

//-------------------------- TRY OPEN ----------------------------------------//
bool TryOpen(int dir, const Signals &S, double pDir, double thr, datetime now) {
   if(dir > 0) g_blockReasonBuy = ""; else g_blockReasonSell = "";
   
   if(UseFailedEntryFilter) {
      if(dir > 0 && now < g_buyPenaltyUntil) { g_blockReasonBuy = "Penalty cooldown"; return false; }
      if(dir < 0 && now < g_sellPenaltyUntil) { g_blockReasonSell = "Penalty cooldown"; return false; }
   }
   
   if(dir > 0 && !AllowLong) { g_blockReasonBuy = "AllowLong=false"; return false; }
   if(dir < 0 && !AllowShort) { g_blockReasonSell = "AllowShort=false"; return false; }
   
   if(pDir < thr) {
      if(dir > 0) g_blockReasonBuy = StringFormat("Prob %.0f%% < %.0f%%", pDir*100, thr*100);
      else g_blockReasonSell = StringFormat("Prob %.0f%% < %.0f%%", pDir*100, thr*100);
      return false;
   }
   
   if(!EntryTFAgree(dir)) {
      if(dir > 0) g_blockReasonBuy = "EntryTF disagree"; else g_blockReasonSell = "EntryTF disagree";
      return false;
   }
   
   if(!DD_AllowsNewEntries()) {
      if(dir > 0) g_blockReasonBuy = "DD limit"; else g_blockReasonSell = "DD limit";
      return false;
   }
   
   if(!TrendAllowsEntry(dir)) {
      if(dir > 0) g_blockReasonBuy = "Trend filter"; else g_blockReasonSell = "Trend filter";
      return false;
   }
   
   if(dir > 0 && (now - lastBuyTime) < MinSecondsBetweenTrades) { g_blockReasonBuy = "Min time"; return false; }
   if(dir < 0 && (now - lastSellTime) < MinSecondsBetweenTrades) { g_blockReasonSell = "Min time"; return false; }
   
   int sl_pts = StopLossPoints, tp_pts = TakeProfitPoints; 
   CalcStopsTP_Regime(dir, g_trending, sl_pts, tp_pts);
   
   double effRisk = EffectiveRiskPercentForNextTrade(); 
   double vol = LotsForRiskPercent(effRisk, sl_pts);
   
   if(vol <= 0.0) {
      if(dir > 0) g_blockReasonBuy = "Invalid lot"; else g_blockReasonSell = "Invalid lot";
      return false;
   }
   
   bool ok = false;
   
   if(MG_Mode == MG_GRID) {
      if(dir > 0) ok = trade.Buy(vol, InpSymbol, Ask(), 0.0, 0.0, "BUY-INIT");
      else ok = trade.Sell(vol, InpSymbol, Bid(), 0.0, 0.0, "SELL-INIT");
      
      if(ok) { 
         if(dir > 0) { lastBuyTime = now; GridInitIfNeed(+1); g_lastAction = "ABRIU BUY"; } 
         else { lastSellTime = now; GridInitIfNeed(-1); g_lastAction = "ABRIU SELL"; }
         g_lastActionTime = now;
      }
      else {
         if(dir > 0) g_blockReasonBuy = "Trade failed"; else g_blockReasonSell = "Trade failed";
      }
   }
   else {
      double pt = Pt();
      if(dir > 0) { 
         double sl = Bid() - sl_pts * pt, tp = Bid() + tp_pts * pt; 
         ok = trade.Buy(vol, InpSymbol, Ask(), sl, tp, "BUY"); 
         if(ok) { lastBuyTime = now; g_lastAction = "ABRIU BUY"; g_lastActionTime = now; }
         else g_blockReasonBuy = "Trade failed";
      }
      else { 
         double sl = Ask() + sl_pts * pt, tp = Ask() - tp_pts * pt; 
         ok = trade.Sell(vol, InpSymbol, Bid(), sl, tp, "SELL"); 
         if(ok) { lastSellTime = now; g_lastAction = "ABRIU SELL"; g_lastActionTime = now; }
         else g_blockReasonSell = "Trade failed";
      }
   }
   return ok;
}

#endif // __MAABOT_TRADEEXECUTION_MQH__
//+------------------------------------------------------------------+
