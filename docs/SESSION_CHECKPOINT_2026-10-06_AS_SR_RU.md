# SESSION CHECKPOINT — 2026-10-06
## ANDRESLAW / SWT research / AS_sr
Предыдущий опубликованный checkpoint:
a9630d5 — research: checkpoint AS Channel 01 comparison
---
## 1. SWTch — исследование центра канала
Подтверждено black-box тестами на EURUSD,H1.
Буферы SWTch W4 ранее установлены:
- 14 = chw4:H
- 15 = chw4:L
- 20 = chw4:cl
Сравнение AS_Channel_01 с SWTch W4 показало:
- SWTch W4 значительно шире исходного AS_Channel_01;
- отношение ширин около 5.15 на исследованном участке;
- центр SWTch движется существенно медленнее исходного AS_Channel_01.
Проверена гипотеза Fixed EMA.
AS_FixedEMA_01:
- causal / non-repainting на закрытых барах;
- bar 0 может меняться только пока формируется;
- self-test recurrence PASS 100/100;
- deterministic signature на 100 закрытых H1 барах:
  checksum=112.936455715924
  weighted=5715.968949564114
Сравнение Fixed EMA с SWTch center:
- period 20  MAE ~0.0090
- period 50  MAE ~0.0078
- period 100 MAE ~0.0061
- period 200 MAE ~0.0035
- period 377 MAE ~0.00060
- period 400 MAE ~0.00032
- period 610 MAE ~0.00152
EMA400 оказался лучшим из проверенных кандидатов, но НЕ доказано,
что SWTch center является буквально EMA400.
Center-law probe:
alpha400 = 0.004987531172
Для 500 H1 баров:
CLOSE:
mean_alpha=0.004562326993
std_alpha=0.001770075517
WEIGHTED:
mean_alpha=0.004650784744
std_alpha=0.001478397029
Вывод:
SWTch center EMA-подобен по динамике, но не является доказанной
одноступенчатой EMA от стандартного price source.
---
## 2. SWTsr — black-box исследование S/R
Inputs оригинального SWTsr:
- ShowLevelsForW2
- ShowStopLossSR
Ключевые W4 буферы установлены точно:
- mode 34 = srw4:R
- mode 35 = srw4:S
- mode 42 = srw4:cl
На 500 закрытых EURUSD,H1 баров:
validPairs=500
flatPairs=457
changePairs=43
CHANGES:
R=43
S=43
BOTH=43
Все 43 изменения пары W4 произошли после строгого пробоя
предыдущей границы на предыдущем баре:
CHANGE_STRICT:
sameBar=33
prevBar=43
twoBar=43
При этом обнаружено:
strictBreakWhileUnchanged=15
Вывод:
пробой старой границы является необходимым условием смены W4-пары
на исследованном участке, но простой High>R / Low<S недостаточен.
Визуально SWTsr представляет собой ступенчатую событийную структуру:
фиксированная пара -> пробой -> новая фиксированная пара.
---
## 3. AS_sr — собственная геометрия Support / Resistance
Принято проектное правило:
AS_sr — собственная прозрачная реализация, НЕ копия SWTsr.
Основные законы:
1. Работа по закрытым барам.
2. Тени не переключают состояние.
3. BREAK UP:
   Close > Resistance.
4. BREAK DOWN:
   Close < Support.
5. Экстремум геометрии строится по телу:
   BodyHigh = max(Open,Close)
   BodyLow  = min(Open,Close)
6. Уровни между событиями фиксированы.
7. Объем не участвует в геометрии.
8. PeakRange в текущей PROJECT_FORMALIZATION:
   max(High-Low) на рассматриваемом участке.
