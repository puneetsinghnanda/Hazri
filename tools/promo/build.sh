#!/usr/bin/env bash
# Builds the Play Store promo video: tools/promo/README.md.
# usage: tools/promo/build.sh <work-dir>   (needs node + Playwright, python3 + numpy + Pillow, ffmpeg)
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/../.." && pwd); W=${1:?work dir}; P="$ROOT/tools/promo"
mkdir -p "$W/screens" "$W/img" "$W/frames"
cp "$P/stage.html" "$P/frames.js" "$W/"
L=""; for n in 92-Welcome 13-ReaderFollowing 14-ReaderMeanings 15-ReaderHindiScrolled 48-ReaderComplete 85-TodayAppBar \
  121-NitnemTinted 106-GoalPlanner 120-TodayGoalFolded 102-SangatHome 104-GroupGlobe 87-DiaryStreak 56-DiaryToday \
  111-SaakhiLibrary 122-VicharLibrary 113-TodayQuiz 114-QuizQuestion 115-QuizResult 116-QuizBoard; do L="$L $n.light"; done
node "$P/render_screens.js" "$W/screens" $L 123-SimranCounts.dark 124-SimranCountsSitting.dark
for p in cover p2 p5; do python3 -c "from PIL import Image;Image.open('$ROOT/assets/saakhi/bhai-lalo-malik-bhago/$p.webp').save('$W/img/bhai-lalo-malik-bhago-$p.png')"; done
cp "$ROOT/store/play/icon-512.png" "$W/img/icon.png"
( cd "$W"; for r in "0 450" "450 900" "900 1350" "1350 1800"; do node frames.js "$W/frames" 2 30 $r & done; wait )
python3 "$P/music.py" "$W/music.wav"
ffmpeg -y -framerate 30 -i "$W/frames/f%05d.jpg" -i "$W/music.wav" -c:v libx264 -preset slow -crf 16 -pix_fmt yuv420p \
  -profile:v high -level 5.1 -movflags +faststart -c:a aac -b:a 256k -shortest "$W/hazri-promo-4k.mp4"
ffmpeg -y -i "$W/hazri-promo-4k.mp4" -vf scale=1920:1080:flags=lanczos -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p \
  -movflags +faststart -c:a copy "$W/hazri-promo-1080p.mp4"

# The Punjabi version: Meta's MMS Punjabi voice (facebook/mms-tts-pan, CC-BY-NC 4.0; needs huggingface.co),
# subtitles burned in and carried as pa/en tracks.
M="$W/mms-tts-pan"; mkdir -p "$M" "$W/vo"
for f in config.json model.safetensors special_tokens_map.json tokenizer_config.json vocab.json; do
  [ -s "$M/$f" ] || curl -sfL -o "$M/$f" "https://huggingface.co/facebook/mms-tts-pan/resolve/main/$f"; done
cp "$P/narration.json" "$W/"
python3 "$P/tts.py" "$W" 1.08 "$M"
python3 "$P/voiceover.py" "$W"
ffmpeg -y -framerate 30 -i "$W/frames/f%05d.jpg" -i "$W/mix_pa.wav" -i "$W/hazri-promo.pa.srt" -i "$W/hazri-promo.en.srt" \
  -filter_complex "[0:v]ass=$W/pa.ass:fontsdir=$ROOT/assets/fonts[v]" -map "[v]" -map 1:a -map 2 -map 3 \
  -c:v libx264 -preset slow -crf 16 -pix_fmt yuv420p -profile:v high -level 5.1 -c:a aac -b:a 256k -c:s mov_text \
  -metadata:s:a:0 language=pan -metadata:s:s:0 language=pan -metadata:s:s:1 language=eng -movflags +faststart -t 60 "$W/hazri-promo-pa-4k.mp4"
ffmpeg -y -i "$W/hazri-promo-pa-4k.mp4" -map 0 -vf scale=1920:1080:flags=lanczos -c:v libx264 -preset slow -crf 18 \
  -pix_fmt yuv420p -c:a copy -c:s copy -movflags +faststart "$W/hazri-promo-pa-1080p.mp4"
