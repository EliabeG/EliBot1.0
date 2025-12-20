//+------------------------------------------------------------------+
//|                                                  Indicators.mqh  |
//|   MAAbot v2.7.0 - Indicadores Avançados (AKTE, PVP, IAE, SCP, FHMI) |
//|                                     Autor: Eliabe N Oliveira     |
//+------------------------------------------------------------------+
#ifndef __MAABOT_INDICATORS_MQH__
#define __MAABOT_INDICATORS_MQH__

#include "Inputs.mqh"
#include "Globals.mqh"
#include "Utils.mqh"

//============================================================================//
//                    1. AKTE (Adaptive Kalman Trend Estimator)               //
//============================================================================//
int CalcAKTESignal(string sym, ENUM_TIMEFRAMES tf) {
   int minBars = AKTE_ATRPeriod + AKTE_StdDevPeriod + 2;
   if(Bars(sym, tf) < minBars) return 0;

   // Copiar dados de preço
   double close[];
   ArraySetAsSeries(close, true);
   if(CopyClose(sym, tf, 0, minBars, close) < minBars) return 0;

   // Copiar ATR
   double atr[];
   ArraySetAsSeries(atr, true);
   if(hATR_AKTE == INVALID_HANDLE)
      hATR_AKTE = iATR(sym, tf, AKTE_ATRPeriod);
   if(CopyBuffer(hATR_AKTE, 0, 0, 3, atr) < 3) return 0;

   // Obter preço atual (medição z)
   double z = close[1];

   // Obter ATR atual para adaptação de R
   g_akte_ATR_atual = atr[1];
   if(g_akte_ATR_atual < SymbolInfoDouble(sym, SYMBOL_POINT))
      g_akte_ATR_atual = SymbolInfoDouble(sym, SYMBOL_POINT);

   // R = (ATR)² - Ruído de medição baseado na volatilidade
   g_akte_R_atual = g_akte_ATR_atual * g_akte_ATR_atual;

   // FILTRO DE KALMAN 1D
   if(!g_akte_initialized) {
      g_akte_x_atual = z;
      g_akte_x_anterior = z;
      g_akte_P_atual = AKTE_InitialP;
      g_akte_K_atual = 0.5;
      g_akte_K_anterior = 0.5;
      g_akte_initialized = true;
      AKTE_AtualizarBuffer(g_akte_x_atual);
      return 0;
   }

   // Salvar valores anteriores
   g_akte_x_anterior = g_akte_x_atual;
   g_akte_K_anterior = g_akte_K_atual;

   // 1. PREDIÇÃO
   double x_pred = g_akte_x_anterior;
   double P_pred = g_akte_P_atual + AKTE_Q;

   // 2. CÁLCULO DO GANHO DE KALMAN
   double K = P_pred / (P_pred + g_akte_R_atual);
   if(K < 0.0) K = 0.0;
   if(K > 1.0) K = 1.0;

   // 3. CORREÇÃO
   g_akte_x_atual = x_pred + K * (z - x_pred);
   g_akte_P_atual = (1.0 - K) * P_pred;
   g_akte_K_atual = K;

   AKTE_AtualizarBuffer(g_akte_x_atual);

   // Verificar inclinação e cruzamento
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

void AKTE_AtualizarBuffer(double valor) {
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

//============================================================================//
//                    2. PVP (Polynomial Velocity Predictor)                  //
//============================================================================//
int CalcPVPSignal(string sym, ENUM_TIMEFRAMES tf) {
   if(Bars(sym, tf) < PVP_LookbackPeriod + 1) return 0;

   double precos[];
   ArrayResize(precos, PVP_LookbackPeriod);

   for(int j = 0; j < PVP_LookbackPeriod; j++) {
      precos[j] = iClose(sym, tf, PVP_LookbackPeriod - j);
   }

   if(!PVP_RegressaoPolinomialCubica(precos, PVP_LookbackPeriod))
      return 0;

   g_pvp_sigma_err = PVP_CalcularSigmaErro(precos, PVP_LookbackPeriod);
   double t_atual = (double)(PVP_LookbackPeriod - 1);

   g_pvp_velocidade = PVP_CalcularVelocidade(t_atual);
   g_pvp_aceleracao = PVP_CalcularAceleracao(t_atual);
   g_pvp_prob_alta = PVP_CalcularProbabilidadeAlta(g_pvp_velocidade, g_pvp_sigma_err);

   if(g_pvp_velocidade > 0 && g_pvp_prob_alta > PVP_ProbBuyThresh) return +1;
   if(g_pvp_velocidade < 0 && g_pvp_prob_alta < PVP_ProbSellThresh) return -1;

   return 0;
}

bool PVP_RegressaoPolinomialCubica(double &precos[], int n) {
   double X[][4];
   ArrayResize(X, n);

   for(int i = 0; i < n; i++) {
      double t = (double)i;
      X[i][0] = t * t * t;
      X[i][1] = t * t;
      X[i][2] = t;
      X[i][3] = 1.0;
   }

   double XTX[16];
   for(int i = 0; i < 4; i++) {
      for(int j = 0; j < 4; j++) {
         XTX[i*4 + j] = 0.0;
         for(int k = 0; k < n; k++) {
            XTX[i*4 + j] += X[k][i] * X[k][j];
         }
      }
   }

   double XTY[4];
   for(int i = 0; i < 4; i++) {
      XTY[i] = 0.0;
      for(int k = 0; k < n; k++) {
         XTY[i] += X[k][i] * precos[k];
      }
   }

   double XTX_inv[16];
   if(!PVP_InverterMatriz4x4(XTX, XTX_inv))
      return false;

   double beta[4];
   for(int i = 0; i < 4; i++) {
      beta[i] = 0.0;
      for(int j = 0; j < 4; j++) {
         beta[i] += XTX_inv[i*4 + j] * XTY[j];
      }
   }

   g_pvp_coef_a = beta[0];
   g_pvp_coef_b = beta[1];
   g_pvp_coef_c = beta[2];
   g_pvp_coef_d = beta[3];

   return true;
}

bool PVP_InverterMatriz4x4(double &A[], double &A_inv[]) {
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
      for(int j = 0; j < 8; j++) {
         aug[col*8 + j] /= pivot;
      }

      for(int row = 0; row < 4; row++) {
         if(row != col) {
            double factor = aug[row*8 + col];
            for(int j = 0; j < 8; j++) {
               aug[row*8 + j] -= factor * aug[col*8 + j];
            }
         }
      }
   }

   for(int i = 0; i < 4; i++) {
      for(int j = 0; j < 4; j++) {
         A_inv[i*4 + j] = aug[i*8 + j + 4];
      }
   }

   return true;
}

double PVP_CalcularP(double t) {
   return g_pvp_coef_a * t * t * t + g_pvp_coef_b * t * t + g_pvp_coef_c * t + g_pvp_coef_d;
}

double PVP_CalcularVelocidade(double t) {
   return 3.0 * g_pvp_coef_a * t * t + 2.0 * g_pvp_coef_b * t + g_pvp_coef_c;
}

double PVP_CalcularAceleracao(double t) {
   return 6.0 * g_pvp_coef_a * t + 2.0 * g_pvp_coef_b;
}

double PVP_CalcularSigmaErro(double &precos[], int n) {
   double soma_erro_quad = 0.0;
   for(int i = 0; i < n; i++) {
      double t = (double)i;
      double p_estimado = PVP_CalcularP(t);
      double erro = precos[i] - p_estimado;
      soma_erro_quad += erro * erro;
   }
   return MathSqrt(soma_erro_quad / (double)n);
}

double PVP_CalcularProbabilidadeAlta(double velocidade, double sigma_err) {
   if(sigma_err < 1e-10) sigma_err = 1e-10;
   double z = velocidade / sigma_err;
   double expoente = -PVP_Sensitivity * z;
   if(expoente > 700) return 0.0;
   if(expoente < -700) return 1.0;
   return 1.0 / (1.0 + MathExp(expoente));
}

//============================================================================//
//                    3. IAE (Integral Arc Efficiency)                        //
//============================================================================//
int CalcIAESignal(string sym, ENUM_TIMEFRAMES tf) {
   int minBars = IAE_Period + IAE_StdDevPeriod + 1;
   if(Bars(sym, tf) < minBars) return 0;

   double close[], ema[];
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(ema, true);

   if(CopyClose(sym, tf, 0, minBars, close) < minBars) return 0;

   if(hEMA_IAE == INVALID_HANDLE)
      hEMA_IAE = iMA(sym, tf, IAE_EMA_Period, 0, MODE_EMA, PRICE_CLOSE);
   if(CopyBuffer(hEMA_IAE, 0, 0, minBars, ema) < minBars) return 0;

   double point_scale = SymbolInfoDouble(sym, SYMBOL_POINT) * 10000;
   if(point_scale == 0) point_scale = 0.01;

   g_iae_deslocamento = close[1] - close[IAE_Period];
   g_iae_comprimento_arco = IAE_CalcularComprimentoArco(close, sym, 1, IAE_Period);

   if(g_iae_comprimento_arco > 0)
      g_iae_eficiencia = MathAbs(g_iae_deslocamento) / g_iae_comprimento_arco;
   else
      g_iae_eficiencia = 0;

   g_iae_eficiencia = MathMin(g_iae_eficiencia, 1.0);
   g_iae_eficiencia = MathMax(g_iae_eficiencia, 0.0);

   g_iae_energia = IAE_CalcularEnergiaIntegral(close, ema, 1, IAE_Period);
   double energia_norm = g_iae_energia / (IAE_Period * point_scale);

   if(g_iae_eficiencia > IAE_EffThreshold && g_iae_deslocamento > 0 && energia_norm > 0)
      return +1;

   if(g_iae_eficiencia > IAE_EffThreshold && g_iae_deslocamento < 0 && energia_norm < 0)
      return -1;

   return 0;
}

double IAE_CalcularComprimentoArco(double &price[], string sym, int idx, int period) {
   double arc_length = 0.0;
   double pt = SymbolInfoDouble(sym, SYMBOL_POINT);
   if(pt == 0) pt = 0.00001;

   for(int j = 1; j < period; j++) {
      int current = idx + j - 1;
      int previous = idx + j;
      double delta_price = (price[current] - price[previous]) / pt;
      double delta_t = IAE_ScaleFactor;
      double segment = MathSqrt(delta_t * delta_t + delta_price * delta_price);
      arc_length += segment;
   }

   return arc_length * pt;
}

double IAE_CalcularEnergiaIntegral(double &price[], double &ema_buf[], int idx, int period) {
   double energia = 0.0;
   for(int j = 0; j < period; j++) {
      int current = idx + j;
      double diff = price[current] - ema_buf[current];
      energia += diff;
   }
   return energia;
}

//============================================================================//
//                    4. SCP (Spectral Cycle Phaser - Fourier DFT)            //
//============================================================================//
int CalcSCPSignal(string sym, ENUM_TIMEFRAMES tf) {
   int minBars = SCP_WindowSize + SCP_MaxPeriod + 2;
   if(Bars(sym, tf) < minBars) return 0;

   double close[];
   ArraySetAsSeries(close, true);
   if(CopyClose(sym, tf, 0, minBars, close) < minBars) return 0;

   // Extrair janela de preços
   double precos_raw[];
   ArrayResize(precos_raw, SCP_WindowSize);
   for(int j = 0; j < SCP_WindowSize; j++) {
      precos_raw[j] = close[SCP_WindowSize - j];
   }

   // Detrending
   double precos_detrend[];
   ArrayResize(precos_detrend, SCP_WindowSize);
   SCP_RemoverTendenciaLinear(precos_raw, precos_detrend, SCP_WindowSize);

   // Janelamento Hanning
   double input_fourier[];
   ArrayResize(input_fourier, SCP_WindowSize);
   SCP_AplicarHanningWindow(precos_detrend, input_fourier, SCP_WindowSize);

   // DFT
   double max_power = 0.0;
   int periodo_dominante = SCP_MinPeriod;
   double fase_dominante = 0.0;

   for(int T = SCP_MinPeriod; T <= SCP_MaxPeriod; T++) {
      double omega = 2.0 * M_PI / (double)T;
      double real_sum = 0.0;
      double imag_sum = 0.0;

      for(int n = 0; n < SCP_WindowSize; n++) {
         double angle = omega * n;
         real_sum += input_fourier[n] * MathCos(angle);
         imag_sum += input_fourier[n] * MathSin(angle);
      }

      double power_T = MathSqrt(real_sum * real_sum + imag_sum * imag_sum);

      if(power_T > max_power) {
         max_power = power_T;
         periodo_dominante = T;
         fase_dominante = MathArctan2(-imag_sum, real_sum);
      }
   }

   g_scp_ciclo_dominante = periodo_dominante;
   g_scp_power_dominante = max_power;

   double omega_dominante = 2.0 * M_PI / (double)g_scp_ciclo_dominante;
   g_scp_fase_atual = fase_dominante + omega_dominante * SCP_WindowSize;
   g_scp_fase_atual = SCP_NormalizarFase(g_scp_fase_atual);

   g_scp_senoide_anterior2 = g_scp_senoide_anterior;
   g_scp_senoide_anterior = g_scp_senoide_atual;
   g_scp_senoide_atual = MathSin(g_scp_fase_atual);

   SCP_AtualizarPowerBuffer(g_scp_power_dominante);
   g_scp_power_medio = SCP_CalcularMediaPower();

   bool power_alto = (g_scp_power_dominante > g_scp_power_medio);

   if(g_scp_senoide_anterior == 0 && g_scp_senoide_anterior2 == 0) return 0;

   bool fundo_ciclo = (g_scp_senoide_anterior < -SCP_SignalThreshold);
   bool virando_cima = (g_scp_senoide_atual > g_scp_senoide_anterior &&
                        g_scp_senoide_anterior <= g_scp_senoide_anterior2);

   if(fundo_ciclo && virando_cima && power_alto) return +1;

   bool topo_ciclo = (g_scp_senoide_anterior > SCP_SignalThreshold);
   bool virando_baixo = (g_scp_senoide_atual < g_scp_senoide_anterior &&
                         g_scp_senoide_anterior >= g_scp_senoide_anterior2);

   if(topo_ciclo && virando_baixo && power_alto) return -1;

   return 0;
}

void SCP_RemoverTendenciaLinear(double &source[], double &dest[], int size) {
   double sum_x = 0.0, sum_y = 0.0, sum_xy = 0.0, sum_x2 = 0.0;

   for(int i = 0; i < size; i++) {
      sum_x += i;
      sum_y += source[i];
      sum_xy += i * source[i];
      sum_x2 += i * i;
   }

   double n = (double)size;
   double denominador = (n * sum_x2 - sum_x * sum_x);

   double m = 0.0, c = 0.0;
   if(MathAbs(denominador) > 1e-10) {
      m = (n * sum_xy - sum_x * sum_y) / denominador;
      c = (sum_y - m * sum_x) / n;
   }

   for(int i = 0; i < size; i++) {
      dest[i] = source[i] - (m * i + c);
   }
}

void SCP_AplicarHanningWindow(double &source[], double &dest[], int size) {
   for(int i = 0; i < size; i++) {
      double w_i = 0.5 * (1.0 - MathCos(2.0 * M_PI * i / (size - 1)));
      dest[i] = source[i] * w_i;
   }
}

double SCP_NormalizarFase(double fase) {
   while(fase > M_PI) fase -= 2.0 * M_PI;
   while(fase < -M_PI) fase += 2.0 * M_PI;
   return fase;
}

void SCP_AtualizarPowerBuffer(double power) {
   int size = ArraySize(g_scp_power_buffer);
   if(size < SCP_PowerMAPeriod) {
      ArrayResize(g_scp_power_buffer, SCP_PowerMAPeriod);
      ArrayInitialize(g_scp_power_buffer, 0);
   }
   for(int i = SCP_PowerMAPeriod - 1; i > 0; i--) {
      g_scp_power_buffer[i] = g_scp_power_buffer[i - 1];
   }
   g_scp_power_buffer[0] = power;
}

double SCP_CalcularMediaPower() {
   double soma = 0.0;
   int count = 0;
   for(int i = 0; i < SCP_PowerMAPeriod; i++) {
      if(g_scp_power_buffer[i] > 0) {
         soma += g_scp_power_buffer[i];
         count++;
      }
   }
   return (count > 0) ? soma / count : 0;
}

//============================================================================//
//                    5. FHMI (Fractal Hurst Memory Index)                    //
//============================================================================//
int CalcFHMISignal(string sym, ENUM_TIMEFRAMES tf) {
   int minBars = FHMI_Period + FHMI_MomentumPeriod + 5;
   if(Bars(sym, tf) < minBars) return 0;

   double close[];
   ArraySetAsSeries(close, true);
   if(CopyClose(sym, tf, 0, minBars, close) < minBars) return 0;

   // Calcular retornos logarítmicos
   double retornos[];
   ArrayResize(retornos, FHMI_Period);
   for(int i = 0; i < FHMI_Period; i++) {
      if(close[i + 2] > 0) {
         retornos[i] = MathLog(close[i + 1] / close[i + 2]);
      } else {
         retornos[i] = 0;
      }
   }

   g_fhmi_hurst_anterior = g_fhmi_hurst;
   g_fhmi_hurst = FHMI_CalcularHurst(retornos, FHMI_Period);

   g_fhmi_momentum_anterior = g_fhmi_momentum;
   if(close[1 + FHMI_MomentumPeriod] > 0) {
      g_fhmi_momentum = (close[1] - close[1 + FHMI_MomentumPeriod]) / close[1 + FHMI_MomentumPeriod];
   } else {
      g_fhmi_momentum = 0;
   }

   bool mercado_tendencial = (g_fhmi_hurst > FHMI_TrendThreshold);
   bool hurst_extremo_baixo = (g_fhmi_hurst < FHMI_ExtremeLow);
   bool hurst_subindo = (g_fhmi_hurst > g_fhmi_hurst_anterior);

   if(mercado_tendencial && g_fhmi_momentum > 0 && hurst_subindo) return +1;
   if(hurst_extremo_baixo && g_fhmi_momentum > 0 && g_fhmi_momentum_anterior <= 0) return +1;

   if(mercado_tendencial && g_fhmi_momentum < 0 && hurst_subindo) return -1;
   if(hurst_extremo_baixo && g_fhmi_momentum < 0 && g_fhmi_momentum_anterior >= 0) return -1;

   return 0;
}

double FHMI_CalcularHurst(double &retornos[], int n) {
   if(n < 10) return 0.5;

   double soma = 0.0;
   for(int i = 0; i < n; i++) soma += retornos[i];
   double media = soma / n;

   double soma_quad = 0.0;
   for(int i = 0; i < n; i++) {
      double diff = retornos[i] - media;
      soma_quad += diff * diff;
   }
   double variancia = soma_quad / n;
   g_fhmi_S = MathSqrt(variancia);

   if(g_fhmi_S < 1e-10) {
      g_fhmi_S = 1e-10;
      return 0.5;
   }

   double desvios_cumulativos[];
   ArrayResize(desvios_cumulativos, n);
   double soma_cumulativa = 0.0;
   for(int i = 0; i < n; i++) {
      soma_cumulativa += (retornos[i] - media);
      desvios_cumulativos[i] = soma_cumulativa;
   }

   double max_cumul = desvios_cumulativos[0];
   double min_cumul = desvios_cumulativos[0];
   for(int i = 1; i < n; i++) {
      if(desvios_cumulativos[i] > max_cumul) max_cumul = desvios_cumulativos[i];
      if(desvios_cumulativos[i] < min_cumul) min_cumul = desvios_cumulativos[i];
   }

   g_fhmi_R = max_cumul - min_cumul;
   g_fhmi_RS = g_fhmi_R / g_fhmi_S;

   if(g_fhmi_RS <= 0 || n <= 2) return 0.5;

   double H = MathLog(g_fhmi_RS) / MathLog((double)n / 2.0);

   if(H < 0.0) H = 0.0;
   if(H > 1.0) H = 1.0;

   return H;
}

//============================================================================//
//                    HEIKIN ASHI (mantido)                                   //
//============================================================================//
int HeikinAshiSignal(string sym, ENUM_TIMEFRAMES tf) {
   int B = HA_Period;
   if(B < 2) B = 2;  // Mínimo de 2 barras
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
//                    QQE (mantido)                                           //
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

#endif // __MAABOT_INDICATORS_MQH__
//+------------------------------------------------------------------+
