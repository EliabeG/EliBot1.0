//+------------------------------------------------------------------+
//|                                              MAAbot_Trainer.mq5  |
//|   Bot Treinador para Otimização Individual de Indicadores        |
//|                                     Autor: Eliabe N Oliveira     |
//|                                      Data: 18/12/2025            |
//+------------------------------------------------------------------+
//| COMO USAR:                                                        |
//| 1. Selecione o indicador que deseja otimizar                     |
//| 2. Configure os parâmetros do indicador escolhido                |
//| 3. Execute o backtest/otimização no Strategy Tester              |
//| 4. O bot fará entradas baseado APENAS no indicador selecionado   |
//| 5. Anote os melhores parâmetros encontrados                      |
//+------------------------------------------------------------------+
#property strict
#property description "Bot Treinador - Otimização Individual de Indicadores"
#property version   "1.00"

#include <Trade/Trade.mqh>

//╔══════════════════════════════════════════════════════════════════╗
//║                    SELEÇÃO DO INDICADOR                          ║
//╚══════════════════════════════════════════════════════════════════╝
enum IndicadorParaOtimizar {
   OPT_EWGC          = 0,  // 1. EWGC (Entropy-Weighted Gaussian Channel)
   OPT_RSI           = 1,  // 2. RSI
   OPT_PVP           = 2,  // 3. PVP (Polynomial Velocity Predictor)
   OPT_IAE           = 3,  // 4. IAE (Integral Arc Efficiency)
   OPT_SCP           = 4,  // 5. SCP (Spectral Cycle Phaser)
   OPT_HEIKIN_ASHI   = 5,  // 6. Heikin Ashi
   OPT_VWAP          = 6,  // 7. VWAP
   OPT_MOMENTUM      = 7,  // 8. Momentum (ROC)
   OPT_QQE           = 8   // 9. QQE
};

//╔══════════════════════════════════════════════════════════════════╗
//║                    CONFIGURAÇÕES BÁSICAS                         ║
//╚══════════════════════════════════════════════════════════════════╝
input group "══════ CONFIGURAÇÃO DO TREINADOR ══════"
input IndicadorParaOtimizar Indicador = OPT_EWGC;  // ████ INDICADOR PARA OTIMIZAR ████
input string   InpSymbol              = "XAUUSD";      // Símbolo
input ENUM_TIMEFRAMES InpTF           = PERIOD_M15;    // Tempo Gráfico

input group "══════ STOP LOSS / TAKE PROFIT ══════"
input int      TakeProfit_Pontos      = 300;           // Take Profit (pontos)
input int      StopLoss_Pontos        = 300;           // Stop Loss (pontos)

input group "══════ GESTÃO ══════"
input double   LoteFixo               = 0.01;          // Lote Fixo
input long     MagicNumber            = 99999;         // Número Mágico

//╔══════════════════════════════════════════════════════════════════╗
//║          PARÂMETROS DO INDICADOR 1: EWGC                         ║
//╚══════════════════════════════════════════════════════════════════╝
input group "══════ 1. EWGC - Entropy-Weighted Gaussian Channel ══════"
input int      EWGC_Period            = 50;            // Período da Janela (n velas)
input int      EWGC_Buckets           = 15;            // Número de Buckets (10-20)
input double   EWGC_ExpansionFactor   = 2.0;           // Fator de Expansão do Canal
input double   EWGC_ChaosThreshold    = 0.8;           // Limiar de Caos (H > valor = caótico)
input double   EWGC_SniperThreshold   = 0.5;           // Limiar Sniper (H < valor = ordenado)

//╔══════════════════════════════════════════════════════════════════╗
//║          PARÂMETROS DO INDICADOR 2: RSI                          ║
//╚══════════════════════════════════════════════════════════════════╝
input group "══════ 2. RSI - Índice de Força Relativa ══════"
input int      RSI_Period             = 14;            // Período
input int      RSI_Sobrevendido       = 30;            // Nível Sobrevendido (COMPRA)
input int      RSI_Sobrecomprado      = 70;            // Nível Sobrecomprado (VENDA)

//╔══════════════════════════════════════════════════════════════════╗
//║          PARÂMETROS DO INDICADOR 3: PVP                          ║
//╚══════════════════════════════════════════════════════════════════╝
input group "══════ 3. PVP - Polynomial Velocity Predictor ══════"
input int      PVP_LookbackPeriod     = 50;            // Período de Lookback (n velas)
input double   PVP_Sensitivity        = 1.5;           // Constante de Sensibilidade (k)
input double   PVP_ProbBuyThresh      = 0.75;          // Limiar Prob. Compra (0.75 = 75%)
input double   PVP_ProbSellThresh     = 0.25;          // Limiar Prob. Venda (0.25 = 25%)

//╔══════════════════════════════════════════════════════════════════╗
//║          PARÂMETROS DO INDICADOR 4: IAE                          ║
//╚══════════════════════════════════════════════════════════════════╝
input group "══════ 4. IAE - Integral Arc Efficiency ══════"
input int      IAE_Period             = 20;            // Período da Janela Móvel (n)
input int      IAE_EMA_Period         = 9;             // Período da EMA base
input double   IAE_EffThreshold       = 0.6;           // Limiar de Eficiência (η)
input double   IAE_ScaleFactor        = 1.0;           // Fator de Escala (λ)
input int      IAE_StdDevPeriod       = 20;            // Período para Desvio Padrão
input double   IAE_StdDevMult         = 2.0;           // Multiplicador do Desvio Padrão

//╔══════════════════════════════════════════════════════════════════╗
//║          PARÂMETROS DO INDICADOR 5: SCP (Spectral Cycle Phaser)  ║
//╚══════════════════════════════════════════════════════════════════╝
input group "══════ 5. SCP - Spectral Cycle Phaser (Fourier) ══════"
input int      SCP_WindowSize         = 64;            // Tamanho da Janela (N) para DFT
input int      SCP_MinPeriod          = 10;            // Período Mínimo do Ciclo (T min)
input int      SCP_MaxPeriod          = 60;            // Período Máximo do Ciclo (T max)
input double   SCP_SignalThreshold    = 0.8;           // Limiar para Sinal (-0.8/+0.8)
input int      SCP_PowerMAPeriod      = 10;            // Período da Média de Power

//╔══════════════════════════════════════════════════════════════════╗
//║          PARÂMETROS DO INDICADOR 6: HEIKIN ASHI                  ║
//╚══════════════════════════════════════════════════════════════════╝
input group "══════ 6. HEIKIN ASHI ══════"
input int      HA_Confirmacao         = 2;             // Candles de confirmação

