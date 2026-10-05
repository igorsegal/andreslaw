# ANDRESLAW — текущее состояние восстановления

Дата контрольной точки: **2026-10-05**
Статус: **RECOVERY STAGE 7 COMPLETE / TREND 4..8 24/24 PASS**

## Подтверждено

1. `AS_Waves.mq4` — **0 errors / 0 warnings**; установлен на график, линии отображаются, runtime-ошибок нет.
2. `AS_Targets.mq4` — **0 errors / 0 warnings**.
3. `Andreslav_AS.mq4` после Stage 2 — **0 errors / 0 warnings**.
4. `AS_ModulesCompileTest.mq4` — **0 errors / 0 warnings**.
5. `Andreslav_AS.mq4` после интеграции Stage 4 — **0 errors / 0 warnings**.
6. Stage 5 runtime `OnInit()` — **PASS** на `BTCUSD,M5`:
   - `initialized`
   - `[AS][STAGE4] Integrated safe core initialized.`
   - `trading_lock=1`
   - `cfg.enabled=false`
   - `equity=8.76`
7. Stage 5 full new-bar runtime pipeline — **PASS** на `BTCUSD,M5`.
   Подтверждены четыре последовательных закрытых M5-бара:
   - 20:05: AS3=110.47413309
   - 20:10: AS3=111.94136535
   - 20:15: AS3=113.35382715
   - 20:20: AS3=114.84906672
   На всех строках: `spread_ok=true`, `open_positions=0`, `daily_block=false`, `trading_lock=1`.
   WARN/ERROR отсутствуют.

## Безопасность

Торговля на этой контрольной точке **заблокирована намеренно**.

- `trading_lock=1`
- `cfg.enabled=false`

Контрольная точка не должна использоваться для реального открытия сделок.

## Stage 6 — следующий этап

Следующий этап: **MTF Wave Provider**. Компиляция Stage 6 подтверждена: **PASS, 0 errors / 0 warnings, 211 ms**.

Принцип:
- `AS_Waves` остаётся единственным источником волновой математики;
- provider получает значения `AS0..AS4` через `iCustom` на явно заданном timeframe;
- никаких новых формул Butterworth/AS3 в EA не создаётся;
- до доказательства точного соответствия не присваивать произвольные timeframe полям `short_trend`, `medium_trend`, `long_trend`, `basic`;
- торговля остаётся заблокирована.

## Что ещё не считается достоверно восстановленным

- точная формула `SWTsr` каналов;
- `sig_rank`;
- `as_pipeline` из спорной Fibonacci-ветки;
- окончательное соответствие всех уровней `AS_TrendHierarchy` конкретным timeframe;
- включение реальной торговли.

Fibonacci-логика не объявляется частью канонического SWT без отдельного доказательства.


## AS specification checkpoint — 2026-10-04

Создан и закреплён новый доказательный слой Andreslaw:

- `docs/AS_CANONICAL_ARCHITECTURE_RU.md`
- `docs/AS_REQUIREMENTS.csv`
- `docs/AS_TREND_4_8_SPEC_RU.md`
- `docs/AS_TREND_4_8_TEST_MATRIX.csv`

Правило проекта:
`SOURCE -> REQUIREMENT -> CODE -> UNIT TEST -> COMPILE -> RUNTIME -> INTEGRATION`.

### Trend 4..8 — source checkpoint

Подтверждено по первичным материалам SWT:

- Basic=8, Long=7, Medium=6, Short=5, Weekly=4 образуют группу Trend;
- TrendVector ограничен 4..8;
- non-adaptive режим использует согласование всех выбранных уровней;
- adaptive v3.3 использует старший направленный Trend;
- при коррекции всех старших уровней направление задаёт Weekly;
- DominantCorrection — отдельная блокировка новых входов;
- ContrTrend инвертирует результирующий Trend, но не Pattern.

Выявлен version drift между старой SWT_Robot и v3.3:
- legacy DominantTrend;
- legacy ReverseReadyToTrade;
- не доказан порядок DominantCorrection + ContrTrend.

Эти пункты оставлены в QUARANTINE и не должны додумываться.

### Stage 6 runtime
Stage 6 FIX1 — **PASS**.
Подтверждено 2026-10-05 на `BTCUSD,M5`:
- current-TF closed-bar series — PASS:
  - AS3=663.63134830
  - prev=659.64566545
  - old=655.42240511
  - shifts 1/2/3 подтверждены;
- MTF source smoke — PASS:
  - H1 AS3=3637.05721677
  - D1 AS3=28340.63195201
  - W1 AS3=28117.88277264;
- единственный источник волновой математики — `AS_Waves`;
- первоначальный `ERR_NO_HISTORY_DATA` был связан с первичной загрузкой истории H1/D1/W1 и исчез после её подготовки;
- `trading_lock=1`;
- `cfg.enabled=false`.
### Stage 7 — Trend 4..8
Создан `AS_Trend48SelfTest.mq4`.
Первый прогон обнаружил один production-дефект:
- `AS-TR-028`: adaptive mode пропускал невалидный обязательный старший уровень вместо fail-closed;
- исходный результат: `PASS=23 FAIL=1 TOTAL=24`.
В `sig_trend.mqh` выполнено минимальное исправление:
невалидный обязательный уровень в adaptive-ветке теперь возвращает `AS_DIR_NO`.
Контрольный повтор:
- `PASS=24`
- `FAIL=0`
- `TOTAL=24`
Trend 4..8 считается подтверждённым по цепочке:
`SOURCE -> REQUIREMENT -> CODE -> UNIT TEST -> FIX -> REGRESSION PASS`.
### ASO Lilit
ASO Lilit должен отражать новое состояние:
- Stage 6 runtime — PASS;
- Trend 4..8 — 24/24 PASS;
- historical FAIL сохраняется как история;
- pending runtime для Stage 6 отсутствует;
- trading остаётся LOCKED.
Следующий исследовательский шаг:
после закрытия Stage 6 и Trend 4..8 определить следующий доказанный участок SWT/Andreslaw по `AS_REQUIREMENTS.csv`; неподтверждённые соответствия timeframe и QUARANTINE-правила не додумывать.
Торговля остаётся **LOCKED** до завершения восстановительного и интеграционного контура.