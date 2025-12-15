//+------------------------------------------------------------------+
//|                                                     Globals.mqh  |
//|   MAAbot v2.3.1 - Variáveis Globais                              |
//|                                     Autor: Eliabe N Oliveira     |
//+------------------------------------------------------------------+
#ifndef __MAABOT_GLOBALS_MQH__
#define __MAABOT_GLOBALS_MQH__

#include "Structs.mqh"
#include <Trade/Trade.mqh>

//-------------------------- OBJETO TRADE GLOBAL (declarado no .mq5 principal) --//
extern CTrade trade;

//-------------------------- HANDLES DE INDICADORES -----------------------------//
int  hEMAfast=INVALID_HANDLE, hEMAslow=INVALID_HANDLE, hRSI=INVALID_HANDLE, hBB=INVALID_HANDLE, hATR=INVALID_HANDLE;
int  hATR_ST_INP=INVALID_HANDLE, hATR_ST_TF1=INVALID_HANDLE, hATR_ST_TF2=INVALID_HANDLE;
int  hQQE_RSI=INVALID_HANDLE;
int  hAnchorEMAfast=INVALID_HANDLE, hAnchorEMAslow=INVALID_HANDLE;
int  hTF1_EMAf=INVALID_HANDLE, hTF1_EMAs=INVALID_HANDLE, hTF2_EMAf=INVALID_HANDLE, hTF2_EMAs=INVALID_HANDLE;
int  hADX_TF1=INVALID_HANDLE, hADX_TF2=INVALID_HANDLE, hEMAPull=INVALID_HANDLE;

//-------------------------- CONTROLE DE TEMPO -----------------------------//
datetime lastBarTime=0, lastBuyTime=0, lastSellTime=0;

//-------------------------- ESTADO DO GRID -----------------------------//
static GridState gridBuy={false,0,0.0,0.0,0.0}, gridSell={false,0,0.0,0.0,0.0};

//-------------------------- DD GUARD -----------------------------//
static double    eqPeak=0.0; 
static datetime  ddPausedUntil=0;

//-------------------------- TENDÊNCIA -----------------------------//
static int       g_trendDir=0;
static bool      g_trending=false;
static double    g_trendScore=0.0;

//-------------------------- FILTRO DE FALHA -----------------------------//
static datetime  g_buyPenaltyUntil=0;
static datetime  g_sellPenaltyUntil=0;
static ulong     g_lastCheckedDeal=0;

//-------------------------- DETECTOR DE NOTÍCIAS -----------------------------//
static bool      g_isNewsBehavior = false;

//-------------------------- VARIÁVEIS PARA O PAINEL -----------------------------//
static double    g_probLong = 0.0;
static double    g_probShort = 0.0;
static int       g_signalsAgreeL = 0;
static int       g_signalsAgreeS = 0;
static string    g_lastAction = "Aguardando...";
static datetime  g_lastActionTime = 0;
static double    g_currentATR = 0.0;
static int       g_currentSpread = 0;
static double    g_currentVWAP = 0.0;
static double    g_dailyPL = 0.0;
static double    g_currentDD = 0.0;
static int       g_todayTrades = 0;
static string    g_statusMsg = "";

//-------------------------- DEBUG - RAZÕES DE BLOQUEIO -----------------------------//
static string    g_blockReasonBuy = "";
static string    g_blockReasonSell = "";
static double    g_thrL = 0.0;
static double    g_thrS = 0.0;

//-------------------------- VALORES DETALHADOS DAS ESTRATÉGIAS -----------------------------//
static double    g_rsiValue = 50.0;
static double    g_bbUpper = 0.0, g_bbMiddle = 0.0, g_bbLower = 0.0;
static double    g_emaFastVal = 0.0, g_emaSlowVal = 0.0;
static double    g_kamaValue = 0.0, g_kamaSlope = 0.0;
static double    g_rocValue = 0.0;
static double    g_adxValue = 0.0;

//-------------------------- PREFIXO DO PAINEL -----------------------------//
#define PANEL_PREFIX "MAABot_Panel_"

#endif // __MAABOT_GLOBALS_MQH__
//+------------------------------------------------------------------+
