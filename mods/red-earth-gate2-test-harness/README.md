# Gate 2 QA Harness 0.2.0

Test-only replacement for the Gate 1 harness. Install only one harness.

| Ball | First interaction | Second interaction |
| --- | --- | --- |
| Left | Shiny Psydren Lv15 | Normal Psydren Lv15 |
| Center | Shiny Vesperis Lv35 | Already dispensed |
| Right | Shiny Solipsdion Lv50 | Already dispensed |

Fifty Rare Candies are supplied once. The two pre-evolution levels are
intentional. After all four gifts, Kaizo's real starter choice is restored.
The normal control has non-shiny DVs and can evolve through the normal line.

The harness observes only its own give_pokemon commands, identifies the new
object across party/boxes by reference, and calls the Gate 2 shiny API only
for explicitly shiny gifts. It does not convert earlier mons or Kaizo gifts.
Persistent per-gift flags prevent duplicates. Party overflow uses native PC
storage; if all storage is full the gift flag remains unset so it can retry.

Version 0.2.2 corrects the exact dependency to Irregular Shiny 0.2.1.
No runtime behavior or artwork changes.
