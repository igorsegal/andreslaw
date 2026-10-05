# AS — Pattern State Machine Specification
Дата: 2026-10-05
Статус: DESIGN / PARTIALLY PROVEN / NO PRODUCTION CHANGE
## 1. Назначение
Документ описывает временную модель полного Pattern для AS-PATTERN-002.
Он строится поверх уже проверенного PatternContext.
Production sig_pattern.mqh пока НЕ менять.
## 2. Состояния
PATTERN_NEUTRAL
PATTERN_REVERSAL_CANDIDATE
PATTERN_REVERSAL_CONFIRMED
PATTERN_RECOVERY
Направление хранится отдельно:
AS_DIR_UP
AS_DIR_DN
AS_DIR_NO
## 3. Fail-closed
Если PatternContext.valid = false:
state = PATTERN_NEUTRAL
direction = AS_DIR_NO
Никакое предыдущее активное состояние не должно автоматически
производить торговый Pattern при отсутствии обязательных данных.
## 4. REVERSAL_CANDIDATE
Источник подтверждает следующее ядро:
- Daily-role W4 меняет направление в зоне экстремума;
- IDay-role W3 имеет тот же исходный знак и движется к нулю;
- Hourly-role W2 уже пересекла ноль в направлении предполагаемого разворота.
Из этих признаков:
ДОКАЗАНО БЕЗ THRESHOLD:
- change-of-direction W4;
- знак W3;
- направление W3;
- zero-cross W2.
ПОКА НЕ ДОКАЗАНО ЧИСЛЕННО:
- "W4 в зоне экстремума";
- "W3 достаточно близко к нулю".
Следовательно REVERSAL_CANDIDATE пока нельзя полностью активировать
в production без feature-layer для этих двух условий.
## 5. REVERSAL_CONFIRMED
Доказанное продолжение reversal:
- W3 меняет полуплоскость;
- W4 меняет полуплоскость;
- направление этих изменений совпадает с направлением reversal.
Это состояние означает подтверждённый разворот Pattern-сценария.
Точный порядок переходов W3/W4 пока должен быть проверен отдельной матрицей.
## 6. RECOVERY
Recovery возможен только после ранее сформированного reversal-сценария.
Доказанное ядро:
- W4 остаётся в исходной полуплоскости;
- W2 и W3 возвращаются в исходную полуплоскость
  и/или
- W4 снова начинает двигаться в исходном направлении.
Recovery отменяет разворотный сценарий
и возвращает Pattern в сторону исходного движения.
## 7. Предварительная transition graph
PATTERN_NEUTRAL
-> PATTERN_REVERSAL_CANDIDATE
PATTERN_REVERSAL_CANDIDATE
-> PATTERN_REVERSAL_CONFIRMED
PATTERN_REVERSAL_CANDIDATE
-> PATTERN_RECOVERY
PATTERN_REVERSAL_CONFIRMED
-> PATTERN_RECOVERY
PATTERN_RECOVERY
-> PATTERN_NEUTRAL
## 8. Что пока нельзя превращать в production boolean
Не кодировать произвольно:
- W4_NEAR_EXTREMUM
- W3_NEAR_ZERO
- attempt_count
- first_attempt / second_attempt
- fixed bar lifetime
- extremum confirmation
- channel confirmation
- volatility threshold
Эти признаки должны пройти отдельную formalization/calibration фазу.
## 9. Что можно тестировать уже сейчас
Можно создать state-transition matrix только для тех переходов,
где используются объективные события PatternContext:
- zero-cross;
- sign change;
- slope change;
- previous state;
- valid / invalid context.
Такие тесты должны проверять:
- направление перехода;
- невозможные переходы;
- fail-closed;
- recovery только после reversal-сценария;
- отсутствие прямого NEUTRAL -> CONFIRMED;
- отсутствие Pattern при invalid context.
## 10. Следующий этап
Создать:
AS_PATTERN_STATE_TRANSITION_MATRIX.csv
Но строки, зависящие от:
W4_NEAR_EXTREMUM
W3_NEAR_ZERO
пометить:
UNRESOLVED_SELECTOR
а не подставлять искусственные thresholds.
До завершения этой матрицы:
AS-PATTERN-002 = MISSING / RESEARCH
sig_pattern.mqh НЕ менять.
