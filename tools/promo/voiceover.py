"""A voiced version: subtitles (SRT, and ASS for burning in) and the voice mixed over the ducked score.
usage: python3 voiceover.py <work-dir> pa|en
  pa: after tts.py has written <work-dir>/vo/NN.wav; writes hazri-promo.pa.srt, .en.srt (translation), pa.ass, mix_pa.wav
  en: after tts_en.py has written <work-dir>/vo_en/NN.wav; writes hazri-promo.vo-en.srt, en.ass, mix_en.wav"""
import json, subprocess, sys, wave, os
W = sys.argv[1]; LANG = sys.argv[2] if len(sys.argv) > 2 else 'pa'; HERE = os.path.dirname(os.path.abspath(__file__))
L = json.load(open(f'{HERE}/narration.json'))
VO, KEY, FONT, SIZE = ('vo', 'pa', 'Baloo Paaji 2 Medium', 42) if LANG == 'pa' else ('vo_en', 'en_vo', 'Inter Medium', 38)
def ts(t, srt=True):
    h = int(t // 3600); m = int(t % 3600 // 60); s = t % 60
    return f"{h:02d}:{m:02d}:{int(s):02d},{int(round((s-int(s))*1000)):03d}" if srt else f"{h}:{m:02d}:{s:05.2f}"
pa, en, ev = [], [], []
for i, l in enumerate(L):
    w = wave.open(f'{W}/{VO}/{i:02d}.wav'); d = w.getnframes() / w.getframerate()
    a = l['start']; b = min(a + d + 0.45, (L[i+1]['start'] - 0.1) if i + 1 < len(L) else 59.6)
    pa.append(f"{i+1}\n{ts(a)} --> {ts(b)}\n{l[KEY]}\n"); en.append(f"{i+1}\n{ts(a)} --> {ts(b)}\n{l['en']}\n")
    ev.append(f"Dialogue: 0,{ts(a,False)},{ts(b,False)},Pa,,0,0,0,,{{\\fad(250,250)}}{l[KEY]}")
if LANG == 'pa':
    open(f'{W}/hazri-promo.pa.srt', 'w').write('\n'.join(pa)); open(f'{W}/hazri-promo.en.srt', 'w').write('\n'.join(en))
else:
    open(f'{W}/hazri-promo.vo-en.srt', 'w').write('\n'.join(pa))
open(f'{W}/{LANG}.ass', 'w').write("""[Script Info]
ScriptType: v4.00+
PlayResX: 1920
PlayResY: 1080
WrapStyle: 0

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Pa,""" + f"{FONT},{SIZE}," + """&H00FFFFFF,&H00FFFFFF,&H00240E0A,&H50240E0A,0,0,0,0,100,100,0,0,3,14,0,2,200,200,34,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
""" + '\n'.join(ev) + '\n')
inp, fl = [], []
for i, l in enumerate(L):
    inp += ['-i', f'{W}/{VO}/{i:02d}.wav']; ms = int(l['start'] * 1000)
    fl.append(f"[{i}:a]aresample=48000,aformat=channel_layouts=stereo,adelay={ms}|{ms}[v{i}]")
n = len(L)
fl.append(''.join(f'[v{i}]' for i in range(n)) + f"amix=inputs={n}:normalize=0,apad=whole_dur=60,atrim=0:60,"
          "highpass=f=90,equalizer=f=250:t=q:w=1:g=-2,equalizer=f=3200:t=q:w=1.2:g=3,"
          "acompressor=threshold=-20dB:ratio=3:attack=5:release=120:makeup=3,aecho=0.8:0.5:40|75:0.18|0.10[voice]")
fl += ["[voice]asplit=2[vmix][vkey]", f"[{n}:a]volume=0.85[mus]",
       "[mus][vkey]sidechaincompress=threshold=0.03:ratio=6:attack=40:release=450:makeup=1[duck]",
       "[duck][vmix]amix=inputs=2:weights=1 1.35:normalize=0,loudnorm=I=-14:TP=-1.0:LRA=9[out]"]
subprocess.run(['ffmpeg', '-hide_banner', '-loglevel', 'error', '-y', *inp, '-i', f'{W}/music.wav',
                '-filter_complex', ';'.join(fl), '-map', '[out]', '-ar', '48000', f'{W}/mix_{LANG}.wav'], check=True)