//╔══════════════════════════════════════════════════════════════════╗
//║          PARÂMETROS DO INDICADOR 7: VWAP                         ║
//╚══════════════════════════════════════════════════════════════════╝
input group "══════ 7. VWAP ══════"
input ENUM_TIMEFRAMES VWAP_TF         = PERIOD_M1;     // Tempo Gráfico VWAP
input bool     VWAP_UseRealVolume     = false;         // Usar Volume Real

//╔══════════════════════════════════════════════════════════════════╗
//║          PARÂMETROS DO INDICADOR 8: MOMENTUM (ROC)               ║
//╚══════════════════════════════════════════════════════════════════╝
input group "══════ 8. MOMENTUM (ROC) ══════"
input int      ROC_Period             = 12;            // Período
input double   ROC_Threshold          = 0.002;         // Limiar (0.002 = 0.2%)

//╔══════════════════════════════════════════════════════════════════╗
//║          PARÂMETROS DO INDICADOR 9: QQE                          ║
//╚══════════════════════════════════════════════════════════════════╝
input group "══════ 9. QQE ══════"
input int      QQE_RSI_Period         = 14;            // Período RSI
input int      QQE_Smoothing          = 5;             // Suavização

//╔══════════════════════════════════════════════════════════════════╗
//║                    VARIÁVEIS GLOBAIS                             ║
//╚══════════════════════════════════════════════════════════════════╝
CTrade trade;

// Handles dos indicadores
int hRSI = INVALID_HANDLE;
int hEMA_IAE = INVALID_HANDLE;   // EMA para IAE

// Variáveis de estado
int g_sinalAtual = 0;       // +1 = COMPRA, -1 = VENDA, 0 = NEUTRO
int g_sinalAnterior = 0;
datetime g_lastBarTime = 0;

// Variáveis EWGC (Entropy-Weighted Gaussian Channel)
double g_ewgc_entropia;          // Entropia normalizada H
double g_ewgc_p_gaussian;        // Linha central gaussiana
double g_ewgc_largura_canal;     // Largura do canal
double g_ewgc_mad;               // Mean Absolute Deviation
double g_ewgc_sigma_dinamico;    // Sigma dinâmico

// Variáveis PVP (Polynomial Velocity Predictor)
double g_pvp_coef_a, g_pvp_coef_b, g_pvp_coef_c, g_pvp_coef_d;  // Coeficientes polinômio
double g_pvp_velocidade, g_pvp_aceleracao;                       // Derivadas
double g_pvp_prob_alta;                                          // Probabilidade de alta
double g_pvp_sigma_err;                                          // Desvio padrão dos erros

// Variáveis IAE (Integral Arc Efficiency)
double g_iae_deslocamento;       // D - Deslocamento Vetorial
double g_iae_comprimento_arco;   // S - Comprimento de Arco
double g_iae_eficiencia;         // η - Coeficiente de Eficiência
double g_iae_energia;            // Energia Integral
double g_iae_eficiencia_ant;     // Eficiência anterior (para filtro)

// Variáveis SCP (Spectral Cycle Phaser)
int    g_scp_ciclo_dominante;    // Período do ciclo dominante (T)
double g_scp_power_dominante;    // Power do ciclo dominante
double g_scp_fase_atual;         // Fase projetada para barra atual (radianos)
double g_scp_senoide_atual;      // Valor da senoide sin(φ_atual)
double g_scp_senoide_anterior;   // Valor anterior da senoide
double g_scp_senoide_anterior2;  // Valor 2 barras atrás
double g_scp_power_medio;        // Média do power
double g_scp_power_buffer[];     // Buffer para cálculo de média

//+------------------------------------------------------------------+
//|                        OnInit                                     |
//+------------------------------------------------------------------+
int OnInit() {
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(20);

   // IMPORTANTE: Resetar variáveis globais para otimização
   g_sinalAtual = 0;
   g_sinalAnterior = 0;
   g_lastBarTime = 0;

   // Reset EWGC
   g_ewgc_entropia = 0;
   g_ewgc_p_gaussian = 0;
   g_ewgc_largura_canal = 0;
   g_ewgc_mad = 0;
   g_ewgc_sigma_dinamico = 0;

   // Reset PVP
   g_pvp_coef_a = 0;
   g_pvp_coef_b = 0;
   g_pvp_coef_c = 0;
   g_pvp_coef_d = 0;
   g_pvp_velocidade = 0;
   g_pvp_aceleracao = 0;
   g_pvp_prob_alta = 0.5;
   g_pvp_sigma_err = 0;

   // Reset IAE
   g_iae_deslocamento = 0;
   g_iae_comprimento_arco = 0;
   g_iae_eficiencia = 0;
   g_iae_energia = 0;
   g_iae_eficiencia_ant = 0;

   // Reset SCP
   g_scp_ciclo_dominante = SCP_MinPeriod;
   g_scp_power_dominante = 0;
   g_scp_fase_atual = 0;
   g_scp_senoide_atual = 0;
   g_scp_senoide_anterior = 0;
   g_scp_senoide_anterior2 = 0;
   g_scp_power_medio = 0;
   ArrayResize(g_scp_power_buffer, SCP_PowerMAPeriod);
   ArrayInitialize(g_scp_power_buffer, 0);

   Print("═══════════════════════════════════════════════════════════");
   Print("      MAAbot TREINADOR - Otimização de Indicadores");
   Print("═══════════════════════════════════════════════════════════");
   Print(" Indicador selecionado: ", GetIndicadorNome());
   Print(" Símbolo: ", InpSymbol, " | TF: ", EnumToString(InpTF));
   Print(" TP: ", TakeProfit_Pontos, " pts | SL: ", StopLoss_Pontos, " pts");
   Print("═══════════════════════════════════════════════════════════");

   // Inicializa indicadores necessários
   if(!InicializarIndicadores()) {
      Print("ERRO: Falha ao inicializar indicadores!");
      return INIT_FAILED;
   }

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//|                        OnDeinit                                   |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   // Libera handles
   if(hRSI != INVALID_HANDLE) IndicatorRelease(hRSI);
   if(hEMA_IAE != INVALID_HANDLE) IndicatorRelease(hEMA_IAE);

   Print("═══════════════════════════════════════════════════════════");
   Print("      MAAbot TREINADOR - Finalizado");
   Print("═══════════════════════════════════════════════════════════");
}

