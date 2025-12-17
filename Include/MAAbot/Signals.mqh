//+------------------------------------------------------------------+
//|                                                     Signals.mqh  |
//|   MAAbot v2.3.1 - Sinais e Ensemble                              |
//|                                     Autor: Eliabe N Oliveira     |
//+------------------------------------------------------------------+
#ifndef __MAABOT_SIGNALS_MQH__
#define __MAABOT_SIGNALS_MQH__

#include "Inputs.mqh"
#include "Globals.mqh"
#include "Utils.mqh"
#include "Indicators.mqh"

//-------------------------- ENSEMBLE / SINAIS -------------------------------//
bool GetSignals(Signals &S) {
   double c[]; ArraySetAsSeries(c, true); 
   if(CopyClose(InpSymbol, InpTF, 0, 60, c) < 60) return false; 
   S.c0 = c[0];
   
   double emaF = 0.0, emaS = 0.0; 
   if(hEMAfast == INVALID_HANDLE) hEMAfast = iMA(InpSymbol, InpTF, EMA_Fast, 0, MODE_EMA, PRICE_CLOSE);
   if(hEMAslow == INVALID_HANDLE) hEMAslow = iMA(InpSymbol, InpTF, EMA_Slow, 0, MODE_EMA, PRICE_CLOSE);
   
   GetBuf(hEMAfast, 0, emaF, 0); GetBuf(hEMAslow, 0, emaS, 0); 
   S.emaF = emaF; S.emaS = emaS;
   g_emaFastVal = emaF; g_emaSlowVal = emaS;
   
   if(emaF > emaS && S.c0 > emaS) S.mac = +1; 
   else if(emaF < emaS && S.c0 < emaS) S.mac = -1; 
   else S.mac = 0;
   
   if(hRSI == INVALID_HANDLE) hRSI = iRSI(InpSymbol, InpTF, RSI_Period, PRICE_CLOSE); 
   double rsi = 50.0; GetBuf(hRSI, 0, rsi, 0);
   g_rsiValue = rsi;
   
   if(rsi < RSI_Low) S.rsi = +1; 
   else if(rsi > RSI_High) S.rsi = -1; 
   else S.rsi = 0;
   
   if(hBB == INVALID_HANDLE) hBB = iBands(InpSymbol, InpTF, BB_Period, 0, BB_Dev, PRICE_CLOSE);
   
   double up = 0.0, md = 0.0, lw = 0.0; 
   GetBuf(hBB, 0, md, 0); GetBuf(hBB, 1, up, 0); GetBuf(hBB, 2, lw, 0);
   g_bbUpper = up; g_bbMiddle = md; g_bbLower = lw;
   
   if(S.c0 < lw) S.bb = +1; 
   else if(S.c0 > up) S.bb = -1; 
   else S.bb = 0;
   
   S.st = CalcSupertrendSignalCached(InpSymbol, InpTF, ST_ATR_Period, ST_Mult, hATR_ST_INP);
   
   double atr = 0.0; 
   if(hATR == INVALID_HANDLE) hATR = iATR(InpSymbol, InpTF, ATR_Period); 
   GetBuf(hATR, 0, atr, 0);
   g_currentATR = atr;
   
   int n = ArraySize(c); 
   double kama = CalcKAMA(c, n, AMA_ER_Period, AMA_Fast, AMA_Slow); 
   double kama_prev = CalcKAMAWithOffset(c, n, 1, AMA_ER_Period, AMA_Fast, AMA_Slow);
   double slope = kama - kama_prev; 
   double pt = Pt(); 
   bool atr_ok = (pt > 0.0) ? (atr <= AMA_ATR_FilterMult * pt * StopLossPoints) : true;
   g_kamaValue = kama; g_kamaSlope = slope;
   
   if(atr_ok) { 
      if(slope > 0.0 && S.c0 > kama) S.ama = +1; 
      else if(slope < 0.0 && S.c0 < kama) S.ama = -1; 
      else S.ama = 0; 
   } else S.ama = 0;
   
   S.ha = HeikinAshiSignal(InpSymbol, InpTF);
   
   double vw = 0.0; 
   if(GetSessionVWAP(InpSymbol, VWAP_TF, VWAP_UseRealVolume, vw)) { 
      S.vwapv = vw; g_currentVWAP = vw;
      if(S.c0 > vw) S.vwap = +1; 
      else if(S.c0 < vw) S.vwap = -1; 
      else S.vwap = 0; 
   } else { S.vwap = 0; S.vwapv = 0.0; }
   
   double roc = ROC(InpSymbol, InpTF, ROC_Period); 
   g_rocValue = roc;
   if(roc > ROC_Threshold) S.mom = +1; 
   else if(roc < -ROC_Threshold) S.mom = -1; 
   else S.mom = 0;
   
   if(UseQQEFilter) S.qqe = CalcQQESignal(InpSymbol, InpTF, QQE_RSI_Period, QQE_SmoothingFactor); 
   else S.qqe = 0;
   
   return true; 
}

