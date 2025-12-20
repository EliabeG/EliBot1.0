//+------------------------------------------------------------------+
//|                                     MAAbot_Trainer_MetaDiaria.mq5 |
//|   Trainer Simplificado: 9 Indicadores + Meta Diaria              |
//|   SEM: Grid, Hedge, Trailing Complexo, Filtros                   |
//|                                     Autor: Eliabe N Oliveira     |
//+------------------------------------------------------------------+
#property strict
#property description "Trainer: Indicadores + Meta Diaria (TP/SL Fixos)"
#property version   "1.00"

#include <Trade/Trade.mqh>

//+------------------------------------------------------------------+
//|                    CONFIGURACOES BASICAS                          |
//+------------------------------------------------------------------+
input group "══════ CONFIGURACAO GERAL ══════"
input string   InpSymbol              = "XAUUSD";
input ENUM_TIMEFRAMES InpTF           = PERIOD_M15;
input long     Magic                  = 123456;
input int      DeviationPoints        = 30;

input group "══════ STOP LOSS / TAKE PROFIT FIXOS ══════"
input int      StopLossPoints         = 300;
input int      TakeProfitPoints       = 450;
input double   RiskPercent            = 1.0;

input group "══════ HORARIO DE OPERACAO ══════"
input int      StartHour              = 3;
input int      EndHour                = 21;

input group "══════ SINAIS ══════"
input int      MinAgreeSignals        = 3;
input double   MinProbability         = 0.60;
input bool     AllowLong              = true;
input bool     AllowShort             = true;

//+------------------------------------------------------------------+
//|           INDICADORES - ATIVAR/DESATIVAR E PESOS                  |
//+------------------------------------------------------------------+
input group "══════ 1. AKTE (Kalman Filter) ══════"
input bool     Enable_AKTE            = true;
input double   W_AKTE                 = 6.75;
input double   AKTE_Q                 = 0.042;
input int      AKTE_ATRPeriod         = 20;
input int      AKTE_StdDevPeriod      = 143;
input double   AKTE_InitialP          = 2.2;

input group "══════ 2. RSI ══════"
input bool     Enable_RSI             = true;
input double   W_RSI                  = 7.1;
input int      RSI_Period             = 27;
input int      RSI_Low                = 64;
input int      RSI_High               = 409;

input group "══════ 3. PVP (Polynomial Velocity) ══════"
input bool     Enable_PVP             = true;
input double   W_PVP                  = 10.08;
input int      PVP_LookbackPeriod     = 332;
input double   PVP_Sensitivity        = 14.55;
input double   PVP_ProbBuyThresh      = 6.435;
input double   PVP_ProbSellThresh     = 0.455;

input group "══════ 4. IAE (Arc Efficiency) ══════"
input bool     Enable_IAE             = true;
input double   W_IAE                  = 2.47;
input int      IAE_Period             = 94;
input int      IAE_EMA_Period         = 20;
input double   IAE_EffThreshold       = 4.2;
input double   IAE_ScaleFactor        = 7.5;

input group "══════ 5. SCP (Spectral Cycle) ══════"
input bool     Enable_SCP             = true;
input double   W_SCP                  = 10.67;
input int      SCP_WindowSize         = 267;
input int      SCP_MinPeriod          = 56;
input int      SCP_MaxPeriod          = 264;
input double   SCP_SignalThreshold    = 0.88;
input int      SCP_PowerMAPeriod      = 10;

input group "══════ 6. Heikin Ashi ══════"
input bool     Enable_HeikinAshi      = true;
input double   W_Heikin               = 8.2;
input int      HA_Period              = 14;

input group "══════ 7. FHMI (Hurst Index) ══════"
input bool     Enable_FHMI            = true;
input double   W_FHMI                 = 7.92;
input int      FHMI_Period            = 559;
input int      FHMI_MomentumPeriod    = 48;
input double   FHMI_TrendThreshold    = 5.4;
input double   FHMI_ExtremeLow        = 1.52;

input group "══════ 8. Momentum (ROC) ══════"
input bool     Enable_Momentum        = true;
input double   W_Momentum             = 4.8;
input int      ROC_Period             = 80;
input double   ROC_Threshold          = 0.0182;

input group "══════ 9. QQE ══════"
input bool     Enable_QQE             = true;
input double   W_QQE                  = 5.17;
input int      QQE_RSI_Period         = 34;
input int      QQE_SmoothingFactor    = 46;

//+------------------------------------------------------------------+
//|                    META DIARIA                                    |
//+------------------------------------------------------------------+
input group "══════ META DIARIA ══════"
input bool     Enable_DailyTarget     = true;
input double   DT_TargetPercent       = 1.0;           // Meta diaria em %
input double   DT_MaxDailyLoss        = 3.0;           // Perda maxima diaria em %
input bool     DT_CloseOnTarget       = true;          // Fechar ao atingir meta
input bool     DT_BlockAfterTarget    = true;          // Bloquear apos meta
input bool     DT_CompoundDaily       = true;          // Juros compostos
input int      DT_StartHour           = 3;
input int      DT_EndHour             = 21;

//+------------------------------------------------------------------+
//|                    VARIAVEIS GLOBAIS                              |
//+------------------------------------------------------------------+
CTrade trade;
int hRSI = INVALID_HANDLE;
int hATR = INVALID_HANDLE;
int hATR_AKTE = INVALID_HANDLE;
int hEMA_IAE = INVALID_HANDLE;
int hQQE_RSI = INVALID_HANDLE;

datetime lastBarTime = 0;
datetime lastBuyTime = 0;
datetime lastSellTime = 0;

