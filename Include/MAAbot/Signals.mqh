//+------------------------------------------------------------------+
//|                                                     Signals.mqh  |
//|   MAAbot v2.7.0 - Sinais com Indicadores Avançados               |
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
   // 1. AKTE (Adaptive Kalman Trend Estimator)
   //================================================================
   if(Enable_AKTE) {
      S.akte = CalcAKTESignal(InpSymbol, InpTF);
   } else {
      S.akte = 0;
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
   // 3. PVP (Polynomial Velocity Predictor)
   //================================================================
   if(Enable_PVP) {
      S.pvp = CalcPVPSignal(InpSymbol, InpTF);
   } else {
      S.pvp = 0;
   }

   //================================================================
   // ATR (sempre calculado para outros usos)
   //================================================================
   double atr = 0.0;
   if(hATR == INVALID_HANDLE) hATR = iATR(InpSymbol, InpTF, ATR_Period);
   GetBuf(hATR, 0, atr, 0);
   g_currentATR = atr;

   //================================================================
   // 4. IAE (Integral Arc Efficiency)
   //================================================================
   if(Enable_IAE) {
      S.iae = CalcIAESignal(InpSymbol, InpTF);
   } else {
      S.iae = 0;
   }

   //================================================================
   // 5. SCP (Spectral Cycle Phaser)
   //================================================================
   if(Enable_SCP) {
      S.scp = CalcSCPSignal(InpSymbol, InpTF);
   } else {
      S.scp = 0;
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
   // 7. FHMI (Fractal Hurst Memory Index)
   //================================================================
   if(Enable_FHMI) {
      S.fhmi = CalcFHMISignal(InpSymbol, InpTF);
   } else {
      S.fhmi = 0;
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

   if(Enable_AKTE && S.akte * dir > 0) c++;
   if(Enable_RSI && S.rsi * dir > 0) c++;
   if(Enable_PVP && S.pvp * dir > 0) c++;
   if(Enable_IAE && S.iae * dir > 0) c++;
   if(Enable_SCP && S.scp * dir > 0) c++;
   if(Enable_HeikinAshi && S.ha * dir > 0) c++;
   if(Enable_FHMI && S.fhmi * dir > 0) c++;
   if(Enable_Momentum && S.mom * dir > 0) c++;
   if(Enable_QQE && S.qqe * dir > 0) c++;

   return c;
}

//+------------------------------------------------------------------+
//| Calcula probabilidades (respeita indicadores ativos)             |
//+------------------------------------------------------------------+
void Probabilities(const Signals &S, double &pL, double &pS) {
   struct P { int s; double w; bool active; };
   P a[9] = {
      {S.akte, GetWeight_AKTE(), Enable_AKTE},
      {S.rsi, GetWeight_RSI(), Enable_RSI},
      {S.pvp, GetWeight_PVP(), Enable_PVP},
      {S.iae, GetWeight_IAE(), Enable_IAE},
      {S.scp, GetWeight_SCP(), Enable_SCP},
      {S.ha, GetWeight_Heikin(), Enable_HeikinAshi},
      {S.fhmi, GetWeight_FHMI(), Enable_FHMI},
      {S.mom, GetWeight_Momentum(), Enable_Momentum},
      {S.qqe, GetWeight_QQE(), Enable_QQE}
   };

   double lw = 0, sw = 0;
   for(int i = 0; i < 9; i++) {
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

   // Boost baseado em indicadores de tendência
   if(Enable_IAE && S.iae * dir > 0) t -= ThrBoost_Struct;
   if(Enable_FHMI && S.fhmi * dir > 0) t -= ThrBoost_Struct * 0.5;
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
      if(Enable_IAE && S.iae > 0) score++;
      if(Enable_FHMI && S.fhmi > 0) score++;
      if(Enable_AKTE && S.akte > 0) score++;

      int structIndicators = (Enable_IAE ? 1 : 0) + (Enable_FHMI ? 1 : 0) + (Enable_AKTE ? 1 : 0);
      int required = (structIndicators >= 2) ? 2 : structIndicators;

      return (score >= required);
   }
   else {
      int score = 0;
      if(Enable_IAE && S.iae < 0) score++;
      if(Enable_FHMI && S.fhmi < 0) score++;
      if(Enable_AKTE && S.akte < 0) score++;

      int structIndicators = (Enable_IAE ? 1 : 0) + (Enable_FHMI ? 1 : 0) + (Enable_AKTE ? 1 : 0);
      int required = (structIndicators >= 2) ? 2 : structIndicators;

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
