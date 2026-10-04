# ANDRESLAW — текущее состояние восстановления

Дата контрольной точки: **2026-10-04**
Статус: **RECOVERY STAGE 5 / SAFE RUNTIME CHECKPOINT**

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

## Безопасность

Торговля на этой контрольной точке **заблокирована намеренно**.

- `trading_lock=1`
- `cfg.enabled=false`

Контрольная точка не должна использоваться для реального открытия сделок.

## Что пока НЕ подтверждено

Полный new-bar runtime путь:

`OnTick -> новый M5 бар -> WaveProvider -> iCustom -> AS_Waves -> AS3 -> интегрированное ядро`

не был подтверждён 2026-10-04, потому что после установки EA на `BTCUSD,M5` не поступил новый бар/поток тиков. Это **NOT_RUN**, а не FAIL.

## Что ещё не считается достоверно восстановленным

- точная формула `SWTsr` каналов;
- `sig_rank`;
- `as_pipeline` из спорной Fibonacci-ветки;
- полный многотаймфреймовый provider и окончательная иерархия трендов;
- включение реальной торговли.

Fibonacci-логика не объявляется частью канонического SWT без отдельного доказательства.
