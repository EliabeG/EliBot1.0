//+------------------------------------------------------------------+
//|                                          DailyTargetManager.mqh  |
//|   MAAbot v2.6.0 - Sistema de Meta Diária (Porcentagem ao Dia)    |
//|                                     Autor: Eliabe N Oliveira     |
//+------------------------------------------------------------------+
//| FUNCIONALIDADES:                                                  |
//| - Meta diária em porcentagem com juros compostos                 |
//| - Monitoramento de saldo INDEPENDENTE a cada tick                |
//| - Fechamento AUTOMÁTICO ao atingir meta (garante 1% exato)       |
//| - Bloqueio TOTAL de operações após meta (só opera no dia seguinte)|
//| - Modo agressivo quando faltando tempo para bater meta           |
//| - Cálculo automático de lote baseado na meta                     |
//| - Gráfico de backtest: linha crescente 1% ao dia                 |
//| - Respeito total ao horário de operação definido                 |
//| - Estatísticas diárias persistentes                              |
//+------------------------------------------------------------------+
#ifndef __MAABOT_DAILYTARGETMANAGER_MQH__
#define __MAABOT_DAILYTARGETMANAGER_MQH__

#include <Trade/Trade.mqh>
#include "Enums.mqh"
#include "Inputs.mqh"
#include "Globals.mqh"
#include "Utils.mqh"

//===================== ESTRUTURA DE ESTADO DIÁRIO =====================//
struct DailyTargetState {
   datetime    dayStart;              // Início do dia de trading
   datetime    dayEnd;                // Fim do dia de trading
   double      startBalance;          // Saldo no início do dia
   double      targetAmount;          // Meta em valor monetário
   double      targetBalance;         // Saldo alvo (startBalance + targetAmount)
   double      currentPL;             // P/L atual do dia
   double      highestPL;             // Maior P/L atingido no dia
   double      lowestPL;              // Menor P/L do dia
   double      lockedProfit;          // Lucro travado (proteção)
   int         tradesOpened;          // Trades abertos hoje
   int         tradesClosed;          // Trades fechados hoje
   int         tradesWon;             // Trades vencedores
   int         tradesLost;            // Trades perdedores
   DailyStatus status;                // Status atual do dia
   AggressiveLevel currentAggLevel;   // Nível de agressividade atual
   bool        targetHit;             // Meta foi atingida?
   bool        targetExceeded;        // Meta foi ultrapassada?
   bool        aggressiveMode;        // Modo agressivo ativo?
   datetime    targetHitTime;         // Hora que atingiu a meta
   datetime    aggressiveStartTime;   // Hora que iniciou modo agressivo
   int         aggressiveTradesOpened;// Trades abertos no modo agressivo
   double      aggressivePL;          // P/L do modo agressivo
   // NOVOS CAMPOS - Operação Forçada
   bool        forceMode;             // Modo forçado ativo (obrigatório operar)
   datetime    lastTradeTime;         // Hora do último trade
   datetime    forceStartTime;        // Hora que iniciou modo forçado
   int         forceLevelReductions;  // Número de reduções aplicadas
};

// Estado global do dia
DailyTargetState g_dtState;

// Histórico de dias (para juros compostos)
struct DailyHistory {
   datetime    date;
   double      startBalance;
   double      endBalance;
   double      targetPercent;
   double      actualPercent;
   bool        targetHit;
   int         totalTrades;
};

DailyHistory g_dtHistory[];
int g_dtHistoryCount = 0;

// Variáveis globais para painel
double g_dt_progressPercent = 0.0;    // Progresso em % da meta
double g_dt_remainingAmount = 0.0;    // Valor restante para meta
int    g_dt_minutesRemaining = 0;     // Minutos restantes
string g_dt_statusText = "";          // Texto de status

// Variáveis para controle de bloqueio
bool   g_dt_tradingBlocked = false;   // Trading bloqueado após meta
datetime g_dt_lastTargetHitDay = 0;   // Dia que atingiu a meta

// Variáveis para operação forçada
bool   g_dt_forceMode = false;        // Modo forçado ativo
int    g_dt_minutesWithoutTrade = 0;  // Minutos sem trade hoje

//===================== INICIALIZAÇÃO =====================//
void InitDailyTargetManager() {
   if(DT_Mode == DTARGET_OFF) return;

   ZeroMemory(g_dtState);
   ArrayFree(g_dtHistory);
   g_dtHistoryCount = 0;

   // Inicializa o estado do dia
   ResetDailyState();

   // Carrega histórico se disponível
   LoadDailyHistory();

   Print("=== GERENCIADOR DE META DIÁRIA INICIADO ===");
   Print("Meta Diária: ", DoubleToString(DT_TargetPercent, 2), "%");
   Print("Saldo Base: ", DoubleToString(g_dtState.startBalance, 2));
   Print("Meta em $: ", DoubleToString(g_dtState.targetAmount, 2));
   Print("Saldo Alvo: ", DoubleToString(g_dtState.targetBalance, 2));
   Print("Modo: ", EnumToString(DT_Mode));
   Print("=====================================");
}

void DeinitDailyTargetManager() {
   if(DT_Mode == DTARGET_OFF) return;

   // Salva estatísticas do dia
   if(DT_SaveDailyStats) {
      SaveDailyStats();
   }

   // Salva histórico
   SaveDailyHistory();

   Print("=== GERENCIADOR DE META DIÁRIA FINALIZADO ===");
   PrintDailySummary();
}

