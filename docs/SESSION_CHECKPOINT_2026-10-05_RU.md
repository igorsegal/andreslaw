# ANDRESLAW — CHECKPOINT 2026-10-05
## Общий статус
Работа остановлена на исследовании полного Pattern 1..3 / AS-PATTERN-002.
Production trading logic НЕ изменялась.
Критические ограничения сохраняются:
- trading_lock = 1
- cfg.enabled = false
- sig_pattern.mqh не менять до полного доказательства AS-PATTERN-002
- неизвестная семантика остается QUARANTINE
- без look-ahead
- только закрытые бары
Методология:
SOURCE -> REQUIREMENT -> CODE -> UNIT TEST -> COMPILE -> RUNTIME -> INTEGRATION
---
# 1. Pattern Context
Создан и проверен PatternContext:
- sign
- slope
- zero cross
- turn up/down
- fail-closed validity
Runtime:
PASS=20
FAIL=0
TOTAL=20
Определение turn:
slope_current  = sign(current - previous)
slope_previous = sign(previous - older)
turn_up:
slope_previous <= 0 AND slope_current > 0
turn_down:
slope_previous >= 0 AND slope_current < 0
AS-PATTERN-002 этим тестом НЕ закрыт.
---
# 2. Pattern State Machine
Объективно доказанная часть state transition:
PASS=11
FAIL=0
TOTAL=11
Позднее модель была уточнена по источнику.
Корректная концепция:
PATTERN_NEUTRAL
    ->
REVERSAL_PATTERN_FORMED
    ->
    ACTUAL_TREND_REVERSAL
    OR
    RECOVERY_PATTERN
ACTUAL_TREND_REVERSAL и RECOVERY_PATTERN —
альтернативные исходы после reversal pattern,
а не последовательные состояния.
Reset/lifecycle обратно в NEUTRAL пока source-unproven.
AS-PATTERN-002 остается открытым.
---
# 3. SWT indicators found
Доступны оригинальные compiled indicators Nicholas Skrigan:
- SWTch.ex4
- SWTsr.ex4
- SWTtr.ex4
SWTch исследован black-box методом.
Декомпиляция НЕ использовалась.
---
# 4. SWTch inputs
Подтвержденные Inputs:
W2_CH          = false
W3_SR          = false
W4_SR          = false/true
ShowCenterLine = false
При W4_SR=true активируются W4 support/resistance buffers.
---
# 5. SWTch buffer map — RUNTIME VERIFIED
Через MT4 Data Window + iCustom probe установлена карта:
mode 10 = chw2:H
mode 11 = chw2:L
mode 12 = chw3:H
mode 13 = chw3:L
mode 14 = chw4:H
mode 15 = chw4:L
mode 16 = chw3:R
mode 17 = chw3:S
mode 18 = chw4:R
mode 19 = chw4:S
mode 20 = chw4:cl
mode 21 = chw3:cl
mode 22 = chw2:cl
mode 23 = rlw4
mode 24 = rlw3
mode 25 = rlw2
Internal buffers 0..9 пока не именовать.
Observed alias:
mode 3 == mode 20 == chw4:cl
на контрольном баре.
---
# 6. Control bar
EURUSD,H1
2026.10.01 10:00
chw4:H = 1.16008149
chw4:L = 1.13078774
chw4:R = 1.16013438
chw4:S = 1.10192145
chw4:cl = 1.14534096
На этом баре цена находилась ниже lower W4 channel boundary.
---
# 7. Simple channel occupancy test
Исходная гипотеза:
UPPER:
High >= chw4:H
LOWER:
Low <= chw4:L
500 закрытых H1-баров:
valid=500
invalid=0
upper_hits=0
lower_hits=181
both_hits=0
Вывод:
Простое нахождение цены за границей канала
НЕ является отдельным событием экстремума.
Один выход за канал может создавать длинную
последовательность hit-bars.
Эта простая формализация отвергнута.
---
# 8. Channel Entry test
Введено первое событие входа изнутри наружу.
LOWER_ENTRY:
previous Low > previous chw4:L
AND
current Low <= current chw4:L
UPPER_ENTRY:
previous High < previous chw4:H
AND
current High >= current chw4:H
После прогрева SWTch:
valid=500
invalid=0
upper_occupancy=0
lower_occupancy=184
upper_entries=0
lower_entries=12
total_entries=12
То есть 184 lower-occupancy bars
схлопнулись в 12 отдельных entry episodes.
Это объективный PROJECT_FORMALIZATION candidate,
но НЕ доказанный полный эквивалент авторского
"W4 in extremum/channel zone".
---
# 9. SWTch cold start
Первый запуск ChannelEntryProbe:
valid=0
invalid=500
Повторный запуск после прогрева SWTch:
valid=500
invalid=0
Вывод:
SWTch через iCustom требует warm-up.
Исторические probes должны учитывать это явно.
---
# 10. Canonical AS wave source
wave_provider.mqh:
Single source of truth:
Indicators\AS\AS_Waves.ex4
Provider:
AS_WaveProvider
Публичный API:
GetWaveValueTF(
    timeframe,
    waveIndex,
    shift,
    outValue
)
Для AS3:
GetClosedAS3TF(...)
GetClosedAS3SeriesTF(...)
GetClosedAS3SeriesTF возвращает:
shift 1
shift 2
shift 3
закрытых баров.
---
# 11. Existing Daily path
Andreslav_AS.mq4 уже использует:
g_provider.GetClosedAS3TF(PERIOD_D1, as3_d1)
Следовательно, D1 AS3 является существующим
каноническим MTF path проекта.
Новый источник для D1 создавать НЕ нужно.
---
# 12. Historical causal D1 probe
Создан:
AS_SWTchD1TurnProbe.mq4
Цель:
для каждого исторического H1 CHANNEL_ENTRY:
H1 event time
    ->
