# AS — каноническая архитектурная спецификация Andreslaw

Дата начала: 2026-10-04  
Статус: RESEARCH SPEC / SOURCE-OF-TRUTH CANDIDATE  
Назначение: восстановление и последующая реализация Andreslaw без догадок.
Исходная методология/первичный источник: SWT.

## 0. Правило проекта

Цепочка для любого правила:

SOURCE -> REQUIREMENT -> CODE -> UNIT TEST -> COMPILE -> RUNTIME -> INTEGRATION

Сначала доказываем правило по первичному источнику, затем кодируем. Неподтвержденные элементы остаются в QUARANTINE и не включаются в торговый контур.

Этот файл не копирует материалы автора SWT. Он содержит техническую структуризацию, краткий пересказ и ссылки на источники.

## 1. Иерархия источников

### A — первичный актуальный источник
Официальный блог Николая Скригана:
https://swt-metod.blogspot.com/

Статические страницы метода, индикаторов и SWT-Robot имеют высший приоритет.

### B — официальный/авторский зеркальный источник
Публикации автора на MQL5 и других площадках. Используются для сверки терминологии и восстановления деталей старых редакций.

### C — наблюдаемое поведение старой программы
Локальные MT4-журналы, параметры SWT-Robot, SWT, SWTsr, SWTch. Это достоверный интерфейс конкретной версии, но не обязательно финальная авторская семантика.

### Q — QUARANTINE
Все предположения, спорные ветки и элементы без достаточного источника.

## 2. Базовая модель SWT

SWT декомпозирует ценовое движение на стохастические волновые тренды разных масштабов. Базовый индикатор SWT является источником:
- волновых компонент;
- состояния трендов;
- волатильности;
- данных для каналов;
- данных для риска и объема;
- входной информации SWT-Robot.

Опубликованные материалы описывают гребенку цифровых фильтров, настроенную на опорные дневные и недельные циклы, с масштабированием соседних уровней примерно в 5 раз.

### Требование Andreslaw
AS_Waves должен оставаться единственным источником волновой математики. В EA нельзя создавать второй независимый AS/Butterworth engine.

Текущая архитектура Andreslaw этому принципу соответствует.

## 3. Фильтры

В опубликованных материалах описаны цифровые фильтры на основе аналогового прототипа и билинейного z-преобразования:
- 2-й порядок — основной режим;
- 4-й порядок — более качественное разделение, но более высокая задержка.

Требуется отдельно проверить точные коэффициенты и режимы текущей финальной редакции SWT.

## 4. Каноническая шкала трендов

| № | SWT trend | Средний цикл | Роль |
|---:|---|---|---|
| G | Global | 50–75 лет | метод, вне основного TrendVector |
| 8 | Basic | 10–15 лет | Trend |
| 7 | Long | 2–3 года | Trend |
| 6 | Medium | 5–7 месяцев | Trend |
| 5 | Short | 4–6 недель | Trend |
| 4 | Weekly | 4–6 дней | Trend |
| 3 | Daily | 20–30 часов | Pattern |
| 2 | IDay | 4–6 часов | Pattern |
| 1 | Hourly | 50–70 минут | Pattern |
| S | Intrahour | 10–15 минут | непосредственный сигнал |

Иерархия робота:

Trend 4..8 -> Pattern 1..3 -> Intrahour W2 signal -> Blocks -> Trade.

## 5. TrendVector

TrendVector задает старший учитываемый тренд:
- 8 = Basic и ниже;
- 7 = Long и ниже;
- 6 = Medium и ниже;
- 5 = Short и ниже;
- 4 = Weekly и ниже.

Рабочий диапазон ограничивается 4..8.

Andreslaw AS_ClampTrendVector уже следует этому контракту.

Статус: STRUCTURALLY ALIGNED.

## 6. Trend

### AdaptiveMode=false
Направление формируется согласованием выбранных уровней группы Trend:
- согласованно UP -> Trend=UP;
- согласованно DN -> Trend=DN;
- конфликт -> Trend=NO.

### AdaptiveMode=true
Используется старший направленный тренд группы Trend. Коррекционные состояния могут не задавать направление. Если старшие уровни находятся в коррекции, Weekly используется как опорный уровень.

### Version drift
В разных редакциях встречаются AdaptiveMode, DominantTrend и DominantCorrection. Их нельзя автоматически считать одинаковыми по смыслу.

Статус sig_trend.mqh: PARTIAL, нужна версионная сверка.