//===================== RESET DIÁRIO =====================//
void ResetDailyState() {
   datetime now = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(now, dt);

   // Define início e fim do dia de trading
   dt.hour = DT_StartHour;
   dt.min = DT_StartMinute;
   dt.sec = 0;
   g_dtState.dayStart = StructToTime(dt);

   dt.hour = DT_EndHour;
   dt.min = DT_EndMinute;
   g_dtState.dayEnd = StructToTime(dt);

   // Calcula saldo base
   g_dtState.startBalance = CalculateBaseBalance();

   // Calcula meta
   g_dtState.targetAmount = g_dtState.startBalance * (DT_TargetPercent / 100.0);
   g_dtState.targetBalance = g_dtState.startBalance + g_dtState.targetAmount;

   // Reseta contadores
   g_dtState.currentPL = 0.0;
   g_dtState.highestPL = 0.0;
   g_dtState.lowestPL = 0.0;
   g_dtState.lockedProfit = 0.0;
   g_dtState.tradesOpened = 0;
   g_dtState.tradesClosed = 0;
   g_dtState.tradesWon = 0;
   g_dtState.tradesLost = 0;
   g_dtState.status = DAY_NOT_STARTED;
   g_dtState.currentAggLevel = AGG_LEVEL_1;
   g_dtState.targetHit = false;
   g_dtState.targetExceeded = false;
   g_dtState.aggressiveMode = false;
   g_dtState.targetHitTime = 0;
   g_dtState.aggressiveStartTime = 0;
   g_dtState.aggressiveTradesOpened = 0;
   g_dtState.aggressivePL = 0.0;
}

//===================== CÁLCULO DE SALDO BASE =====================//
double CalculateBaseBalance() {
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);

   switch(DT_BalanceBase) {
      case BALANCE_START_DAY:
         // Usa o saldo atual se for início do dia, senão mantém
         if(g_dtState.startBalance > 0) return g_dtState.startBalance;
         return balance;

      case BALANCE_START_WEEK:
         return GetWeekStartBalance();

      case BALANCE_START_MONTH:
         return GetMonthStartBalance();

      case BALANCE_CURRENT:
         return equity;

      case BALANCE_FIXED:
         return DT_FixedBalance;

      default:
         return balance;
   }
}

double GetWeekStartBalance() {
   // Busca o saldo do início da semana no histórico
   datetime now = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(now, dt);

   // Volta para segunda-feira
   int daysBack = dt.day_of_week - 1;
   if(daysBack < 0) daysBack = 6; // Se for domingo

   datetime weekStart = now - (daysBack * 86400);

   // Procura no histórico
   for(int i = g_dtHistoryCount - 1; i >= 0; i--) {
      if(g_dtHistory[i].date >= weekStart) {
         return g_dtHistory[i].startBalance;
      }
   }

   return AccountInfoDouble(ACCOUNT_BALANCE);
}

double GetMonthStartBalance() {
   // Busca o saldo do início do mês no histórico
   datetime now = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(now, dt);

   dt.day = 1;
   dt.hour = 0;
   dt.min = 0;
   dt.sec = 0;
   datetime monthStart = StructToTime(dt);

   // Procura no histórico
   for(int i = g_dtHistoryCount - 1; i >= 0; i--) {
      if(g_dtHistory[i].date >= monthStart) {
         return g_dtHistory[i].startBalance;
      }
   }

   return AccountInfoDouble(ACCOUNT_BALANCE);
}

//===================== JUROS COMPOSTOS =====================//
double CalculateCompoundBalance() {
   if(!DT_CompoundDaily) {
      return CalculateBaseBalance();
   }

   double baseBalance = DT_FixedBalance;
   if(DT_BalanceBase != BALANCE_FIXED) {
      baseBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   }

   // Se exigir meta batida para compor
   if(DT_CompoundOnTarget) {
      // Verifica dias anteriores
      int consecutiveTargets = 0;
      for(int i = g_dtHistoryCount - 1; i >= 0; i--) {
         if(g_dtHistory[i].targetHit) {
            consecutiveTargets++;
            baseBalance = g_dtHistory[i].endBalance;
         } else {
            break; // Para na primeira falha
         }
      }

      if(consecutiveTargets > 0) {
         Print("Juros Compostos: ", consecutiveTargets, " dias consecutivos. Base: ",
               DoubleToString(baseBalance, 2));
      }
   }

   return baseBalance;
}

//===================== VERIFICAÇÃO DE HORÁRIO =====================//
bool IsInDailyTradingWindow() {
   datetime now = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(now, dt);

   int currentMinutes = dt.hour * 60 + dt.min;
   int startMinutes = DT_StartHour * 60 + DT_StartMinute;
   int endMinutes = DT_EndHour * 60 + DT_EndMinute;

   // Verifica fim de semana
   if(dt.day_of_week == 0 || dt.day_of_week == 6) return false;

   return (currentMinutes >= startMinutes && currentMinutes < endMinutes);
}

bool IsInAggressiveWindow() {
   if(!DT_EnableAggressive) return false;

   datetime now = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(now, dt);

   int currentMinutes = dt.hour * 60 + dt.min;
   int endMinutes = DT_EndHour * 60 + DT_EndMinute;
   int aggressiveStart = endMinutes - DT_AggressiveMinutes;

   return (currentMinutes >= aggressiveStart && currentMinutes < endMinutes);
}

int GetMinutesRemaining() {
   datetime now = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(now, dt);

   int currentMinutes = dt.hour * 60 + dt.min;
   int endMinutes = DT_EndHour * 60 + DT_EndMinute;

   return MathMax(0, endMinutes - currentMinutes);
}

//===================== ATUALIZAÇÃO DE P/L =====================//
void UpdateDailyPL() {
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   g_dtState.currentPL = equity - g_dtState.startBalance;

   // Atualiza high/low
   if(g_dtState.currentPL > g_dtState.highestPL) {
      g_dtState.highestPL = g_dtState.currentPL;
   }
   if(g_dtState.currentPL < g_dtState.lowestPL) {
      g_dtState.lowestPL = g_dtState.currentPL;
   }

   // Atualiza progresso
   if(g_dtState.targetAmount > 0) {
      g_dt_progressPercent = (g_dtState.currentPL / g_dtState.targetAmount) * 100.0;
   }
   g_dt_remainingAmount = g_dtState.targetAmount - g_dtState.currentPL;
   g_dt_minutesRemaining = GetMinutesRemaining();

   // Verifica se atingiu meta
   CheckTargetStatus();
}

