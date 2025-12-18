//+------------------------------------------------------------------+
//|                                                     Signals.mqh  |
//|   MAAbot v2.6.0 - Sinais com Indicadores Individuais             |
//|                                     Autor: Eliabe N Oliveira     |
//+------------------------------------------------------------------+
#ifndef __MAABOT_SIGNALS_MQH__
#define __MAABOT_SIGNALS_MQH__

#include "Inputs.mqh"
#include "Globals.mqh"
#include "Utils.mqh"
#include "Indicators.mqh"

//+------------------------------------------------------------------+
//| ENSEMBLE / SINAIS - Respeita indicadores ativados/desativados    |
//+------------------------------------------------------------------+
bool GetSignals(Signals &S) {
   double c[]; ArraySetAsSeries(c, true);
   if(CopyClose(InpSymbol, InpTF, 0, 60, c) < 60) return false;
   S.c0 = c[0];

   //================================================================
   // 1. MA CROSS - Cruzamento de Médias
   //================================================================
   if(Enable_MACross) {
      double emaF = 0.0, emaS = 0.0;
      if(hEMAfast == INVALID_HANDLE) hEMAfast = iMA(InpSymbol, InpTF, EMA_Fast, 0, MODE_EMA, PRICE_CLOSE);
      if(hEMAslow == INVALID_HANDLE) hEMAslow = iMA(InpSymbol, InpTF, EMA_Slow, 0, MODE_EMA, PRICE_CLOSE);

      GetBuf(hEMAfast, 0, emaF, 0); GetBuf(hEMAslow, 0, emaS, 0);
      S.emaF = emaF; S.emaS = emaS;
      g_emaFastVal = emaF; g_emaSlowVal = emaS;

      if(emaF > emaS && S.c0 > emaS) S.mac = +1;
      else if(emaF < emaS && S.c0 < emaS) S.mac = -1;
      else S.mac = 0;
   } else {
      S.mac = 0;
      S.emaF = 0; S.emaS = 0;
   }

   //================================================================
   // 2. RSI - Índice de Força Relativa
   //================================================================
   if(Enable_RSI) {
      if(hRSI == INVALID_HANDLE) hRSI = iRSI(InpSymbol, InpTF, RSI_Period, PRICE_CLOSE);
      double rsi = 50.0; GetBuf(hRSI, 0, rsi, 0);
      g_rsiValue = rsi;

      if(rsi < RSI_Low) S.rsi = +1;
      else if(rsi > RSI_High) S.rsi = -1;
      else S.rsi = 0;
   } else {
      S.rsi = 0;
      g_rsiValue = 50.0;
   }

   //================================================================
   // 3. BOLLINGER BANDS
   //================================================================
   if(Enable_BBands) {
      if(hBB == INVALID_HANDLE) hBB = iBands(InpSymbol, InpTF, BB_Period, 0, BB_Dev, PRICE_CLOSE);

      double up = 0.0, md = 0.0, lw = 0.0;
      GetBuf(hBB, 0, md, 0); GetBuf(hBB, 1, up, 0); GetBuf(hBB, 2, lw, 0);
      g_bbUpper = up; g_bbMiddle = md; g_bbLower = lw;

      if(S.c0 < lw) S.bb = +1;
      else if(S.c0 > up) S.bb = -1;
      else S.bb = 0;
   } else {
      S.bb = 0;
      g_bbUpper = 0; g_bbMiddle = 0; g_bbLower = 0;
   }

   //================================================================
   // 4. SUPERTREND
   //================================================================
   if(Enable_Supertrend) {
      S.st = CalcSupertrendSignalCached(InpSymbol, InpTF, ST_ATR_Period, ST_Mult, hATR_ST_INP);
   } else {
      S.st = 0;
   }

   //================================================================
   // ATR (sempre calculado para outros usos)
   //================================================================
   double atr = 0.0;
   if(hATR == INVALID_HANDLE) hATR = iATR(InpSymbol, InpTF, ATR_Period);
   GetBuf(hATR, 0, atr, 0);
   g_currentATR = atr;

   //================================================================
   // 5. AMA/KAMA - Média Adaptativa
   //================================================================
   if(Enable_AMA) {
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
   } else {
      S.ama = 0;
      g_kamaValue = 0; g_kamaSlope = 0;
   }

   //================================================================
   // 6. HEIKIN ASHI
   //================================================================
   if(Enable_HeikinAshi) {
      S.ha = HeikinAshiSignal(InpSymbol, InpTF);
   } else {
      S.ha = 0;
   }

   //================================================================
   // 7. VWAP
   //================================================================
   if(Enable_VWAP) {
      double vw = 0.0;
      if(GetSessionVWAP(InpSymbol, VWAP_TF, VWAP_UseRealVolume, vw)) {
         S.vwapv = vw; g_currentVWAP = vw;
         if(S.c0 > vw) S.vwap = +1;
         else if(S.c0 < vw) S.vwap = -1;
         else S.vwap = 0;
      } else { S.vwap = 0; S.vwapv = 0.0; }
   } else {
      S.vwap = 0; S.vwapv = 0.0;
      g_currentVWAP = 0;
   }

   //================================================================
   // 8. MOMENTUM (ROC)
   //================================================================
   if(Enable_Momentum) {
      double roc = ROC(InpSymbol, InpTF, ROC_Period);
      g_rocValue = roc;
      if(roc > ROC_Threshold) S.mom = +1;
      else if(roc < -ROC_Threshold) S.mom = -1;
      else S.mom = 0;
   } else {
      S.mom = 0;
      g_rocValue = 0;
   }

   //================================================================
   // 9. QQE
   //================================================================
   if(Enable_QQE && UseQQEFilter) {
      S.qqe = CalcQQESignal(InpSymbol, InpTF, QQE_RSI_Period, QQE_SmoothingFactor);
   } else {
      S.qqe = 0;
   }

   return true;
}