// AKTE variables
double g_akte_x_atual, g_akte_x_anterior;
double g_akte_P_atual, g_akte_K_atual, g_akte_K_anterior;
double g_akte_R_atual, g_akte_ATR_atual;
double g_akte_kalman_buffer[];
bool g_akte_initialized = false;

// PVP variables
double g_pvp_coef_a, g_pvp_coef_b, g_pvp_coef_c, g_pvp_coef_d;
double g_pvp_velocidade, g_pvp_aceleracao, g_pvp_prob_alta, g_pvp_sigma_err;

// IAE variables
double g_iae_deslocamento, g_iae_comprimento_arco, g_iae_eficiencia, g_iae_energia;

// SCP variables
int g_scp_ciclo_dominante;
double g_scp_power_dominante, g_scp_fase_atual;
double g_scp_senoide_atual, g_scp_senoide_anterior, g_scp_senoide_anterior2;
double g_scp_power_medio;
double g_scp_power_buffer[];

// FHMI variables
double g_fhmi_hurst, g_fhmi_hurst_anterior;
double g_fhmi_RS, g_fhmi_R, g_fhmi_S;
double g_fhmi_momentum, g_fhmi_momentum_anterior;

// Daily Target variables
double g_dt_startBalance = 0;
double g_dt_targetBalance = 0;
bool g_dt_targetHit = false;
bool g_dt_blocked = false;
datetime g_dt_dayStart = 0;

#ifndef M_PI
   #define M_PI 3.14159265358979323846
#endif

//+------------------------------------------------------------------+
//|                    ESTRUTURA DE SINAIS                            |
//+------------------------------------------------------------------+
struct Signals {
   int akte, rsi, pvp, iae, scp, ha, fhmi, mom, qqe;
};

//+------------------------------------------------------------------+
//|                           OnInit                                  |
//+------------------------------------------------------------------+
int OnInit() {
   trade.SetExpertMagicNumber(Magic);
   trade.SetDeviationInPoints(DeviationPoints);

   // Handles
   hRSI = iRSI(InpSymbol, InpTF, RSI_Period, PRICE_CLOSE);
   hATR = iATR(InpSymbol, InpTF, 14);
   if(Enable_AKTE) hATR_AKTE = iATR(InpSymbol, InpTF, AKTE_ATRPeriod);
   if(Enable_IAE) hEMA_IAE = iMA(InpSymbol, InpTF, IAE_EMA_Period, 0, MODE_EMA, PRICE_CLOSE);
   if(Enable_QQE) hQQE_RSI = iRSI(InpSymbol, InpTF, QQE_RSI_Period, PRICE_CLOSE);

   // Reset AKTE
   g_akte_initialized = false;
   ArrayResize(g_akte_kalman_buffer, AKTE_StdDevPeriod);
   ArrayInitialize(g_akte_kalman_buffer, 0);

   // Reset SCP
   ArrayResize(g_scp_power_buffer, SCP_PowerMAPeriod);
   ArrayInitialize(g_scp_power_buffer, 0);

   // Init Daily Target
   InitDailyTarget();

   Print("═══════════════════════════════════════════════════════════");
   Print("   MAAbot Trainer: Indicadores + Meta Diaria");
   Print("═══════════════════════════════════════════════════════════");
   Print(" Indicadores Ativos: ", CountActiveIndicators());
   Print(" Meta Diaria: ", Enable_DailyTarget ? DoubleToString(DT_TargetPercent, 2) + "%" : "OFF");
   Print(" TP: ", TakeProfitPoints, " | SL: ", StopLossPoints);
   Print("═══════════════════════════════════════════════════════════");

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//|                           OnDeinit                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   if(hRSI != INVALID_HANDLE) IndicatorRelease(hRSI);
   if(hATR != INVALID_HANDLE) IndicatorRelease(hATR);
   if(hATR_AKTE != INVALID_HANDLE) IndicatorRelease(hATR_AKTE);
   if(hEMA_IAE != INVALID_HANDLE) IndicatorRelease(hEMA_IAE);
   if(hQQE_RSI != INVALID_HANDLE) IndicatorRelease(hQQE_RSI);
}

//+------------------------------------------------------------------+
//|                           OnTick                                  |
//+------------------------------------------------------------------+
void OnTick() {
   datetime now = TimeCurrent();

   // Verificar meta diaria
   if(Enable_DailyTarget) {
      CheckDailyReset();
      if(MonitorDailyTarget()) return; // Meta atingida, bloqueado
      if(g_dt_blocked) return;
   }

   // Verificar horario
   MqlDateTime dt; TimeToStruct(now, dt);
   if(dt.hour < StartHour || dt.hour >= EndHour) return;

   // Nova barra?
   datetime barTime = iTime(InpSymbol, InpTF, 0);
   if(barTime == lastBarTime) return;
   lastBarTime = barTime;

   // Obter sinais
   Signals S;
   ZeroMemory(S);
   if(!GetSignals(S)) return;

   // Calcular probabilidades
   double pL = 0, pS = 0;
   CalcProbabilities(S, pL, pS);

   // Contar sinais concordantes
   int agreeL = CountAgree(S, +1);
   int agreeS = CountAgree(S, -1);

   // Verificar condicoes de entrada
   bool wantBuy = AllowLong && (agreeL >= MinAgreeSignals) && (pL >= MinProbability);
   bool wantSell = AllowShort && (agreeS >= MinAgreeSignals) && (pS >= MinProbability);

   // Verificar se ja tem posicao
   bool hasPos = HasPosition();

   if(!hasPos) {
      if(wantBuy && wantSell) {
         if(pL >= pS) OpenBuy();
         else OpenSell();
      }
      else if(wantBuy) OpenBuy();
      else if(wantSell) OpenSell();
   }
}

