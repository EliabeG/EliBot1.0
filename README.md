# MAAbot v2.3.1 - Versão Modular

## Estrutura de Arquivos

O EA original foi dividido em **17 arquivos** organizados por funcionalidade:

```
MQL5/
├── Experts/
│   └── MAAbot_v2_Visual.mq5      # Arquivo principal (OnInit, OnDeinit, OnTick)
│
└── Include/
    └── MAAbot/
        ├── Enums.mqh             # Enumerações (SLMode, TPMode, PrecMode, MGMode)
        ├── Inputs.mqh            # Todos os parâmetros de entrada
        ├── Structs.mqh           # Estruturas (GridState, Signals, BasketInfo)
        ├── Globals.mqh           # Variáveis globais, handles e extern CTrade
        ├── Utils.mqh             # Funções utilitárias (Pt, Bid, Ask, etc.)
        ├── Indicators.mqh        # Indicadores customizados (SuperTrend, QQE, KAMA)
        ├── RiskManagement.mqh    # Gestão de risco e capital
        ├── Signals.mqh           # Sistema de sinais ensemble (9 estratégias)
        ├── Trend.mqh             # Análise de tendência MTF
        ├── Filters.mqh           # Filtros (falhas rápidas, notícias)
        ├── Basket.mqh            # Gestão de cestas de posições
        ├── Grid.mqh              # Sistema Grid/Martingale trend-aware
        ├── Hedge.mqh             # Sistema de Hedge com recuperação
        ├── TradeManagement.mqh   # Gestão de trades (SL/TP, trailing, BE)
        ├── TradeExecution.mqh    # Execução de trades (TryOpen)
        └── Panel.mqh             # Painel visual completo
```

## Instalação

1. **Copie a pasta `MAAbot`** para:
   ```
   [Pasta do MetaTrader 5]/MQL5/Include/MAAbot/
   ```

2. **Copie o arquivo `MAAbot_v2_Visual.mq5`** para:
   ```
   [Pasta do MetaTrader 5]/MQL5/Experts/MAAbot_v2_Visual.mq5
   ```

3. **Compile o EA** no MetaEditor clicando em `Compile` (F7)

## Funcionalidades Preservadas

✅ 9 Estratégias Ensemble (MA Cross, RSI, BBands, SuperTrend, AMA/KAMA, Heikin Ashi, VWAP, Momentum, QQE)
✅ Sistema Grid/Martingale trend-aware
✅ Sistema de Hedge com recuperação
✅ Filtros de notícias comportamental
✅ Filtro de falhas rápidas
✅ Tendência MTF (H1/H4)
✅ Gestão avançada de SL/TP (ATR, Estrutura, Híbrido)
✅ DD Guard e throttling de risco
✅ Painel visual completo

## Notas Técnicas

- **Funcionamento idêntico** ao EA original
- **Nenhuma funcionalidade** foi adicionada ou removida
- Todos os **inputs mantidos** exatamente como no original
- **Guards de compilação** (#ifndef) evitam inclusões duplicadas
- Objeto `CTrade trade` é declarado no .mq5 principal e acessado via `extern` nos módulos
- **Assinaturas de funções idênticas** ao original (sem parâmetros trade extras)

## Autor

Eliabe N Oliveira
Data: 10/12/2025
Versão: 2.3.1
