//+------------------------------------------------------------------+
//|                                                      Basket.mqh  |
//|   MAAbot v2.3.1 - Gestão de Cestas e Posições                    |
//|                                     Autor: Eliabe N Oliveira     |
//+------------------------------------------------------------------+
#ifndef __MAABOT_BASKET_MQH__
#define __MAABOT_BASKET_MQH__

#include <Trade/Trade.mqh>
#include "Inputs.mqh"
#include "Globals.mqh"
#include "Utils.mqh"

//-------------------------- REFERÊNCIA AO TRADE ----------------------------//
// O objeto trade é declarado no arquivo principal e passado por referência
// quando necessário, ou declaramos aqui como extern se preferir

//-------------------------- CESTAS / POSIÇÕES ------------------------------//
void BasketStats(int dir, BasketInfo &B) { 
   B.avg = 0.0; B.vol = 0.0; B.cnt = 0; B.profit = 0.0; 
   
   int total = PositionsTotal();
   for(int i = 0; i < total; i++) { 
      ulong tk = PositionGetTicket(i); 
      if(!PositionSelectByTicket(tk)) continue;
      string sym = PositionGetString(POSITION_SYMBOL); 
      if(sym != InpSymbol) continue; 
      long mg = (long)PositionGetInteger(POSITION_MAGIC); 
      if(mg != Magic) continue;
      long tp = (long)PositionGetInteger(POSITION_TYPE); 
      if((dir > 0 && tp != POSITION_TYPE_BUY) || (dir < 0 && tp != POSITION_TYPE_SELL)) continue;
      
      double v = PositionGetDouble(POSITION_VOLUME);
      double p = PositionGetDouble(POSITION_PRICE_OPEN);
      double pr = PositionGetDouble(POSITION_PROFIT);
      
      B.avg = (B.vol > 0.0) ? ((B.avg * B.vol + p * v) / (B.vol + v)) : p; 
      B.vol += v; B.cnt++; B.profit += pr; 
   } 
}

bool HasBasket(int dir) { BasketInfo b; BasketStats(dir, b); return (b.cnt > 0); }

void CloseBasket(int dir, CTrade &trade) { 
   int total = PositionsTotal();
   for(int i = total-1; i >= 0; i--) { 
      ulong tk = PositionGetTicket(i); 
      if(!PositionSelectByTicket(tk)) continue;
      string sym = PositionGetString(POSITION_SYMBOL); 
      if(sym != InpSymbol) continue; 
      long mg = (long)PositionGetInteger(POSITION_MAGIC); 
      if(mg != Magic) continue;
      long tp = (long)PositionGetInteger(POSITION_TYPE); 
      if((dir > 0 && tp != POSITION_TYPE_BUY) || (dir < 0 && tp != POSITION_TYPE_SELL)) continue; 
      trade.PositionClose(tk); 
   } 
}

void CloseAllOur(CTrade &trade) { 
   int total = PositionsTotal(); 
   for(int i = total-1; i >= 0; i--) { 
      ulong tk = PositionGetTicket(i); 
      if(!PositionSelectByTicket(tk)) continue;
      string sym = PositionGetString(POSITION_SYMBOL); 
      if(sym != InpSymbol) continue; 
      long mg = (long)PositionGetInteger(POSITION_MAGIC); 
      if(mg != Magic) continue; 
      trade.PositionClose(tk); 
   } 
}

double NetOpenProfit() { 
   double s = 0.0; 
   int total = PositionsTotal(); 
   for(int i = 0; i < total; i++) { 
      ulong tk = PositionGetTicket(i); 
      if(!PositionSelectByTicket(tk)) continue;
      string sym = PositionGetString(POSITION_SYMBOL); 
      if(sym != InpSymbol) continue; 
      long mg = (long)PositionGetInteger(POSITION_MAGIC); 
      if(mg != Magic) continue; 
      s += PositionGetDouble(POSITION_PROFIT); 
   } 
   return s; 
}

//-------------------------- DD GUARD PARA CESTAS ----------------------------//
bool DD_AllowsNewEntries(CTrade &trade) { 
   double dd = CurrentDDPercent(); 
   g_currentDD = dd;
   
   if(dd >= MaxEquityDDPercent) {
      if(DD_CloseAllOnBreach) { 
         int total = PositionsTotal(); 
         for(int i = total-1; i >= 0; i--) { 
            ulong tk = PositionGetTicket(i);
            if(!PositionSelectByTicket(tk)) continue; 
            string sym = PositionGetString(POSITION_SYMBOL); 
            if(sym != InpSymbol) continue;
            long mg = (long)PositionGetInteger(POSITION_MAGIC); 
            if(mg != Magic) continue; 
            trade.PositionClose(tk); 
         } 
         gridBuy.active = false; gridSell.active = false; 
      }
      ddPausedUntil = TimeCurrent() + DD_CooldownMinutes * 60; 
      g_statusMsg = "DD maximo atingido";
      return false; 
   }
   
   if(TimeCurrent() < ddPausedUntil) { g_statusMsg = "Em cooldown DD"; return false; }
   return true; 
}

#endif // __MAABOT_BASKET_MQH__
//+------------------------------------------------------------------+
