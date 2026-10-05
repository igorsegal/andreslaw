# AS — SWTch EX4 black-box buffer map
Дата: 2026-10-05
Статус: RUNTIME VERIFIED
Источник:
оригинальный SWTch.ex4 Nicholas Skrigan.
Метод:
iCustom black-box probe + MT4 Data Window.
Декомпиляция не использовалась.
Контроль:
EURUSD,H1
bar = 2026.10.01 10:00
inputs:
W2_CH=false
W3_SR=false
W4_SR=true
ShowCenterLine=false
## Verified exported buffers
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
At the control bar:
chw3:H  = 1.14012301
chw3:L  = 1.13030256
chw4:H  = 1.16008149
chw4:L  = 1.13078774
chw4:R  = 1.16013438
chw4:S  = 1.10192145
chw4:cl = 1.14534096
W2 buffers were zero because W2_CH=false.
W3 R/S were zero because W3_SR=false.
rlw4/rlw3/rlw2 returned EMPTY_VALUE on this control bar.
## Internal buffers 0..9
Buffers 0..9 return numeric values but their semantic meaning
has not yet been proven.
Important observed alias:
mode 3 = 1.14534096
mode 20 = chw4:cl = 1.14534096
Do not assign names to modes 0..9 without additional proof.
## Candidate objective channel events
Without arbitrary numeric thresholds:
UPPER_W4_CHANNEL_HIT:
bar High >= chw4:H
LOWER_W4_CHANNEL_HIT:
bar Low <= chw4:L
On control bar 2026.10.01 10:00:
Low = 1.12979
chw4:L = 1.13078774
Therefore:
LOWER_W4_CHANNEL_HIT = true
This is PROJECT_FORMALIZATION.
It is not yet claimed to exhaust the author's qualitative word
"near/возле".
Next:
verify W4 channel-hit behavior across historical bars and actual
turning points before using it in AS-PATTERN-002.
Production sig_pattern.mqh remains unchanged.