## 7. ContraTrend

ContraTrend меняет результирующее направление торговли относительно Trend. Pattern при этом не должен механически инвертироваться.

Статус Andreslaw: LIKELY ALIGNED, требуется тест.

## 8. Pattern

Pattern формируется тремя младшими трендами:
- Hourly;
- IDay;
- Daily.

Они определяют графические паттерны SWT и разрешают вход в направлении Trend.

Текущий sig_pattern.mqh сводит Pattern к простому совпадению направлений трех трендов. Этого недостаточно для признания полной реализации SWT-паттернов.

Нужно восстановить:
- trend/correction state;
- паттерны разворота;
- паттерны восстановления;
- условия открытия и закрытия;
- связь с цифровым кодом SWTtr.

Статус: PARTIAL.

## 9. Непосредственный сигнал W2

Авторская документация прямо описывает сигнал по внутричасовому тренду — W2 минутного масштаба.

BUY:
1. пересечение нуля снизу вверх; или
2. волна выше нуля шла к нулю и развернулась вверх.

SELL:
1. пересечение нуля сверху вниз; или
2. волна ниже нуля шла к нулю и развернулась вниз.

AS_W2Signal в sig_reversal.mqh уже реализует эти два случая.

Статус: HIGH CONFIDENCE.

Обязательный тест: таблица older/prev/current со всеми BUY/SELL/NONE вариантами.

## 10. Разрешение сделки

BUY только если одновременно:
- Trend=UP;
- Pattern=UP;
- W2 signal=BUY;
- PermitLong=true;
- отсутствуют блокировки.

SELL — симметрично.

Основные блокировки:
- risk limit;
- leverage limit;
- dominant correction, если режим используется;
- пользовательские PermitLong/PermitShort;
- timeout;
- дневные лимиты;
- проектный safety gate.

sig_collect.mqh структурно соответствует этой схеме.

## 11. SWTsr — критический недостающий provider

SWTsr строит рассчитанные по волатильности горизонтальные диапазоны для W2/W3/W4:
- границы связаны с текущим циклом тренда;
- отсчет ведется от реализованных экстремумов;
- границы являются расчетными целями;
- уровни StopLossLevel привязаны к каналам трендов;
- используются доверительные интервалы.

Без точного SWTsr нельзя считать восстановленными:
- strategic stop;
- channel take-profit;
- channel trailing;
- полноценный position management.

Статус: MISSING / PRIORITY A.

Fibonacci не является допустимой заменой без отдельного доказательства.

## 12. SWTch

SWTch строит динамические каналы волатильности и используется:
- для оценки естественного диапазона тренда;
- промежуточных целей;
- возврата цены внутрь канала;
- оценки перегрева;
- дополнительного режима ChannelInput.

Статус Andreslaw: MISSING / PRIORITY B.

## 13. ChannelInput

Дополнительная ветка SWT-Robot:
- включается отдельным параметром;
- торгует только по направлению Trend;
- учитывает risk/leverage blocks;
- возврат сверху в канал может давать SELL;
- возврат снизу может давать BUY;
- дневной и внутридневной каналы работают независимо;
- Pattern может игнорироваться.

Не реализовывать до восстановления SWTch.

## 14. Grid / DoubleGrid

Документированы:
- Grid;
- DoubleGrid;
- GridStep;
- GridStepFactor;
- GridStepManual в наблюдаемой версии;
- перестройка уровней после срабатывания;
- сброс после полного закрытия позиции.

В одной из редакций VGrid связан со средней волатильностью Hourly и Intrahour.

Статус: MISSING / HIGH-RISK OPTIONAL.

Grid не должен блокировать базовую реализацию Andreslaw.

## 15. MFactor

MFactor — агрессивное наращивание объема; автор прямо описывает его как разновидность растянутого мартингейла.

Статус: DELIBERATELY DEFERRED.

## 16. StopLossLevel / TakeProfitLevel

StopLossLevel:
1 Hourly
2 IDay
3 Daily
4 Weekly
5 Short
6 Medium
7 Long

TakeProfitLevel в новых редакциях:
1 Hourly
2 IDay
3 Daily
4 Weekly
5 Short
6 Medium
7 Long
8 Basic

Ценовые уровни должны поступать от канального provider, прежде всего SWTsr.

Andreslaw имеет поля контракта, но не имеет канонического provider цены.

## 17. Риск и объем

SWT связывает размер позиции с:
- капиталом;
- процентным риском;
- stop level;
- волатильностью;
- tick value.

