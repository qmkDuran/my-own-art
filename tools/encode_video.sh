#!/usr/bin/env bash
# Encode a --write-movie frame folder to MP4: tools/encode_video.sh FRAMES_DIR OUT.mp4 [crop-filter]
# Godot's movie writer saves the 2D-HDR picture sRGB-encoded once too often (frames come out washed out); the exact
# sRGB-to-linear curve undoes it, so the video matches the game and its screenshots. 960x540 is scaled 2x, nearest.
set -eu
FRAMES="$1"; OUT="$2"; CROP="${3:-null}"
DECODE="if(lte(val\,10.31)\,val/12.92\,255*pow((val/255+0.055)/1.055\,2.4))"
ffmpeg -y -loglevel error -framerate 60 -i "$FRAMES/f%08d.png" -i "$FRAMES/f.wav" \
  -vf "$CROP,scale=1920:1080:flags=neighbor,lutrgb=r='$DECODE':g='$DECODE':b='$DECODE'" \
  -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p -c:a aac -b:a 160k -shortest "$OUT"