//===================== VERIFICAÇÃO DE META =====================//
void CheckTargetStatus() {
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);

   // Verifica se atingiu a meta
   if(!g_dtState.targetHit && equity >= g_dtState.targetBalance) {
      g_dtState.targetHit = true;
      g_dtState.targetHitTime = TimeCurrent();
      g_dtState.status = DAY_TARGET_HIT;

      if(DT_AlertOnTarget) {
         Alert("META DIÁRIA ATINGIDA! Lucro: $",
               DoubleToString(g_dtState.currentPL, 2),
               " (", DoubleToString(g_dt_progressPercent, 1), "%)");
      }

      Print("=== META DIÁRIA ATINGIDA ===");
      Print("Hora: ", TimeToString(TimeCurrent()));
      Print("Lucro: $", DoubleToString(g_dtState.currentPL, 2));
      Print("============================");

      // Aplica proteção de lucro se configurado
      ApplyProfitProtection();
   }

   // Verifica se ultrapassou a meta
   if(g_dtState.targetHit && equity > g_dtState.targetBalance * 1.1) {
      g_dtState.targetExceeded = true;
      g_dtState.status = DAY_TARGET_EXCEEDED;
   }

   // Verifica perda máxima
   double maxLoss = g_dtState.startBalance * (DT_MaxDailyLoss / 100.0);
   if(g_dtState.currentPL <= -maxLoss) {
      g_dtState.status = DAY_STOPPED_LOSS;

      if(DT_StopOnMaxLoss && !DT_RecoverOnAggressive) {
         Print("=== PERDA MÁXIMA DIÁRIA ATINGIDA ===");
         Print("Perda: $", DoubleToString(MathAbs(g_dtState.currentPL), 2));
      }
   }
}

//===================== MONITORAMENTO INDEPENDENTE A CADA TICK =====================//
// PONTO 1: Esta função monitora o saldo INDEPENDENTEMENTE da estratégia de stops
// Deve ser chamada a cada tick no OnTick() principal
//==================================================================================//
bool MonitorBalanceOnTick(CTrade &trade) {
   if(DT_Mode == DTARGET_OFF) return false;

   // Verifica se é novo dia para resetar bloqueio
   CheckAndResetDailyBlock();

   // Se já atingiu a meta e trading está bloqueado, não faz nada
   if(g_dt_tradingBlocked && DT_BlockAfterTarget) {
      return true; // Retorna true = bloqueado
   }

   // Verifica se está dentro do horário de operação (PONTO 4)
   if(DT_OnlyInTimeWindow && !IsInDailyTradingWindow()) {
      return false; // Fora do horário, não monitora meta
   }

   // Obtém equity atual
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);

   // Calcula meta com tolerância (permite fechar um pouco antes para garantir)
   double targetWithTolerance = g_dtState.startBalance +
      (g_dtState.targetAmount * (1.0 - DT_TargetTolerance));

   // PONTO 1: Verifica se atingiu a meta
   if(!g_dtState.targetHit && equity >= targetWithTolerance) {
      // META ATINGIDA!
      Print("=====================================================");
      Print("  >>> META DIÁRIA ATINGIDA! FECHANDO OPERAÇÕES <<<   ");
      Print("=====================================================");
      Print("Saldo Inicial: $", DoubleToString(g_dtState.startBalance, 2));
      Print("Equity Atual: $", DoubleToString(equity, 2));
      Print("Meta: $", DoubleToString(g_dtState.targetBalance, 2));
      Print("Lucro: $", DoubleToString(equity - g_dtState.startBalance, 2));
      Print("Percentual: ", DoubleToString(((equity - g_dtState.startBalance) / g_dtState.startBalance) * 100, 2), "%");
      Print("=====================================================");

      // Marca meta como atingida
      g_dtState.targetHit = true;
      g_dtState.targetHitTime = TimeCurrent();
      g_dtState.status = DAY_TARGET_HIT;
      g_dtState.currentPL = equity - g_dtState.startBalance;

      // Registra o dia que atingiu
      datetime now = TimeCurrent();
      MqlDateTime dt;
      TimeToStruct(now, dt);
      dt.hour = 0; dt.min = 0; dt.sec = 0;
      g_dt_lastTargetHitDay = StructToTime(dt);

      // PONTO 1: Fecha TODAS as operações automaticamente
      if(DT_CloseOnTarget) {
         CloseAllPositionsForTarget(trade);
      }

      // PONTO 2: Bloqueia novas operações
      if(DT_BlockAfterTarget) {
         g_dt_tradingBlocked = true;
         Print(">>> TRADING BLOQUEADO ATÉ O PRÓXIMO DIA <<<");
      }

      // Alerta
      if(DT_AlertOnTarget) {
         Alert("META DIÁRIA ATINGIDA! +",
               DoubleToString(DT_TargetPercent, 2), "% | Lucro: $",
               DoubleToString(g_dtState.currentPL, 2),
               " | OPERAÇÕES ENCERRADAS!");
      }

      // Salva no histórico
      SaveTodayToHistory();

      return true; // Meta atingida
   }

   return false;
}

//===================== VERIFICA E RESETA BLOQUEIO DIÁRIO =====================//
// PONTO 2: No início de cada novo dia, reseta o bloqueio para permitir operar
// CORRIGIDO: Agora também reseta TODO o estado do dia para novo trading
//=========================================================================//
void CheckAndResetDailyBlock() {
   datetime now = TimeCurrent();
   MqlDateTime dtNow, dtState;
   TimeToStruct(now, dtNow);
   TimeToStruct(g_dtState.dayStart, dtState);

   // Verifica se mudou o dia (comparando com dayStart do estado atual)
   bool isNewDay = (dtNow.day != dtState.day || dtNow.mon != dtState.mon || dtNow.year != dtState.year);

   // Se é um novo dia, SEMPRE reseta tudo (mesmo que não esteja bloqueado)
   if(isNewDay && g_dtState.dayStart > 0) {
      Print("=====================================================");
      Print("  >>> NOVO DIA DE TRADING DETECTADO <<<              ");
      Print("=====================================================");
      Print("Dia anterior: ", TimeToString(g_dtState.dayStart, TIME_DATE));
      Print("Novo dia: ", TimeToString(now, TIME_DATE));

      // Salva estatísticas do dia anterior (se teve trades)
      if(g_dtState.tradesOpened > 0 || g_dtState.targetHit) {
         SaveTodayToHistory();
      }

      // Remove bloqueio
      g_dt_tradingBlocked = false;
      g_dt_forceMode = false;

      // IMPORTANTE: Guarda o saldo final do dia anterior para juros compostos
      double previousEndBalance = AccountInfoDouble(ACCOUNT_BALANCE);

      // Reseta TODO o estado do dia
      ResetDailyState();

      // Aplica juros compostos se configurado
      if(DT_CompoundDaily) {
         // Usa o saldo final do dia anterior como base
         g_dtState.startBalance = previousEndBalance;
         g_dtState.targetAmount = g_dtState.startBalance * (DT_TargetPercent / 100.0);
         g_dtState.targetBalance = g_dtState.startBalance + g_dtState.targetAmount;

         Print(">>> JUROS COMPOSTOS APLICADOS <<<");
         Print("Nova Base: $", DoubleToString(g_dtState.startBalance, 2));
         Print("Nova Meta: $", DoubleToString(g_dtState.targetAmount, 2), " (",
               DoubleToString(DT_TargetPercent, 2), "%)");
         Print("Saldo Alvo: $", DoubleToString(g_dtState.targetBalance, 2));
      }

      Print(">>> TRADING LIBERADO PARA O NOVO DIA <<<");
      Print("=====================================================");
   }
}

