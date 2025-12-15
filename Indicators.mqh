//+------------------------------------------------------------------+
//|                                                  Indicators.mqh  |
//|   MAAbot v2.3.1 - Funções de Indicadores                         |
//|                                     Autor: Eliabe N Oliveira     |
//+------------------------------------------------------------------+
#ifndef __MAABOT_INDICATORS_MQH__
#define __MAABOT_INDICATORS_MQH__

#include "Inputs.mqh"
#include "Globals.mqh"
#include "Utils.mqh"

//============================================================================//
//                    SUPERTREND CORRIGIDO                                    //
//============================================================================//
int CalcSupertrendSignalCached(string sym, ENUM_TIMEFRAMES tf, int atr_period, double mult, int &hATR_ST_Handle) {
   const int B = 300; 
   MqlRates r[]; ArraySetAsSeries(r, true); 
   if(CopyRates(sym, tf, 0, B, r) < B) return 0;
   
   double atr[]; ArraySetAsSeries(atr, true);
   
   if(hATR_ST_Handle == INVALID_HANDLE) 
      hATR_ST_Handle = iATR(sym, tf, atr_period);
   if(hATR_ST_Handle == INVALID_HANDLE) return 0;
   if(CopyBuffer(hATR_ST_Handle, 0, 0, B, atr) < B) return 0;
   
   double u[], l[], fu[], fl[]; 
   ArrayResize(u, B); ArrayResize(l, B); ArrayResize(fu, B); ArrayResize(fl, B);
   
   int trend = 1;
   for(int i = B-1; i >= 0; i--) {
      double hl2 = (r[i].high + r[i].low) / 2.0; 
      u[i] = hl2 + mult * atr[i]; 
      l[i] = hl2 - mult * atr[i];
      
      if(i == B-1) { fu[i] = u[i]; fl[i] = l[i]; continue; }
      
      fu[i] = (u[i] < fu[i+1] || r[i+1].close > fu[i+1]) ? u[i] : fu[i+1];
      fl[i] = (l[i] > fl[i+1] || r[i+1].close < fl[i+1]) ? l[i] : fl[i+1];
      
      if(trend == 1 && r[i].close < fl[i]) trend = -1; 
      else if(trend == -1 && r[i].close > fu[i]) trend = 1;
   }
   return trend;
}

//============================================================================//
//                    QQE SEM MEMORY LEAK                                     //
//============================================================================//
int CalcQQESignal(string sym, ENUM_TIMEFRAMES tf, int rsi_period, int sf) {
   const int bars = 200;
   
   if(hQQE_RSI == INVALID_HANDLE) return 0;
   
   double rsi_buffer[];
   ArraySetAsSeries(rsi_buffer, true);
   
   if(CopyBuffer(hQQE_RSI, 0, 0, bars, rsi_buffer) < bars) return 0;
   
   double smoothed_rsi[]; 
   ArrayResize(smoothed_rsi, bars);
   ArrayInitialize(smoothed_rsi, 50.0);
   
   double alpha = 2.0 / (sf + 1.0);
   smoothed_rsi[bars-1] = rsi_buffer[bars-1];
   
   for(int i = bars - 2; i >= 0; i--) { 
      smoothed_rsi[i] = rsi_buffer[i] * alpha + smoothed_rsi[i+1] * (1.0 - alpha); 
   }
   
   double rsi_atr[];
   ArrayResize(rsi_atr, bars);
   ArrayInitialize(rsi_atr, 0);
   
   for(int i = bars - sf - 1; i >= 0; i--) {
      double sum = 0;
      for(int j = 0; j < sf; j++) {
         if(i + j + 1 < bars)
            sum += MathAbs(smoothed_rsi[i+j] - smoothed_rsi[i+j+1]);
      }
      rsi_atr[i] = sum / sf;
   }
   
   double wilders_atr[];
   ArrayResize(wilders_atr, bars);
   ArrayInitialize(wilders_atr, 0);
   
   wilders_atr[bars-1] = rsi_atr[bars-1];
   double wilders_alpha = 1.0 / (sf * 2.0);
   
   for(int i = bars - 2; i >= 0; i--) {
      wilders_atr[i] = rsi_atr[i] * wilders_alpha + wilders_atr[i+1] * (1.0 - wilders_alpha);
   }
   
   double mult = 4.236;
   double fast_atr[];
   ArrayResize(fast_atr, bars);
   
   for(int i = 0; i < bars; i++) {
      fast_atr[i] = wilders_atr[i] * mult;
   }
   
   double qqe_line[];
   ArrayResize(qqe_line, bars);
   qqe_line[bars-1] = smoothed_rsi[bars-1];
   
   for(int i = bars - 2; i >= 0; i--) {
      double upper = qqe_line[i+1] + fast_atr[i];
      double lower = qqe_line[i+1] - fast_atr[i];
      
      if(smoothed_rsi[i] > qqe_line[i+1]) {
         qqe_line[i] = MathMax(lower, smoothed_rsi[i] > upper ? smoothed_rsi[i] : qqe_line[i+1]);
      } else {
         qqe_line[i] = MathMin(upper, smoothed_rsi[i] < lower ? smoothed_rsi[i] : qqe_line[i+1]);
      }
   }
   
   bool cross_up = (smoothed_rsi[0] > qqe_line[0] && smoothed_rsi[1] <= qqe_line[1]);
   bool cross_down = (smoothed_rsi[0] < qqe_line[0] && smoothed_rsi[1] >= qqe_line[1]);
   
   if(cross_up) return 1;
   if(cross_down) return -1;
   
   if(smoothed_rsi[0] > qqe_line[0] && smoothed_rsi[0] > 50) return 1;
   if(smoothed_rsi[0] < qqe_line[0] && smoothed_rsi[0] < 50) return -1;
   
   return 0;
}