//+------------------------------------------------------------------+
//|                        OnTick                                     |
//+------------------------------------------------------------------+
void OnTick() {
   // Verifica se é uma nova barra
   datetime currentBarTime = iTime(InpSymbol, InpTF, 0);
   if(currentBarTime == g_lastBarTime) return;
   g_lastBarTime = currentBarTime;

   // Obtém o sinal do indicador selecionado
   g_sinalAnterior = g_sinalAtual;
   g_sinalAtual = ObterSinalIndicador();

   // Verifica se há posição aberta
   bool temPosicao = TemPosicaoAberta();
   int direcaoPosicao = GetDirecaoPosicao();

   // REGRA 7: Se o sinal mudou e tem posição, fecha e abre nova
   if(temPosicao && g_sinalAtual != 0 && g_sinalAtual != direcaoPosicao) {
      // Fecha a posição atual
      FecharTodasPosicoes();

      // Abre nova posição no sentido do sinal
      if(g_sinalAtual > 0) {
         AbrirCompra();
      } else if(g_sinalAtual < 0) {
         AbrirVenda();
      }
   }
   // REGRA 6: Se não tem posição e tem sinal, abre
   else if(!temPosicao && g_sinalAtual != 0) {
      if(g_sinalAtual > 0) {
         AbrirCompra();
      } else if(g_sinalAtual < 0) {
         AbrirVenda();
      }
   }
}

//+------------------------------------------------------------------+
//|              Inicializa indicadores necessários                   |
//+------------------------------------------------------------------+
bool InicializarIndicadores() {
   switch(Indicador) {
      case OPT_EWGC:
         // EWGC é calculado manualmente (entropia + gaussiano)
         return true;

      case OPT_RSI:
         hRSI = iRSI(InpSymbol, InpTF, RSI_Period, PRICE_CLOSE);
         return (hRSI != INVALID_HANDLE);

      case OPT_PVP:
         // PVP é calculado manualmente (regressão polinomial)
         return true;

      case OPT_IAE:
         hEMA_IAE = iMA(InpSymbol, InpTF, IAE_EMA_Period, 0, MODE_EMA, PRICE_CLOSE);
         return (hEMA_IAE != INVALID_HANDLE);

      case OPT_SCP:
         // SCP é calculado manualmente (DFT)
         return true;

      case OPT_HEIKIN_ASHI:
         // Heikin Ashi é calculado manualmente
         return true;

      case OPT_VWAP:
         // VWAP é calculado manualmente
         return true;

      case OPT_MOMENTUM:
         // ROC é calculado manualmente
         return true;

      case OPT_QQE:
         hRSI = iRSI(InpSymbol, InpTF, QQE_RSI_Period, PRICE_CLOSE);
         return (hRSI != INVALID_HANDLE);
   }
   return false;
}

//+------------------------------------------------------------------+
//|              Obtém o sinal do indicador selecionado               |
//+------------------------------------------------------------------+
int ObterSinalIndicador() {
   switch(Indicador) {
      case OPT_EWGC:        return SinalEWGC();
      case OPT_RSI:         return SinalRSI();
      case OPT_PVP:         return SinalPVP();
      case OPT_IAE:         return SinalIAE();
      case OPT_SCP:         return SinalSCP();
      case OPT_HEIKIN_ASHI: return SinalHeikinAshi();
      case OPT_VWAP:        return SinalVWAP();
      case OPT_MOMENTUM:    return SinalMomentum();
      case OPT_QQE:         return SinalQQE();
   }
   return 0;
}

//+------------------------------------------------------------------+
//|              1. SINAL EWGC (Entropy-Weighted Gaussian Channel)    |
//+------------------------------------------------------------------+
int SinalEWGC() {
   if(Bars(InpSymbol, InpTF) < EWGC_Period + 2) return 0;

   // Copiar dados
   double close[];
   ArraySetAsSeries(close, true);
   if(CopyClose(InpSymbol, InpTF, 0, EWGC_Period + 2, close) < EWGC_Period + 2) return 0;

   //=== A. CALCULAR ENTROPIA DE SHANNON NORMALIZADA ===
   g_ewgc_entropia = EWGC_CalcularEntropiaNormalizada(close, 1, EWGC_Period, EWGC_Buckets);

   // Verificar se mercado está caótico - NÃO dar sinais
   if(g_ewgc_entropia > EWGC_ChaosThreshold) return 0;

   //=== B. CALCULAR SIGMA DINÂMICO E LINHA CENTRAL GAUSSIANA ===
   g_ewgc_sigma_dinamico = EWGC_Period * (1.0 - g_ewgc_entropia);
   if(g_ewgc_sigma_dinamico < 1.0) g_ewgc_sigma_dinamico = 1.0;

   g_ewgc_p_gaussian = EWGC_CalcularMediaGaussiana(close, 1, EWGC_Period, g_ewgc_sigma_dinamico);

   //=== C. CALCULAR CANAL DINÂMICO ===
   g_ewgc_mad = EWGC_CalcularMAD(close, 1, EWGC_Period, g_ewgc_p_gaussian);
   g_ewgc_largura_canal = g_ewgc_mad * (1.0 + g_ewgc_entropia * EWGC_ExpansionFactor);

   double bandaSuperior = g_ewgc_p_gaussian + g_ewgc_largura_canal;
   double bandaInferior = g_ewgc_p_gaussian - g_ewgc_largura_canal;

   double preco_atual = close[1];

   //=== D. LÓGICA DE SINALIZAÇÃO ===
   // Nota: Se entropia > ChaosThreshold, já retornamos 0 acima

   // Modo "Sniper": entropia muito baixa = mercado muito ordenado = sinais mais confiáveis
   bool modoSniper = (g_ewgc_entropia < EWGC_SniperThreshold);

   // Sinal de COMPRA: preço toca/cruza banda inferior
   // Em modo sniper, aceita preço próximo da banda (dentro de 20% da largura)
   double margemSniper = modoSniper ? g_ewgc_largura_canal * 0.2 : 0;

   if(preco_atual <= bandaInferior + margemSniper) {
      return +1;
   }

   // Sinal de VENDA: preço toca/cruza banda superior
   if(preco_atual >= bandaSuperior - margemSniper) {
      return -1;
   }

   return 0;
}

