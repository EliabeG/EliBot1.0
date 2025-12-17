//+------------------------------------------------------------------+
//|                                                       Panel.mqh  |
//|   MAAbot v2.3.1 - Painel Visual                                  |
//|                                     Autor: Eliabe N Oliveira     |
//+------------------------------------------------------------------+
#ifndef __MAABOT_PANEL_MQH__
#define __MAABOT_PANEL_MQH__

#include "Inputs.mqh"
#include "Globals.mqh"
#include "Utils.mqh"
#include "Basket.mqh"
#include "Grid.mqh"

//+------------------------------------------------------------------+
//|          PAINEL VISUAL CORRIGIDO - SEM SOBREPOSIÇÕES            |
//+------------------------------------------------------------------+

void DeletePanelObjects() { ObjectsDeleteAll(0, PANEL_PREFIX); }

void CreatePanelLabel(string name, int x, int y, string text, color clr, int fontSize = 0) {
   string objName = PANEL_PREFIX + name;
   if(ObjectFind(0, objName) < 0) ObjectCreate(0, objName, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetString(0, objName, OBJPROP_TEXT, text);
   ObjectSetString(0, objName, OBJPROP_FONT, PanelFontName);
   ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, (fontSize > 0) ? fontSize : PanelFontSize);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, objName, OBJPROP_HIDDEN, true);
}

void CreatePanelRectangle(string name, int x, int y, int width, int height, color bgColor) {
   string objName = PANEL_PREFIX + name;
   if(ObjectFind(0, objName) < 0) ObjectCreate(0, objName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, objName, OBJPROP_XSIZE, width);
   ObjectSetInteger(0, objName, OBJPROP_YSIZE, height);
   ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, objName, OBJPROP_BGCOLOR, bgColor);
   ObjectSetInteger(0, objName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, objName, OBJPROP_BORDER_COLOR, C'60,60,80');
   ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, objName, OBJPROP_BACK, false);
   ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, objName, OBJPROP_HIDDEN, true);
}

void CreateProgressBar(string name, int x, int y, int width, int height, double percent, color barColor, color bgColor) {
   CreatePanelRectangle(name + "_bg", x, y, width, height, bgColor);
   int barWidth = (int)(width * MathMin(1.0, MathMax(0.0, percent)));
   if(barWidth > 0) CreatePanelRectangle(name + "_bar", x, y, barWidth, height, barColor);
}

string TrendToString(int dir) { if(dir > 0) return "ALTA"; if(dir < 0) return "BAIXA"; return "NEUTRO"; }
color TrendToColor(int dir) { if(dir > 0) return PanelBuyColor; if(dir < 0) return PanelSellColor; return PanelNeutralColor; }
string SignalToIcon(int sig) { if(sig > 0) return "^"; if(sig < 0) return "v"; return "-"; }
string SignalToText(int sig) { if(sig > 0) return "BUY"; if(sig < 0) return "SELL"; return "---"; }
color SignalToColor(int sig) { if(sig > 0) return PanelBuyColor; if(sig < 0) return PanelSellColor; return PanelNeutralColor; }

