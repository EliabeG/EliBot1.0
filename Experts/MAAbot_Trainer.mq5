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
   OPT_MA_CROSS      = 0,  // 1. Cruzamento de Médias (MA Cross)
   OPT_RSI           = 1,  // 2. RSI
   OPT_BOLLINGER     = 2,  // 3. Bandas de Bollinger
   OPT_SUPERTREND    = 3,  // 4. SuperTrend
   OPT_AMA_KAMA      = 4,  // 5. AMA/KAMA
   OPT_HEIKIN_ASHI   = 5,  // 6. Heikin Ashi
   OPT_VWAP          = 6,  // 7. VWAP
   OPT_MOMENTUM      = 7,  // 8. Momentum (ROC)
   OPT_QQE           = 8   // 9. QQE
};

//╔══════════════════════════════════════════════════════════════════╗
//║                    CONFIGURAÇÕES BÁSICAS                         ║
//╚══════════════════════════════════════════════════════════════════╝
input group "══════ CONFIGURAÇÃO DO TREINADOR ══════"
input IndicadorParaOtimizar Indicador = OPT_MA_CROSS;  // ████ INDICADOR PARA OTIMIZAR ████
input string   InpSymbol              = "XAUUSD";      // Símbolo
input ENUM_TIMEFRAMES InpTF           = PERIOD_M15;    // Tempo Gráfico

input group "══════ STOP LOSS / TAKE PROFIT ══════"
input int      TakeProfit_Pontos      = 300;           // Take Profit (pontos)
input int      StopLoss_Pontos        = 300;           // Stop Loss (pontos)

input group "══════ GESTÃO ══════"
input double   LoteFixo               = 0.01;          // Lote Fixo
input long     MagicNumber            = 99999;         // Número Mágico

//╔══════════════════════════════════════════════════════════════════╗
//║          PARÂMETROS DO INDICADOR 1: MA CROSS                     ║
//╚══════════════════════════════════════════════════════════════════╝
input group "══════ 1. MA CROSS - Cruzamento de Médias ══════"
input int      MA_Fast_Period         = 20;            // EMA Rápida (período)
input int      MA_Slow_Period         = 50;            // EMA Lenta (período)
input ENUM_MA_METHOD MA_Method        = MODE_EMA;      // Método da Média

//╔══════════════════════════════════════════════════════════════════╗
//║          PARÂMETROS DO INDICADOR 2: RSI                          ║
//╚══════════════════════════════════════════════════════════════════╝
input group "══════ 2. RSI - Índice de Força Relativa ══════"
input int      RSI_Period             = 14;            // Período
input int      RSI_Sobrevendido       = 30;            // Nível Sobrevendido (COMPRA)
input int      RSI_Sobrecomprado      = 70;            // Nível Sobrecomprado (VENDA)

//╔══════════════════════════════════════════════════════════════════╗
//║          PARÂMETROS DO INDICADOR 3: BOLLINGER                    ║
//╚══════════════════════════════════════════════════════════════════╝
input group "══════ 3. BOLLINGER BANDS ══════"
input int      BB_Period              = 20;            // Período
input double   BB_Desvio              = 2.0;           // Desvio Padrão

//╔══════════════════════════════════════════════════════════════════╗
//║          PARÂMETROS DO INDICADOR 4: SUPERTREND                   ║
//╚══════════════════════════════════════════════════════════════════╝
input group "══════ 4. SUPERTREND ══════"
input int      ST_ATR_Period          = 10;            // Período ATR
input double   ST_Multiplicador       = 3.0;           // Multiplicador

//╔══════════════════════════════════════════════════════════════════╗
//║          PARÂMETROS DO INDICADOR 5: AMA/KAMA                     ║
//╚══════════════════════════════════════════════════════════════════╝
input group "══════ 5. AMA/KAMA - Média Adaptativa ══════"
input int      AMA_ER_Period          = 10;            // Período ER
input int      AMA_Fast               = 2;             // Constante Rápida
input int      AMA_Slow               = 30;            // Constante Lenta

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
int hEMAfast = INVALID_HANDLE;
int hEMAslow = INVALID_HANDLE;
int hRSI = INVALID_HANDLE;
int hBB = INVALID_HANDLE;
int hATR = INVALID_HANDLE;

