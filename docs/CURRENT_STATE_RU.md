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