//===================== FECHA TODAS AS POSIÇÕES (META ATINGIDA) =====================//
// PONTO 1: Fecha imediatamente todas as posições ao atingir a meta
//==================================================================================//
void CloseAllPositionsForTarget(CTrade &trade) {
   int total = PositionsTotal();
   int closed = 0;

   Print("Fechando ", total, " posições abertas...");

   for(int i = total - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket)) {
         if(PositionGetString(POSITION_SYMBOL) == InpSymbol &&
            PositionGetInteger(POSITION_MAGIC) == Magic) {

            double profit = PositionGetDouble(POSITION_PROFIT);
            string type = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? "COMPRA" : "VENDA";

            if(trade.PositionClose(ticket)) {
               closed++;
               Print("  Fechada: Ordem #", ticket, " | ", type, " | Lucro: $", DoubleToString(profit, 2));
            }
         }
      }
   }

   Print("=== ", closed, " POSIÇÕES FECHADAS - META GARANTIDA ===");
}

//===================== PROTEÇÃO DE LUCRO =====================//
void ApplyProfitProtection() {
   if(DT_ProfitProtection == PROFIT_PROT_OFF) return;
   if(!g_dtState.targetHit) return;

   switch(DT_ProfitProtection) {
      case PROFIT_PROT_HALF:
         g_dtState.lockedProfit = g_dtState.currentPL * 0.5;
         break;

      case PROFIT_PROT_TRAIL:
         // Trailing será atualizado continuamente
         if(g_dtState.currentPL > g_dtState.lockedProfit + (g_dtState.targetAmount * DT_TrailProfitStep)) {
            g_dtState.lockedProfit = g_dtState.currentPL - (g_dtState.targetAmount * DT_TrailProfitStep);
         }
         break;

      case PROFIT_PROT_LOCK:
         g_dtState.lockedProfit = g_dtState.currentPL * (DT_LockProfitPercent / 100.0);
         break;
   }
}

//===================== MODO AGRESSIVO =====================//
void CheckAggressiveMode() {
   if(!DT_EnableAggressive) return;
   if(DT_Mode != DTARGET_AGGRESSIVE) return;
   if(g_dtState.targetHit) return;

   bool shouldBeAggressive = IsInAggressiveWindow() && !g_dtState.targetHit;

   // Também entra em modo agressivo se estiver perdendo e perto do fim
   if(!shouldBeAggressive && DT_RecoverOnAggressive) {
      if(g_dtState.currentPL < 0 && GetMinutesRemaining() <= DT_AggressiveMinutes * 1.5) {
         shouldBeAggressive = true;
      }
   }

   // NOVO: Entra em modo agressivo se não fez NENHUM trade há muito tempo
   if(!shouldBeAggressive && DT_ForceDailyTrade) {
      int minutesWithoutTrade = GetMinutesSinceLastTrade();
      if(minutesWithoutTrade >= DT_ForceAggressiveMin && g_dtState.tradesOpened == 0) {
         shouldBeAggressive = true;
         Print(">>> AGRESSIVO FORÇADO: ", minutesWithoutTrade, " minutos sem trades <<<");
      }
   }

   if(shouldBeAggressive && !g_dtState.aggressiveMode) {
      // Ativa modo agressivo
      g_dtState.aggressiveMode = true;
      g_dtState.aggressiveStartTime = TimeCurrent();
      g_dtState.status = DAY_AGGRESSIVE;

      if(DT_AlertOnAggressive) {
         Alert("MODO AGRESSIVO ATIVADO! Faltam ", GetMinutesRemaining(),
               " minutos. Meta restante: $", DoubleToString(g_dt_remainingAmount, 2));
      }

      Print("=== MODO AGRESSIVO ATIVADO ===");
      Print("Minutos restantes: ", GetMinutesRemaining());
      Print("Meta restante: $", DoubleToString(g_dt_remainingAmount, 2));
      Print("==============================");
   }

   // Atualiza nível de agressividade
   if(g_dtState.aggressiveMode) {
      UpdateAggressiveLevel();
   }
}

void UpdateAggressiveLevel() {
   int minutesLeft = GetMinutesRemaining();
   double percentRemaining = (g_dt_remainingAmount / g_dtState.targetAmount) * 100.0;

   // Calcula nível baseado no tempo e na meta restante
   AggressiveLevel newLevel = AGG_LEVEL_1;

   if(minutesLeft <= 10 || percentRemaining >= 80) {
      newLevel = AGG_LEVEL_5;
   } else if(minutesLeft <= 20 || percentRemaining >= 60) {
      newLevel = AGG_LEVEL_4;
   } else if(minutesLeft <= 30 || percentRemaining >= 40) {
      newLevel = AGG_LEVEL_3;
   } else if(minutesLeft <= 45 || percentRemaining >= 20) {
      newLevel = AGG_LEVEL_2;
   }

   // Limita ao máximo configurado
   if(newLevel > DT_MaxAggressiveLevel) {
      newLevel = DT_MaxAggressiveLevel;
   }

   if(newLevel != g_dtState.currentAggLevel) {
      g_dtState.currentAggLevel = newLevel;
      Print("Nível de Agressividade: ", EnumToString(newLevel));
   }
}