//+------------------------------------------------------------------+
//|                    FUNCOES DE SINAIS                              |
//+------------------------------------------------------------------+
bool GetSignals(Signals &S) {
   if(Enable_AKTE) S.akte = CalcAKTESignal();
   if(Enable_RSI) S.rsi = CalcRSISignal();
   if(Enable_PVP) S.pvp = CalcPVPSignal();
   if(Enable_IAE) S.iae = CalcIAESignal();
   if(Enable_SCP) S.scp = CalcSCPSignal();
   if(Enable_HeikinAshi) S.ha = CalcHeikinAshiSignal();
   if(Enable_FHMI) S.fhmi = CalcFHMISignal();
   if(Enable_Momentum) S.mom = CalcMomentumSignal();
   if(Enable_QQE) S.qqe = CalcQQESignal();
   return true;
}

int CountActiveIndicators() {
   int c = 0;
   if(Enable_AKTE) c++;
   if(Enable_RSI) c++;
   if(Enable_PVP) c++;
   if(Enable_IAE) c++;
   if(Enable_SCP) c++;
   if(Enable_HeikinAshi) c++;
   if(Enable_FHMI) c++;
   if(Enable_Momentum) c++;
   if(Enable_QQE) c++;
   return c;
}

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

void CalcProbabilities(const Signals &S, double &pL, double &pS) {
   double lw = 0, sw = 0;

   if(Enable_AKTE) { if(S.akte > 0) lw += W_AKTE; else if(S.akte < 0) sw += W_AKTE; }
   if(Enable_RSI) { if(S.rsi > 0) lw += W_RSI; else if(S.rsi < 0) sw += W_RSI; }
   if(Enable_PVP) { if(S.pvp > 0) lw += W_PVP; else if(S.pvp < 0) sw += W_PVP; }
   if(Enable_IAE) { if(S.iae > 0) lw += W_IAE; else if(S.iae < 0) sw += W_IAE; }
   if(Enable_SCP) { if(S.scp > 0) lw += W_SCP; else if(S.scp < 0) sw += W_SCP; }
   if(Enable_HeikinAshi) { if(S.ha > 0) lw += W_Heikin; else if(S.ha < 0) sw += W_Heikin; }
   if(Enable_FHMI) { if(S.fhmi > 0) lw += W_FHMI; else if(S.fhmi < 0) sw += W_FHMI; }
   if(Enable_Momentum) { if(S.mom > 0) lw += W_Momentum; else if(S.mom < 0) sw += W_Momentum; }
   if(Enable_QQE) { if(S.qqe > 0) lw += W_QQE; else if(S.qqe < 0) sw += W_QQE; }

   double tot = lw + sw;
   if(tot <= 0) { pL = 0; pS = 0; return; }
   pL = lw / tot;
   pS = sw / tot;
}

//+------------------------------------------------------------------+
//|                    INDICADOR 1: AKTE                              |
//+------------------------------------------------------------------+
int CalcAKTESignal() {
   int minBars = AKTE_ATRPeriod + AKTE_StdDevPeriod + 2;
   if(Bars(InpSymbol, InpTF) < minBars) return 0;

   double close[]; ArraySetAsSeries(close, true);
   if(CopyClose(InpSymbol, InpTF, 0, minBars, close) < minBars) return 0;

   double atr[]; ArraySetAsSeries(atr, true);
   if(hATR_AKTE == INVALID_HANDLE) return 0;
   if(CopyBuffer(hATR_AKTE, 0, 0, 3, atr) < 3) return 0;

   double z = close[1];
   g_akte_ATR_atual = atr[1];
   if(g_akte_ATR_atual < SymbolInfoDouble(InpSymbol, SYMBOL_POINT))
      g_akte_ATR_atual = SymbolInfoDouble(InpSymbol, SYMBOL_POINT);

   g_akte_R_atual = g_akte_ATR_atual * g_akte_ATR_atual;

   if(!g_akte_initialized) {
      g_akte_x_atual = z;
      g_akte_x_anterior = z;
      g_akte_P_atual = AKTE_InitialP;
      g_akte_K_atual = 0.5;
      g_akte_K_anterior = 0.5;
      g_akte_initialized = true;
      AKTE_UpdateBuffer(g_akte_x_atual);
      return 0;
   }

   g_akte_x_anterior = g_akte_x_atual;
   g_akte_K_anterior = g_akte_K_atual;

   double x_pred = g_akte_x_anterior;
   double P_pred = g_akte_P_atual + AKTE_Q;
   double K = P_pred / (P_pred + g_akte_R_atual);
   if(K < 0.0) K = 0.0; if(K > 1.0) K = 1.0;

   g_akte_x_atual = x_pred + K * (z - x_pred);
   g_akte_P_atual = (1.0 - K) * P_pred;
   g_akte_K_atual = K;

   AKTE_UpdateBuffer(g_akte_x_atual);

   bool inclinacao_positiva = (g_akte_x_atual > g_akte_x_anterior);
   bool inclinacao_negativa = (g_akte_x_atual < g_akte_x_anterior);
   bool K_subindo = (g_akte_K_atual > g_akte_K_anterior);

   double close_atual = close[1];
   double close_anterior = close[2];
   bool cruza_para_cima = (close_anterior < g_akte_x_anterior && close_atual > g_akte_x_atual);
   bool cruza_para_baixo = (close_anterior > g_akte_x_anterior && close_atual < g_akte_x_atual);

   if(cruza_para_cima && inclinacao_positiva && K_subindo) return +1;
   if(cruza_para_baixo && inclinacao_negativa && K_subindo) return -1;

   return 0;
}