void UpdatePanel(const Signals &S) {
   if(!ShowPanel) return;
   
   int x = PanelX;
   int y = PanelY;
   int lineH = PanelFontSize + 6;
   int row = 0;
   int digits = (int)SymbolInfoInteger(InpSymbol, SYMBOL_DIGITS);
   
   // Colunas com espaçamento adequado
   int col1 = x + 8;
   int col2 = x + 130;
   int col3 = x + 290;
   int col4 = x + 400;
   
   // ============ FUNDO PRINCIPAL ============
   int totalHeight = lineH * 46 + 30;
   CreatePanelRectangle("BG_Main", x, y, PanelWidth, totalHeight, PanelBgColor);
   
   // ============ CABEÇALHO ============
   CreatePanelRectangle("Header_BG", x, y, PanelWidth, lineH + 8, C'30,30,50');
   CreatePanelLabel("Header", x + 150, y + 4, "MAABot v2.3.1 - PANEL", PanelHeaderColor, PanelFontSize + 1);
   row += 2;
   
   // ============ SEÇÃO: MERCADO ============
   int secY = y + lineH * row;
   CreatePanelRectangle("Sec1_BG", x + 3, secY, PanelWidth - 6, lineH * 4 + 4, PanelBgColor2);
   CreatePanelLabel("Sec1_Title", col1, secY + 2, "[ MERCADO ]", clrGold);
   row++;
   
   CreatePanelLabel("SymbolLbl", col1, y + lineH * row, "Simbolo:", PanelTextColor);
   CreatePanelLabel("SymbolVal", col2, y + lineH * row, InpSymbol + " @ " + EnumToString(InpTF), clrCyan);
   row++;
   
   CreatePanelLabel("PriceLbl", col1, y + lineH * row, "Preco:", PanelTextColor);
   CreatePanelLabel("PriceVal", col2, y + lineH * row, "Bid: " + DoubleToString(Bid(), digits), clrWhite);
   CreatePanelLabel("AskLbl", col3, y + lineH * row, "Ask: " + DoubleToString(Ask(), digits), clrWhite);
   row++;
   
   CreatePanelLabel("SpreadLbl", col1, y + lineH * row, "Spread:", PanelTextColor);
   color spreadClr = (g_currentSpread <= MaxSpreadPoints/2) ? PanelBuyColor : (g_currentSpread <= MaxSpreadPoints) ? clrYellow : PanelSellColor;
   CreatePanelLabel("SpreadVal", col2, y + lineH * row, IntegerToString(g_currentSpread) + " pts", spreadClr);
   CreatePanelLabel("ATRLbl", col3, y + lineH * row, "ATR: " + DoubleToString(g_currentATR, digits), PanelAccentColor);
   row++;
   
   row++; // Espaço
   
   // ============ SEÇÃO: TENDÊNCIA MTF ============
   secY = y + lineH * row;
   CreatePanelRectangle("Sec2_BG", x + 3, secY, PanelWidth - 6, lineH * 3 + 4, PanelBgColor);
   CreatePanelLabel("Sec2_Title", col1, secY + 2, "[ TENDENCIA MTF ]", clrGold);
   row++;
   
   CreatePanelLabel("TrendDirLbl", col1, y + lineH * row, "Direcao:", PanelTextColor);
   CreatePanelLabel("TrendDirVal", col2, y + lineH * row, TrendToString(g_trendDir), TrendToColor(g_trendDir));
   CreatePanelLabel("TrendScoreLbl", col3, y + lineH * row, "Score: " + DoubleToString(g_trendScore, 2), C'180,180,180');
   row++;
   
   CreatePanelLabel("TrendingLbl", col1, y + lineH * row, "Trending:", PanelTextColor);
   CreatePanelLabel("TrendingVal", col2, y + lineH * row, g_trending ? "SIM" : "NAO", g_trending ? PanelBuyColor : clrOrange);
   CreatePanelLabel("ADXLbl", col3, y + lineH * row, "ADX: " + DoubleToString(g_adxValue, 1), (g_adxValue >= Trend_ADX_Thr) ? PanelBuyColor : clrOrange);
   row++;
   
   row++; // Espaço
   
   // ============ SEÇÃO: 9 ESTRATÉGIAS ============
   secY = y + lineH * row;
   CreatePanelRectangle("Sec3_BG", x + 3, secY, PanelWidth - 6, lineH * 11 + 4, PanelBgColor2);
   CreatePanelLabel("Sec3_Title", col1, secY + 2, "[ 9 ESTRATEGIAS ]", clrGold);
   row++;
   
   // Cabeçalho da tabela
   int tCol1 = col1;
   int tCol2 = x + 140;
   int tCol3 = x + 200;
   int tCol4 = x + 280;
   int tCol5 = x + 340;
   
   CreatePanelLabel("TH_Name", tCol1, y + lineH * row, "ESTRATEGIA", C'150,150,150');
   CreatePanelLabel("TH_Sig", tCol2, y + lineH * row, "SIG", C'150,150,150');
   CreatePanelLabel("TH_Status", tCol3, y + lineH * row, "STATUS", C'150,150,150');
   CreatePanelLabel("TH_Weight", tCol4, y + lineH * row, "PESO", C'150,150,150');
   CreatePanelLabel("TH_Detail", tCol5, y + lineH * row, "VALOR", C'150,150,150');
   row++;
   
   // 1. MA Cross
   CreatePanelLabel("S1_Name", tCol1, y + lineH * row, "1.MA Cross", PanelAccentColor);
   CreatePanelLabel("S1_Sig", tCol2, y + lineH * row, SignalToIcon(S.mac), SignalToColor(S.mac));
   CreatePanelLabel("S1_Status", tCol3, y + lineH * row, SignalToText(S.mac), SignalToColor(S.mac));
   CreatePanelLabel("S1_Weight", tCol4, y + lineH * row, DoubleToString(W_MAcross, 1), C'180,180,180');
   CreatePanelLabel("S1_Detail", tCol5, y + lineH * row, "EMA" + IntegerToString(EMA_Fast) + "/" + IntegerToString(EMA_Slow), C'150,150,150');
   row++;
   
   // 2. RSI
   CreatePanelLabel("S2_Name", tCol1, y + lineH * row, "2.RSI", PanelAccentColor);
   CreatePanelLabel("S2_Sig", tCol2, y + lineH * row, SignalToIcon(S.rsi), SignalToColor(S.rsi));
   CreatePanelLabel("S2_Status", tCol3, y + lineH * row, SignalToText(S.rsi), SignalToColor(S.rsi));
   CreatePanelLabel("S2_Weight", tCol4, y + lineH * row, DoubleToString(W_RSI, 1), C'180,180,180');
   CreatePanelLabel("S2_Detail", tCol5, y + lineH * row, "RSI=" + DoubleToString(g_rsiValue, 1), C'150,150,150');
   row++;
   
   // 3. Bollinger
   CreatePanelLabel("S3_Name", tCol1, y + lineH * row, "3.BBands", PanelAccentColor);
   CreatePanelLabel("S3_Sig", tCol2, y + lineH * row, SignalToIcon(S.bb), SignalToColor(S.bb));
   CreatePanelLabel("S3_Status", tCol3, y + lineH * row, SignalToText(S.bb), SignalToColor(S.bb));
   CreatePanelLabel("S3_Weight", tCol4, y + lineH * row, DoubleToString(W_BBands, 1), C'180,180,180');
   string bbPos = (S.c0 > g_bbUpper) ? "Acima" : (S.c0 < g_bbLower) ? "Abaixo" : "Dentro";
   CreatePanelLabel("S3_Detail", tCol5, y + lineH * row, bbPos, C'150,150,150');
   row++;
   
   // 4. SuperTrend
   CreatePanelLabel("S4_Name", tCol1, y + lineH * row, "4.SuperTrend", PanelAccentColor);
   CreatePanelLabel("S4_Sig", tCol2, y + lineH * row, SignalToIcon(S.st), SignalToColor(S.st));
   CreatePanelLabel("S4_Status", tCol3, y + lineH * row, SignalToText(S.st), SignalToColor(S.st));
   CreatePanelLabel("S4_Weight", tCol4, y + lineH * row, DoubleToString(W_Supertrend, 1), C'180,180,180');
   CreatePanelLabel("S4_Detail", tCol5, y + lineH * row, (S.st > 0) ? "Bull" : (S.st < 0) ? "Bear" : "---", C'150,150,150');
   row++;
   
   // 5. AMA/KAMA
   CreatePanelLabel("S5_Name", tCol1, y + lineH * row, "5.AMA/KAMA", PanelAccentColor);
   CreatePanelLabel("S5_Sig", tCol2, y + lineH * row, SignalToIcon(S.ama), SignalToColor(S.ama));
   CreatePanelLabel("S5_Status", tCol3, y + lineH * row, SignalToText(S.ama), SignalToColor(S.ama));
   CreatePanelLabel("S5_Weight", tCol4, y + lineH * row, DoubleToString(W_AMA, 1), C'180,180,180');
   string kamaDir = (g_kamaSlope > 0) ? "Up" : (g_kamaSlope < 0) ? "Down" : "Flat";
   CreatePanelLabel("S5_Detail", tCol5, y + lineH * row, kamaDir, C'150,150,150');
   row++;
   
   // 6. Heikin Ashi
   CreatePanelLabel("S6_Name", tCol1, y + lineH * row, "6.HeikinAshi", PanelAccentColor);
   CreatePanelLabel("S6_Sig", tCol2, y + lineH * row, SignalToIcon(S.ha), SignalToColor(S.ha));
   CreatePanelLabel("S6_Status", tCol3, y + lineH * row, SignalToText(S.ha), SignalToColor(S.ha));
   CreatePanelLabel("S6_Weight", tCol4, y + lineH * row, DoubleToString(W_Heikin, 1), C'180,180,180');
   CreatePanelLabel("S6_Detail", tCol5, y + lineH * row, (S.ha > 0) ? "Bull" : (S.ha < 0) ? "Bear" : "---", C'150,150,150');
   row++;
   
   // 7. VWAP
   CreatePanelLabel("S7_Name", tCol1, y + lineH * row, "7.VWAP", PanelAccentColor);
   CreatePanelLabel("S7_Sig", tCol2, y + lineH * row, SignalToIcon(S.vwap), SignalToColor(S.vwap));
   CreatePanelLabel("S7_Status", tCol3, y + lineH * row, SignalToText(S.vwap), SignalToColor(S.vwap));
   CreatePanelLabel("S7_Weight", tCol4, y + lineH * row, DoubleToString(W_VWAP, 1), C'180,180,180');
   CreatePanelLabel("S7_Detail", tCol5, y + lineH * row, (S.c0 > g_currentVWAP) ? "Acima" : "Abaixo", C'150,150,150');
   row++;
   
   // 8. Momentum
   CreatePanelLabel("S8_Name", tCol1, y + lineH * row, "8.Momentum", PanelAccentColor);
   CreatePanelLabel("S8_Sig", tCol2, y + lineH * row, SignalToIcon(S.mom), SignalToColor(S.mom));
   CreatePanelLabel("S8_Status", tCol3, y + lineH * row, SignalToText(S.mom), SignalToColor(S.mom));
   CreatePanelLabel("S8_Weight", tCol4, y + lineH * row, DoubleToString(W_Momentum, 1), C'180,180,180');
   CreatePanelLabel("S8_Detail", tCol5, y + lineH * row, DoubleToString(g_rocValue * 100, 2) + "%", C'150,150,150');
   row++;
   
   // 9. QQE
   CreatePanelLabel("S9_Name", tCol1, y + lineH * row, "9.QQE", PanelAccentColor);
   CreatePanelLabel("S9_Sig", tCol2, y + lineH * row, SignalToIcon(S.qqe), SignalToColor(S.qqe));
   CreatePanelLabel("S9_Status", tCol3, y + lineH * row, SignalToText(S.qqe), SignalToColor(S.qqe));
   CreatePanelLabel("S9_Weight", tCol4, y + lineH * row, DoubleToString(W_QQE, 1), C'180,180,180');
   CreatePanelLabel("S9_Detail", tCol5, y + lineH * row, UseQQEFilter ? ((S.qqe != 0) ? "Active" : "---") : "OFF", C'150,150,150');
   row++;
   
   row++; // Espaço
   
   // ============ SEÇÃO: PROBABILIDADES ============
   secY = y + lineH * row;
   CreatePanelRectangle("Sec4_BG", x + 3, secY, PanelWidth - 6, lineH * 6 + 4, PanelBgColor);
   CreatePanelLabel("Sec4_Title", col1, secY + 2, "[ PROBABILIDADES ]", clrGold);
   row++;
   
   // Prob LONG
   CreatePanelLabel("ProbLLbl", col1, y + lineH * row, "Prob LONG:", PanelTextColor);
   color probLClr = (g_probLong >= g_thrL) ? PanelBuyColor : PanelNeutralColor;
   CreatePanelLabel("ProbLVal", col2, y + lineH * row, DoubleToString(g_probLong * 100, 1) + "%", probLClr);
   CreateProgressBar("ProbL", col2 + 60, y + lineH * row + 2, 100, 8, g_probLong, PanelBuyColor, C'40,40,40');
   CreatePanelLabel("ThrLLbl", col4, y + lineH * row, "Thr:" + DoubleToString(g_thrL * 100, 0) + "%", C'150,150,150');
   row++;
   
   // Prob SHORT
   CreatePanelLabel("ProbSLbl", col1, y + lineH * row, "Prob SHORT:", PanelTextColor);
   color probSClr = (g_probShort >= g_thrS) ? PanelSellColor : PanelNeutralColor;
   CreatePanelLabel("ProbSVal", col2, y + lineH * row, DoubleToString(g_probShort * 100, 1) + "%", probSClr);
   CreateProgressBar("ProbS", col2 + 60, y + lineH * row + 2, 100, 8, g_probShort, PanelSellColor, C'40,40,40');
   CreatePanelLabel("ThrSLbl", col4, y + lineH * row, "Thr:" + DoubleToString(g_thrS * 100, 0) + "%", C'150,150,150');
   row++;
   
   // Sinais LONG
   CreatePanelLabel("AgreeLLbl", col1, y + lineH * row, "Sinais LONG:", PanelTextColor);
   color agreeLClr = (g_signalsAgreeL >= MinAgreeSignals) ? PanelBuyColor : PanelNeutralColor;
   CreatePanelLabel("AgreeLVal", col2, y + lineH * row, IntegerToString(g_signalsAgreeL) + "/9", agreeLClr);
   string barL = ""; for(int i = 0; i < 9; i++) barL += (i < g_signalsAgreeL) ? "|" : ".";
   CreatePanelLabel("AgreeLBar", col2 + 50, y + lineH * row, "[" + barL + "]", agreeLClr);
   CreatePanelLabel("MinLLbl", col4, y + lineH * row, "Min:" + IntegerToString(MinAgreeSignals), C'150,150,150');
   row++;
   
   // Sinais SHORT
   CreatePanelLabel("AgreeSLbl", col1, y + lineH * row, "Sinais SHORT:", PanelTextColor);
   color agreeSClr = (g_signalsAgreeS >= MinAgreeSignals) ? PanelSellColor : PanelNeutralColor;
   CreatePanelLabel("AgreeSVal", col2, y + lineH * row, IntegerToString(g_signalsAgreeS) + "/9", agreeSClr);
   string barS = ""; for(int i = 0; i < 9; i++) barS += (i < g_signalsAgreeS) ? "|" : ".";
   CreatePanelLabel("AgreeSBar", col2 + 50, y + lineH * row, "[" + barS + "]", agreeSClr);
   CreatePanelLabel("MinSLbl", col4, y + lineH * row, "Min:" + IntegerToString(MinAgreeSignals), C'150,150,150');
   row++;
   
   // Decisão
   bool canBuy = (g_signalsAgreeL >= MinAgreeSignals) && (g_probLong >= g_thrL) && AllowLong;
   bool canSell = (g_signalsAgreeS >= MinAgreeSignals) && (g_probShort >= g_thrS) && AllowShort;
   string decisionStr = ""; color decisionClr = PanelNeutralColor;
   if(canBuy && canSell) { decisionStr = "AMBOS OK"; decisionClr = clrYellow; }
   else if(canBuy) { decisionStr = "PODE COMPRAR"; decisionClr = PanelBuyColor; }
   else if(canSell) { decisionStr = "PODE VENDER"; decisionClr = PanelSellColor; }
   else { decisionStr = "SEM SINAL"; decisionClr = PanelNeutralColor; }
   CreatePanelLabel("DecisionLbl", col1, y + lineH * row, "DECISAO:", PanelTextColor);
   CreatePanelLabel("DecisionVal", col2, y + lineH * row, decisionStr, decisionClr);
   row++;
   
   row++; // Espaço
   
   // ============ SEÇÃO: BLOQUEIOS ============
   secY = y + lineH * row;
   CreatePanelRectangle("Sec5_BG", x + 3, secY, PanelWidth - 6, lineH * 3 + 4, PanelBgColor2);
   CreatePanelLabel("Sec5_Title", col1, secY + 2, "[ BLOQUEIOS ]", clrOrange);
   row++;
   
   string buyBlock = (g_blockReasonBuy == "") ? "OK" : g_blockReasonBuy;
   CreatePanelLabel("BlockBuyLbl", col1, y + lineH * row, "BUY:", PanelTextColor);
   CreatePanelLabel("BlockBuyVal", col2 - 30, y + lineH * row, buyBlock, (g_blockReasonBuy == "") ? PanelBuyColor : clrOrange);
   row++;
   
   string sellBlock = (g_blockReasonSell == "") ? "OK" : g_blockReasonSell;
   CreatePanelLabel("BlockSellLbl", col1, y + lineH * row, "SELL:", PanelTextColor);
   CreatePanelLabel("BlockSellVal", col2 - 30, y + lineH * row, sellBlock, (g_blockReasonSell == "") ? PanelSellColor : clrOrange);
   row++;
   
   row++; // Espaço
   
   // ============ SEÇÃO: CONTA ============
   secY = y + lineH * row;
   CreatePanelRectangle("Sec6_BG", x + 3, secY, PanelWidth - 6, lineH * 4 + 4, PanelBgColor);
   CreatePanelLabel("Sec6_Title", col1, secY + 2, "[ CONTA ]", clrGold);
   row++;
   
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double floatingPL = equity - balance;
   
   CreatePanelLabel("BalLbl", col1, y + lineH * row, "Saldo:", PanelTextColor);
   CreatePanelLabel("BalVal", col2, y + lineH * row, DoubleToString(balance, 2), clrWhite);
   CreatePanelLabel("EqLbl", col3, y + lineH * row, "Equity: " + DoubleToString(equity, 2), (equity >= balance) ? PanelBuyColor : PanelSellColor);
   row++;
   
   CreatePanelLabel("FloatLbl", col1, y + lineH * row, "P/L Flut:", PanelTextColor);
   string floatStr = (floatingPL >= 0 ? "+" : "") + DoubleToString(floatingPL, 2);
   CreatePanelLabel("FloatVal", col2, y + lineH * row, floatStr, (floatingPL >= 0) ? PanelBuyColor : PanelSellColor);
   string plDayStr = (g_dailyPL >= 0 ? "+" : "") + DoubleToString(g_dailyPL, 2);
   CreatePanelLabel("PLDayLbl", col3, y + lineH * row, "P/L Dia: " + plDayStr, (g_dailyPL >= 0) ? PanelBuyColor : PanelSellColor);
   row++;
   
   CreatePanelLabel("DDLbl", col1, y + lineH * row, "Drawdown:", PanelTextColor);
   color ddColor = (g_currentDD < RT_L1) ? PanelBuyColor : ((g_currentDD < RT_L2) ? clrOrange : PanelSellColor);
   CreatePanelLabel("DDVal", col2, y + lineH * row, DoubleToString(g_currentDD, 2) + "%", ddColor);
   CreatePanelLabel("TradesLbl", col3, y + lineH * row, "Trades: " + IntegerToString(g_todayTrades) + "/" + IntegerToString(MaxTradesPerDay), (g_todayTrades < MaxTradesPerDay) ? PanelBuyColor : PanelSellColor);
   row++;
   
   row++; // Espaço
   
   // ============ SEÇÃO: GRID ============
   BasketInfo buyBasket, sellBasket;
   BasketStats(+1, buyBasket); BasketStats(-1, sellBasket);
   
   secY = y + lineH * row;
   CreatePanelRectangle("Sec7_BG", x + 3, secY, PanelWidth - 6, lineH * 3 + 4, PanelBgColor2);
   CreatePanelLabel("Sec7_Title", col1, secY + 2, "[ GRID ]", clrGold);
   row++;
   
   CreatePanelLabel("GridBuyLbl", col1, y + lineH * row, "Grid BUY:", PanelTextColor);
   if(gridBuy.active) {
      string buyGridStr = StringFormat("Adds:%d/%d Vol:%.2f P/L:%+.2f", gridBuy.adds, AllowedAddsForDir(+1), buyBasket.vol, buyBasket.profit);
      CreatePanelLabel("GridBuyVal", col2, y + lineH * row, buyGridStr, PanelBuyColor);
   } else CreatePanelLabel("GridBuyVal", col2, y + lineH * row, "INATIVO", PanelNeutralColor);
   row++;
   
   CreatePanelLabel("GridSellLbl", col1, y + lineH * row, "Grid SELL:", PanelTextColor);
   if(gridSell.active) {
      string sellGridStr = StringFormat("Adds:%d/%d Vol:%.2f P/L:%+.2f", gridSell.adds, AllowedAddsForDir(-1), sellBasket.vol, sellBasket.profit);
      CreatePanelLabel("GridSellVal", col2, y + lineH * row, sellGridStr, PanelSellColor);
   } else CreatePanelLabel("GridSellVal", col2, y + lineH * row, "INATIVO", PanelNeutralColor);
   row++;
   
   row++; // Espaço
   
   // ============ SEÇÃO: STATUS ============
   secY = y + lineH * row;
   CreatePanelRectangle("Sec8_BG", x + 3, secY, PanelWidth - 6, lineH * 3 + 4, PanelBgColor);
   CreatePanelLabel("Sec8_Title", col1, secY + 2, "[ STATUS ]", clrGold);
   row++;
   
   bool isTradingHours = InTradingWindow(TimeCurrent());
   CreatePanelLabel("TradingLbl", col1, y + lineH * row, "Horario:", PanelTextColor);
   CreatePanelLabel("TradingVal", col2, y + lineH * row, isTradingHours ? "ATIVO" : "FORA", isTradingHours ? PanelBuyColor : clrOrange);
   CreatePanelLabel("TradingHours", col3, y + lineH * row, StringFormat("(%02d:00-%02d:00)", StartHour, EndHour), C'150,150,150');
   row++;
   
   string actionStr = g_lastAction;
   if(g_lastActionTime > 0) {
      int secsAgo = (int)(TimeCurrent() - g_lastActionTime);
      if(secsAgo < 60) actionStr += " (" + IntegerToString(secsAgo) + "s)";
      else if(secsAgo < 3600) actionStr += " (" + IntegerToString(secsAgo/60) + "m)";
      else actionStr += " (" + IntegerToString(secsAgo/3600) + "h)";
   }
   CreatePanelLabel("ActionLbl", col1, y + lineH * row, "Acao:", PanelTextColor);
   CreatePanelLabel("ActionVal", col2, y + lineH * row, actionStr, clrCyan);
   row++;
   
   ChartRedraw(0);
}

#endif // __MAABOT_PANEL_MQH__
//+------------------------------------------------------------------+