//===================== OPERAÇÃO FORÇADA (OBRIGATÓRIO OPERAR) =====================//
// Estas funções garantem que o bot opere TODOS OS DIAS, mesmo que precise
// reduzir thresholds e ignorar filtros progressivamente
//================================================================================//

// Retorna minutos desde o início do dia de trading
int GetMinutesSinceDayStart() {
   if(g_dtState.dayStart == 0) return 0;

   datetime now = TimeCurrent();
   if(now < g_dtState.dayStart) return 0;

   return (int)((now - g_dtState.dayStart) / 60);
}

// Retorna minutos desde o último trade (ou início do dia se nenhum trade)
int GetMinutesSinceLastTrade() {
   datetime reference = g_dtState.lastTradeTime;
   if(reference == 0) {
      reference = g_dtState.dayStart;
   }
   if(reference == 0) return 0;

   datetime now = TimeCurrent();
   if(now < reference) return 0;

   return (int)((now - reference) / 60);
}

// Verifica e ativa modo de operação forçada
void CheckForcedTradingMode() {
   if(!DT_ForceDailyTrade) return;
   if(g_dtState.targetHit) return;
   if(!IsInDailyTradingWindow()) return;

   int minutesSinceStart = GetMinutesSinceDayStart();
   int minutesSinceLastTrade = GetMinutesSinceLastTrade();

   // Atualiza minutos sem trade
   g_dt_minutesWithoutTrade = minutesSinceLastTrade;

   // Se passou muito tempo sem trade, entra em modo forçado
   if(minutesSinceLastTrade >= DT_ForceAfterMinutes && !g_dtState.forceMode) {
      g_dtState.forceMode = true;
      g_dtState.forceStartTime = TimeCurrent();
      g_dtState.forceLevelReductions = 0;
      g_dt_forceMode = true;

      Print("=====================================================");
      Print(">>> MODO FORÇADO ATIVADO - OBRIGATÓRIO OPERAR! <<<");
      Print("Minutos sem trade: ", minutesSinceLastTrade);
      Print("Trades hoje: ", g_dtState.tradesOpened);
      Print("=====================================================");
   }

   // Atualiza nível de redução progressiva (a cada 30 minutos)
   if(g_dtState.forceMode) {
      int minutesInForceMode = (int)((TimeCurrent() - g_dtState.forceStartTime) / 60);
      int newReductions = minutesInForceMode / 30; // Uma redução a cada 30 min

      if(newReductions > g_dtState.forceLevelReductions) {
         g_dtState.forceLevelReductions = newReductions;
         Print(">>> REDUÇÃO FORÇADA NÍVEL ", g_dtState.forceLevelReductions, " <<<");
      }
   }
}

// Verifica se está em modo de operação forçada
bool IsForcedTradingMode() {
   return g_dtState.forceMode || g_dt_forceMode;
}

// Retorna o multiplicador de threshold para modo forçado
// Reduz progressivamente o threshold para garantir entrada
double GetForcedThresholdMultiplier() {
   if(!IsForcedTradingMode()) return 1.0;

   // Começa em 80% e reduz 5% a cada nível
   double baseReduction = 0.2; // Começa com 20% de redução
   double progressiveReduction = g_dtState.forceLevelReductions * DT_ForceProgressiveReduce;

   double multiplier = 1.0 - baseReduction - progressiveReduction;

   // Mínimo de 30% do threshold (DT_ForceMinThreshold)
   return MathMax(DT_ForceMinThreshold, multiplier);
}

// Retorna mínimo de sinais para modo forçado
int GetForcedMinSignals() {
   if(!IsForcedTradingMode()) return MinAgreeSignals;

   // Reduz requisito de sinais progressivamente
   int reduced = MinAgreeSignals - g_dtState.forceLevelReductions;

   return MathMax(DT_ForceMinSignals, reduced);
}

// Verifica se deve ignorar filtros no modo forçado
bool ShouldIgnoreFiltersForced() {
   if(!IsForcedTradingMode()) return false;

   // Ignora filtros após algumas reduções ou se configurado
   return DT_ForceIgnoreFilters && (g_dtState.forceLevelReductions >= 2);
}

// Retorna multiplicador combinado (agressivo + forçado)
double GetCombinedThresholdMultiplier() {
   double aggMult = GetAggressiveThresholdMultiplier();
   double forceMult = GetForcedThresholdMultiplier();

   // Usa o menor (mais permissivo)
   return MathMin(aggMult, forceMult);
}

// Retorna mínimo de sinais combinado (agressivo + forçado)
int GetCombinedMinSignals() {
   int aggSignals = GetAggressiveMinSignals();
   int forceSignals = GetForcedMinSignals();

   // Usa o menor (mais permissivo)
   return MathMin(aggSignals, forceSignals);
}

// Verifica se deve ignorar filtros (agressivo OU forçado)
bool ShouldIgnoreFiltersCombined() {
   return ShouldIgnoreFilters() || ShouldIgnoreFiltersForced();
}