void AKTE_UpdateBuffer(double valor) {
   int size = ArraySize(g_akte_kalman_buffer);
   if(size < AKTE_StdDevPeriod) {
      ArrayResize(g_akte_kalman_buffer, AKTE_StdDevPeriod);
      ArrayInitialize(g_akte_kalman_buffer, 0);
   }
   for(int i = AKTE_StdDevPeriod - 1; i > 0; i--) {
      g_akte_kalman_buffer[i] = g_akte_kalman_buffer[i - 1];
   }
   g_akte_kalman_buffer[0] = valor;
}

//+------------------------------------------------------------------+
//|                    INDICADOR 2: RSI                               |
//+------------------------------------------------------------------+
int CalcRSISignal() {
   if(hRSI == INVALID_HANDLE) return 0;
   double rsi[1];
   if(CopyBuffer(hRSI, 0, 1, 1, rsi) < 1) return 0;

   if(rsi[0] < RSI_Low) return +1;
   if(rsi[0] > RSI_High) return -1;
   return 0;
}

//+------------------------------------------------------------------+
//|                    INDICADOR 3: PVP                               |
//+------------------------------------------------------------------+
int CalcPVPSignal() {
   if(Bars(InpSymbol, InpTF) < PVP_LookbackPeriod + 1) return 0;

   double precos[];
   ArrayResize(precos, PVP_LookbackPeriod);

   for(int j = 0; j < PVP_LookbackPeriod; j++) {
      precos[j] = iClose(InpSymbol, InpTF, PVP_LookbackPeriod - j);
   }

   if(!PVP_RegressaoCubica(precos, PVP_LookbackPeriod)) return 0;

   g_pvp_sigma_err = PVP_CalcSigmaErro(precos, PVP_LookbackPeriod);
   double t_atual = (double)(PVP_LookbackPeriod - 1);

   g_pvp_velocidade = 3.0 * g_pvp_coef_a * t_atual * t_atual + 2.0 * g_pvp_coef_b * t_atual + g_pvp_coef_c;
   g_pvp_prob_alta = PVP_CalcProbAlta(g_pvp_velocidade, g_pvp_sigma_err);

   if(g_pvp_velocidade > 0 && g_pvp_prob_alta > PVP_ProbBuyThresh) return +1;
   if(g_pvp_velocidade < 0 && g_pvp_prob_alta < PVP_ProbSellThresh) return -1;

   return 0;
}

bool PVP_RegressaoCubica(double &precos[], int n) {
   double X[][4]; ArrayResize(X, n);

   for(int i = 0; i < n; i++) {
      double t = (double)i;
      X[i][0] = t * t * t; X[i][1] = t * t; X[i][2] = t; X[i][3] = 1.0;
   }

   double XTX[16], XTY[4];
   for(int i = 0; i < 4; i++) {
      for(int j = 0; j < 4; j++) {
         XTX[i*4 + j] = 0.0;
         for(int k = 0; k < n; k++) XTX[i*4 + j] += X[k][i] * X[k][j];
      }
      XTY[i] = 0.0;
      for(int k = 0; k < n; k++) XTY[i] += X[k][i] * precos[k];
   }

   double XTX_inv[16];
   if(!PVP_InvertMatrix4x4(XTX, XTX_inv)) return false;

   g_pvp_coef_a = 0; g_pvp_coef_b = 0; g_pvp_coef_c = 0; g_pvp_coef_d = 0;
   for(int j = 0; j < 4; j++) {
      g_pvp_coef_a += XTX_inv[0*4 + j] * XTY[j];
      g_pvp_coef_b += XTX_inv[1*4 + j] * XTY[j];
      g_pvp_coef_c += XTX_inv[2*4 + j] * XTY[j];
      g_pvp_coef_d += XTX_inv[3*4 + j] * XTY[j];
   }
   return true;
}

bool PVP_InvertMatrix4x4(double &A[], double &A_inv[]) {
   double aug[32];
   for(int i = 0; i < 4; i++) {
      for(int j = 0; j < 4; j++) {
         aug[i*8 + j] = A[i*4 + j];
         aug[i*8 + j + 4] = (i == j) ? 1.0 : 0.0;
      }
   }
   for(int col = 0; col < 4; col++) {
      int max_row = col;
      double max_val = MathAbs(aug[col*8 + col]);
      for(int row = col + 1; row < 4; row++) {
         if(MathAbs(aug[row*8 + col]) > max_val) {
            max_val = MathAbs(aug[row*8 + col]);
            max_row = row;
         }
      }
      if(max_val < 1e-10) return false;
      if(max_row != col) {
         for(int j = 0; j < 8; j++) {
            double temp = aug[col*8 + j];
            aug[col*8 + j] = aug[max_row*8 + j];
            aug[max_row*8 + j] = temp;
         }
      }
      double pivot = aug[col*8 + col];
      for(int j = 0; j < 8; j++) aug[col*8 + j] /= pivot;
      for(int row = 0; row < 4; row++) {
         if(row != col) {
            double factor = aug[row*8 + col];
            for(int j = 0; j < 8; j++) aug[row*8 + j] -= factor * aug[col*8 + j];
         }
      }
   }
   for(int i = 0; i < 4; i++)
      for(int j = 0; j < 4; j++)
         A_inv[i*4 + j] = aug[i*8 + j + 4];
   return true;
}