SWTml показывает расчетные допустимые объемы для типовых stop levels.

Andreslaw уже имеет order_size, val_risk и val_margin, но требуется проверить:
- TickValueFactor;
- серверные ошибки tick value;
- отдельные long/short значения;
- текущий риск открытых позиций;
- различие расчетного стратегического риска и фактического SL.

Статус: PARTIAL.

## 18. Закрытие

Подтвержденные ветки:
- изменение/разворот тренда;
- ProfitRiskPerc -> CloseByRT;
- SafeModeClose;
- strategic SL;
- tactical TP;
- adaptive trailing;
- подтягивание stop по изменению каналов.

Для Weekly-глубины документация отдельно различает простую смену направления и настоящий разворот/выход из коррекции.

Модули Andreslaw pm_trigger/stop/take/trail/dispatch пока являются инфраструктурой, потому что SWTsr/SWTch и полный Pattern отсутствуют.

## 19. Конфигурация SWT-Robot

В разных актуальных/наблюдаемых версиях подтверждаются параметры:

- TrendVector
- AdaptiveMode
- DominantTrend / DominantCorrection
- ContrTrend
- ChannelInput
- Grid
- DoubleGrid
- GridStepFactor
- RiskLimitPerc
- RiskTradePerc
- LeverageLimit
- LotsManual
- MFactor
- StopLossLevel
- TakeProfitLevel
- ProfitRiskPerc
- AdaptiveTrailingStop
- SafeModeClose
- ManualPositionControl
- TimeOutMinutes
- PermitLong
- PermitShort
- Magic
- DailyProfitTargetPerc
- DailyLossLimitPerc
- UI/table parameters

### Наблюдаемая старая конфигурация из MT4 log

- TrendVector=7
- ContrTrend=false
- ReverseRTT=false
- DominantCorrection=true
- Grid=true
- DoubleGrid=true
- GridStepFactor=0.25
- GridStepManual=0
- RiskLimitPerc=100
- RiskTradePerc=1
- LotsManual=0
- MFactor=true
- StopLossLevel=5
- TakeProfitLevel=3
- ProfitRiskPerc=5
- AdaptiveTrailingStop=6
- SafeModeClose=true
- ManualPositionControl=true
- TimeOutMinutes=15
- PermitLong=true
- PermitShort=true
- TickValueFactor=1
- SizeLabel=9
- ModifyColorLabel=9234160
- Magic=220656
- HideLabels=false

Это baseline конкретной версии, а не безопасные defaults Andreslaw.

## 20. SAFE_RECOVERY_DEFAULTS vs RECOVERED_SWT_BASELINE

Andreslaw обязан хранить отдельно:

SAFE_RECOVERY_DEFAULTS:
- enabled=false;
- hard trading lock;
- консервативные ограничения;
- без Grid/MFactor;
- без реальной торговли.

RECOVERED_SWT_BASELINE:
- подтвержденные настройки конкретной версии SWT-Robot;
- используется для совместимости и тестов;
- не включает торговлю автоматически.

Нельзя автоматически заменять безопасные defaults историческими SWT-настройками.

## 21. Карта модулей Andreslaw

| SWT-функция | Andreslaw | Статус |
|---|---|---|
| Wave decomposition | AS_Waves + wave_bank | IMPLEMENTED / TESTED |
| Current-TF wave provider | wave_provider | Stage5 PASS |
| MTF provider | wave_provider Stage6 | IN TEST |
| Trend hierarchy | contracts + wave_hierarchy | STRUCTURE ONLY |
| Trend aggregation | sig_trend | PARTIAL |
| Pattern | sig_pattern | PARTIAL |
| W2 signal | sig_reversal | HIGH CONFIDENCE |
| Trade conjunction | sig_collect | STRUCTURAL PASS |
| SWTsr | отсутствует | MISSING |
| SWTch | отсутствует | MISSING |
| Risk | val_risk | PARTIAL |
| Margin/leverage | val_margin | PARTIAL |
| Lot sizing | order_size | PARTIAL |
| SWTml layer | отсутствует отдельно | MISSING/PARTIAL |
| Grid | отсутствует | DEFER |
| MFactor | отсутствует | DEFER |
| Stop/TP/trail | pm_* | INFRASTRUCTURE |
| Full state machine | Andreslav_AS | NOT COMPLETE |

## 22. Что пока QUARANTINE