//===================== CÁLCULO DE LOTE AGRESSIVO =====================//
double CalculateAggressiveLot(double baseLot) {
   if(!g_dtState.aggressiveMode) return baseLot;

   double multiplier = 1.0;
   int level = (int)g_dtState.currentAggLevel;

   // Multiplicador por nível
   multiplier = 1.0 + (level * (DT_AggLotMultiplier - 1.0) / 5.0);

   // Se precisar recuperar perda, aumenta mais
   if(g_dtState.currentPL < 0 && DT_RecoverOnAggressive) {
      multiplier *= DT_RecoveryMultiplier;
   }

   // No nível máximo com all-in permitido
   if(level >= 5 && DT_AggAllowAllIn) {
      // Calcula lote para tentar bater a meta de uma vez
      double equity = AccountInfoDouble(ACCOUNT_EQUITY);
      double riskAmount = equity * (DT_AggMaxRiskPercent / 100.0);
      double atr = 0.0;
      if(hATR != INVALID_HANDLE) GetBuf(hATR, 0, atr, 0);

      if(atr > 0) {
         double tickValue = SymbolInfoDouble(InpSymbol, SYMBOL_TRADE_TICK_VALUE);
         double tickSize = SymbolInfoDouble(InpSymbol, SYMBOL_TRADE_TICK_SIZE);
         if(tickValue > 0 && tickSize > 0) {
            double allInLot = riskAmount / ((atr / tickSize) * tickValue);

            double maxLot = SymbolInfoDouble(InpSymbol, SYMBOL_VOLUME_MAX);
            double minLot = SymbolInfoDouble(InpSymbol, SYMBOL_VOLUME_MIN);
            double lotStep = SymbolInfoDouble(InpSymbol, SYMBOL_VOLUME_STEP);

            allInLot = MathMin(allInLot, maxLot);
            allInLot = MathMax(allInLot, minLot);
            allInLot = MathFloor(allInLot / lotStep) * lotStep;

            if(allInLot > baseLot * multiplier) {
               return allInLot;
            }
         }
      }
   }

   double finalLot = baseLot * multiplier;

   // Aplica limites
   double maxLot = SymbolInfoDouble(InpSymbol, SYMBOL_VOLUME_MAX);
   double minLot = SymbolInfoDouble(InpSymbol, SYMBOL_VOLUME_MIN);
   double lotStep = SymbolInfoDouble(InpSymbol, SYMBOL_VOLUME_STEP);

   finalLot = MathMin(finalLot, maxLot);
   finalLot = MathMax(finalLot, minLot);
   finalLot = MathFloor(finalLot / lotStep) * lotStep;

   return finalLot;
}

//===================== MODIFICADORES DE THRESHOLD =====================//
double GetAggressiveThresholdMultiplier() {
   if(!g_dtState.aggressiveMode) return 1.0;

   int level = (int)g_dtState.currentAggLevel;

   // Reduz threshold por nível
   double reduction = level * DT_AggThresholdReduce;
   return MathMax(0.3, 1.0 - reduction); // Mínimo 30% do threshold original
}

int GetAggressiveMinSignals() {
   if(!g_dtState.aggressiveMode) return MinAgreeSignals;

   int level = (int)g_dtState.currentAggLevel;

   // Reduz sinais necessários por nível
   int minSignals = MinAgreeSignals - (level / 2);

   // No nível máximo, aceita qualquer sinal
   if(level >= 5 && DT_AggIgnoreFilters) {
      return 1;
   }

   return MathMax(1, minSignals);
}

bool ShouldIgnoreFilters() {
   if(!g_dtState.aggressiveMode) return false;

   int level = (int)g_dtState.currentAggLevel;
   return (level >= 4 && DT_AggIgnoreFilters);
}

int GetAggressiveMaxPositions() {
   if(!g_dtState.aggressiveMode) return 1;

   int level = (int)g_dtState.currentAggLevel;
   return MathMin(DT_AggMaxPositions, 1 + level);
}

//===================== VERIFICAÇÃO DE PERMISSÃO PARA TRADE =====================//
// PONTO 2: Esta função bloqueia TODAS as operações após a meta ser atingida
//          O bot SÓ volta a operar no DIA SEGUINTE
//================================================================================//
bool CanOpenNewTrade() {
   if(DT_Mode == DTARGET_OFF) return true;

   // PONTO 2: Se trading está bloqueado (meta atingida), não permite NENHUMA operação
   if(g_dt_tradingBlocked && DT_BlockAfterTarget) {
      g_dt_statusText = "META ATINGIDA - Bloqueado até amanhã";
      return false;
   }

   // Se meta já foi atingida hoje, bloqueia (independente do modo)
   if(g_dtState.targetHit && DT_BlockAfterTarget) {
      g_dt_statusText = "META ATINGIDA - Sem operações hoje";
      return false;
   }

   // Modo conservador também bloqueia após meta
   if(DT_Mode == DTARGET_CONSERVATIVE && g_dtState.targetHit) {
      g_dt_statusText = "Meta atingida - Operações pausadas";
      return false;
   }

   // PONTO 4: Verifica se está dentro do horário de operação definido pelo usuário
   if(!IsInDailyTradingWindow()) {
      g_dt_statusText = "Fora do horário de operação";
      return false;
   }

   // Verifica perda máxima
   double maxLoss = g_dtState.startBalance * (DT_MaxDailyLoss / 100.0);
   if(g_dtState.currentPL <= -maxLoss) {
      if(DT_StopOnMaxLoss && !g_dtState.aggressiveMode) {
         g_dt_statusText = "Perda máxima atingida";
         return false;
      }
   }

   // Verifica proteção de lucro
   if(g_dtState.lockedProfit > 0) {
      double equity = AccountInfoDouble(ACCOUNT_EQUITY);
      double minEquity = g_dtState.startBalance + g_dtState.lockedProfit;
      if(equity <= minEquity) {
         g_dt_statusText = "Lucro protegido - Limite atingido";
         return false;
      }
   }

   // Verifica número de posições no modo agressivo
   if(g_dtState.aggressiveMode) {
      int currentPositions = CountOpenPositions();
      if(currentPositions >= GetAggressiveMaxPositions()) {
         g_dt_statusText = "Máximo de posições agressivas";
         return false;
      }
   }

   g_dt_statusText = "";
   return true;
}

int CountOpenPositions() {
   int count = 0;
   int total = PositionsTotal();

   for(int i = 0; i < total; i++) {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket)) {
         if(PositionGetString(POSITION_SYMBOL) == InpSymbol &&
            PositionGetInteger(POSITION_MAGIC) == Magic) {
            count++;
         }
      }
   }

   return count;
}

//===================== FUNÇÃO PRINCIPAL DE GERENCIAMENTO =====================//
void ManageDailyTarget() {
   if(DT_Mode == DTARGET_OFF) return;

   // Verifica se mudou o dia
   CheckNewDay();

   // Atualiza P/L
   UpdateDailyPL();

   // Verifica modo agressivo
   CheckAggressiveMode();

   // NOVO: Verifica modo de operação forçada (obrigatório operar)
   CheckForcedTradingMode();

   // Atualiza proteção de lucro (trailing)
   if(g_dtState.targetHit && DT_ProfitProtection == PROFIT_PROT_TRAIL) {
      ApplyProfitProtection();
   }

   // Atualiza status
   UpdateStatusText();
}

