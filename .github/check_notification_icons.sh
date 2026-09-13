#!/usr/bin/env bash
# Reports whether the icons audio_service puts in the media notification are
# still in an APK, and exits non-zero if any of them is gone.
#
# Every one of them is looked up by name at runtime --
# getResources().getIdentifier("ic_notification", "drawable", ...) -- from a
# string that lives in the Dart snapshot. Nothing in the Kotlin or the XML
# refers to them, which is exactly the shape of resource a shrinker removes. If
# the small icon goes, getIdentifier returns 0, startForeground() throws
# "invalid notification", and the app loses its media notification and its
# lock-screen controls while the recitation carries on playing -- because that
# is just_audio, not the service.
#
# The check reads the resource table rather than the file listing: with code
# shrinking on, AGP renames the packaged files (res/ic_notification.png becomes
# res/lB.png), so a filename says nothing. What matters is that the name still
# resolves and that it still points at a real image -- a shrunk-away resource
# keeps its entry and gets a placeholder of a few bytes.
set -u

apk=$1
verbose=${2:-}

sdk=${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}
aapt2=$(ls -d "$sdk"/build-tools/*/aapt2 2>/dev/null | sort -V | tail -1)
if [ -z "$aapt2" ]; then
  echo "aapt2 not found under '$sdk'; cannot read the resource table"
  exit 1
fi

table=$("$aapt2" dump resources "$apk")
listing=$(unzip -l "$apk")
missing=0

icons='ic_notification audio_service_play_arrow audio_service_pause
  audio_service_skip_next audio_service_skip_previous
  audio_service_fast_forward audio_service_fast_rewind'

for icon in $icons; do
  # The entry, and everything under it up to the next resource.
  block=$(awk -v n="drawable/$icon" '
      $0 ~ ("resource .* " n "$") || $0 ~ ("resource .* " n "[^_a-zA-Z0-9]") {on = 1; print; next}
      on && /resource 0x/ {exit}
      on {print}
    ' <<<"$table")
  if [ -z "$block" ]; then
    echo "$icon: NO ENTRY in the resource table"
    missing=1
    continue
  fi
  if [ -n "$verbose" ]; then
    sed 's/^/    /' <<<"$block"
  fi

  # Every density's file, and the largest of them. A real icon is hundreds of
  # bytes even at mdpi; the shrinker's placeholder is under a hundred.
  biggest=0
  for path in $(grep -oE 'res/[^ ")]+' <<<"$block" | sort -u); do
    size=$(awk -v p="$path" '$4 == p {print $1; exit}' <<<"$listing")
    [ -n "$size" ] && [ "$size" -gt "$biggest" ] && biggest=$size
  done

  if [ "$biggest" -eq 0 ]; then
    echo "$icon: named in the table but no file behind it"
    missing=1
  elif [ "$biggest" -lt 100 ]; then
    echo "$icon: $biggest bytes -- a placeholder, the image was stripped"
    missing=1
  else
    echo "$icon: $biggest bytes"
  fi
done

exit $missing
