#!/usr/bin/env bash
# Reports whether the icons audio_service puts in the media notification are
# still in an APK, and exits non-zero if any is gone.
#
# Every one of them is resolved by name at runtime, so nothing in the code or
# the XML refers to them and a resource shrinker takes them out. The small icon
# then resolves to 0, startForeground() throws "invalid notification", and the
# app loses its notification and its lock-screen controls while the recitation
# carries on playing -- because that is just_audio, not the service.
set -u
apk=$1
missing=0
icons='ic_notification audio_service_play_arrow audio_service_pause
  audio_service_skip_next audio_service_skip_previous
  audio_service_fast_forward audio_service_fast_rewind'
for icon in $icons; do
  # A stripped resource is replaced by a tiny placeholder rather than removed,
  # so the size is what tells the two apart.
  size=$(unzip -l "$apk" | awk -v n="$icon" '$4 ~ n {print $1; exit}')
  if [ -z "$size" ]; then
    echo "$icon: NOT IN THE APK"
    missing=1
  elif [ "$size" -lt 100 ]; then
    echo "$icon: $size bytes -- stripped to a placeholder"
    missing=1
  else
    echo "$icon: $size bytes"
  fi
done
exit $missing
