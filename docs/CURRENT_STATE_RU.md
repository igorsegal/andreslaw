# ANDRESLAW — текущее состояние восстановления

Дата контрольной точки: **2026-10-04**
Статус: **RECOVERY STAGE 5 COMPLETE / NEW-BAR PIPELINE VERIFIED**

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

Stage 6 FIX1:
- compile PASS: 0 errors / 0 warnings;
- init PASS;
- current-TF runtime read остаётся PENDING до нового M5 тика/бара;
- H1/D1/W1 smoke оценивается только после восстановления current-TF runtime.

### ASO Lilit

ASO Lilit обновлён:
- знает AS canonical architecture;
- читает AS_REQUIREMENTS.csv;
- отслеживает AS Trend 4..8 spec/matrix;
- различает historical FAIL и текущий PENDING;
- MCP предоставляет requirements_status;
- trading остаётся LOCKED.

Следующий исследовательский шаг:
реализовать self-test для `AS_TREND_4_8_TEST_MATRIX.csv` до изменения production `sig_trend.mqh`.