double PVP_CalcSigmaErro(double &precos[], int n) {
   double soma = 0.0;
   for(int i = 0; i < n; i++) {
      double t = (double)i;
      double p_est = g_pvp_coef_a * t * t * t + g_pvp_coef_b * t * t + g_pvp_coef_c * t + g_pvp_coef_d;
      double erro = precos[i] - p_est;
      soma += erro * erro;
   }
   return MathSqrt(soma / (double)n);
}

double PVP_CalcProbAlta(double vel, double sigma) {
   if(sigma < 1e-10) sigma = 1e-10;
   double z = vel / sigma;
   double exp = -PVP_Sensitivity * z;
   if(exp > 700) return 0.0;
   if(exp < -700) return 1.0;
   return 1.0 / (1.0 + MathExp(exp));
}

//+------------------------------------------------------------------+
//|                    INDICADOR 4: IAE                               |
//+------------------------------------------------------------------+
int CalcIAESignal() {
   int minBars = IAE_Period + 2;
   if(Bars(InpSymbol, InpTF) < minBars) return 0;

   double close[], ema[];
   ArraySetAsSeries(close, true); ArraySetAsSeries(ema, true);
   if(CopyClose(InpSymbol, InpTF, 0, minBars, close) < minBars) return 0;
   if(hEMA_IAE == INVALID_HANDLE) return 0;
   if(CopyBuffer(hEMA_IAE, 0, 0, minBars, ema) < minBars) return 0;

   double pt = SymbolInfoDouble(InpSymbol, SYMBOL_POINT) * 10000;
   if(pt == 0) pt = 0.01;

   g_iae_deslocamento = close[1] - close[IAE_Period];
   g_iae_comprimento_arco = IAE_CalcArcLength(close, 1, IAE_Period);

   if(g_iae_comprimento_arco > 0)
      g_iae_eficiencia = MathAbs(g_iae_deslocamento) / g_iae_comprimento_arco;
   else
      g_iae_eficiencia = 0;

   g_iae_eficiencia = MathMin(1.0, MathMax(0.0, g_iae_eficiencia));
   g_iae_energia = IAE_CalcEnergy(close, ema, 1, IAE_Period);
   double energia_norm = g_iae_energia / (IAE_Period * pt);

   if(g_iae_eficiencia > IAE_EffThreshold && g_iae_deslocamento > 0 && energia_norm > 0) return +1;
   if(g_iae_eficiencia > IAE_EffThreshold && g_iae_deslocamento < 0 && energia_norm < 0) return -1;

   return 0;
}

double IAE_CalcArcLength(double &price[], int idx, int period) {
   double arc = 0.0;
   double pt = SymbolInfoDouble(InpSymbol, SYMBOL_POINT);
   if(pt == 0) pt = 0.00001;

   for(int j = 1; j < period; j++) {
      int curr = idx + j - 1;
      int prev = idx + j;
      double dp = (price[curr] - price[prev]) / pt;
      double dt = IAE_ScaleFactor;
      arc += MathSqrt(dt * dt + dp * dp);
   }
   return arc * pt;
}

double IAE_CalcEnergy(double &price[], double &ema[], int idx, int period) {
   double e = 0.0;
   for(int j = 0; j < period; j++) {
      e += price[idx + j] - ema[idx + j];
   }
   return e;
}

//+------------------------------------------------------------------+
//|                    INDICADOR 5: SCP (Fourier)                     |
//+------------------------------------------------------------------+
int CalcSCPSignal() {
   int minBars = SCP_WindowSize + SCP_MaxPeriod + 2;
   if(Bars(InpSymbol, InpTF) < minBars) return 0;

   double close[]; ArraySetAsSeries(close, true);
   if(CopyClose(InpSymbol, InpTF, 0, minBars, close) < minBars) return 0;

   double precos_raw[], precos_detrend[], input_fourier[];
   ArrayResize(precos_raw, SCP_WindowSize);
   ArrayResize(precos_detrend, SCP_WindowSize);
   ArrayResize(input_fourier, SCP_WindowSize);

   for(int j = 0; j < SCP_WindowSize; j++) precos_raw[j] = close[SCP_WindowSize - j];

   SCP_Detrend(precos_raw, precos_detrend, SCP_WindowSize);
   SCP_Hanning(precos_detrend, input_fourier, SCP_WindowSize);

   double max_power = 0.0;
   int periodo_dominante = SCP_MinPeriod;
   double fase_dominante = 0.0;

   for(int T = SCP_MinPeriod; T <= SCP_MaxPeriod; T++) {
      double omega = 2.0 * M_PI / (double)T;
      double real_sum = 0.0, imag_sum = 0.0;

      for(int n = 0; n < SCP_WindowSize; n++) {
         double angle = omega * n;
         real_sum += input_fourier[n] * MathCos(angle);
         imag_sum += input_fourier[n] * MathSin(angle);
      }

      double power_T = MathSqrt(real_sum * real_sum + imag_sum * imag_sum);

      if(power_T > max_power) {
         max_power = power_T;
         periodo_dominante = T;
         fase_dominante = atan2(-imag_sum, real_sum);
      }
   }

   g_scp_ciclo_dominante = periodo_dominante;
   g_scp_power_dominante = max_power;

   double omega_dom = 2.0 * M_PI / (double)g_scp_ciclo_dominante;
   g_scp_fase_atual = fase_dominante + omega_dom * SCP_WindowSize;
   g_scp_fase_atual = SCP_NormalizeFase(g_scp_fase_atual);

   g_scp_senoide_anterior2 = g_scp_senoide_anterior;
   g_scp_senoide_anterior = g_scp_senoide_atual;
   g_scp_senoide_atual = MathSin(g_scp_fase_atual);

   SCP_UpdatePowerBuffer(g_scp_power_dominante);
   g_scp_power_medio = SCP_CalcMediaPower();

   bool power_alto = (g_scp_power_dominante > g_scp_power_medio);
   if(g_scp_senoide_anterior == 0 && g_scp_senoide_anterior2 == 0) return 0;

   bool fundo = (g_scp_senoide_anterior < -SCP_SignalThreshold);
   bool virando_cima = (g_scp_senoide_atual > g_scp_senoide_anterior && g_scp_senoide_anterior <= g_scp_senoide_anterior2);
   if(fundo && virando_cima && power_alto) return +1;

   bool topo = (g_scp_senoide_anterior > SCP_SignalThreshold);
   bool virando_baixo = (g_scp_senoide_atual < g_scp_senoide_anterior && g_scp_senoide_anterior >= g_scp_senoide_anterior2);
   if(topo && virando_baixo && power_alto) return -1;

   return 0;
}

