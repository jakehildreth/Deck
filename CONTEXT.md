# Deck

Terminal presentations from Markdown using PowerShell 7.4+ and Spectre.Console.

## Language

**Progressive bullet**:
A list line starting with `* ` that is revealed one at a time during forward navigation, as opposed to a static bullet (`- `) which appears all at once. Tracked per slide by a visible count.
_Avoid_: step bullet, reveal bullet

**Fade**:
De-emphasizing an already-revealed progressive bullet that is no longer the current point, by rendering it at reduced prominence instead of full intensity. Controlled by `fadeBullets` and `fadeColor`; applies to content, image, and multi-column slides.
_Avoid_: dim (the mechanism, not the feature), hide, grey-out

**dim**:
The default fade rendering: the Spectre `dim` style (ANSI SGR 2 faint), which lowers the luminosity of whatever foreground color the text already has. Adaptive; not a fixed color.
_Avoid_: grey, faint color

**fadeColor**:
An optional named Spectre color that, when set, is used as the fade tone *instead of* `dim`. A fixed, non-adaptive tone.
_Avoid_: fade style, dim color
