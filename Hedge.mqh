//+------------------------------------------------------------------+
//|                                                       Hedge.mqh  |
//|   MAAbot v2.3.1 - Sistema de Hedge                               |
//|                                     Autor: Eliabe N Oliveira     |
//+------------------------------------------------------------------+
#ifndef __MAABOT_HEDGE_MQH__
#define __MAABOT_HEDGE_MQH__

#include "Inputs.mqh"
#include "Globals.mqh"
#include "Utils.mqh"
#include "Basket.mqh"
#include "Grid.mqh"

//-------------------------- HEDGE RECOVERY ---------------------------------//
void HedgeRecoveryCheck() { 
   if(!Hedge_Enable || !Hedge_CloseOnNetProfit) return;
   double target = 0.0; 
   if(Hedge_NetTP_Money > 0.0) target = Hedge_NetTP_Money; 
   else if(Hedge_NetTP_Percent > 0.0) target = AccountInfoDouble(ACCOUNT_EQUITY) * (Hedge_NetTP_Percent / 100.0);
   if(target <= 0.0) return; 
   double net = NetOpenProfit(); 
   if(net >= target) { 
      CloseAllOur(); GridReset(+1); GridReset(-1);
      g_lastAction = "Hedge TP"; g_lastActionTime = TimeCurrent();
   } 
}

bool AdverseTrigger(int dir) { 
   if(!Hedge_OpenOnAdverse) return false;
   double pt = Pt(); int needPts = Hedge_Adverse_Points; 
   if(Hedge_Adverse_UseATR) { 
      double atr = 0.0; GetBuf(hATR, 0, atr, 0); 
      if(atr > 0.0) { int v = (int)MathRound((atr * Hedge_Adverse_ATRMult) / pt); if(v > 0) needPts = v; } 
   }
   double price = (dir > 0) ? Bid() : Ask(); 
   if(dir > 0) { if(!gridBuy.active) return false; return (price <= gridBuy.basePrice - needPts * pt); }
   else { if(!gridSell.active) return false; return (price >= gridSell.basePrice + needPts * pt); } 
}

#endif // __MAABOT_HEDGE_MQH__
//+------------------------------------------------------------------+
