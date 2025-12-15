//+------------------------------------------------------------------+
//|                                                       Utils.mqh  |
//|   MAAbot v2.3.1 - Funções Utilitárias                            |
//|                                     Autor: Eliabe N Oliveira     |
//+------------------------------------------------------------------+
#ifndef __MAABOT_UTILS_MQH__
#define __MAABOT_UTILS_MQH__

#include "Inputs.mqh"
#include "Globals.mqh"

//-------------------------- UTILITÁRIOS BÁSICOS ----------------------//
double Pt() { 
   double pt = SymbolInfoDouble(InpSymbol, SYMBOL_POINT);
   return (pt > 0) ? pt : 0.00001;
}

double Bid() { return SymbolInfoDouble(InpSymbol, SYMBOL_BID); }
double Ask() { return SymbolInfoDouble(InpSymbol, SYMBOL_ASK); }

double NormalizeToDigits(string sym, double price) {
   int digits = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
   return NormalizeDouble(price, digits);
}

bool ModifyPositionByTicket(ulong tk, double sl, double tp, string sym) {
   MqlTradeRequest req; MqlTradeResult res; 
   ZeroMemory(req); ZeroMemory(res);
   req.action   = TRADE_ACTION_SLTP;
   req.symbol   = sym;
   req.position = tk;
   if(sl > 0.0) req.sl = NormalizeToDigits(sym, sl);
   if(tp > 0.0) req.tp = NormalizeToDigits(sym, tp);
   return OrderSend(req, res);
}

bool InTradingWindow(datetime tserver) { 
   MqlDateTime s; TimeToStruct(tserver, s);
   int minutes = s.hour * 60 + s.min;
   
   if(BlockRollover) { 
      if(RolloverStartMin > RolloverEndMin) { 
         if(minutes >= RolloverStartMin || minutes <= RolloverEndMin) return false; 
      }
      else { 
         if(minutes >= RolloverStartMin && minutes <= RolloverEndMin) return false; 
      } 
   }
   
   if(s.day_of_week == 0 || s.day_of_week == 6) return false;
   
   if(StartHour <= EndHour) 
      return (s.hour >= StartHour && s.hour < EndHour);
   return (s.hour >= StartHour || s.hour < EndHour); 
}

bool SpreadOK() { 
   int sprd = (int)SymbolInfoInteger(InpSymbol, SYMBOL_SPREAD); 
   g_currentSpread = sprd;
   return (sprd > 0 && sprd <= MaxSpreadPoints); 
}

datetime DayStart(datetime t) { 
   MqlDateTime s; TimeToStruct(t, s); 
   s.hour = 0; s.min = 0; s.sec = 0; 
   return StructToTime(s); 
}

bool GetBuf(int h, int b, double &v, int sh=0) { 
   if(h == INVALID_HANDLE) return false;
   double tmp[]; 
   if(CopyBuffer(h, b, sh, 1, tmp) <= 0) return false; 
   v = tmp[0]; 
   return true; 
}

double ROC(string sym, ENUM_TIMEFRAMES tf, int p) { 
   double c[]; ArraySetAsSeries(c, true);
   if(CopyClose(sym, tf, 0, p+1, c) < p+1) return 0.0; 
   double now = c[0], prev = c[p]; 
   if(prev == 0.0) return 0.0; 
   return (now - prev) / prev; 
}

bool GetSessionVWAP(string sym, ENUM_TIMEFRAMES tf, bool useReal, double &vwap) {
   datetime now = TimeCurrent(), from = DayStart(now); 
   MqlRates r[]; ArraySetAsSeries(r, true); 
   if(CopyRates(sym, tf, from, now, r) <= 0) return false;
   
   double num = 0.0, den = 0.0; 
   int N = ArraySize(r);
   
   for(int i = 0; i < N; i++) { 
      double tp = (r[i].high + r[i].low + r[i].close) / 3.0; 
      double vol = useReal ? (double)r[i].real_volume : (double)r[i].tick_volume; 
      num += tp * vol; den += vol; 
   }
   
   if(den <= 0.0) return false; 
   vwap = num / den; 
   return true; 
}

#endif // __MAABOT_UTILS_MQH__
//+------------------------------------------------------------------+