//+------------------------------------------------------------------+
//| EWGC: Calcular Entropia de Shannon Normalizada                    |
//+------------------------------------------------------------------+
double EWGC_CalcularEntropiaNormalizada(double &price[], int idx, int period, int num_buckets) {
   // Calcular retornos logarítmicos
   double retornos[];
   ArrayResize(retornos, period - 1);

   double min_retorno = DBL_MAX;
   double max_retorno = -DBL_MAX;

   for(int j = 0; j < period - 1; j++) {
      int current = idx + j;
      int previous = current + 1;

      if(price[previous] <= 0) {
         retornos[j] = 0;
         continue;
      }

      retornos[j] = MathLog(price[current] / price[previous]);

      if(retornos[j] < min_retorno) min_retorno = retornos[j];
      if(retornos[j] > max_retorno) max_retorno = retornos[j];
   }

   // Criar histograma de frequência
   double range = max_retorno - min_retorno;
   if(range < 1e-10) range = 1e-10;

   double bucket_size = range / num_buckets;

   int frequencias[];
   ArrayResize(frequencias, num_buckets);
   ArrayInitialize(frequencias, 0);

   int total_retornos = period - 1;

   for(int j = 0; j < total_retornos; j++) {
      int bucket_idx = (int)MathFloor((retornos[j] - min_retorno) / bucket_size);
      if(bucket_idx < 0) bucket_idx = 0;
      if(bucket_idx >= num_buckets) bucket_idx = num_buckets - 1;
      frequencias[bucket_idx]++;
   }

   // Calcular entropia H = -Σ p_k · ln(p_k)
   double entropia = 0.0;
   for(int k = 0; k < num_buckets; k++) {
      if(frequencias[k] > 0) {
         double p_k = (double)frequencias[k] / (double)total_retornos;
         entropia -= p_k * MathLog(p_k);
      }
   }

   // Normalizar H_norm = H / ln(N)
   double entropia_maxima = MathLog((double)num_buckets);
   if(entropia_maxima > 0)
      return entropia / entropia_maxima;
   return 0;
}

//+------------------------------------------------------------------+
//| EWGC: Calcular Média Gaussiana Ponderada                          |
//+------------------------------------------------------------------+
double EWGC_CalcularMediaGaussiana(double &price[], int idx, int period, double sigma) {
   double soma_ponderada = 0.0;
   double soma_pesos = 0.0;

   double sigma_sq_2 = 2.0 * sigma * sigma;
   if(sigma_sq_2 < 1e-10) sigma_sq_2 = 1e-10;

   for(int j = 0; j < period; j++) {
      int current = idx + j;
      double peso = MathExp(-(double)(j * j) / sigma_sq_2);
      soma_ponderada += price[current] * peso;
      soma_pesos += peso;
   }

   if(soma_pesos > 0)
      return soma_ponderada / soma_pesos;
   return price[idx];
}

//+------------------------------------------------------------------+
//| EWGC: Calcular MAD (Mean Absolute Deviation)                      |
//+------------------------------------------------------------------+
double EWGC_CalcularMAD(double &price[], int idx, int period, double media) {
   double soma_desvios = 0.0;
   int count = 0;

   for(int j = 0; j < period; j++) {
      int current = idx + j;
      soma_desvios += MathAbs(price[current] - media);
      count++;
   }

   if(count > 0)
      return soma_desvios / count;
   return 0;
}

//+------------------------------------------------------------------+
//|              2. SINAL RSI                                         |
//+------------------------------------------------------------------+
int SinalRSI() {
   double rsi[];
   ArraySetAsSeries(rsi, true);

   if(CopyBuffer(hRSI, 0, 0, 3, rsi) < 3) return 0;

   // RSI abaixo do nível sobrevendido = COMPRA
   if(rsi[1] < RSI_Sobrevendido) return +1;
   // RSI acima do nível sobrecomprado = VENDA
   if(rsi[1] > RSI_Sobrecomprado) return -1;

   return 0;
}

//+------------------------------------------------------------------+
//|              3. SINAL PVP (Polynomial Velocity Predictor)         |
//+------------------------------------------------------------------+
int SinalPVP() {
   // Verificar dados suficientes
   if(Bars(InpSymbol, InpTF) < PVP_LookbackPeriod + 1) return 0;

   // Extrair dados para regressão (últimas n velas)
   double precos[];
   ArrayResize(precos, PVP_LookbackPeriod);

   for(int j = 0; j < PVP_LookbackPeriod; j++) {
      precos[j] = iClose(InpSymbol, InpTF, PVP_LookbackPeriod - j);
   }

   // Realizar regressão polinomial cúbica
   if(!PVP_RegressaoPolinomialCubica(precos, PVP_LookbackPeriod))
      return 0;

   // Calcular desvio padrão dos erros
   g_pvp_sigma_err = PVP_CalcularSigmaErro(precos, PVP_LookbackPeriod);

   // Ponto atual
   double t_atual = (double)(PVP_LookbackPeriod - 1);

   // Calcular velocidade e aceleração
   g_pvp_velocidade = PVP_CalcularVelocidade(t_atual);
   g_pvp_aceleracao = PVP_CalcularAceleracao(t_atual);

   // Calcular preço previsto para t+1
   double t_proximo = t_atual + 1.0;
   double preco_previsto = PVP_CalcularP(t_proximo);

   // Calcular probabilidade de alta
   g_pvp_prob_alta = PVP_CalcularProbabilidadeAlta(g_pvp_velocidade, g_pvp_sigma_err);

   // Sinal de COMPRA (simplificado): velocidade + probabilidade
   if(g_pvp_velocidade > 0 && g_pvp_prob_alta > PVP_ProbBuyThresh) {
      return +1;
   }

   // Sinal de VENDA (simplificado): velocidade + probabilidade
   if(g_pvp_velocidade < 0 && g_pvp_prob_alta < PVP_ProbSellThresh) {
      return -1;
   }

   return 0;
}