void CheckNewDay() {
   datetime now = TimeCurrent();
   MqlDateTime dtNow, dtState;
   TimeToStruct(now, dtNow);
   TimeToStruct(g_dtState.dayStart, dtState);

   // Se mudou o dia
   if(dtNow.day != dtState.day || dtNow.mon != dtState.mon || dtNow.year != dtState.year) {
      // Salva estatísticas do dia anterior
      SaveTodayToHistory();

      // Reinicia para o novo dia
      Print("=== NOVO DIA DE TRADING ===");
      ResetDailyState();

      // Recalcula base com juros compostos
      if(DT_CompoundDaily) {
         g_dtState.startBalance = CalculateCompoundBalance();
         g_dtState.targetAmount = g_dtState.startBalance * (DT_TargetPercent / 100.0);
         g_dtState.targetBalance = g_dtState.startBalance + g_dtState.targetAmount;

         Print("Juros Compostos Aplicados!");
         Print("Nova Base: $", DoubleToString(g_dtState.startBalance, 2));
         Print("Nova Meta: $", DoubleToString(g_dtState.targetAmount, 2));
      }
   }
}

void SaveTodayToHistory() {
   if(g_dtState.dayStart == 0) return;

   int newSize = g_dtHistoryCount + 1;
   ArrayResize(g_dtHistory, newSize);

   g_dtHistory[g_dtHistoryCount].date = g_dtState.dayStart;
   g_dtHistory[g_dtHistoryCount].startBalance = g_dtState.startBalance;
   g_dtHistory[g_dtHistoryCount].endBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   g_dtHistory[g_dtHistoryCount].targetPercent = DT_TargetPercent;
   g_dtHistory[g_dtHistoryCount].actualPercent = (g_dtState.currentPL / g_dtState.startBalance) * 100.0;
   g_dtHistory[g_dtHistoryCount].targetHit = g_dtState.targetHit;
   g_dtHistory[g_dtHistoryCount].totalTrades = g_dtState.tradesClosed;

   g_dtHistoryCount++;
}

void UpdateStatusText() {
   if(g_dtState.targetHit) {
      g_dt_statusText = StringFormat("META ATINGIDA! +$%.2f (%.1f%%)",
                                      g_dtState.currentPL, g_dt_progressPercent);
   } else if(g_dtState.aggressiveMode) {
      g_dt_statusText = StringFormat("AGRESSIVO Lv%d | Faltam $%.2f | %d min",
                                      (int)g_dtState.currentAggLevel,
                                      g_dt_remainingAmount, g_dt_minutesRemaining);
   } else if(g_dtState.status == DAY_STOPPED_LOSS) {
      g_dt_statusText = StringFormat("LOSS DIÁRIO: -$%.2f", MathAbs(g_dtState.currentPL));
   } else {
      g_dt_statusText = StringFormat("Meta: %.1f%% | Faltam $%.2f",
                                      g_dt_progressPercent, g_dt_remainingAmount);
   }
}

//===================== AÇÃO AO FIM DO DIA =====================//
void ExecuteEndOfDayAction(CTrade &trade) {
   if(DT_Mode == DTARGET_OFF) return;
   if(GetMinutesRemaining() > 0) return;

   g_dtState.status = DAY_ENDED;

   switch(DT_EndOfDayAction) {
      case EOD_CLOSE_ALL:
         CloseAllPositions(trade);
         break;

      case EOD_KEEP_WINNING:
         CloseLosingPositions(trade);
         break;

      case EOD_KEEP_ALL:
         // Não faz nada
         break;

      case EOD_AGGRESSIVE_PUSH:
         // Já tratado pelo modo agressivo
         if(!g_dtState.targetHit) {
            Print("FIM DO DIA - Meta não atingida!");
            Print("Resultado: $", DoubleToString(g_dtState.currentPL, 2));
         }
         break;
   }
}

void CloseAllPositions(CTrade &trade) {
   int total = PositionsTotal();
   for(int i = total - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket)) {
         if(PositionGetString(POSITION_SYMBOL) == InpSymbol &&
            PositionGetInteger(POSITION_MAGIC) == Magic) {
            trade.PositionClose(ticket);
         }
      }
   }
}

void CloseLosingPositions(CTrade &trade) {
   int total = PositionsTotal();
   for(int i = total - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket)) {
         if(PositionGetString(POSITION_SYMBOL) == InpSymbol &&
            PositionGetInteger(POSITION_MAGIC) == Magic) {
            double profit = PositionGetDouble(POSITION_PROFIT);
            if(profit < 0) {
               trade.PositionClose(ticket);
            }
         }
      }
   }
}

//===================== ESTATÍSTICAS =====================//
void PrintDailySummary() {
   Print("========== RESUMO DO DIA ==========");
   Print("Data: ", TimeToString(g_dtState.dayStart, TIME_DATE));
   Print("Saldo Inicial: $", DoubleToString(g_dtState.startBalance, 2));
   Print("Saldo Final: $", DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2));
   Print("Meta: $", DoubleToString(g_dtState.targetAmount, 2), " (",
         DoubleToString(DT_TargetPercent, 2), "%)");
   Print("Resultado: $", DoubleToString(g_dtState.currentPL, 2), " (",
         DoubleToString((g_dtState.currentPL / g_dtState.startBalance) * 100, 2), "%)");
   Print("Meta Atingida: ", g_dtState.targetHit ? "SIM" : "NÃO");
   Print("Trades: ", g_dtState.tradesClosed, " (Ganhos:", g_dtState.tradesWon, " Perdas:", g_dtState.tradesLost, ")");
   Print("Maior Lucro: $", DoubleToString(g_dtState.highestPL, 2));
   Print("Maior Perda: $", DoubleToString(g_dtState.lowestPL, 2));
   Print("Modo Agressivo: ", g_dtState.aggressiveMode ? "Usado" : "Não usado");
   if(g_dtState.aggressiveMode) {
      Print("  - Trades Agressivos: ", g_dtState.aggressiveTradesOpened);
      Print("  - P/L Agressivo: $", DoubleToString(g_dtState.aggressivePL, 2));
   }
   Print("===================================");
}