9. Противоположная граница строится через PeakRange.
10. Никакого repaint закрытой истории.
### AS_sr geometry
Файлы:
- MQL4/Include/AS/AS_sr_geometry.mqh
- MQL4/Experts/AS_sr_GeometrySelfTest.mq4
Проверены:
- wick-only no breakout;
- Close breakout up/down;
- BodyHigh / BodyLow;
- PeakRange;
- MaxBodyHigh / MinBodyLow;
- BuildPair UP / DOWN;
- one-bar body-extremum confirmation.
Финальный результат:
checked=19
failed=0
PASS
### AS_sr state machine
Файлы:
- MQL4/Include/AS/AS_sr_state.mqh
- MQL4/Experts/AS_sr_StateSelfTest.mq4
Фазы:
- AS_SR_ACTIVE
- AS_SR_SEEK_HIGH
- AS_SR_SEEK_LOW
Проверены обе симметричные ветки:
ACTIVE -> BREAK -> SEEK -> candidate -> confirmation -> new pair -> ACTIVE
Финальный результат:
checked=14
failed=0
PASS
---
## 4. Первый индикатор AS_sr
Создан:
MQL4/Indicators/AS/AS_sr.mq4
Первый runtime на EURUSD,H1 состоялся.
Обнаружена визуальная архитектурная проблема:
во время AS_SR_SEEK_HIGH / AS_SR_SEEK_LOW candidate уже меняется
в state machine, но индикатор его не отображает.
Следовательно текущая версия визуально запаздывает:
после подтвержденного Close-пробоя новая активная сторона должна быть
видна уже с открытия следующего bar 0.
Важно:
bar 0 не используется для подтверждения события, потому что он формируется.
Только что закрывшийся bar 0 становится bar 1.
Результат решения по bar 1 должен отображаться сразу на новом bar 0.
---
## 5. Следующая версия визуализации AS_sr
Планируется 4 визуальных буфера:
- AS_sr:R
- AS_sr:S
- AS_sr:Rguide
- AS_sr:Sguide
Во время SEEK:
SEEK_HIGH:
- Rguide = текущий candidate BodyHigh
- противоположная guide-граница рассчитывается по геометрии
SEEK_LOW:
- Sguide = текущий candidate BodyLow
- противоположная guide-граница рассчитывается по геометрии
Это НЕ SWTch и не "живой канал".
Это визуальное сопровождение эволюции S/R.
---
## 6. Инерция / hysteresis — новая рабочая гипотеза
Чтобы AS_sr не реагировал на каждый новый локальный high/low,
обсуждается порог перестройки относительно ширины текущего диапазона:
W = Resistance - Support
Кандидат первой версии:
K = 0.50
Идея для движения UP:
- Resistance/candidate может сопровождать движение;
- старая Support удерживается;
- Support разрешается перестроить только после продвижения
  цены не менее чем на K*W.
Зеркально для DOWN.
Также предложен ratchet-принцип:
- в UP Support может только подниматься;
- в DOWN Resistance может только опускаться.
K=0.50 пока НЕ заморожен.
Перед фиксацией желательно измерить реальное отношение ширин:
SWTsr W4 против AS_sr на одинаковых 500 барах.
---
## 7. Что НЕ завершено
1. Не завершена визуализация Rguide/Sguide.
2. Не измерено распределение SWTsr_width / AS_sr_width.
3. K=0.50 является исследовательской гипотезой.
4. Формула SWTch остается открытой исследовательской задачей.
5. Никакой торговой логики к AS_sr пока не подключать.
6. Автоторговля по этой ветке не разрешена.
---
## STATUS
AS_sr geometry: PASS 19/19
AS_sr state machine: PASS 14/14
AS_sr indicator: FIRST RUNTIME PASS, VISUAL GUIDE FIX REQUIRED
SWTsr W4 black-box behavior: RESEARCH PASS
SWTch center / FixedEMA: RESEARCH CHECKPOINT
TRADING: LOCKED
Следующая сессия:
1. Rguide/Sguide;
2. SWTsr vs AS_sr width measurement;
3. проверить hysteresis K относительно W;
4. после этого заморозить AS_sr v1 geometry.


---
## 8. Width measurement — 2026-10-08

Probe:
- MQL4/Experts/AS_SWTsr_ASsrWidthProbe.mq4
- EURUSD,H1
- 500 closed bars

Coverage:
- SWTsr valid: 500/500
- AS_sr ACTIVE: 321
- AS_sr GUIDE/SEEK: 179
- AS_sr invalid: 0
- effective AS_sr coverage: 500/500

Mean widths:
- ACTIVE overlap:
  - SWTsr = 0.02641738
  - AS_sr = 0.00263424
  - SWTsr / AS_sr = 10.028477
- EFFECTIVE (ACTIVE + GUIDE):
  - SWTsr = 0.02624302
  - AS_sr = 0.00227088
  - SWTsr / AS_sr = 11.556322

Ratio distribution SWTsr_width / AS_sr_width:
- ACTIVE: mean=13.579390; median=11.722222; p25=7.368201; p75=16.299363
- EFFECTIVE: mean=16.656413; median=13.866142; p25=7.686901; p75=21.105263
- EFFECTIVE range: 2.504551 .. 83.857143

Conclusion:
- current AS_sr is materially narrower than SWTsr W4 on the tested segment;
- this does NOT prove that AS_sr should copy SWTsr width;
- K=0.50 is still only a hypothesis and must not be frozen from the width ratio alone;
- next research step is a hysteresis sweep / event-persistence study before changing production geometry.
