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

DATA-01: `as/data/xfbar_record.hpp` + `as/data/xfbar_reader.hpp`;
CTest `as_xfbar_contracts`. Header metadata beyond version is not yet decoded.

## DATA-01 FIX: рабочий CLI + fail-closed Gateway
`as_lab inspect-xfbar <absolute-bin-path> <symbol>` вызывает реальный
`read_xfbar_records()`, сообщает количество свечей и границы времени.
Коды завершения: `1` — ошибка данных, `2` — ошибка аргументов,
`3` — payload прочитан, но Gateway **PARTIAL** (метаданные заголовка и
соответствие исходному экспортёру не доказаны). Кода `0` для полного
Gateway до эталонной верификации **нет намеренно**.

Для безопасной проверки на реальной истории:
`as_lab inspect-xfbar D:\\AHexaTrader\\1DataFiles\\raw\\EURUSD_H1.bin EURUSD`
(путь к файлу подставлять фактический). Без указания пути сканирования диска нет.