void SaveDailyStats() {
   string filename = "DailyTarget_" + InpSymbol + "_" +
                     TimeToString(TimeCurrent(), TIME_DATE) + ".csv";

   int handle = FileOpen(filename, FILE_WRITE|FILE_CSV|FILE_COMMON);
   if(handle == INVALID_HANDLE) return;

   FileWrite(handle, "Data", "Saldo Inicial", "Saldo Final", "Meta %", "Resultado %",
             "Meta Atingida", "Trades", "Wins", "Losses", "Modo Agressivo");
   FileWrite(handle,
             TimeToString(g_dtState.dayStart, TIME_DATE),
             DoubleToString(g_dtState.startBalance, 2),
             DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2),
             DoubleToString(DT_TargetPercent, 2),
             DoubleToString((g_dtState.currentPL / g_dtState.startBalance) * 100, 2),
             g_dtState.targetHit ? "SIM" : "NAO",
             g_dtState.tradesClosed,
             g_dtState.tradesWon,
             g_dtState.tradesLost,
             g_dtState.aggressiveMode ? "SIM" : "NAO");

   FileClose(handle);
}

void LoadDailyHistory() {
   string filename = "DailyTarget_History_" + InpSymbol + ".bin";

   int handle = FileOpen(filename, FILE_READ|FILE_BIN|FILE_COMMON);
   if(handle == INVALID_HANDLE) return;

   g_dtHistoryCount = (int)FileReadInteger(handle);
   if(g_dtHistoryCount > 0) {
      ArrayResize(g_dtHistory, g_dtHistoryCount);
      for(int i = 0; i < g_dtHistoryCount; i++) {
         g_dtHistory[i].date = (datetime)FileReadLong(handle);
         g_dtHistory[i].startBalance = FileReadDouble(handle);
         g_dtHistory[i].endBalance = FileReadDouble(handle);
         g_dtHistory[i].targetPercent = FileReadDouble(handle);
         g_dtHistory[i].actualPercent = FileReadDouble(handle);
         g_dtHistory[i].targetHit = (bool)FileReadInteger(handle);
         g_dtHistory[i].totalTrades = FileReadInteger(handle);
      }
   }

   FileClose(handle);
   Print("Histórico carregado: ", g_dtHistoryCount, " dia(s)");
}

void SaveDailyHistory() {
   string filename = "DailyTarget_History_" + InpSymbol + ".bin";

   int handle = FileOpen(filename, FILE_WRITE|FILE_BIN|FILE_COMMON);
   if(handle == INVALID_HANDLE) return;

   FileWriteInteger(handle, g_dtHistoryCount);
   for(int i = 0; i < g_dtHistoryCount; i++) {
      FileWriteLong(handle, g_dtHistory[i].date);
      FileWriteDouble(handle, g_dtHistory[i].startBalance);
      FileWriteDouble(handle, g_dtHistory[i].endBalance);
      FileWriteDouble(handle, g_dtHistory[i].targetPercent);
      FileWriteDouble(handle, g_dtHistory[i].actualPercent);
      FileWriteInteger(handle, g_dtHistory[i].targetHit ? 1 : 0);
      FileWriteInteger(handle, g_dtHistory[i].totalTrades);
   }

   FileClose(handle);
}

//===================== CALLBACKS PARA TRADES =====================//
void OnDailyTargetTradeOpened() {
   if(DT_Mode == DTARGET_OFF) return;

   g_dtState.tradesOpened++;
   g_dtState.lastTradeTime = TimeCurrent(); // Registra hora do trade

   // Reseta modo forçado quando um trade é aberto
   if(g_dtState.forceMode) {
      Print(">>> Trade aberto - Modo forçado temporariamente pausado <<<");
      // Não reseta completamente, apenas pausa
      // O modo pode voltar se passar mais tempo sem trades
   }

   if(g_dtState.aggressiveMode) {
      g_dtState.aggressiveTradesOpened++;
   }
}

void OnDailyTargetTradeClosed(double profit) {
   if(DT_Mode == DTARGET_OFF) return;

   g_dtState.tradesClosed++;

   if(profit > 0) {
      g_dtState.tradesWon++;
   } else {
      g_dtState.tradesLost++;
   }

   if(g_dtState.aggressiveMode) {
      g_dtState.aggressivePL += profit;
   }
}

//===================== GETTERS PARA INTEGRAÇÃO =====================//
bool IsDailyTargetActive() {
   return (DT_Mode != DTARGET_OFF);
}

bool IsDailyTargetHit() {
   return g_dtState.targetHit;
}

bool IsAggressiveModeActive() {
   return g_dtState.aggressiveMode;
}

double GetDailyProgress() {
   return g_dt_progressPercent;
}

double GetDailyTargetRemaining() {
   return g_dt_remainingAmount;
}

string GetDailyStatusText() {
   return g_dt_statusText;
}

DailyStatus GetDailyStatus() {
   return g_dtState.status;
}

AggressiveLevel GetCurrentAggressiveLevel() {
   return g_dtState.currentAggLevel;
}

double GetStartBalance() {
   return g_dtState.startBalance;
}

double GetTargetBalance() {
   return g_dtState.targetBalance;
}

double GetCurrentDailyPL() {
   return g_dtState.currentPL;
}

// PONTO 2: Verifica se o trading está bloqueado após meta atingida
bool IsTradingBlockedAfterTarget() {
   return g_dt_tradingBlocked;
}

// Retorna a data que a meta foi atingida
datetime GetLastTargetHitDay() {
   return g_dt_lastTargetHitDay;
}

// Retorna o nível de reduções forçadas
int GetForceLevelReductions() {
   return g_dtState.forceLevelReductions;
}

// Retorna minutos sem trade
int GetMinutesWithoutTrade() {
   return g_dt_minutesWithoutTrade;
}

#endif // __MAABOT_DAILYTARGETMANAGER_MQH__
//+------------------------------------------------------------------+