//+------------------------------------------------------------------+
//| PVP: Regressão Polinomial Cúbica usando Mínimos Quadrados        |
//| P(t) = at³ + bt² + ct + d                                        |
//+------------------------------------------------------------------+
bool PVP_RegressaoPolinomialCubica(double &precos[], int n) {
   // Construir Matriz de Vandermonde X (n x 4)
   double X[][4];
   ArrayResize(X, n);

   for(int i = 0; i < n; i++) {
      double t = (double)i;
      X[i][0] = t * t * t;  // t³
      X[i][1] = t * t;      // t²
      X[i][2] = t;          // t
      X[i][3] = 1.0;        // 1
   }

   // Calcular X^T X (4 x 4) usando array 1D (índice = i*4 + j)
   double XTX[16];  // 4x4 em 1D
   for(int i = 0; i < 4; i++) {
      for(int j = 0; j < 4; j++) {
         XTX[i*4 + j] = 0.0;
         for(int k = 0; k < n; k++) {
            XTX[i*4 + j] += X[k][i] * X[k][j];
         }
      }
   }

   // Calcular X^T Y (4 x 1)
   double XTY[4];
   for(int i = 0; i < 4; i++) {
      XTY[i] = 0.0;
      for(int k = 0; k < n; k++) {
         XTY[i] += X[k][i] * precos[k];
      }
   }

   // Calcular (X^T X)^(-1) usando Gauss-Jordan
   double XTX_inv[16];  // 4x4 em 1D
   if(!PVP_InverterMatriz4x4(XTX, XTX_inv))
      return false;

   // Calcular β = (X^T X)^(-1) X^T Y
   double beta[4];
   for(int i = 0; i < 4; i++) {
      beta[i] = 0.0;
      for(int j = 0; j < 4; j++) {
         beta[i] += XTX_inv[i*4 + j] * XTY[j];
      }
   }

   // Armazenar coeficientes [a, b, c, d]
   g_pvp_coef_a = beta[0];
   g_pvp_coef_b = beta[1];
   g_pvp_coef_c = beta[2];
   g_pvp_coef_d = beta[3];

   return true;
}

//+------------------------------------------------------------------+
//| PVP: Inverter Matriz 4x4 usando Gauss-Jordan (arrays 1D)         |
//| A e A_inv são arrays 1D de 16 elementos (índice = row*4 + col)   |
//+------------------------------------------------------------------+
bool PVP_InverterMatriz4x4(double &A[], double &A_inv[]) {
   // Criar matriz aumentada [A | I] em 1D (4x8 = 32 elementos)
   double aug[32];

   for(int i = 0; i < 4; i++) {
      for(int j = 0; j < 4; j++) {
         aug[i*8 + j] = A[i*4 + j];
         aug[i*8 + j + 4] = (i == j) ? 1.0 : 0.0;
      }
   }

   // Eliminação de Gauss-Jordan
   for(int col = 0; col < 4; col++) {
      // Encontrar pivô
      int max_row = col;
      double max_val = MathAbs(aug[col*8 + col]);

      for(int row = col + 1; row < 4; row++) {
         if(MathAbs(aug[row*8 + col]) > max_val) {
            max_val = MathAbs(aug[row*8 + col]);
            max_row = row;
         }
      }

      // Verificar singularidade
      if(max_val < 1e-10)
         return false;

      // Trocar linhas
      if(max_row != col) {
         for(int j = 0; j < 8; j++) {
            double temp = aug[col*8 + j];
            aug[col*8 + j] = aug[max_row*8 + j];
            aug[max_row*8 + j] = temp;
         }
      }

      // Normalizar linha do pivô
      double pivot = aug[col*8 + col];
      for(int j = 0; j < 8; j++) {
         aug[col*8 + j] /= pivot;
      }

      // Eliminar outras linhas
      for(int row = 0; row < 4; row++) {
         if(row != col) {
            double factor = aug[row*8 + col];
            for(int j = 0; j < 8; j++) {
               aug[row*8 + j] -= factor * aug[col*8 + j];
            }
         }
      }
   }

   // Extrair matriz inversa
   for(int i = 0; i < 4; i++) {
      for(int j = 0; j < 4; j++) {
         A_inv[i*4 + j] = aug[i*8 + j + 4];
      }
   }

   return true;
}

//+------------------------------------------------------------------+
//| PVP: Calcular P(t) = at³ + bt² + ct + d                          |
//+------------------------------------------------------------------+
double PVP_CalcularP(double t) {
   return g_pvp_coef_a * t * t * t + g_pvp_coef_b * t * t + g_pvp_coef_c * t + g_pvp_coef_d;
}

//+------------------------------------------------------------------+
//| PVP: Calcular Velocidade v(t) = P'(t) = 3at² + 2bt + c           |
//+------------------------------------------------------------------+
double PVP_CalcularVelocidade(double t) {
   return 3.0 * g_pvp_coef_a * t * t + 2.0 * g_pvp_coef_b * t + g_pvp_coef_c;
}

//+------------------------------------------------------------------+
//| PVP: Calcular Aceleração a(t) = P''(t) = 6at + 2b                |
//+------------------------------------------------------------------+
double PVP_CalcularAceleracao(double t) {
   return 6.0 * g_pvp_coef_a * t + 2.0 * g_pvp_coef_b;
}

//+------------------------------------------------------------------+
//| PVP: Calcular Desvio Padrão dos Erros (sigma_err)                |
//+------------------------------------------------------------------+
double PVP_CalcularSigmaErro(double &precos[], int n) {
   double soma_erro_quad = 0.0;

   for(int i = 0; i < n; i++) {
      double t = (double)i;
      double p_estimado = PVP_CalcularP(t);
      double erro = precos[i] - p_estimado;
      soma_erro_quad += erro * erro;
   }

   double mse = soma_erro_quad / (double)n;
   return MathSqrt(mse);
}

//+------------------------------------------------------------------+
//| PVP: Calcular Probabilidade de Alta (Sigmoide Modificada)        |
//| Prob_alta = 1 / (1 + e^(-k * v(t) / sigma_err))                  |
//+------------------------------------------------------------------+
double PVP_CalcularProbabilidadeAlta(double velocidade, double sigma_err) {
   if(sigma_err < 1e-10)
      sigma_err = 1e-10;

   double z = velocidade / sigma_err;
   double expoente = -PVP_Sensitivity * z;

   // Limitar expoente para evitar overflow
   if(expoente > 700) return 0.0;
   if(expoente < -700) return 1.0;

   return 1.0 / (1.0 + MathExp(expoente));
}