void SCP_Detrend(double &src[], double &dst[], int size) {
   double sx = 0, sy = 0, sxy = 0, sx2 = 0;
   for(int i = 0; i < size; i++) { sx += i; sy += src[i]; sxy += i * src[i]; sx2 += i * i; }
   double n = (double)size;
   double den = (n * sx2 - sx * sx);
   double m = 0, c = 0;
   if(MathAbs(den) > 1e-10) { m = (n * sxy - sx * sy) / den; c = (sy - m * sx) / n; }
   for(int i = 0; i < size; i++) dst[i] = src[i] - (m * i + c);
}

void SCP_Hanning(double &src[], double &dst[], int size) {
   for(int i = 0; i < size; i++) {
      double w = 0.5 * (1.0 - MathCos(2.0 * M_PI * i / (size - 1)));
      dst[i] = src[i] * w;
   }
}

double SCP_NormalizeFase(double f) {
   while(f > M_PI) f -= 2.0 * M_PI;
   while(f < -M_PI) f += 2.0 * M_PI;
   return f;
}

void SCP_UpdatePowerBuffer(double p) {
   for(int i = SCP_PowerMAPeriod - 1; i > 0; i--) g_scp_power_buffer[i] = g_scp_power_buffer[i - 1];
   g_scp_power_buffer[0] = p;
}

double SCP_CalcMediaPower() {
   double s = 0; int c = 0;
   for(int i = 0; i < SCP_PowerMAPeriod; i++) { if(g_scp_power_buffer[i] > 0) { s += g_scp_power_buffer[i]; c++; } }
   return (c > 0) ? s / c : 0;
}

//+------------------------------------------------------------------+
//|                    INDICADOR 6: HEIKIN ASHI                       |
//+------------------------------------------------------------------+
int CalcHeikinAshiSignal() {
   int B = HA_Period;
   if(B < 2) B = 2;
   MqlRates r[]; ArraySetAsSeries(r, true);
   if(CopyRates(InpSymbol, InpTF, 0, B, r) < B) return 0;

   double ho[], hc[];
   ArrayResize(ho, B); ArrayResize(hc, B);

   for(int i = B-1; i >= 0; i--) {
      double cl = (r[i].open + r[i].high + r[i].low + r[i].close) / 4.0;
      double op = (i == B-1) ? (r[i].open + r[i].close) / 2.0 : (ho[i+1] + hc[i+1]) / 2.0;
      hc[i] = cl; ho[i] = op;
   }

   bool bull = (hc[1] > ho[1] && hc[0] > ho[0]);
   bool bear = (hc[1] < ho[1] && hc[0] < ho[0]);

   if(bull && !bear) return +1;
   if(bear && !bull) return -1;
   return 0;
}

//+------------------------------------------------------------------+
//|                    INDICADOR 7: FHMI (Hurst)                      |
//+------------------------------------------------------------------+
int CalcFHMISignal() {
   int minBars = FHMI_Period + FHMI_MomentumPeriod + 5;
   if(Bars(InpSymbol, InpTF) < minBars) return 0;

   double close[]; ArraySetAsSeries(close, true);
   if(CopyClose(InpSymbol, InpTF, 0, minBars, close) < minBars) return 0;

   double retornos[];
   ArrayResize(retornos, FHMI_Period);
   for(int i = 0; i < FHMI_Period; i++) {
      if(close[i + 2] > 0) retornos[i] = MathLog(close[i + 1] / close[i + 2]);
      else retornos[i] = 0;
   }

   g_fhmi_hurst_anterior = g_fhmi_hurst;
   g_fhmi_hurst = FHMI_CalcHurst(retornos, FHMI_Period);

   g_fhmi_momentum_anterior = g_fhmi_momentum;
   if(close[1 + FHMI_MomentumPeriod] > 0)
      g_fhmi_momentum = (close[1] - close[1 + FHMI_MomentumPeriod]) / close[1 + FHMI_MomentumPeriod];
   else
      g_fhmi_momentum = 0;

   bool tendencial = (g_fhmi_hurst > FHMI_TrendThreshold);
   bool extremo_baixo = (g_fhmi_hurst < FHMI_ExtremeLow);
   bool hurst_subindo = (g_fhmi_hurst > g_fhmi_hurst_anterior);

   if(tendencial && g_fhmi_momentum > 0 && hurst_subindo) return +1;
   if(extremo_baixo && g_fhmi_momentum > 0 && g_fhmi_momentum_anterior <= 0) return +1;

   if(tendencial && g_fhmi_momentum < 0 && hurst_subindo) return -1;
   if(extremo_baixo && g_fhmi_momentum < 0 && g_fhmi_momentum_anterior >= 0) return -1;

   return 0;
}

