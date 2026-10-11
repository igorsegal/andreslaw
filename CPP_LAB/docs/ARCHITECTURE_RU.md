# ANDRESLAW C++ LAB — архитектура v0.1

Статус: COMPILABLE SKELETON / NOT DEMO READY.

## Принцип
Один модуль = один контракт = один подменяемый алгоритм. Все функции неизвестных правил возвращают `NotImplemented`; они не создают сигналов или сделок. Программа не производит торговлю.

## Декомпозиция

- `core/`: `status`, `types`; следующие: error registry, clock, configuration, deterministic IDs.
- `data/`: validation, CSV fixtures, XFBAR adapter (блокирован до точного формата); следующие: checksum, endian, calendar alignment, gaps, resampling, M1/M5 paths.
- `waves/`: provider interface, timeframe/scale mapping stub; следующие: Butterworth coefficients, parity vectors from MQL4, multi-scale cache.
- `trend/`: states, nonadaptive, adaptive, contra; следующие: dominant correction, versioned behavior.
- `pattern/`: базовый согласованный 1–3, расширенная state machine в карантине.
- `signal/`: W2 zero-cross и turn.
- `decision/`: conjunction и запреты; последующие: de-dup, event cadence, TTL.
- `channel/`: SWTsr, SWTch — явные белые пятна; AS_sr только после отдельного контракта.
- `risk/`: sizing и margin — блокировка до модели брокера и golden vectors.
- `execution/`: position state, fills, close — блокировка до внутрибара, Bid/Ask, комиссии, спреда и конфликтов SL/TP.
- `metrics/`: базовый подсчёт; следующие: drawdown, PF, WR, exposure, confidence intervals.
- `optimizer/`: параметры, grid, walk-forward — блокировка до завершения симулятора.

## Независимая сверка
Каждый расчет волн, тренда, паттерна и сигнала должен быть сопоставлен с MQL4 на одинаковых timestamp/барах до доверия историческим результатам. Ветка тестирования отдельно от `main`.

## Источник рыночных данных
Только `D:\AHexaTrader\1DataFiles\raw` на рабочей машине. Облачные unit-тесты допускают синтетические fixtures; никаких псевдо-raw или перепаковок BIN. Реальные BIN не загружаются в GitHub автоматически.

## Демо
Нельзя интерпретировать `BOOTSTRAP_PASS` как завершённый эмулятор. DEMO требует отдельно подтверждённой логики риска, исполнения и мониторинга.
