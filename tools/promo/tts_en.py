"""English voice-over with Kokoro-82M (Apache 2.0). usage: tts_en.py <work-dir> <kokoro-dir> [voice] [speed]"""
import json, os, sys, numpy as np, soundfile as sf, torch
from kokoro import KModel, KPipeline
W, K = sys.argv[1], sys.argv[2]; voice = sys.argv[3] if len(sys.argv) > 3 else 'af_heart'; speed = float(sys.argv[4]) if len(sys.argv) > 4 else 1.0
HERE = os.path.dirname(os.path.abspath(__file__))
model = KModel(config=f'{K}/config.json', model=f'{K}/kokoro-v1_0.pth').eval()
pipe = KPipeline(lang_code=voice[0], model=model)
pack = torch.load(f'{K}/voices/{voice}.pt', weights_only=True)
os.makedirs(f'{W}/vo_en', exist_ok=True)
for i, l in enumerate(json.load(open(f'{HERE}/narration.json'))):
    audio = [r.audio.numpy() for r in pipe(l['en_say'], voice=pack, speed=speed)]
    a = np.concatenate(audio)
    sf.write(f'{W}/vo_en/{i:02d}.wav', a, 24000)
    print(i, round(len(a) / 24000, 2), 'slot', round(l['end'] - l['start'], 2))