double FHMI_CalcHurst(double &ret[], int n) {
   if(n < 10) return 0.5;

   double soma = 0.0;
   for(int i = 0; i < n; i++) soma += ret[i];
   double media = soma / n;

   double soma_quad = 0.0;
   for(int i = 0; i < n; i++) { double d = ret[i] - media; soma_quad += d * d; }
   double var = soma_quad / n;
   g_fhmi_S = MathSqrt(var);

   if(g_fhmi_S < 1e-10) { g_fhmi_S = 1e-10; return 0.5; }

   double dc[]; ArrayResize(dc, n);
   double sc = 0.0;
   for(int i = 0; i < n; i++) { sc += (ret[i] - media); dc[i] = sc; }

   double maxC = dc[0], minC = dc[0];
   for(int i = 1; i < n; i++) { if(dc[i] > maxC) maxC = dc[i]; if(dc[i] < minC) minC = dc[i]; }

   g_fhmi_R = maxC - minC;
   g_fhmi_RS = g_fhmi_R / g_fhmi_S;

   if(g_fhmi_RS <= 0 || n <= 2) return 0.5;

   double H = MathLog(g_fhmi_RS) / MathLog((double)n / 2.0);
   if(H < 0.0) H = 0.0; if(H > 1.0) H = 1.0;
   return H;
}

//+------------------------------------------------------------------+
//|                    INDICADOR 8: MOMENTUM (ROC)                    |
//+------------------------------------------------------------------+
int CalcMomentumSignal() {
   double close[]; ArraySetAsSeries(close, true);
   if(CopyClose(InpSymbol, InpTF, 0, ROC_Period + 2, close) < ROC_Period + 2) return 0;

   if(close[ROC_Period + 1] == 0) return 0;
   double roc = (close[1] - close[ROC_Period + 1]) / close[ROC_Period + 1];

   if(roc > ROC_Threshold) return +1;
   if(roc < -ROC_Threshold) return -1;
   return 0;
}

//+------------------------------------------------------------------+
//|                    INDICADOR 9: QQE                               |
//+------------------------------------------------------------------+
int CalcQQESignal() {
   if(hQQE_RSI == INVALID_HANDLE) return 0;

   const int bars = 200;
   double rsi_buf[]; ArraySetAsSeries(rsi_buf, true);
   if(CopyBuffer(hQQE_RSI, 0, 0, bars, rsi_buf) < bars) return 0;

   double smoothed[], rsi_atr[], wilders_atr[], fast_atr[], qqe_line[];
   ArrayResize(smoothed, bars); ArrayResize(rsi_atr, bars);
   ArrayResize(wilders_atr, bars); ArrayResize(fast_atr, bars);
   ArrayResize(qqe_line, bars);
   ArrayInitialize(smoothed, 50); ArrayInitialize(rsi_atr, 0);
   ArrayInitialize(wilders_atr, 0); ArrayInitialize(qqe_line, 50);

   double alpha = 2.0 / (QQE_SmoothingFactor + 1.0);
   smoothed[bars-1] = rsi_buf[bars-1];
   for(int i = bars - 2; i >= 0; i--) smoothed[i] = rsi_buf[i] * alpha + smoothed[i+1] * (1.0 - alpha);

   for(int i = bars - QQE_SmoothingFactor - 1; i >= 0; i--) {
      double sum = 0;
      for(int j = 0; j < QQE_SmoothingFactor; j++) if(i + j + 1 < bars) sum += MathAbs(smoothed[i+j] - smoothed[i+j+1]);
      rsi_atr[i] = sum / QQE_SmoothingFactor;
   }

   wilders_atr[bars-1] = rsi_atr[bars-1];
   double wa = 1.0 / (QQE_SmoothingFactor * 2.0);
   for(int i = bars - 2; i >= 0; i--) wilders_atr[i] = rsi_atr[i] * wa + wilders_atr[i+1] * (1.0 - wa);

   double mult = 4.236;
   for(int i = 0; i < bars; i++) fast_atr[i] = wilders_atr[i] * mult;

   qqe_line[bars-1] = smoothed[bars-1];
   for(int i = bars - 2; i >= 0; i--) {
      double upper = qqe_line[i+1] + fast_atr[i];
      double lower = qqe_line[i+1] - fast_atr[i];
      if(smoothed[i] > qqe_line[i+1]) qqe_line[i] = MathMax(lower, smoothed[i] > upper ? smoothed[i] : qqe_line[i+1]);
      else qqe_line[i] = MathMin(upper, smoothed[i] < lower ? smoothed[i] : qqe_line[i+1]);
   }

   bool cross_up = (smoothed[0] > qqe_line[0] && smoothed[1] <= qqe_line[1]);
   bool cross_down = (smoothed[0] < qqe_line[0] && smoothed[1] >= qqe_line[1]);

   if(cross_up) return +1;
   if(cross_down) return -1;
   if(smoothed[0] > qqe_line[0] && smoothed[0] > 50) return +1;
   if(smoothed[0] < qqe_line[0] && smoothed[0] < 50) return -1;
   return 0;
}

//+------------------------------------------------------------------+
//|                    META DIARIA                                    |
//+------------------------------------------------------------------+
void InitDailyTarget() {
   if(!Enable_DailyTarget) return;

   g_dt_startBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   g_dt_targetBalance = g_dt_startBalance * (1.0 + DT_TargetPercent / 100.0);
   g_dt_targetHit = false;
   g_dt_blocked = false;

   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   dt.hour = 0; dt.min = 0; dt.sec = 0;
   g_dt_dayStart = StructToTime(dt);

   Print("Meta Diaria: ", DoubleToString(DT_TargetPercent, 2), "% | Alvo: $", DoubleToString(g_dt_targetBalance, 2));
}