int CountAgree(const Signals &S, int dir) { 
   int c = 0;
   if(S.mac * dir > 0) c++; if(S.rsi * dir > 0) c++; if(S.bb * dir > 0) c++; if(S.st * dir > 0) c++;
   if(S.ama * dir > 0) c++; if(S.ha * dir > 0) c++; if(S.vwap * dir > 0) c++; if(S.mom * dir > 0) c++;
   if(S.qqe * dir > 0) c++;
   return c; 
}

void Probabilities(const Signals &S, double &pL, double &pS) {
   struct P { int s; double w; }; 
   P a[9] = {
      {S.mac, W_MAcross}, {S.rsi, W_RSI}, {S.bb, W_BBands}, {S.st, W_Supertrend}, 
      {S.ama, W_AMA}, {S.ha, W_Heikin}, {S.vwap, W_VWAP}, {S.mom, W_Momentum}, {S.qqe, W_QQE}
   };
   
   double lw = 0, sw = 0; 
   for(int i = 0; i < 9; i++) { 
      if(a[i].s > 0) lw += a[i].w; 
      else if(a[i].s < 0) sw += a[i].w; 
   } 
   
   double tot = lw + sw; 
   if(tot <= 0) { pL = 0; pS = 0; return; }
   
   pL = lw / tot; pS = sw / tot;
   
   if(UseAnchor) {
      if(hAnchorEMAfast == INVALID_HANDLE) hAnchorEMAfast = iMA(AnchorSymbol, AnchorTF, Anchor_EMA_Fast, 0, MODE_EMA, PRICE_CLOSE);
      if(hAnchorEMAslow == INVALID_HANDLE) hAnchorEMAslow = iMA(AnchorSymbol, AnchorTF, Anchor_EMA_Slow, 0, MODE_EMA, PRICE_CLOSE);
      
      double f = 0.0, s = 0.0; 
      GetBuf(hAnchorEMAfast, 0, f, 0); GetBuf(hAnchorEMAslow, 0, s, 0);
      
      if(f > s) { pL *= (1.0 + AnchorBoost); pS *= (1.0 - AnchorBoost); }
      else if(f < s) { pS *= (1.0 + AnchorBoost); pL *= (1.0 - AnchorBoost); }
      
      pL = MathMin(1.0, MathMax(0.0, pL)); pS = MathMin(1.0, MathMax(0.0, pS));
   } 
}

int AnchorSignal() {
   if(!UseAnchor) return 0;
   if(hAnchorEMAfast == INVALID_HANDLE) hAnchorEMAfast = iMA(AnchorSymbol, AnchorTF, Anchor_EMA_Fast, 0, MODE_EMA, PRICE_CLOSE);
   if(hAnchorEMAslow == INVALID_HANDLE) hAnchorEMAslow = iMA(AnchorSymbol, AnchorTF, Anchor_EMA_Slow, 0, MODE_EMA, PRICE_CLOSE);
   double f = 0.0, s = 0.0; 
   GetBuf(hAnchorEMAfast, 0, f, 0); GetBuf(hAnchorEMAslow, 0, s, 0);
   if(f > s) return +1; if(f < s) return -1; 
   return 0;
}

double EffThr(const Signals &S, int dir, int anchorSig) { 
   double t = BaseThr();
   if(S.st * dir > 0) t -= ThrBoost_Struct; 
   if(S.vwap * dir > 0) t -= ThrBoost_Struct * 0.5;
   if(UseAnchor && anchorSig * dir > 0) t -= ThrBoost_Anchor;
   return MathMin(0.85, MathMax(0.50, t));
}

bool StructureOK(const Signals &S, int dir) { 
   if(!UseStructureLock) return true;
   
   if(dir > 0) {
      int score = 0;
      if(S.st > 0) score++; if(S.vwap > 0) score++; if(S.emaF > S.emaS) score++;
      return (score >= 2);
   }
   else {
      int score = 0;
      if(S.st < 0) score++; if(S.vwap < 0) score++; if(S.emaF < S.emaS) score++;
      return (score >= 2);
   }
}

bool EntryTFAgree(int dir) { 
   if(!UseEntryTF) return true; 
   double r = ROC(InpSymbol, EntryTF, EntryROC_Period);
   if(dir > 0) return (r >= EntryROC_Threshold); 
   if(dir < 0) return (r <= -EntryROC_Threshold); 
   return false; 
}

#endif // __MAABOT_SIGNALS_MQH__
//+------------------------------------------------------------------+
