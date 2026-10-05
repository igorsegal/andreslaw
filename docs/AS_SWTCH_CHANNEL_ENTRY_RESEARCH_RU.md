# AS — SWTch W4 Channel Entry Research
Дата: 2026-10-05
Статус: RESEARCH / RUNTIME VERIFIED
Инструмент:
EURUSD,H1
Окно:
500 закрытых H1-баров
Источник границ:
SWTch.ex4
Буферы:
mode 14 = chw4:H
mode 15 = chw4:L
## Эксперимент 1 — occupancy
Условие:
UPPER_OCCUPANCY:
High >= chw4:H
LOWER_OCCUPANCY:
Low <= chw4:L
Результат первого прогона:
valid=500
upper_hits=0
lower_hits=181
Вывод:
простое нахождение цены за границей канала не является отдельным
экстремальным событием, потому что один выход может давать много
последовательных hit-баров.
## Эксперимент 2 — first entry
LOWER_ENTRY:
previous Low > previous chw4:L
AND
current Low <= current chw4:L
UPPER_ENTRY:
previous High < previous chw4:H
AND
current High >= current chw4:H
Результат после прогрева SWTch:
valid=500
invalid=0
upper_occupancy=0
lower_occupancy=184
upper_entries=0
lower_entries=12
total_entries=12
184 lower occupancy bars collapsed to 12 distinct channel-entry events.
Контрольный визуальный бар:
2026.10.02 18:00
Low=1.12539
chw4:L=1.12627
lower_entry=true
Этот бар ранее был независимо подтвержден через MT4 Data Window.
## Cold-start finding
Первый запуск ChannelEntryProbe:
valid=0
invalid=500
Повторный запуск после прогрева SWTch:
valid=500
invalid=0
Следовательно, SWTch iCustom history requires warm-up before
historical scan. Research probes must handle this explicitly before
being considered reproducible.
## Current interpretation
W4 CHANNEL_ENTRY is an objective PROJECT_FORMALIZATION candidate.
It is stronger than simple channel occupancy because it describes
the first transition from inside to outside the W4 channel.
It is NOT yet claimed to be equivalent to the author's full
"W4 in extremum/channel zone" condition.
Next evidence required:
verify whether W4 direction turn occurs at or around these distinct
channel-entry events.
Production sig_pattern.mqh remains unchanged.
AS-PATTERN-002 remains not closed.