//+------------------------------------------------------------------+
//|              4. SINAL IAE (Integral Arc Efficiency)               |
//+------------------------------------------------------------------+
int SinalIAE() {
   int minBars = IAE_Period + IAE_StdDevPeriod + 1;
   if(Bars(InpSymbol, InpTF) < minBars) return 0;

   // Copiar dados
   double close[], ema[];
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(ema, true);

   if(CopyClose(InpSymbol, InpTF, 0, minBars, close) < minBars) return 0;
   if(CopyBuffer(hEMA_IAE, 0, 0, minBars, ema) < minBars) return 0;

   // Normalização
   double point_scale = SymbolInfoDouble(InpSymbol, SYMBOL_POINT) * 10000;
   if(point_scale == 0) point_scale = 0.01;

   //=== A. CALCULAR DESLOCAMENTO VETORIAL (D) ===
   g_iae_deslocamento = close[1] - close[IAE_Period];

   //=== B. CALCULAR COMPRIMENTO DE ARCO (S) ===
   g_iae_comprimento_arco = IAE_CalcularComprimentoArco(close, 1, IAE_Period);

   //=== C. CALCULAR COEFICIENTE DE EFICIÊNCIA (η) ===
   if(g_iae_comprimento_arco > 0)
      g_iae_eficiencia = MathAbs(g_iae_deslocamento) / g_iae_comprimento_arco;
   else
      g_iae_eficiencia = 0;

   g_iae_eficiencia = MathMin(g_iae_eficiencia, 1.0);
   g_iae_eficiencia = MathMax(g_iae_eficiencia, 0.0);

   //=== D. CALCULAR ENERGIA (Integral de Riemann) ===
   g_iae_energia = IAE_CalcularEnergiaIntegral(close, ema, 1, IAE_Period);
   double energia_norm = g_iae_energia / (IAE_Period * point_scale);

   //=== E. CALCULAR DESVIO PADRÃO DA ENERGIA ===
   double energia_hist[];
   ArrayResize(energia_hist, IAE_StdDevPeriod);
   for(int i = 0; i < IAE_StdDevPeriod; i++) {
      double e = IAE_CalcularEnergiaIntegral(close, ema, 1 + i, IAE_Period);
      energia_hist[i] = e / (IAE_Period * point_scale);
   }

   double energia_media = 0, energia_stddev = 0;
   for(int i = 0; i < IAE_StdDevPeriod; i++) energia_media += energia_hist[i];
   energia_media /= IAE_StdDevPeriod;

   for(int i = 0; i < IAE_StdDevPeriod; i++) {
      double diff = energia_hist[i] - energia_media;
      energia_stddev += diff * diff;
   }
   energia_stddev = MathSqrt(energia_stddev / IAE_StdDevPeriod);

   double energia_upper = energia_media + IAE_StdDevMult * energia_stddev;
   double energia_lower = energia_media - IAE_StdDevMult * energia_stddev;

   //=== F. ATUALIZAR ESTADO ===
   g_iae_eficiencia_ant = g_iae_eficiencia;

   //=== G. LÓGICA DE SINALIZAÇÃO (simplificada para otimização) ===

   // Sinal de COMPRA: η alto + direção alta + energia positiva
   if(g_iae_eficiencia > IAE_EffThreshold &&
      g_iae_deslocamento > 0 &&
      energia_norm > 0) {
      return +1;
   }

   // Sinal de VENDA: η alto + direção baixa + energia negativa
   if(g_iae_eficiencia > IAE_EffThreshold &&
      g_iae_deslocamento < 0 &&
      energia_norm < 0) {
      return -1;
   }

   return 0;
}

