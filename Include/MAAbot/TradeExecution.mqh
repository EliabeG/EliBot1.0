//+------------------------------------------------------------------+
//|                                            TradeExecution.mqh    |
//|   MAAbot v2.3.1 - Execução de Trades                             |
//|                                     Autor: Eliabe N Oliveira     |
//+------------------------------------------------------------------+
#ifndef __MAABOT_TRADEEXECUTION_MQH__
#define __MAABOT_TRADEEXECUTION_MQH__

#include <Trade/Trade.mqh>
#include "Inputs.mqh"
#include "Globals.mqh"
#include "Utils.mqh"
#include "Signals.mqh"
#include "Trend.mqh"
#include "RiskManagement.mqh"
#include "TradeManagement.mqh"
#include "Grid.mqh"
#include "Basket.mqh"
#include "DailyTargetManager.mqh"

//-------------------------- TRY OPEN ----------------------------------------//
bool TryOpen(int dir, const Signals &S, double pDir, double thr, datetime now, CTrade &trade) {
   if(dir > 0) g_blockReasonBuy = ""; else g_blockReasonSell = "";

   // ======== VERIFICAÇÃO DE COOLDOWN POR MARGEM ========
   // Evita loop infinito quando não há margem suficiente
   if(g_lastMarginFailTime > 0 && (now - g_lastMarginFailTime) < g_marginCooldownSeconds) {
      string reason = StringFormat("Margin cooldown (%ds)", g_marginCooldownSeconds - (int)(now - g_lastMarginFailTime));
      if(dir > 0) g_blockReasonBuy = reason; else g_blockReasonSell = reason;
      return false;
   }

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
   
   if(!DD_AllowsNewEntries(trade)) {
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
         // CORREÇÃO: Notifica sistema de meta diária sobre novo trade
         OnDailyTargetTradeOpened();
         // Reseta contadores de falha de margem
         g_marginFailCount = 0;
         g_lastMarginFailTime = 0;
      }
      else {
         // Verifica se foi falha por margem
         HandleTradeFailure(dir, trade, now);
      }
   }
   else {
      double pt = Pt();
      if(dir > 0) {
         double sl = Bid() - sl_pts * pt, tp = Bid() + tp_pts * pt;
         ok = trade.Buy(vol, InpSymbol, Ask(), sl, tp, "BUY");
         if(ok) {
            lastBuyTime = now;
            g_lastAction = "ABRIU BUY";
            g_lastActionTime = now;
            // CORREÇÃO: Notifica sistema de meta diária sobre novo trade
            OnDailyTargetTradeOpened();
            // Reseta contadores de falha de margem
            g_marginFailCount = 0;
            g_lastMarginFailTime = 0;
         }
         else HandleTradeFailure(dir, trade, now);
      }
      else {
         double sl = Ask() + sl_pts * pt, tp = Ask() - tp_pts * pt;
         ok = trade.Sell(vol, InpSymbol, Bid(), sl, tp, "SELL");
         if(ok) {
            lastSellTime = now;
            g_lastAction = "ABRIU SELL";
            g_lastActionTime = now;
            // CORREÇÃO: Notifica sistema de meta diária sobre novo trade
            OnDailyTargetTradeOpened();
            // Reseta contadores de falha de margem
            g_marginFailCount = 0;
            g_lastMarginFailTime = 0;
         }
         else HandleTradeFailure(dir, trade, now);
      }
   }
   return ok;
}

// Trata falha de trade e detecta se foi por margem insuficiente
void HandleTradeFailure(int dir, CTrade &trade, datetime now) {
   uint retcode = trade.ResultRetcode();
   string reason = "Trade failed";

   // Verifica códigos de erro relacionados a margem
   if(retcode == TRADE_RETCODE_NO_MONEY || retcode == 10019) {
      reason = "No money/margin";
      g_marginFailCount++;
      g_lastMarginFailTime = now;

      // Aumenta cooldown progressivamente com falhas consecutivas
      g_marginCooldownSeconds = MathMin(300, 60 * g_marginFailCount); // Máx 5 min

      Print("[MARGIN FAIL] Falha #", g_marginFailCount,
            " | Cooldown: ", g_marginCooldownSeconds, "s",
            " | Próxima tentativa após: ", TimeToString(now + g_marginCooldownSeconds));
   }
   else {
      reason = StringFormat("Error %d: %s", retcode, trade.ResultRetcodeDescription());
   }

   if(dir > 0) g_blockReasonBuy = reason;
   else g_blockReasonSell = reason;
}

#endif // __MAABOT_TRADEEXECUTION_MQH__
//+------------------------------------------------------------------+
