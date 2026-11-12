# MKF - Free Prisoners

Freeing a bound prisoner, the [Modifier Key Framework](https://github.com/eXgamble/Modifier-Key-Framework) way.

Two random encounters bring a bound prisoner along the roads: the Thalmor escorting a prisoner, and Imperial
soldiers with a Stormcloak prisoner. Vanilla asks "Free Prisoner?" in a message box (No / Yes / Free and share
items). This mod drops the box:

| Input | What happens |
|---|---|
| Activate (E / A) | The prisoner pleads, in a whisper while the captors live, plainly once they're dead. No conversation opens |
| Modifier + Activate | **Free**: the same as vanilla's Yes |
| Modifier + X (R on a keyboard) | **Free and Give Items**: the same as vanilla's "share items". Their inventory opens so you can arm them, and while it's open the world runs at a quarter speed |

The actions show only while the prisoner is bound, alive and not in combat, as vanilla's box did, and disappear
once they're free. Freeing them works as in vanilla: their captors turn on them (and on you), and they thank you.

## Requirements

- Modifier Key Framework 1.8.0 or newer
- SKSE

Without the framework the prisoner keeps vanilla's message box.

## How it works

- `WEPrisonerAliasScript` (the prisoner's alias script in both encounters) is replaced by this mod's own version.
  It keeps vanilla's properties, so the encounter quests need no edits and stay compatible with the Unofficial
  Skyrim Special Edition Patch. Its loose script must win over other copies of the same script (Skyrim Souls RE
  ships one): put this mod below them in MO2.
- While bound, the prisoner is in this mod's faction (`MKF - Free Prisoners.esp|0x800`), which the framework rule
  asks for. The same NPC records appear outside these encounters (the civil war's prisoners), so the rule can't go
  by NPC alone.
- The faction rank tells the dialogue whether the captors still live: rank 0, two whispered pleas; rank 1, two
  plain ones. The script sets it just before the prisoner speaks.
- Freeing also ends the bound pose (vanilla left the freed prisoner's hands tied until their package changed).
- Free and Give Items casts a silent, hidden Slow Time spell at 0.25 on the player while the inventory is open.
  It only shows when menus don't pause the game (Skyrim Souls RE); otherwise the game is paused anyway. The
  captors turn and the prisoner thanks you once the inventory closes.

`MKF - Free Prisoners.esp` (ESL): the faction, the dialogue quest and its four lines, the Slow Time effect and spell.
The four lines are voiced in the male Nord voice (both prisoner records are male Nords), made with an ElevenLabs
voice clone of the vanilla MaleNord voice: the voice-lines skill's script reads `tools/voice_lines.json` (words, delivery tags, voice type) and writes `mod/Sound/Voice/MKF - Free Prisoners.esp/MaleNord/`.
AI-generated voice: the Nexus page carries the AI-Generated Content tag and credits ElevenLabs.

## Vanilla behaviour, for reference

- Vanilla's box: No / Yes / Free and share items, shown when the bound prisoner is activated while alive and not
  in combat. "Share items" opens the prisoner's inventory in gift mode.
- Hitting the prisoner makes the captors and the player enemies, as before.
- With the Unofficial Skyrim Special Edition Patch, a prisoner whose captors all die is freed by the patch itself
  (its "prisoner runs away" packages in both encounters call the same freeing function): they thank you and leave.
  So the two "captors are dead" pleas are heard only without that patch.
- The Thalmor warn you off ("Move along") and attack if you linger by their prisoner; that is their own behaviour.

## Building

The script compiles against SKSE's sources (`Script Compilation Dependencies` in MO2) with the vanilla sources.
`mod/` is the MO2 mod folder (junctioned as "MKF - Free Prisoners").

## License

GPL-3.0, see LICENSE.