void CheckDailyReset() {
   datetime now = TimeCurrent();
   MqlDateTime dtNow, dtStart;
   TimeToStruct(now, dtNow);
   TimeToStruct(g_dt_dayStart, dtStart);

   if(dtNow.day != dtStart.day || dtNow.mon != dtStart.mon || dtNow.year != dtStart.year) {
      // Novo dia
      if(DT_CompoundDaily && g_dt_targetHit) {
         g_dt_startBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      } else if(DT_CompoundDaily) {
         g_dt_startBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      }

      g_dt_targetBalance = g_dt_startBalance * (1.0 + DT_TargetPercent / 100.0);
      g_dt_targetHit = false;
      g_dt_blocked = false;

      dtNow.hour = 0; dtNow.min = 0; dtNow.sec = 0;
      g_dt_dayStart = StructToTime(dtNow);

      Print("Novo dia - Meta: $", DoubleToString(g_dt_targetBalance - g_dt_startBalance, 2));
   }
}

bool MonitorDailyTarget() {
   if(!Enable_DailyTarget) return false;
   if(g_dt_blocked) return true;

   // Verificar horario
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   if(dt.hour < DT_StartHour || dt.hour >= DT_EndHour) return false;

   double equity = AccountInfoDouble(ACCOUNT_EQUITY);

   // Meta atingida?
   if(!g_dt_targetHit && equity >= g_dt_targetBalance) {
      g_dt_targetHit = true;
      Print("═══════════════════════════════════════════════════════════");
      Print("   META DIARIA ATINGIDA!");
      Print("   Lucro: $", DoubleToString(equity - g_dt_startBalance, 2));
      Print("═══════════════════════════════════════════════════════════");

      if(DT_CloseOnTarget) CloseAllPositions();
      if(DT_BlockAfterTarget) g_dt_blocked = true;

      return true;
   }

   // Perda maxima?
   double maxLoss = g_dt_startBalance * (DT_MaxDailyLoss / 100.0);
   double currentPL = equity - g_dt_startBalance;
   if(currentPL <= -maxLoss) {
      Print("PERDA MAXIMA DIARIA: $", DoubleToString(MathAbs(currentPL), 2));
      CloseAllPositions();
      g_dt_blocked = true;
      return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//|                    FUNCOES DE TRADE                               |
//+------------------------------------------------------------------+
bool HasPosition() {
   int total = PositionsTotal();
   for(int i = 0; i < total; i++) {
      ulong tk = PositionGetTicket(i);
      if(PositionSelectByTicket(tk)) {
         if(PositionGetString(POSITION_SYMBOL) == InpSymbol && PositionGetInteger(POSITION_MAGIC) == Magic)
            return true;
      }
   }
   return false;
}

void OpenBuy() {
   double pt = SymbolInfoDouble(InpSymbol, SYMBOL_POINT);
   double ask = SymbolInfoDouble(InpSymbol, SYMBOL_ASK);
   double sl = ask - StopLossPoints * pt;
   double tp = ask + TakeProfitPoints * pt;
   double lot = CalcLot(StopLossPoints);

   if(trade.Buy(lot, InpSymbol, ask, sl, tp, "Buy")) {
      lastBuyTime = TimeCurrent();
   }
}

void OpenSell() {
   double pt = SymbolInfoDouble(InpSymbol, SYMBOL_POINT);
   double bid = SymbolInfoDouble(InpSymbol, SYMBOL_BID);
   double sl = bid + StopLossPoints * pt;
   double tp = bid - TakeProfitPoints * pt;
   double lot = CalcLot(StopLossPoints);

   if(trade.Sell(lot, InpSymbol, bid, sl, tp, "Sell")) {
      lastSellTime = TimeCurrent();
   }
}

double CalcLot(int sl_pts) {
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double risk_money = equity * (RiskPercent / 100.0);
   double pt = SymbolInfoDouble(InpSymbol, SYMBOL_POINT);
   double tick_size = SymbolInfoDouble(InpSymbol, SYMBOL_TRADE_TICK_SIZE);
   double tick_value = SymbolInfoDouble(InpSymbol, SYMBOL_TRADE_TICK_VALUE);
   double step = SymbolInfoDouble(InpSymbol, SYMBOL_VOLUME_STEP);
   double minlot = SymbolInfoDouble(InpSymbol, SYMBOL_VOLUME_MIN);
   double maxlot = SymbolInfoDouble(InpSymbol, SYMBOL_VOLUME_MAX);

   if(tick_size <= 0 || tick_value <= 0 || pt <= 0) return minlot;

   double money_per_lot = (sl_pts * pt) * (tick_value / tick_size);
   if(money_per_lot <= 0) return minlot;

   double lots = risk_money / money_per_lot;
   int k = (int)MathFloor(lots / step);
   lots = k * step;

   return MathMax(minlot, MathMin(maxlot, lots));
}

void CloseAllPositions() {
   int total = PositionsTotal();
   for(int i = total - 1; i >= 0; i--) {
      ulong tk = PositionGetTicket(i);
      if(PositionSelectByTicket(tk)) {
         if(PositionGetString(POSITION_SYMBOL) == InpSymbol && PositionGetInteger(POSITION_MAGIC) == Magic) {
            trade.PositionClose(tk);
         }
      }
   }
}
//+------------------------------------------------------------------+