// Variáveis de estado
int g_sinalAtual = 0;       // +1 = COMPRA, -1 = VENDA, 0 = NEUTRO
int g_sinalAnterior = 0;
datetime g_lastBarTime = 0;

//+------------------------------------------------------------------+
//|                        OnInit                                     |
//+------------------------------------------------------------------+
int OnInit() {
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(20);

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
   if(hEMAfast != INVALID_HANDLE) IndicatorRelease(hEMAfast);
   if(hEMAslow != INVALID_HANDLE) IndicatorRelease(hEMAslow);
   if(hRSI != INVALID_HANDLE) IndicatorRelease(hRSI);
   if(hBB != INVALID_HANDLE) IndicatorRelease(hBB);
   if(hATR != INVALID_HANDLE) IndicatorRelease(hATR);

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
      case OPT_MA_CROSS:
         hEMAfast = iMA(InpSymbol, InpTF, MA_Fast_Period, 0, MA_Method, PRICE_CLOSE);
         hEMAslow = iMA(InpSymbol, InpTF, MA_Slow_Period, 0, MA_Method, PRICE_CLOSE);
         return (hEMAfast != INVALID_HANDLE && hEMAslow != INVALID_HANDLE);

      case OPT_RSI:
         hRSI = iRSI(InpSymbol, InpTF, RSI_Period, PRICE_CLOSE);
         return (hRSI != INVALID_HANDLE);

      case OPT_BOLLINGER:
         hBB = iBands(InpSymbol, InpTF, BB_Period, 0, BB_Desvio, PRICE_CLOSE);
         return (hBB != INVALID_HANDLE);

      case OPT_SUPERTREND:
         hATR = iATR(InpSymbol, InpTF, ST_ATR_Period);
         return (hATR != INVALID_HANDLE);

      case OPT_AMA_KAMA:
         // KAMA é calculado manualmente
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
      case OPT_MA_CROSS:    return SinalMACross();
      case OPT_RSI:         return SinalRSI();
      case OPT_BOLLINGER:   return SinalBollinger();
      case OPT_SUPERTREND:  return SinalSupertrend();
      case OPT_AMA_KAMA:    return SinalAMAKAMA();
      case OPT_HEIKIN_ASHI: return SinalHeikinAshi();
      case OPT_VWAP:        return SinalVWAP();
      case OPT_MOMENTUM:    return SinalMomentum();
      case OPT_QQE:         return SinalQQE();
   }
   return 0;
}