Не считать восстановленным:
- точную формулу SWTsr;
- точную формулу SWTch;
- полный Pattern;
- sig_rank;
- спорный as_pipeline;
- Fibonacci как замену SWT-каналов;
- точную семантику DominantTrend/DominantCorrection между версиями;
- любые wave/timeframe mapping, полученные только логическим предположением.

## 23. Приоритеты

P0 — завершить доказательную спецификацию и source matrix.  
P1 — MTF hierarchy, Trend, Pattern, W2 tests.  
P2 — SWTsr, затем SWTch.  
P3 — risk, lot sizing, CloseByRT, SafeModeClose, trailing.  
P4 — ChannelInput, Grid, DoubleGrid, MFactor.

## 24. Реестр требований

Следующий машинно-читаемый файл:

docs/AS_REQUIREMENTS.csv

Колонки:
ID, DOMAIN, REQUIREMENT, SOURCE_CLASS, SOURCE_URL, SOURCE_DATE, CONFIDENCE, ANDRESLAW_MODULE, IMPLEMENTATION_STATUS, TEST_ID, TEST_STATUS, NOTES

## 25. Целевая архитектура

~~~
PRICE / HISTORY
      |
      v
 AS_Waves / canonical SWT wave source
      |
      +-----------------------+
      |                       |
      v                       v
Trend-state providers    Channel/volatility providers
      |                       |
      v                       +--> SWTsr
Trend hierarchy               +--> SWTch
      |
      +--> Trend 4..8
      +--> Pattern 1..3
      +--> Intrahour W2 signal
                 |
                 v
         Decision conjunction
                 |
         Risk / blocks
                 |
         Trade intent
                 |
        Execution / PM
                 |
     stop / target / trail /
     CloseByRT / SafeModeClose
~~~

До полного восстановления providers и rules:

EXECUTION REMAINS LOCKED.

## 26. Первичные страницы для полного прохода

Основной сайт:
https://swt-metod.blogspot.com/

Теория:
https://swt-metod.blogspot.com/p/blog-page_22.html
https://swt-metod.blogspot.com/p/1-swt.html

SWT-Robot:
https://swt-metod.blogspot.com/p/swt.html
https://swt-metod.blogspot.com/2026/04/1-swt-robot-v33.html

Дополнительно необходимо пройти по статическим страницам:
- SWTtr
- SWTsr
- SWTch
- SWTml
- графические паттерны
- доминирующие trend/correction
- risk management
- правила открытия
- правила закрытия
- приложения по фильтрам и спектральному анализу

## 27. Архитектурный вывод

Andreslaw уже содержит значительную часть каркаса SWT-Robot, но главные пробелы находятся не в OrderSend/OrderClose.

Критические пробелы:
1. доказанная полная MTF hierarchy;
2. полноценный Pattern;
3. SWTsr;
4. SWTch;
5. version-aware configuration semantics;
6. формальные тесты каждого правила.

Поэтому дальнейшее восстановление должно идти от спецификации к коду, а не наоборот.


## 28. Контрольная точка AS Trend 4..8

Полный первичный проход старшей Trend-группы выполнен 2026-10-04.

Канонически подтверждено:
- уровни Basic=8, Long=7, Medium=6, Short=5, Weekly=4 образуют Trend;
- TrendVector нормализуется в диапазон 4..8;
- AdaptiveMode=false использует всю выбранную группу;
- AdaptiveMode=true в v3.3 использует старший направленный Trend;
- если все выбранные старшие уровни находятся в коррекции, направление задаёт Weekly;
- DominantCorrection является отдельной блокировкой новых входов и работает при AdaptiveMode=true;
- ContrTrend инвертирует результирующий Trend, но не Pattern.

Созданы:
- docs/AS_TREND_4_8_SPEC_RU.md;
- docs/AS_TREND_4_8_TEST_MATRIX.csv.

Выявлены два нерешённых вопроса:
1. старая статическая версия содержит отдельные DominantTrend и ReverseReadyToTrade, отсутствующие в v3.3;
2. порядок DominantCorrection относительно ContrTrend в комбинированном режиме не доказан.

До разрешения этих вопросов они остаются QUARANTINE.

Дополнительно введено проектное safety-требование: отсутствие обязательных данных выбранного Trend-уровня должно приводить к fail-closed (Trend=NO), а не к молчаливому переходу к младшему источнику.

Production-код sig_trend.mqh на этой контрольной точке намеренно не изменён. Сначала должен быть реализован self-test по AS_TREND_4_8_TEST_MATRIX.csv.