latest D1 bar already CLOSED at that time
    ->
historical D1 AS3 values
    ->
turn calculation
Без look-ahead.
---
# 13. D1 history
EURUSD D1 history:
D1_BARS=13984
AS_Waves требует:
rates_total >= 50
Следовательно, нехватка D1 history исключена.
---
# 14. AS_Waves raw buffers
AS_Waves:
RawAS0 buffer 6
RawAS1 buffer 7
RawAS2 buffer 8
RawAS3 buffer 9
RawAS4 buffer 10
process_bar writes:
RawAS0[b]
RawAS1[b]
RawAS2[b]
RawAS3[b]
RawAS4[b]
RawAS3 therefore существует как отдельный exported raw buffer.
---
# 15. Timer / warm-up diagnostics
EventSetTimer(3) используется.
Диагностика TIMER_ENTER подтвердила:
OnTimer реально вызывается.
TRACE instrumentation использовалась только
для локализации readiness/cold-start.
Эти TRACE строки не являются production logic.
---
# 16. CHANNEL_ENTRY + D1 AS3 TURN runtime result
EURUSD,H1
500 H1 closed bars
SUMMARY:
valid_channel=500
invalid_channel=0
upper_entries=0
lower_entries=12
total_entries=12
d1_valid=12
d1_invalid=0
d1_turn_up=0
d1_turn_down=0
aligned_lower_turn_up=0
aligned_upper_turn_down=0
aligned_total=0
То есть:
12 / 12 channel-entry events
имели корректный historical D1 AS3 context,
но:
0 / 12 имели D1 AS3 turn в момент события.
---
# 17. Interpretation
Конкретная гипотеза:
SWTch W4 CHANNEL_ENTRY
+
immediate D1 AS3 TURN
НЕ подтверждена.
Результат:
0 из 12.
Это НЕ означает, что авторский reversal pattern опровергнут.
Это означает только:
D1 AS3 immediate turn
не является подтвержденным эквивалентом
авторской формулировки
"W4 turns in extremum/channel zone".
---
# 18. Important semantic caution
НЕ считать автоматически:
semantic W4 == internal AS4
или
semantic W4 == D1 AS3
без source/runtime proof.
Ранее уже установлено:
семантические W2/W3/W4
нельзя автоматически приравнивать к
AS2/AS3/AS4 buffer indexes.
---
# 19. Current strongest open question
Главный нерешенный вопрос:
Как объективно определить авторское:
"W4 развернулась / находится
в экстремальной канальной зоне"?
CHANNEL_ENTRY является полезным объективным событием,
но само по себе еще не закрывает эту семантику.
---
# 20. Next session
Следующий шаг НЕ должен быть:
- подбор N дней после entry
- подбор arbitrary tolerance
- ATR multiplier
- percentage distance
- оптимизация threshold
Это создало бы риск подгонки.
Следующий источник исследования:
SWTtr.ex4
Человеческий вопрос:
"Что SWTtr считает трендом
и показывает ли он непосредственно тот момент
разворота, который автор связывает с W4?"
После SWTtr:
при необходимости исследовать SWTsr.ex4
как независимый support/resistance source.
Желательный порядок:
1. SWTtr Inputs
2. SWTtr Data Window
3. SWTtr exported buffers
4. black-box iCustom map
5. сравнение SWTtr reversal events с 12 SWTch CHANNEL_ENTRY
6. только после этого решать формализацию W4_IN_EXTREMUM_CHANNEL_ZONE
---
# 21. Production state
НЕ ИЗМЕНЕНО:
sig_pattern.mqh
Trading остается locked.
AS-PATTERN-002 остается:
OPEN / RESEARCH
До нового evidence production integration не делать.
