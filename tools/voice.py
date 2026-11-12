"""Voice the prisoner's four lines with ElevenLabs, straight into the game's voice files.

Each line -> mp3 from the MaleNord clone -> mod/Sound/Voice/MKF - Free Prisoners.esp/MaleNord/<file>.fuz (xWMA + lip
sync, via the Immersive Romance Framework repo's tools/make_fuz.py and the Creation Kit's LipGen tools).
A line that already has its .fuz is skipped: re-voicing a line is deleting its .fuz (and its cached mp3).

Usage: python voice.py          Needs ELEVENLABS_API_KEY or ELEVENLABS_API_KEY_FILE. About 1 credit per character.

File names follow the game's rule: quest EditorID + "_" + topic EditorID, the quest cut to 10 characters and the topic
to 25 minus that when the two together pass 25, then the INFO's FormID (8 hex, light plugin = local ID) and the
response number. MKFFP_DialogueQuest + MKFFP_PleadTopic -> MKFFP_Dial_MKFFP_PleadTopi.
"""
import hashlib
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
OUT = REPO / "mod" / "Sound" / "Voice" / "MKF - Free Prisoners.esp" / "MaleNord"
CACHE = Path(r"C:\Modding\houseCARL\VoiceSamples\generated")
MAKE_FUZ = REPO.parent / "ImmersiveRomanceFramework" / "tools" / "make_fuz.py"
API = "https://api.us.elevenlabs.io/v1/text-to-speech/{voice}?output_format=mp3_44100_128"
MODEL = "eleven_v4"
VOICE = "jcGAygfKOpFl7MdtVdep"  # the user's ElevenLabs clone of MaleNord (vanilla lines, 2026-11-12)
PREFIX = "MKFFP_Dial_MKFFP_PleadTopi"

# INFO (local FormID) -> (delivery tags, words as the plugin has them)
LINES = {
    0x804: ("[whispers] [urgent]", "Please... cut me loose. I'll fight beside you."),
    0x805: ("[whispers] [urgent]", "Psst. Over here. Get these ropes off me, quick."),
    0x806: ("[relieved] [tired]", "Thank the gods. Untie me, please."),
    0x807: ("[surprised] [urgent]", "They're dead? Then cut me loose, quickly."),
}


def api_key():
    key = os.environ.get("ELEVENLABS_API_KEY", "").strip()
    if not key and os.environ.get("ELEVENLABS_API_KEY_FILE"):
        key = Path(os.environ["ELEVENLABS_API_KEY_FILE"]).read_text(encoding="utf-8").strip()
    return key or sys.exit("Set ELEVENLABS_API_KEY (or ELEVENLABS_API_KEY_FILE)")


def generate(key, text, out):
    body = json.dumps({"text": text, "model_id": MODEL}).encode("utf-8")
    for attempt in range(6):
        request = urllib.request.Request(API.format(voice=VOICE), data=body, method="POST",
                                         headers={"xi-api-key": key, "Content-Type": "application/json", "Accept": "audio/mpeg"})
        try:
            with urllib.request.urlopen(request, timeout=120) as response:
                out.write_bytes(response.read())
                return
        except urllib.error.HTTPError as e:
            if e.code in (429, 503) and attempt < 5:
                time.sleep(5 * (attempt + 1))
                continue
            sys.exit(f"ElevenLabs {e.code}: {e.read().decode('utf-8', 'replace')[:300]}")


def main():
    key = None
    for info, (tags, text) in LINES.items():
        fuz = OUT / f"{PREFIX}_{info:08X}_1.fuz"
        if fuz.exists():
            print("have", fuz.name)
            continue
        spoken = f"{tags} {text}".strip()
        mp3 = CACHE / f"MaleNord_{fuz.stem}_{hashlib.sha1(spoken.encode()).hexdigest()[:8]}.mp3"
        if not mp3.exists():
            key = key or api_key()
            generate(key, spoken, mp3)
        subprocess.run([sys.executable, str(MAKE_FUZ), str(mp3), text, str(fuz)], check=True)


if __name__ == "__main__":
    main()