//+------------------------------------------------------------------+
//| IAE: Calcular Comprimento de Arco                                 |
//+------------------------------------------------------------------+
double IAE_CalcularComprimentoArco(double &price[], int idx, int period) {
   double arc_length = 0.0;
   double pt = SymbolInfoDouble(InpSymbol, SYMBOL_POINT);
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

//+------------------------------------------------------------------+
//| IAE: Calcular Energia Integral (Riemann)                          |
//+------------------------------------------------------------------+
double IAE_CalcularEnergiaIntegral(double &price[], double &ema_buf[], int idx, int period) {
   double energia = 0.0;

   for(int j = 0; j < period; j++) {
      int current = idx + j;
      double diff = price[current] - ema_buf[current];
      energia += diff;
   }

   return energia;
}

//+------------------------------------------------------------------+
//|              5. SINAL SCP (Spectral Cycle Phaser - Fourier DFT)   |
//+------------------------------------------------------------------+
int SinalSCP() {
   int minBars = SCP_WindowSize + SCP_MaxPeriod + 2;
   if(Bars(InpSymbol, InpTF) < minBars) return 0;

   // Copiar dados
   double close[];
   ArraySetAsSeries(close, true);
   if(CopyClose(InpSymbol, InpTF, 0, minBars, close) < minBars) return 0;

   //=== 1. PRÉ-PROCESSAMENTO (LIMPEZA DE SINAL) ===

   // Extrair janela de preços
   double precos_raw[];
   ArrayResize(precos_raw, SCP_WindowSize);

   for(int j = 0; j < SCP_WindowSize; j++) {
      precos_raw[j] = close[SCP_WindowSize - j];  // Ordenar do mais antigo ao mais recente
   }

   // A. Detrending (Remoção de Tendência Linear)
   double precos_detrend[];
   ArrayResize(precos_detrend, SCP_WindowSize);
   SCP_RemoverTendenciaLinear(precos_raw, precos_detrend, SCP_WindowSize);

   // B. Janelamento (Hanning Window)
   double input_fourier[];
   ArrayResize(input_fourier, SCP_WindowSize);
   SCP_AplicarHanningWindow(precos_detrend, input_fourier, SCP_WindowSize);

   //=== 2. MOTOR MATEMÁTICO (DFT OTIMIZADA) ===
   // Buscar ciclos na faixa de interesse (MinPeriod a MaxPeriod barras)

   double max_power = 0.0;
   int periodo_dominante = SCP_MinPeriod;
   double fase_dominante = 0.0;

   // Loop pelos períodos T de interesse
   for(int T = SCP_MinPeriod; T <= SCP_MaxPeriod; T++) {
      // Frequência angular: ω = 2π/T
      double omega = 2.0 * M_PI / (double)T;

      // Calcular componentes Real e Imaginária
      double real_sum = 0.0;
      double imag_sum = 0.0;

      for(int n = 0; n < SCP_WindowSize; n++) {
         double angle = omega * n;
         real_sum += input_fourier[n] * MathCos(angle);
         imag_sum += input_fourier[n] * MathSin(angle);
      }

      // Potência (Amplitude do Ciclo): Power_T = √(Real² + Imag²)
      double power_T = MathSqrt(real_sum * real_sum + imag_sum * imag_sum);

      // Verificar se é o ciclo dominante (maior power)
      if(power_T > max_power) {
         max_power = power_T;
         periodo_dominante = T;

         // Fase (Posição no Ciclo): φ_T = arctan(-Imag/Real)
         fase_dominante = MathArctan2(-imag_sum, real_sum);
      }
   }

   // Salvar resultados do ciclo dominante
   g_scp_ciclo_dominante = periodo_dominante;
   g_scp_power_dominante = max_power;

   //=== 3. PREVISÃO DE FASE ===
   // A fase retornada refere-se ao início da janela
   // Projetar para a barra atual

   double omega_dominante = 2.0 * M_PI / (double)g_scp_ciclo_dominante;

   // φ_atual = φ_dominante + ω_dominante · N
   g_scp_fase_atual = fase_dominante + omega_dominante * SCP_WindowSize;

   // Normalizar para ficar entre -π e +π
   g_scp_fase_atual = SCP_NormalizarFase(g_scp_fase_atual);

   //=== 4. OSCILADOR SENOIDAL ===
   // Atualizar histórico
   g_scp_senoide_anterior2 = g_scp_senoide_anterior;
   g_scp_senoide_anterior = g_scp_senoide_atual;
   g_scp_senoide_atual = MathSin(g_scp_fase_atual);

   // Atualizar buffer de power para média móvel
   SCP_AtualizarPowerBuffer(g_scp_power_dominante);
   g_scp_power_medio = SCP_CalcularMediaPower();

   //=== 5. LÓGICA DE SINALIZAÇÃO ===
   bool power_alto = (g_scp_power_dominante > g_scp_power_medio);

   // Verificar se há histórico suficiente
   if(g_scp_senoide_anterior == 0 && g_scp_senoide_anterior2 == 0) return 0;

   // SINAL DE COMPRA
   // Senoide no fundo (< -threshold) e virando para cima
   bool fundo_ciclo = (g_scp_senoide_anterior < -SCP_SignalThreshold);
   bool virando_cima = (g_scp_senoide_atual > g_scp_senoide_anterior &&
                        g_scp_senoide_anterior <= g_scp_senoide_anterior2);

   if(fundo_ciclo && virando_cima && power_alto) {
      return +1;
   }

   // SINAL DE VENDA
   // Senoide no topo (> threshold) e virando para baixo
   bool topo_ciclo = (g_scp_senoide_anterior > SCP_SignalThreshold);
   bool virando_baixo = (g_scp_senoide_atual < g_scp_senoide_anterior &&
                         g_scp_senoide_anterior >= g_scp_senoide_anterior2);

   if(topo_ciclo && virando_baixo && power_alto) {
      return -1;
   }

   return 0;
}

//+------------------------------------------------------------------+
//| SCP: Remover Tendência Linear (Detrending)                        |
//| x_i = Price_i - (m·i + c)                                         |
//+------------------------------------------------------------------+
void SCP_RemoverTendenciaLinear(double &input[], double &output[], int size) {
   // Calcular regressão linear y = mx + c
   double sum_x = 0.0;
   double sum_y = 0.0;
   double sum_xy = 0.0;
   double sum_x2 = 0.0;

   for(int i = 0; i < size; i++) {
      sum_x += i;
      sum_y += input[i];
      sum_xy += i * input[i];
      sum_x2 += i * i;
   }

   double n = (double)size;
   double denominador = (n * sum_x2 - sum_x * sum_x);

   double m = 0.0;  // Inclinação
   double c = 0.0;  // Intercepto

   if(MathAbs(denominador) > 1e-10) {
      m = (n * sum_xy - sum_x * sum_y) / denominador;
      c = (sum_y - m * sum_x) / n;
   }

   // Remover tendência: x_i = Price_i - (m·i + c)
   for(int i = 0; i < size; i++) {
      output[i] = input[i] - (m * i + c);
   }
}

//+------------------------------------------------------------------+
//| SCP: Aplicar Janela de Hanning (Windowing)                        |
//| w_i = 0.5 · (1 - cos(2πi/(N-1)))                                  |
//+------------------------------------------------------------------+
void SCP_AplicarHanningWindow(double &input[], double &output[], int size) {
   for(int i = 0; i < size; i++) {
      // Calcular peso da janela Hanning
      double w_i = 0.5 * (1.0 - MathCos(2.0 * M_PI * i / (size - 1)));

      // Aplicar janela ao dado
      output[i] = input[i] * w_i;
   }
}

//+------------------------------------------------------------------+
//| SCP: Normalizar Fase para ficar entre -π e +π                     |
//+------------------------------------------------------------------+
double SCP_NormalizarFase(double fase) {
   while(fase > M_PI)
      fase -= 2.0 * M_PI;

   while(fase < -M_PI)
      fase += 2.0 * M_PI;

   return fase;
}

//+------------------------------------------------------------------+
//| SCP: Atualizar Buffer de Power (circular)                         |
//+------------------------------------------------------------------+
void SCP_AtualizarPowerBuffer(double power) {
   // Deslocar valores
   for(int i = SCP_PowerMAPeriod - 1; i > 0; i--) {
      g_scp_power_buffer[i] = g_scp_power_buffer[i - 1];
   }
   g_scp_power_buffer[0] = power;
}

//+------------------------------------------------------------------+
//| SCP: Calcular Média do Power                                      |
//+------------------------------------------------------------------+
double SCP_CalcularMediaPower() {
   double soma = 0.0;
   int count = 0;

   for(int i = 0; i < SCP_PowerMAPeriod; i++) {
      if(g_scp_power_buffer[i] > 0) {
         soma += g_scp_power_buffer[i];
         count++;
      }
   }

   if(count > 0)
      return soma / count;
   return 0;
}

//+------------------------------------------------------------------+
//|              6. SINAL HEIKIN ASHI                                 |
//+------------------------------------------------------------------+
int SinalHeikinAshi() {
   double open[], high[], low[], close[];
   ArraySetAsSeries(open, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);

   int bars = HA_Confirmacao + 3;
   if(CopyOpen(InpSymbol, InpTF, 0, bars, open) < bars) return 0;
   if(CopyHigh(InpSymbol, InpTF, 0, bars, high) < bars) return 0;
   if(CopyLow(InpSymbol, InpTF, 0, bars, low) < bars) return 0;
   if(CopyClose(InpSymbol, InpTF, 0, bars, close) < bars) return 0;

   // Calcula Heikin Ashi
   double haClose = (open[1] + high[1] + low[1] + close[1]) / 4.0;
   double haOpen = (open[2] + close[2]) / 2.0;

   int bullCount = 0, bearCount = 0;

   for(int i = 1; i <= HA_Confirmacao; i++) {
      double hc = (open[i] + high[i] + low[i] + close[i]) / 4.0;
      double ho = (open[i+1] + close[i+1]) / 2.0;

      if(hc > ho) bullCount++;
      else if(hc < ho) bearCount++;
   }

   // N candles consecutivos bullish = COMPRA
   if(bullCount >= HA_Confirmacao) return +1;
   // N candles consecutivos bearish = VENDA
   if(bearCount >= HA_Confirmacao) return -1;

   return 0;
}

//+------------------------------------------------------------------+
//|              7. SINAL VWAP                                        |
//+------------------------------------------------------------------+
int SinalVWAP() {
   double vwap = CalcularVWAP();
   if(vwap <= 0) return 0;

   double close = iClose(InpSymbol, InpTF, 1);

   // Preço acima do VWAP = COMPRA
   if(close > vwap) return +1;
   // Preço abaixo do VWAP = VENDA
   if(close < vwap) return -1;

   return 0;
}

double CalcularVWAP() {
   datetime dayStart = StringToTime(TimeToString(TimeCurrent(), TIME_DATE));
   int bars = Bars(InpSymbol, VWAP_TF, dayStart, TimeCurrent());
   if(bars <= 0) return 0;

   double sumPV = 0, sumV = 0;

   for(int i = 0; i < bars; i++) {
      double h = iHigh(InpSymbol, VWAP_TF, i);
      double l = iLow(InpSymbol, VWAP_TF, i);
      double c = iClose(InpSymbol, VWAP_TF, i);
      double typical = (h + l + c) / 3.0;

      double vol = (double)(VWAP_UseRealVolume ? iVolume(InpSymbol, VWAP_TF, i) : iTickVolume(InpSymbol, VWAP_TF, i));

      sumPV += typical * vol;
      sumV += vol;
   }

   return (sumV > 0) ? sumPV / sumV : 0;
}

//+------------------------------------------------------------------+
//|              8. SINAL MOMENTUM (ROC)                              |
//+------------------------------------------------------------------+
int SinalMomentum() {
   double close[];
   ArraySetAsSeries(close, true);

   if(CopyClose(InpSymbol, InpTF, 0, ROC_Period + 3, close) < ROC_Period + 3) return 0;

   // ROC = (Close - Close[n]) / Close[n]
   double roc = (close[1] - close[1 + ROC_Period]) / close[1 + ROC_Period];

   // ROC acima do limiar = COMPRA
   if(roc > ROC_Threshold) return +1;
   // ROC abaixo do limiar negativo = VENDA
   if(roc < -ROC_Threshold) return -1;

   return 0;
}

//+------------------------------------------------------------------+
//|              9. SINAL QQE                                         |
//+------------------------------------------------------------------+
int SinalQQE() {
   double rsi[];
   ArraySetAsSeries(rsi, true);

   if(CopyBuffer(hRSI, 0, 0, QQE_Smoothing + 5, rsi) < QQE_Smoothing + 5) return 0;

   // QQE simplificado: RSI suavizado
   double smoothedRSI = 0;
   for(int i = 1; i <= QQE_Smoothing; i++) {
      smoothedRSI += rsi[i];
   }
   smoothedRSI /= QQE_Smoothing;

   double prevSmoothedRSI = 0;
   for(int i = 2; i <= QQE_Smoothing + 1; i++) {
      prevSmoothedRSI += rsi[i];
   }
   prevSmoothedRSI /= QQE_Smoothing;

   // RSI suavizado cruzando 50 para cima = COMPRA
   if(smoothedRSI > 50 && prevSmoothedRSI <= 50) return +1;
   // RSI suavizado cruzando 50 para baixo = VENDA
   if(smoothedRSI < 50 && prevSmoothedRSI >= 50) return -1;

   // Manter direção
   if(smoothedRSI > 50) return +1;
   if(smoothedRSI < 50) return -1;

   return 0;
}

//+------------------------------------------------------------------+
//|              Funções de Gestão de Posições                        |
//+------------------------------------------------------------------+
bool TemPosicaoAberta() {
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket)) {
         if(PositionGetString(POSITION_SYMBOL) == InpSymbol &&
            PositionGetInteger(POSITION_MAGIC) == MagicNumber) {
            return true;
         }
      }
   }
   return false;
}