//+------------------------------------------------------------------+
//|              1. SINAL MA CROSS                                    |
//+------------------------------------------------------------------+
int SinalMACross() {
   double emaFast[], emaSlow[];
   ArraySetAsSeries(emaFast, true);
   ArraySetAsSeries(emaSlow, true);

   if(CopyBuffer(hEMAfast, 0, 0, 3, emaFast) < 3) return 0;
   if(CopyBuffer(hEMAslow, 0, 0, 3, emaSlow) < 3) return 0;

   double close = iClose(InpSymbol, InpTF, 1);

   // EMA rápida acima da lenta e preço acima da lenta = COMPRA
   if(emaFast[1] > emaSlow[1] && close > emaSlow[1]) return +1;
   // EMA rápida abaixo da lenta e preço abaixo da lenta = VENDA
   if(emaFast[1] < emaSlow[1] && close < emaSlow[1]) return -1;

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
//|              3. SINAL BOLLINGER BANDS                             |
//+------------------------------------------------------------------+
int SinalBollinger() {
   double upper[], middle[], lower[];
   ArraySetAsSeries(upper, true);
   ArraySetAsSeries(middle, true);
   ArraySetAsSeries(lower, true);

   if(CopyBuffer(hBB, 0, 0, 3, middle) < 3) return 0;
   if(CopyBuffer(hBB, 1, 0, 3, upper) < 3) return 0;
   if(CopyBuffer(hBB, 2, 0, 3, lower) < 3) return 0;

   double close = iClose(InpSymbol, InpTF, 1);

   // Preço abaixo da banda inferior = COMPRA
   if(close < lower[1]) return +1;
   // Preço acima da banda superior = VENDA
   if(close > upper[1]) return -1;

   return 0;
}

//+------------------------------------------------------------------+
//|              4. SINAL SUPERTREND                                  |
//+------------------------------------------------------------------+
int SinalSupertrend() {
   double atr[];
   ArraySetAsSeries(atr, true);

   if(CopyBuffer(hATR, 0, 0, 10, atr) < 10) return 0;

   double high[], low[], close[];
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);

   if(CopyHigh(InpSymbol, InpTF, 0, 10, high) < 10) return 0;
   if(CopyLow(InpSymbol, InpTF, 0, 10, low) < 10) return 0;
   if(CopyClose(InpSymbol, InpTF, 0, 10, close) < 10) return 0;

   // Cálculo simplificado do SuperTrend
   double hl2 = (high[1] + low[1]) / 2.0;
   double upperBand = hl2 + ST_Multiplicador * atr[1];
   double lowerBand = hl2 - ST_Multiplicador * atr[1];

   // Tendência de alta: preço acima da banda inferior
   if(close[1] > lowerBand && close[2] > lowerBand) return +1;
   // Tendência de baixa: preço abaixo da banda superior
   if(close[1] < upperBand && close[2] < upperBand) return -1;

   return 0;
}

//+------------------------------------------------------------------+
//|              5. SINAL AMA/KAMA                                    |
//+------------------------------------------------------------------+
int SinalAMAKAMA() {
   double close[];
   ArraySetAsSeries(close, true);

   if(CopyClose(InpSymbol, InpTF, 0, AMA_ER_Period + AMA_Slow + 5, close) < AMA_ER_Period + AMA_Slow + 5) return 0;

   int n = ArraySize(close);
   double kama = CalcularKAMA(close, n, AMA_ER_Period, AMA_Fast, AMA_Slow, 1);
   double kama_prev = CalcularKAMA(close, n, AMA_ER_Period, AMA_Fast, AMA_Slow, 2);

   double slope = kama - kama_prev;

   // KAMA subindo e preço acima = COMPRA
   if(slope > 0 && close[1] > kama) return +1;
   // KAMA descendo e preço abaixo = VENDA
   if(slope < 0 && close[1] < kama) return -1;

   return 0;
}

double CalcularKAMA(double &close[], int n, int erPeriod, int fast, int slow, int shift) {
   if(n < erPeriod + slow + shift) return close[shift];

   // Efficiency Ratio
   double change = MathAbs(close[shift] - close[shift + erPeriod]);
   double volatility = 0;
   for(int i = shift; i < shift + erPeriod; i++) {
      volatility += MathAbs(close[i] - close[i + 1]);
   }
   double er = (volatility > 0) ? change / volatility : 0;

   // Smoothing Constant
   double fastSC = 2.0 / (fast + 1);
   double slowSC = 2.0 / (slow + 1);
   double sc = MathPow(er * (fastSC - slowSC) + slowSC, 2);

   // KAMA
   static double kama = 0;
   if(kama == 0) kama = close[shift + erPeriod];
   kama = kama + sc * (close[shift] - kama);

   return kama;
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
      case OPT_MA_CROSS:    return "MA Cross";
      case OPT_RSI:         return "RSI";
      case OPT_BOLLINGER:   return "Bollinger";
      case OPT_SUPERTREND:  return "SuperTrend";
      case OPT_AMA_KAMA:    return "AMA/KAMA";
      case OPT_HEIKIN_ASHI: return "Heikin Ashi";
      case OPT_VWAP:        return "VWAP";
      case OPT_MOMENTUM:    return "Momentum";
      case OPT_QQE:         return "QQE";
   }
   return "Desconhecido";
}
//+------------------------------------------------------------------+
