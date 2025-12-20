//+------------------------------------------------------------------+
//|                                                     Globals.mqh  |
//|   MAAbot v2.3.1 - Variáveis Globais                              |
//|                                     Autor: Eliabe N Oliveira     |
//+------------------------------------------------------------------+
#ifndef __MAABOT_GLOBALS_MQH__
#define __MAABOT_GLOBALS_MQH__

#include "Structs.mqh"

//-------------------------- HANDLES DE INDICADORES -----------------------------//
int  hRSI=INVALID_HANDLE, hATR=INVALID_HANDLE;
int  hATR_AKTE=INVALID_HANDLE;           // ATR para AKTE
int  hEMA_IAE=INVALID_HANDLE;            // EMA para IAE
int  hQQE_RSI=INVALID_HANDLE;
int  hAnchorEMAfast=INVALID_HANDLE, hAnchorEMAslow=INVALID_HANDLE;
int  hTF1_EMAf=INVALID_HANDLE, hTF1_EMAs=INVALID_HANDLE, hTF2_EMAf=INVALID_HANDLE, hTF2_EMAs=INVALID_HANDLE;
int  hADX_TF1=INVALID_HANDLE, hADX_TF2=INVALID_HANDLE, hEMAPull=INVALID_HANDLE;

//-------------------------- VARIÁVEIS AKTE (Adaptive Kalman Trend Estimator) ---//
double g_akte_x_atual=0, g_akte_x_anterior=0;
double g_akte_P_atual=1.0, g_akte_K_atual=0, g_akte_K_anterior=0;
double g_akte_R_atual=0, g_akte_error_atual=0, g_akte_ATR_atual=0;
double g_akte_kalman_buffer[];
bool   g_akte_initialized=false;

//-------------------------- VARIÁVEIS PVP (Polynomial Velocity Predictor) ------//
double g_pvp_coef_a=0, g_pvp_coef_b=0, g_pvp_coef_c=0, g_pvp_coef_d=0;
double g_pvp_velocidade=0, g_pvp_aceleracao=0;
double g_pvp_prob_alta=0.5, g_pvp_sigma_err=0;

//-------------------------- VARIÁVEIS IAE (Integral Arc Efficiency) ------------//
double g_iae_deslocamento=0, g_iae_comprimento_arco=0;
double g_iae_eficiencia=0, g_iae_energia=0, g_iae_eficiencia_ant=0;

//-------------------------- VARIÁVEIS SCP (Spectral Cycle Phaser) --------------//
int    g_scp_ciclo_dominante=10;
double g_scp_power_dominante=0, g_scp_fase_atual=0;
double g_scp_senoide_atual=0, g_scp_senoide_anterior=0, g_scp_senoide_anterior2=0;
double g_scp_power_medio=0;
double g_scp_power_buffer[];

//-------------------------- VARIÁVEIS FHMI (Fractal Hurst Memory Index) --------//
double g_fhmi_hurst=0.5, g_fhmi_hurst_anterior=0.5;
double g_fhmi_RS=0, g_fhmi_R=0, g_fhmi_S=0;
double g_fhmi_momentum=0, g_fhmi_momentum_anterior=0;
double g_fhmi_retornos_buffer[];
bool   g_fhmi_initialized=false;

//-------------------------- CONSTANTE PI ---------------------------------------//
#ifndef M_PI
   #define M_PI 3.14159265358979323846
#endif

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
