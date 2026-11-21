import json, re, sys, torch, numpy as np, scipy.io.wavfile as wf
from transformers import VitsModel, AutoTokenizer
S = sys.argv[1]; rate = float(sys.argv[2])
M = sys.argv[3]
tok = AutoTokenizer.from_pretrained(M); m = VitsModel.from_pretrained(M)
m.speaking_rate = rate; m.noise_scale = 0.55; m.noise_scale_duration = 0.6
SR = m.config.sampling_rate
lines = json.load(open(f'{S}/narration.json'))
def trim(w, th=0.01):
    idx = np.where(np.abs(w) > th * np.abs(w).max())[0]
    return w[max(0, idx[0]-int(.02*SR)): idx[-1]+int(.06*SR)]
for i, l in enumerate(lines):
    parts = re.findall(r'[^,।]+[,।]?', l['pa']); out = []
    for p in parts:
        p = p.strip(); end = p[-1] if p[-1] in ',।' else ''; txt = p.rstrip(',।').strip()
        if not txt: continue
        torch.manual_seed(11)
        with torch.no_grad(): w = m(**tok(txt, return_tensors='pt')).waveform[0].numpy()
        out += [trim(w), np.zeros(int(SR * (0.38 if end == '।' else 0.2 if end == ',' else 0)))]
    w = np.concatenate(out[:-1] if out[-1].size else out)
    wf.write(f'{S}/vo/{i:02d}.wav', SR, (w / np.abs(w).max() * 0.9 * 32767).astype('int16'))
    print(i, round(len(w)/SR, 2), 'slot', round(l['end']-l['start'], 2))