int GetDirecaoPosicao() {
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket)) {
         if(PositionGetString(POSITION_SYMBOL) == InpSymbol &&
            PositionGetInteger(POSITION_MAGIC) == MagicNumber) {
            long type = PositionGetInteger(POSITION_TYPE);
            return (type == POSITION_TYPE_BUY) ? +1 : -1;
         }
      }
   }
   return 0;
}

void FecharTodasPosicoes() {
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket)) {
         if(PositionGetString(POSITION_SYMBOL) == InpSymbol &&
            PositionGetInteger(POSITION_MAGIC) == MagicNumber) {
            trade.PositionClose(ticket);
         }
      }
   }
}

void AbrirCompra() {
   double ask = SymbolInfoDouble(InpSymbol, SYMBOL_ASK);
   double pt = SymbolInfoDouble(InpSymbol, SYMBOL_POINT);

   double sl = ask - StopLoss_Pontos * pt;
   double tp = ask + TakeProfit_Pontos * pt;

   if(trade.Buy(LoteFixo, InpSymbol, ask, sl, tp, "Trainer " + GetIndicadorNome())) {
      Print("COMPRA aberta - Indicador: ", GetIndicadorNome());
   }
}

void AbrirVenda() {
   double bid = SymbolInfoDouble(InpSymbol, SYMBOL_BID);
   double pt = SymbolInfoDouble(InpSymbol, SYMBOL_POINT);

   double sl = bid + StopLoss_Pontos * pt;
   double tp = bid - TakeProfit_Pontos * pt;

   if(trade.Sell(LoteFixo, InpSymbol, bid, sl, tp, "Trainer " + GetIndicadorNome())) {
      Print("VENDA aberta - Indicador: ", GetIndicadorNome());
   }
}

string GetIndicadorNome() {
   switch(Indicador) {
      case OPT_EWGC:        return "EWGC";
      case OPT_RSI:         return "RSI";
      case OPT_PVP:         return "PVP";
      case OPT_IAE:         return "IAE";
      case OPT_SCP:         return "SCP";
      case OPT_HEIKIN_ASHI: return "Heikin Ashi";
      case OPT_VWAP:        return "VWAP";
      case OPT_MOMENTUM:    return "Momentum";
      case OPT_QQE:         return "QQE";
   }
   return "Desconhecido";
}
//+------------------------------------------------------------------+