//============================================================================//
//                    HEIKIN ASHI                                             //
//============================================================================//
int HeikinAshiSignal(string sym, ENUM_TIMEFRAMES tf) { 
   const int B = 6; 
   MqlRates r[]; ArraySetAsSeries(r, true);
   if(CopyRates(sym, tf, 0, B, r) < B) return 0; 
   
   double ho[], hc[]; 
   ArrayResize(ho, B); ArrayResize(hc, B);
   
   for(int i = B-1; i >= 0; i--) { 
      double cl = (r[i].open + r[i].high + r[i].low + r[i].close) / 4.0; 
      double op = (i == B-1) ? (r[i].open + r[i].close) / 2.0 : (ho[i+1] + hc[i+1]) / 2.0; 
      hc[i] = cl; ho[i] = op; 
   }
   
   bool bull = (hc[1] > ho[1] && hc[0] > ho[0]);
   bool bear = (hc[1] < ho[1] && hc[0] < ho[0]);
   
   if(bull && !bear) return 1; 
   if(bear && !bull) return -1; 
   return 0; 
}

//============================================================================//
//                    KAMA (Kaufman Adaptive Moving Average)                  //
//============================================================================//
double CalcKAMA(const double &c[], int n, int er, int f, int s) { 
   if(n <= er + 2) return c[0];
   
   double fSC = 2.0 / (f + 1.0), sSC = 2.0 / (s + 1.0); 
   int seed = n - 1 - er; 
   if(seed < 0) seed = 0; 
   double kama = c[seed];
   
   for(int i = seed + 1; i < n; i++) { 
      int start_idx = i - er;
      if(start_idx < 0) start_idx = 0;
      
      double ch = MathAbs(c[i] - c[start_idx]); 
      double vol = 0.0; 
      
      for(int j = start_idx + 1; j <= i && j < n; j++) 
         vol += MathAbs(c[j] - c[j-1]);
      
      double ER = (vol == 0.0) ? 0.0 : ch / vol; 
      double SC = MathPow(ER * (fSC - sSC) + sSC, 2.0); 
      kama = kama + SC * (c[i] - kama); 
   }
   return kama; 
}

double CalcKAMAWithOffset(const double &c[], int n, int offset, int er, int f, int s) { 
   if(n <= er + 2 + offset) return c[offset];
   
   double fSC = 2.0 / (f + 1.0), sSC = 2.0 / (s + 1.0); 
   int seed = n - 1 - er; 
   if(seed < offset) seed = offset; 
   double kama = c[seed];
   
   for(int i = seed + 1; i < n; i++) { 
      int start_idx = i - er;
      if(start_idx < offset) start_idx = offset;
      
      double ch = MathAbs(c[i] - c[start_idx]); 
      double vol = 0.0; 
      
      for(int j = start_idx + 1; j <= i && j < n; j++) 
         vol += MathAbs(c[j] - c[j-1]);
      
      double ER = (vol == 0.0) ? 0.0 : ch / vol; 
      double SC = MathPow(ER * (fSC - sSC) + sSC, 2.0); 
      kama = kama + SC * (c[i] - kama); 
   }
   return kama; 
}

#endif // __MAABOT_INDICATORS_MQH__
//+------------------------------------------------------------------+
