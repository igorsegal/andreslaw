# AS — Pattern State Model v2
Дата: 2026-10-05
Статус: DESIGN CORRECTION / NO PRODUCTION CHANGE
## 1. Причина пересмотра
Предыдущая модель смешивала:
1. сформированный торговый reversal-pattern;
2. фактически состоявшийся разворот тренда;
3. recovery исходного тренда.
Дополнительный source-audit показал, что пункты 2 и 3
являются альтернативными исходами после сформированного Pattern.
## 2. Новая модель
PATTERN_NEUTRAL
-> REVERSAL_PATTERN_FORMED
после чего возможны два альтернативных исхода:
REVERSAL_PATTERN_FORMED
-> ACTUAL_TREND_REVERSAL
или
REVERSAL_PATTERN_FORMED
-> RECOVERY_PATTERN
## 3. REVERSAL_PATTERN_FORMED
Формируется при согласовании роли W2/W3/W4.
Объективные части:
- W2 zero-cross в направлении предполагаемого разворота;
- W3 zero-cross в том же направлении;
- W4 change-of-direction в направлении предполагаемого разворота.
Остающийся качественный selector:
- W4_IN_EXTREMUM_CHANNEL_ZONE.
Без доказанной формализации этого selector
production Pattern не активировать.
## 4. ACTUAL_TREND_REVERSAL
После сформированного reversal-pattern:
- W3 уже находится в новой полуплоскости;
- W4 также пересекает нулевую линию
  в направлении reversal.
Это означает фактически состоявшийся разворот соответствующего тренда.
ACTUAL_TREND_REVERSAL не является обязательным торговым Pattern state.
Это последующий market outcome.
## 5. RECOVERY_PATTERN
После сформированного reversal-pattern:
- W3 перешла в новую полуплоскость;
- W4 НЕ пересекла нулевую линию;
- W4 сохранила исходный знак;
- W4 снова меняет направление в сторону исходного тренда.
Это означает восстановление исходного движения.
RECOVERY_PATTERN является альтернативой ACTUAL_TREND_REVERSAL.
## 6. Запрещенная логическая связь
Не использовать как базовый переход:
ACTUAL_TREND_REVERSAL -> RECOVERY_PATTERN
в рамках одного и того же reversal-сценария.
Если позднее возникает новый противоположный Pattern,
это уже новый независимый цикл Pattern state machine.
## 7. Lifecycle
После завершения одного сценария
следующее распознавание должно начинаться как новый цикл.
Точный момент reset в PATTERN_NEUTRAL
пока не считать source-proven.
Не изобретать:
- fixed timeout;
- fixed bar lifetime;
- automatic N-bar reset.
## 8. Нерешенный selector
Главный оставшийся selector:
W4_IN_EXTREMUM_CHANNEL_ZONE
Его нельзя заменить произвольным:
- количеством пунктов;
- процентом;
- ATR multiplier;
- числом баров.
Сначала требуется восстановить/формализовать
математику соответствующей SWT zone/channel.
## 9. Итог
Модель v2 разделяет:
PATTERN EVENT
и
MARKET OUTCOME.
Это устраняет ошибочную последовательность:
REVERSAL_CONFIRMED -> RECOVERY
и оставляет единственный главный качественный пробел:
W4_IN_EXTREMUM_CHANNEL_ZONE.
sig_pattern.mqh пока НЕ менять.
AS-PATTERN-002 пока НЕ закрывать.
