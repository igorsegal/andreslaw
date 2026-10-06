# SESSION CHECKPOINT — 2026-10-06
## Статус
Исследовательская сессия остановлена штатно.
Торговая интеграция НЕ выполнялась.
AS_Channel_01 остаётся RESEARCH / PROJECT_FORMALIZATION.
## AS_Channel_01 — baseline
Файл:
MQL4/Indicators/AS/AS_Channel_01.mq4
Исходная модель:
CENTER = EMA(Close, N)
VOLATILITY =
standard deviation исторических residual:
Close - EMA
INNER:
CENTER +/- K1 * VOLATILITY
OUTER:
CENTER +/- K2 * VOLATILITY
Исследовательские параметры:
CenterPeriod=20
VolatilityWindow=50
InnerK=2.0
OuterK=3.0
Буферы:
0 CENTER
1 INNER_HIGH
2 INNER_LOW
3 OUTER_HIGH
4 OUTER_LOW
Компиляция:
0 errors
0 warnings
Runtime EURUSD,H1:
rates_total=179117
test_ok=true
center=1.12153188
sigma=0.00184155
B0=1.12153188
B1=1.12521499
B2=1.11784878
B3=1.12705654
B4=1.11600723
Индикатор успешно рисует пять линий на графике.
## Сравнение с SWTch W4
Файл:
MQL4/Experts/AS_Channel01CompareProbe.mq4
После исправления вызова SWTch на явный PERIOD_H1:
SUMMARY:
valid=500
invalid=0
RAW:
SWT_H=1.15776774
SWT_L=1.12138938
OUR_H=1.12521499
OUR_L=1.11784878
Средняя ширина за 500 H1 баров:
SWT=0.02244068
OUR=0.00435418
OUR_DIV_SWT=0.1940
То есть baseline AS_Channel_01 примерно в 5.15 раза уже SWTch.
POSITION:
center_MAE=0.00888896
high_MAE=0.01723131
low_MAE=0.00365464
Среднее абсолютное изменение границы на бар:
SWT_H=0.00002459
SWT_L=0.00006735
OUR_H=0.00011610
OUR_L=0.00013323
Вывод:
AS_Channel_01 baseline не является функциональным аналогом SWTch.
Он существенно уже и его границы двигаются заметно быстрее.
Простое увеличение K не считается достаточным решением:
оно изменит ширину, но не архитектуру и динамику канала.
## SWTch center
Подтверждённый буфер:
20 = chw4:cl
В AS_Channel01CompareProbe уже добавлена функция SWT_C().
СЛЕДУЮЩИЙ ШАГ:
измерить геометрию SWTch относительно собственного center:
upper_from_CL = chw4:H - chw4:cl
lower_from_CL = chw4:cl - chw4:L
Цель:
объективно определить асимметрию верхней и нижней частей SWTch.
ШАГ с расчётом SWT_SHAPE ещё НЕ выполнен.
## Важное
Не оптимизировать AS_Channel_01 глазами.
Не подбирать K под один участок EURUSD.
Не интегрировать канал в торговую логику.
Сначала:
SWT_SHAPE -> архитектура Channel_02 -> объективное сравнение -> out-of-sample.
Trading remains locked.
