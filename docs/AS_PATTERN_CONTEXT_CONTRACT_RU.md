# AS — PatternContext / PatternState contract
Дата: 2026-10-05
Статус: DESIGN / NO PRODUCTION CHANGE
## 1. Назначение
AS-PATTERN-002 требует временного контекста.
Текущего:
AS_TrendState(direction, correction, valid)
недостаточно, потому что Pattern зависит не только от текущего состояния,
но и от последовательности изменений W2/W3/W4 во времени.
Этот документ определяет минимальный контракт данных.
Он НЕ определяет торговые thresholds и НЕ изменяет sig_pattern.mqh.
## 2. Семантические роли
В Pattern используются три роли:
- W2 = Hourly role;
- W3 = IDay role;
- W4 = Daily role.
ВАЖНО:
Это семантические роли Pattern.
Пока НЕ доказано, что W2/W3/W4 должны напрямую соответствовать
буферам AS2/AS3/AS4 индикатора AS_Waves.
Прямую привязку к AS0..AS4 не кодировать до отдельного доказательства.
## 3. Минимальная история одной роли
Для каждой роли Pattern необходимо хранить минимум три закрытых наблюдения:
- current_closed;
- previous_closed;
- older_closed.
Из них без произвольных thresholds можно вычислить:
- текущий знак;
- предыдущий знак;
- текущий slope;
- предыдущий slope;
- zero-cross UP;
- zero-cross DOWN;
- change-of-direction UP;
- change-of-direction DOWN.
Формирующийся бар не используется.
## 4. PatternWaveContext
Предварительный логический контракт:
PatternWaveContext
- valid
- current_closed
- previous_closed
- older_closed
- sign_current
- sign_previous
- slope_current
- slope_previous
- crossed_zero_up
- crossed_zero_down
- turned_up
- turned_down
Все поля должны быть получены только из закрытых данных.
## 5. PatternContext
Минимальный PatternContext содержит:
PatternContext
- hourly
- iday
- daily
- previous_pattern_state
- previous_pattern_direction
- valid
где hourly / iday / daily являются PatternWaveContext.
## 6. PatternState
Минимальные состояния:
PATTERN_NEUTRAL
PATTERN_REVERSAL_CANDIDATE
PATTERN_REVERSAL_CONFIRMED
PATTERN_RECOVERY
Направление состояния хранится отдельно:
AS_DIR_UP
AS_DIR_DN
AS_DIR_NO
Это позволяет не дублировать состояния
REVERSAL_UP / REVERSAL_DOWN отдельными кодами.
## 7. Что сознательно НЕ входит в contract v0
Пока не добавлять:
- near_zero boolean;
- near_high boolean;
- near_low boolean;
- fixed distance threshold;
- fixed bar window;
- attempt_count;
- channel confirmation;
- volatility threshold;
- extremum confirmation boolean.
Причина:
формулы или thresholds этих понятий пока не доказаны.
## 8. Будущий слой измеряемых признаков
Качественные понятия будут формализоваться отдельным feature-layer.
Примеры будущих непрерывных измерений:
- zero_distance;
- normalized_zero_distance;
- distance_to_recent_high;
- distance_to_recent_low;
- normalized_extremum_distance;
- bars_since_high;
- bars_since_low.
Сначала сохраняется измеряемая величина.
Только после calibration допускается превращение её в boolean condition.
## 9. Fail-closed правило
Если обязательный источник hourly / iday / daily:
- отсутствует;
- содержит invalid number;
- не имеет необходимой истории закрытых наблюдений;
то PatternContext.valid = false.
При invalid PatternContext:
Pattern = AS_DIR_NO.
Никаких пропусков отсутствующего обязательного уровня.
## 10. Следующий этап
До production-кода необходимо создать:
AS_PATTERN_CONTEXT_MATRIX.csv
и проверить контракт на synthetic cases:
- signs;
- slopes;
- zero-cross;
- turns;
- invalid history;
- fail-closed behavior.
Только после PASS этой матрицы допускается создание
структур PatternContext в contracts.mqh.
sig_pattern.mqh пока НЕ менять.
