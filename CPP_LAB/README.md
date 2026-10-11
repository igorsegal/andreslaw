# Andreslav C++ Lab — modular scaffold

Isolated C++17 analyzer/simulator/optimizer architecture. **No production market parser or execution engine yet.** Unknown source-specific algorithms deliberately fail closed.

Build:
```sh
cmake -S . -B build
cmake --build build
ctest --test-dir build --output-on-failure
```

See [Russian architecture](docs/ARCHITECTURE_RU.md).

## Блок SIM-01 (C++17)
Добавлена детерминированная OHLC-модель сделки `include/as/simulator/`:
- сигнал на закрытии бара `k`, вход по open бара `k+1`;
- максимум одна позиция; второй вход во время удержания отклоняется;
- консервативный приоритет SL при одновременном касании SL и TP;
- на гэпе через SL используется цена открытия бара (не выгоднее уровня стопа);
- спред, проскальзывание и комиссии задаются явно в единицах *цены* / quote-PnL, **не** в реальных денежных единицах брокера;
- принудительная оценка по close последнего бара `EndOfData`;
- повторяемые тесты на синтетических барах.

**Не готово к торговому бэктесту**: XFBAR parser, реальные цены bid/ask, спецификация пункта/тик-вэлью/контракта, lot/margin, торговые сессии, частичное исполнение, MT4 parity. Результаты SIM-01 нельзя считать реальными денежными доходностями.

Рабочий путь на ПК пользователя: `D:\AHexaTrader\2026.09.29 ANDRESLAW\cpp_lab`. Реальные бинарные данные читать только из `D:\AHexaTrader\1DataFiles\raw`.
