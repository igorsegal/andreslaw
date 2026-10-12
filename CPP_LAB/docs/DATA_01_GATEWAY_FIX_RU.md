# DATA-01 Gateway Fix — 2026-10-12

## Реализованные исправления

- `src/main.cpp`: команда `inspect-xfbar <absolute-bin-path> <symbol>` действительно вызывает Reader; выводит BARS/FIRST_TIME/LAST_TIME.
- `tests/test_xfbar_reader.cpp`: все проверки заменены на всегда исполняемые `check()`; ошибка приводит к ненулевому коду.
- `CMakeLists.txt`: контрактные тесты с `assert()` не выключаются в Release (`/UNDEBUG` или `-UNDEBUG`); дополнительный CLI-negative тест.
- Защита от ложного общего PASS: 0 не возвращается для непроверенных metadata/parity. Успешная обработка payload = exit code 3 / DATA01_GATEWAY=PARTIAL.

## Выполненные проверки в контейнере
- CMake Release compile: PASS.
- CTest: 4/4 PASS.
- CLI для отсутствующего BIN: XFBAR_PAYLOAD=FAIL, exit code 1: PASS (negative test).

## Незакрытые проверки
- Полная семантика 60-байтового заголовка: UNVERIFIED. Код намеренно не утверждает расположение полей без эталонного контракта.
- Чтение пользовательского реального BIN: NOT TESTED (D: не смонтирован здесь).
- Паритет с проверенным экспортёром и MQL4: NOT TESTED.
- Следующий новый блок до прохождения полного Gateway начинать запрещено.

## Запуск на Windows

```powershell
$P = 'D:\AHexaTrader\2026.09.29 ANDRESLAW\cpp_lab'
cmake -S $P -B "$P\build" -DCMAKE_BUILD_TYPE=Release
cmake --build "$P\build" --config Release
ctest --test-dir "$P\build" -C Release --output-on-failure
& "$P\build\Release\as_lab.exe" inspect-xfbar 'D:\AHexaTrader\1DataFiles\raw\EURUSD_H1.bin' EURUSD
```

Исполняемый файл при одноконфигурационной сборке может находиться вместо `build\Release` непосредственно в `build`. Подставлять фактический путь BIN, не угадывать имя. Exit code 3 означает частичный Gateway, а не ошибку декодирования.
