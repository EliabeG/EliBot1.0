//+------------------------------------------------------------------+
//|                                                     Filters.mqh  |
//|   MAAbot v2.3.1 - Filtros (Notícias e Falhas)                    |
//|                                     Autor: Eliabe N Oliveira     |
//+------------------------------------------------------------------+
#ifndef __MAABOT_FILTERS_MQH__
#define __MAABOT_FILTERS_MQH__

#include "Inputs.mqh"
#include "Globals.mqh"
#include "Utils.mqh"

//-------------------------- FILTRO DE FALHA RÁPIDA -------------------------//
void CheckForFailedEntries() {
   if(!UseFailedEntryFilter) return;
   if(!HistorySelect(DayStart(TimeCurrent()), TimeCurrent())) return;
   
   uint totalDeals = HistoryDealsTotal();
   
   for(uint i = 0; i < totalDeals; i++) {
      ulong dealTicket = HistoryDealGetTicket(i);
      if(dealTicket == 0) continue;
      if(dealTicket <= g_lastCheckedDeal) continue;
      
      if((long)HistoryDealGetInteger(dealTicket, DEAL_MAGIC) != Magic) continue;
      if(HistoryDealGetString(dealTicket, DEAL_SYMBOL) != InpSymbol) continue;
      
      if((ENUM_DEAL_ENTRY)HistoryDealGetInteger(dealTicket, DEAL_ENTRY) == DEAL_ENTRY_OUT && 
         HistoryDealGetDouble(dealTicket, DEAL_PROFIT) < 0) {
         
         ulong positionID = (ulong)HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID);
         datetime closeTime = (datetime)HistoryDealGetInteger(dealTicket, DEAL_TIME);
         ENUM_DEAL_TYPE dealType = (ENUM_DEAL_TYPE)HistoryDealGetInteger(dealTicket, DEAL_TYPE);

         for(uint j = 0; j < totalDeals; j++) {
            ulong entryDealTicket = HistoryDealGetTicket(j);
            if(entryDealTicket == 0) continue;
            
            if((ulong)HistoryDealGetInteger(entryDealTicket, DEAL_POSITION_ID) == positionID && 
               (ENUM_DEAL_ENTRY)HistoryDealGetInteger(entryDealTicket, DEAL_ENTRY) == DEAL_ENTRY_IN) {
               
               datetime openTime = (datetime)HistoryDealGetInteger(entryDealTicket, DEAL_TIME);
               long durationInSeconds = (long)(closeTime - openTime);
               long periodSeconds = PeriodSeconds(InpTF);
               if(periodSeconds <= 0) continue;
               int barsInTrade = (int)(durationInSeconds / periodSeconds);

               if(barsInTrade <= FailedEntryBars) {
                  if(dealType == DEAL_TYPE_SELL)
                     g_buyPenaltyUntil = TimeCurrent() + FailedEntryCooldownMin * 60;
                  else if(dealType == DEAL_TYPE_BUY)
                     g_sellPenaltyUntil = TimeCurrent() + FailedEntryCooldownMin * 60;
               }
               break;
            }
         }
      }
      
      if(dealTicket > g_lastCheckedDeal)
         g_lastCheckedDeal = dealTicket;
   }
}

//-------------------------- DETECTOR DE NOTÍCIAS ---------------------------//
void DetectNewsBehavior() {
   if(!UseNewsDetector) { g_isNewsBehavior = false; return; }

   if(News_UseStdDev) {
      int bars_to_check = News_AvgLookback + News_Lookback_Window + 2; 
      MqlRates rates[];
      if(CopyRates(InpSymbol, InpTF, 0, bars_to_check, rates) < bars_to_check) {
         g_isNewsBehavior = false; return;
      }
      ArraySetAsSeries(rates, true);

      double sum_of_ranges = 0;
      double ranges[];
      ArrayResize(ranges, News_AvgLookback);

      for(int i = 0; i < News_AvgLookback; i++) {
         int idx = i + News_Lookback_Window;
         if(idx >= ArraySize(rates)) continue;
         double range = rates[idx].high - rates[idx].low;
         ranges[i] = range;
         sum_of_ranges += range;
      }
      
      double avg_range = (News_AvgLookback > 0) ? sum_of_ranges / News_AvgLookback : 0;
      
      double sum_of_squared_diff = 0;
      for(int i = 0; i < News_AvgLookback; i++) {
         sum_of_squared_diff += MathPow(ranges[i] - avg_range, 2);
      }
      
      double std_dev_range = (News_AvgLookback > 0) ? MathSqrt(sum_of_squared_diff / News_AvgLookback) : 0;
      double volatility_threshold = avg_range + (News_StdDev_Ratio * std_dev_range);

      g_isNewsBehavior = false;
      for(int i = 1; i <= News_Lookback_Window; i++) {
         if(i >= ArraySize(rates)) continue;
         
         double last_candle_range = rates[i].high - rates[i].low;
         double last_candle_body  = MathAbs(rates[i].close - rates[i].open);
         
         bool is_volatility_spike = (last_candle_range > volatility_threshold);
         bool has_conviction = (last_candle_range > 0) ? ((last_candle_body / last_candle_range) >= News_BodyToRange_Ratio) : false;

         if(is_volatility_spike && has_conviction) {
            g_isNewsBehavior = true;
            break;
         }
      }
      return;
   }
   else {
      int bars_to_check = News_AvgLookback + 2;
      MqlRates rates[];
      if(CopyRates(InpSymbol, InpTF, 0, bars_to_check, rates) < bars_to_check) {
         g_isNewsBehavior = false; return;
      }
      ArraySetAsSeries(rates, true);

      double total_size = 0;
      long total_volume = 0;
      for(int i = 2; i < News_AvgLookback + 2; i++) {
         if(i >= ArraySize(rates)) continue;
         total_size += rates[i].high - rates[i].low;
         total_volume += rates[i].tick_volume;
      }
      
      double avg_size = (News_AvgLookback > 0) ? total_size / News_AvgLookback : 0;
      double avg_volume = (News_AvgLookback > 0) ? (double)total_volume / News_AvgLookback : 0;

      double last_candle_size = rates[1].high - rates[1].low;
      long last_candle_volume = rates[1].tick_volume;

      bool isVolatilitySpike = (avg_size > 0 && (last_candle_size / avg_size) >= News_CandleToAvg_Ratio);
      bool isVolumeSpike = (avg_volume > 0 && (last_candle_volume / avg_volume) >= News_VolumeToAvg_Ratio);

      g_isNewsBehavior = (isVolatilitySpike && isVolumeSpike);
   }
}

#endif // __MAABOT_FILTERS_MQH__
//+------------------------------------------------------------------+
