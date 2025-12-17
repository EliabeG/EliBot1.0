//+------------------------------------------------------------------+
//|                                                       Trend.mqh  |
//|   MAAbot v2.3.1 - Análise de Tendência MTF                       |
//|                                     Autor: Eliabe N Oliveira     |
//+------------------------------------------------------------------+
#ifndef __MAABOT_TREND_MQH__
#define __MAABOT_TREND_MQH__

#include "Inputs.mqh"
#include "Globals.mqh"
#include "Utils.mqh"
#include "Indicators.mqh"

//-------------------------- TENDÊNCIA (MTF) -------------------------------//
int TrendDirection(double &score_out, bool &isTrending_out) {
   score_out = 0.0; isTrending_out = false;
   
   if(hTF1_EMAf == INVALID_HANDLE) hTF1_EMAf = iMA(InpSymbol, Trend_TF1, Trend_EMA_Fast, 0, MODE_EMA, PRICE_CLOSE);
   if(hTF1_EMAs == INVALID_HANDLE) hTF1_EMAs = iMA(InpSymbol, Trend_TF1, Trend_EMA_Slow, 0, MODE_EMA, PRICE_CLOSE);
   if(hADX_TF1 == INVALID_HANDLE) hADX_TF1 = iADX(InpSymbol, Trend_TF1, Trend_ADX_Period);
   
   double f1 = 0.0, s1 = 0.0, adx1 = 0.0, pdi1 = 0.0, mdi1 = 0.0;
   GetBuf(hTF1_EMAf, 0, f1, 0); GetBuf(hTF1_EMAs, 0, s1, 0);
   GetBuf(hADX_TF1, 0, adx1, 0); GetBuf(hADX_TF1, 1, pdi1, 0); GetBuf(hADX_TF1, 2, mdi1, 0);
   g_adxValue = adx1;
   
   double c1[]; ArraySetAsSeries(c1, true); 
   if(CopyClose(InpSymbol, Trend_TF1, 0, 1, c1) < 1) return 0;
   
   int st1 = CalcSupertrendSignalCached(InpSymbol, Trend_TF1, ST_ATR_Period, ST_Mult, hATR_ST_TF1);
   
   double wAdx = 1.0, wEMA = 1.0, wPx = 0.5, wST = 1.0; 
   double sumw = (wAdx + wEMA + wPx + wST);
   
   double sTF1 = 0.0; 
   if(pdi1 > mdi1) sTF1 += wAdx; else if(pdi1 < mdi1) sTF1 -= wAdx;
   if(f1 > s1) sTF1 += wEMA; else if(f1 < s1) sTF1 -= wEMA;
   if(c1[0] > s1) sTF1 += wPx; else if(c1[0] < s1) sTF1 -= wPx;
   if(st1 > 0) sTF1 += wST; else if(st1 < 0) sTF1 -= wST;
   
   sTF1 /= sumw;
   
   double sTot = sTF1; double adx2 = 0.0; int st2 = 0;
   
   if(Trend_UseTF2) {
      if(hTF2_EMAf == INVALID_HANDLE) hTF2_EMAf = iMA(InpSymbol, Trend_TF2, Trend_EMA_Fast, 0, MODE_EMA, PRICE_CLOSE);
      if(hTF2_EMAs == INVALID_HANDLE) hTF2_EMAs = iMA(InpSymbol, Trend_TF2, Trend_EMA_Slow, 0, MODE_EMA, PRICE_CLOSE);
      if(hADX_TF2 == INVALID_HANDLE) hADX_TF2 = iADX(InpSymbol, Trend_TF2, Trend_ADX_Period);
      
      double f2 = 0.0, s2 = 0.0, pdi2 = 0.0, mdi2 = 0.0; 
      GetBuf(hTF2_EMAf, 0, f2, 0); GetBuf(hTF2_EMAs, 0, s2, 0);
      GetBuf(hADX_TF2, 0, adx2, 0); GetBuf(hADX_TF2, 1, pdi2, 0); GetBuf(hADX_TF2, 2, mdi2, 0);
      
      double c2[]; ArraySetAsSeries(c2, true); 
      if(CopyClose(InpSymbol, Trend_TF2, 0, 1, c2) < 1) return 0;
      
      st2 = CalcSupertrendSignalCached(InpSymbol, Trend_TF2, ST_ATR_Period, ST_Mult, hATR_ST_TF2);
      
      double sTF2 = 0.0; 
      if(pdi2 > mdi2) sTF2 += wAdx; else if(pdi2 < mdi2) sTF2 -= wAdx;
      if(f2 > s2) sTF2 += wEMA; else if(f2 < s2) sTF2 -= wEMA;
      if(c2[0] > s2) sTF2 += wPx; else if(c2[0] < s2) sTF2 -= wPx;
      if(st2 > 0) sTF2 += wST; else if(st2 < 0) sTF2 -= wST;
      sTF2 /= sumw;
      
      sTot = (sTF1 + Trend_TF2_Weight * sTF2) / (1.0 + Trend_TF2_Weight);
   }
   
   score_out = sTot;
   bool adx_ok = (adx1 >= Trend_ADX_Thr) || (Trend_UseTF2 && adx2 >= 0.9 * Trend_ADX_Thr);
   isTrending_out = (adx_ok && MathAbs(sTot) >= TrendScore_Thr);
   
   if(sTot > 0.10) return +1;
   if(sTot < -0.10) return -1;
   return 0;
}

