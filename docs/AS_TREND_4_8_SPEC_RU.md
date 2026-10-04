# AS — спецификация Trend 4..8

Дата: 2026-10-04  
Статус: **SOURCE PASS / CODE CHANGE DEFERRED UNTIL VERSION CONFLICT RESOLVED**

## 1. Назначение

Этот документ фиксирует доказанную по первичным материалам SWT семантику старших трендов Andreslaw и отделяет её от неподтверждённых предположений.

Область:
- TrendVector;
- Basic / Long / Medium / Short / Weekly;
- AdaptiveMode;
- DominantCorrection;
- ContrTrend;
- версионный конфликт DominantTrend / ReverseReadyToTrade;
- требования к безопасной обработке неполных данных.

## 2. Источники

### A1 — SWT-Robot v3.3, параметры
https://swt-metod.blogspot.com/2026/04/1-swt-robot-v33.html

### A2 — SWT-Robot, правила открытия
https://swt-metod.blogspot.com/2026/04/

Раздел: 2. SWT-Robot. Правила открытия позиций, 06.04.2026.

### A3 — старая статическая версия SWT_Robot
https://swt-metod.blogspot.com/p/swt.html

Страница прямо помечена как старая версия и используется только для анализа version drift.

### A4 — базовый SWT
https://swt-metod.blogspot.com/p/1-swt.html

## 3. Уровни Trend

Группа Trend состоит ровно из пяти старших уровней:

| Level | Name | Роль |
|---:|---|---|
| 8 | Basic | Trend |
| 7 | Long | Trend |
| 6 | Medium | Trend |
| 5 | Short | Trend |
| 4 | Weekly | Trend |

Daily=3, IDay=2, Hourly=1 относятся к Pattern и не входят в логическое произведение Trend.

## 4. TrendVector

TrendVector задаёт старший учитываемый уровень.

Нормализация:
- значение >=8 -> 8;
- 7 -> 7;
- 6 -> 6;
- 5 -> 5;
- значение <=4 -> 4.

Выбранный набор Trend:
- TV=8: 8,7,6,5,4;
- TV=7: 7,6,5,4;
- TV=6: 6,5,4;
- TV=5: 5,4;
- TV=4: 4.

Текущий AS_ClampTrendVector соответствует этому контракту.

## 5. Non-adaptive mode

При AdaptiveMode=false учитываются все уровни Trend от Weekly=4 до TrendVector включительно независимо от признака trend/correction.

Формализация:
- если все выбранные уровни разрешают UP -> Trend=UP;
- если все выбранные уровни разрешают DN -> Trend=DN;
- если направления конфликтуют -> Trend=NO;
- отсутствие валидных данных по обязательному выбранному уровню в Andreslaw должно давать Trend=NO (fail closed).

Важно:
признак correction в non-adaptive mode не означает автоматическое исключение уровня из расчёта.

## 6. Adaptive mode — v3.3

При AdaptiveMode=true:
1. среди выбранной группы Trend ищется самый старший направленный (не коррекционный) тренд;
2. его направление становится результирующим Trend;
3. коррекционные старшие уровни при выборе доминирующего направленного тренда пропускаются;
4. если все старшие уровни группы находятся в коррекции, направление задаётся Weekly.

Это соответствует формулировкам v3.3 и правил открытия от 06.04.2026.

## 7. DominantCorrection — v3.3

DominantCorrection работает только при AdaptiveMode=true.

При наличии доминирующей коррекции, направленной против торгуемого тренда:
- сам Trend не обязан становиться NO;
- открытие новых позиций блокируется отдельным флагом.

Для Andreslaw это означает разделение:
- AS_TrendDirection() -> направление;
- dominant_correction_block -> отдельная блокировка.

Текущая архитектура функции следует именно такому разделению.

## 8. ContrTrend

ContrTrend=true меняет результирующее направление Trend на противоположное.

Pattern при этом не инвертируется автоматически.

Следствие:
- исходный Trend UP -> торговый Trend DN;
- исходный Trend DN -> торговый Trend UP;
- NO остаётся NO.

## 9. Неразрешённый вопрос: DominantCorrection + ContrTrend

В v3.3 DominantCorrection описана как коррекция против торгуемого тренда, а ContrTrend меняет направление торговли.

Из текста недостаточно однозначно следует порядок:
1. сначала определить dominant correction относительно базового Trend, затем инвертировать Trend;
или
2. сначала получить фактическое торговое направление с ContrTrend, затем определять противоположную коррекцию.

Текущий sig_trend.mqh вычисляет dominant_correction_block ДО инверсии ContrTrend.

Статус: **QUARANTINE / REQUIRE SOURCE OR BEHAVIORAL EVIDENCE**.

До разрешения этого пункта комбинация AdaptiveMode=true + DominantCorrection=true + ContrTrend=true не должна считаться канонически восстановленной.

## 10. Version drift: старая версия против v3.3

Старая статическая страница содержит дополнительные параметры:
- DominantTrend;
- ReverseReadyToTrade.

Старая семантика:
- AdaptiveMode=true выбирает диапазон начиная со старшего направленного;
- DominantTrend=true учитывает только старший направленный;
- DominantTrend=false учитывает направления всех более младших после него;
- DominantCorrection работает только при DominantTrend=true;
- ReverseReadyToTrade хранит отдельную готовность к первой сделке.

В v3.3:
- отдельного DominantTrend в опубликованном интерфейсе нет;
- AdaptiveMode=true уже сам означает использование старшего направленного Trend;
- DominantCorrection остаётся отдельной блокировкой;
- вместо старого RTT-контракта описан Pattern.

Вывод:
эти версии нельзя смешивать в одной функции без явной версии алгоритма.

## 11. Проверка текущего sig_trend.mqh

### Совпадает с v3.3
- clamp TrendVector 4..8;
- уровни 4..8;
- non-adaptive consensus;
- adaptive search сверху вниз;
- пропуск correction при поиске senior directed;
- Weekly fallback;
- отдельный dominant_correction_block;
- ContrTrend инвертирует Trend.

### Требует изменения/доказательства
1. В adaptive mode невалидный выбранный уровень сейчас может быть пропущен.
   Для Andreslaw безопаснее fail closed, если обязательные source data отсутствуют.
2. Не доказан порядок DominantCorrection + ContrTrend.
3. Не реализована старая ветка DominantTrend=false.
4. Не реализован ReverseReadyToTrade.
5. Не решено, какую версию SWT-Robot Andreslaw должен воспроизводить как целевую.

## 12. Политика до разрешения version drift

- v3.3 используется как основной источник для базовой Trend-логики.
- старая версия хранится как отдельный compatibility branch specification.
- код не должен смешивать две версии неявно.
- торговля остаётся заблокированной.
- изменения sig_trend выполняются только после прохождения AS_TREND_4_8_TEST_MATRIX.

## 13. Следующий кодовый шаг

До изменения production-функции:
1. реализовать self-test harness для чистой Trend-логики;
2. прогнать таблицу AS_TREND_4_8_TEST_MATRIX.csv;
3. отдельно решить fail-closed для invalid state;
4. оставить DominantCorrection+ContrTrend в quarantine до доказательства;
5. затем минимально исправить sig_trend.mqh.