//+------------------------------------------------------------------+
//| Conta sinais concordantes (respeita indicadores ativos)          |
//+------------------------------------------------------------------+
int CountAgree(const Signals &S, int dir) {
   int c = 0;

   // Só conta se o indicador está ativo
   if(Enable_MACross && S.mac * dir > 0) c++;
   if(Enable_RSI && S.rsi * dir > 0) c++;
   if(Enable_BBands && S.bb * dir > 0) c++;
   if(Enable_Supertrend && S.st * dir > 0) c++;
   if(Enable_AMA && S.ama * dir > 0) c++;
   if(Enable_HeikinAshi && S.ha * dir > 0) c++;
   if(Enable_VWAP && S.vwap * dir > 0) c++;
   if(Enable_Momentum && S.mom * dir > 0) c++;
   if(Enable_QQE && S.qqe * dir > 0) c++;

   return c;
}

//+------------------------------------------------------------------+
//| Calcula probabilidades (respeita indicadores ativos)             |
//+------------------------------------------------------------------+
void Probabilities(const Signals &S, double &pL, double &pS) {
   // Estrutura para sinais e pesos
   struct P { int s; double w; bool active; };
   P a[9] = {
      {S.mac, GetWeight_MACross(), Enable_MACross},
      {S.rsi, GetWeight_RSI(), Enable_RSI},
      {S.bb, GetWeight_BBands(), Enable_BBands},
      {S.st, GetWeight_Supertrend(), Enable_Supertrend},
      {S.ama, GetWeight_AMA(), Enable_AMA},
      {S.ha, GetWeight_Heikin(), Enable_HeikinAshi},
      {S.vwap, GetWeight_VWAP(), Enable_VWAP},
      {S.mom, GetWeight_Momentum(), Enable_Momentum},
      {S.qqe, GetWeight_QQE(), Enable_QQE}
   };

   double lw = 0, sw = 0;
   for(int i = 0; i < 9; i++) {
      // Só considera indicadores ativos
      if(!a[i].active) continue;

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

//+------------------------------------------------------------------+
//| Sinal do ativo correlacionado                                    |
//+------------------------------------------------------------------+
int AnchorSignal() {
   if(!UseAnchor) return 0;
   if(hAnchorEMAfast == INVALID_HANDLE) hAnchorEMAfast = iMA(AnchorSymbol, AnchorTF, Anchor_EMA_Fast, 0, MODE_EMA, PRICE_CLOSE);
   if(hAnchorEMAslow == INVALID_HANDLE) hAnchorEMAslow = iMA(AnchorSymbol, AnchorTF, Anchor_EMA_Slow, 0, MODE_EMA, PRICE_CLOSE);
   double f = 0.0, s = 0.0;
   GetBuf(hAnchorEMAfast, 0, f, 0); GetBuf(hAnchorEMAslow, 0, s, 0);
   if(f > s) return +1; if(f < s) return -1;
   return 0;
}

//+------------------------------------------------------------------+
//| Threshold efetivo                                                |
//+------------------------------------------------------------------+
double EffThr(const Signals &S, int dir, int anchorSig) {
   double t = BaseThr();

   // Só aplica boost se o indicador está ativo
   if(Enable_Supertrend && S.st * dir > 0) t -= ThrBoost_Struct;
   if(Enable_VWAP && S.vwap * dir > 0) t -= ThrBoost_Struct * 0.5;
   if(UseAnchor && anchorSig * dir > 0) t -= ThrBoost_Anchor;

   return MathMin(0.85, MathMax(0.50, t));
}

//+------------------------------------------------------------------+
//| Verificação de estrutura                                         |
//+------------------------------------------------------------------+
bool StructureOK(const Signals &S, int dir) {
   if(!UseStructureLock) return true;

   if(dir > 0) {
      int score = 0;
      if(Enable_Supertrend && S.st > 0) score++;
      if(Enable_VWAP && S.vwap > 0) score++;
      if(Enable_MACross && S.emaF > S.emaS) score++;

      // Ajusta requisito baseado em indicadores ativos
      int required = 2;
      int structIndicators = (Enable_Supertrend ? 1 : 0) + (Enable_VWAP ? 1 : 0) + (Enable_MACross ? 1 : 0);
      if(structIndicators < 2) required = structIndicators;

      return (score >= required);
   }
   else {
      int score = 0;
      if(Enable_Supertrend && S.st < 0) score++;
      if(Enable_VWAP && S.vwap < 0) score++;
      if(Enable_MACross && S.emaF < S.emaS) score++;

      int required = 2;
      int structIndicators = (Enable_Supertrend ? 1 : 0) + (Enable_VWAP ? 1 : 0) + (Enable_MACross ? 1 : 0);
      if(structIndicators < 2) required = structIndicators;

      return (score >= required);
   }
}

//+------------------------------------------------------------------+
//| Verificação de TF de entrada                                     |
//+------------------------------------------------------------------+
bool EntryTFAgree(int dir) {
   if(!UseEntryTF) return true;
   double r = ROC(InpSymbol, EntryTF, EntryROC_Period);
   if(dir > 0) return (r >= EntryROC_Threshold);
   if(dir < 0) return (r <= -EntryROC_Threshold);
   return false;
}

#endif // __MAABOT_SIGNALS_MQH__
//+------------------------------------------------------------------+