bool PullbackOK(int dir) {
   if(!Trend_UsePullbackEntry) return true;
   if(!g_trending) return true;
   
   if(hEMAPull == INVALID_HANDLE) hEMAPull = iMA(InpSymbol, InpTF, Trend_Pull_EMA, 0, MODE_EMA, PRICE_CLOSE);
   
   double ema = 0.0; GetBuf(hEMAPull, 0, ema, 0);
   
   double c0[]; ArraySetAsSeries(c0, true); 
   if(CopyClose(InpSymbol, InpTF, 0, 1, c0) < 1) return true;
   
   double atr = 0.0; 
   if(hATR == INVALID_HANDLE) hATR = iATR(InpSymbol, InpTF, ATR_Period); 
   GetBuf(hATR, 0, atr, 0);
   
   double dist = MathAbs(c0[0] - ema);
   bool side = (dir > 0) ? c0[0] >= ema : c0[0] <= ema;
   bool distOK = (atr <= 0.0) ? true : (dist <= Trend_Pull_ATRMultMax * atr);
   
   return (side && distOK);
}

bool BreakoutOK(int dir, int lookback) {
   if(!Trend_AllowBreakout) return false;
   
   int N = (lookback < 10) ? 10 : lookback;
   double H[], L[], C[]; 
   ArraySetAsSeries(H, true); ArraySetAsSeries(L, true); ArraySetAsSeries(C, true);
   
   if(CopyHigh(InpSymbol, InpTF, 0, N+2, H) < N+2) return false;
   if(CopyLow(InpSymbol, InpTF, 0, N+2, L) < N+2) return false;
   if(CopyClose(InpSymbol, InpTF, 0, 2, C) < 2) return false;
   
   double maxH = H[1], minL = L[1];
   for(int i = 1; i <= N; i++) { if(H[i] > maxH) maxH = H[i]; if(L[i] < minL) minL = L[i]; }
   
   if(dir > 0) return (C[0] > maxH);
   else return (C[0] < minL);
}

bool TrendAllowsEntry(int dir) {
   if(!UseTrendFilter) return true;
   if(!g_trending) return true;
   if(Trend_Strict_Entries && dir != g_trendDir) return false;
   bool okPull = PullbackOK(dir);
   bool okBO = BreakoutOK(dir, Trend_Donchian_Lookback);
   if(!Trend_UsePullbackEntry && !Trend_AllowBreakout) return true;
   return (okPull || okBO);
}

#endif // __MAABOT_TREND_MQH__
//+------------------------------------------------------------------+
