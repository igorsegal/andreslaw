# Andreslav C++ Lab — архитектурный контракт v0.1

Принцип: один небольшой блок — один контракт — один тест — возможность независимой замены.

## Подсистемы
- core: типы, коды состояния, конфигурация, часы, детерминированные ID.
- data: XFBAR schema, reader, endian, OHLC validation, gaps, alignment, timeseries, M1/M5 execution path, fixture parser.
- waves: provider interface, Butterworth engine, scale mapping, parity with MQL4; до parity engine не доверен.
- trend: Trend4..8, adaptive/nonadaptive, contra, dominant correction, version policy.
- pattern: базовый Pattern1..3, расширенная state-machine = QUARANTINE.
- signal: W2 zero-cross, zero-turn.
- decision: Trend+Pattern+Signal conjunction, gates, signal deduplication, TTL.
- channel: SWTsr/SWTch = NOT_IMPLEMENTED; замены допускаются только как отдельный доказуемый контракт.
- risk: tick value, stop geometry, sizing, broker-specific margin = NOT_IMPLEMENTED.
- execution: fills, bid/ask, intrabar precedence, SL/TP, fees, slippage, lifecycle = NOT_IMPLEMENTED.
- metrics: trades, PnL, PF, WR, drawdown, error bars.
- optimizer: grid, walk-forward, split and out-of-sample = NOT_IMPLEMENTED до проверенного эмулятора.

## Данные
Реальные рыночные BIN читаются исключительно из D:\\AHexaTrader\\1DataFiles\\raw. Облачные синтетические unit fixtures не являются подменой raw. Никаких ложных результатов оптимизации.

## Обязательные проходные условия
1. Проверить точный контракт бинарного XFBAR по фактическому файлу и парсеру.
2. Совпадение W2, Pattern, Trend и MTF с MT4 на одних и тех же барах.
3. Подтвердить bid/ask, SL/TP, и conservative intrabar policy.
4. Ввести out-of-sample и walk-forward до оптимизации параметров.
5. DEMO открывать лишь после независимого риск/preflight и execution gate.

Статус: архитектура зафиксирована; компилируемый C++ код первой версии подготовлен отдельно, но пока НЕ опубликован в этом checkpoint полностью.
