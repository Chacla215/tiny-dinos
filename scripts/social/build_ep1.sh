#!/bin/zsh
# Build RISING TIDE Ep1 "NOBODY TOUCHES THE LEAF" from clean generated sources.
#
# THE TWO IRON RULES (see NEXT_TWO_CLIPS.md) — this script exists because the
# previous build burned narration subtitles into the picture and ended on two
# stills. Both are banned:
#   1. The ONLY text is the hook card + the "12 SECONDS EARLIER" signpost.
#      A text card NEVER stands in for a missing beat — generate the beat.
#   2. Every frame is real generated footage. No stills, no zoompan push-ins.
#
# Sources live in wip/ep1/src (re-downloadable from the Higgsfield library).
# Run from the repo root:  zsh scripts/social/build_ep1.sh
set -e

EP=wip/ep1
SRC=$EP/src
BUILD=$EP/build
OUT=$EP/ep1_v3.mp4
mkdir -p $BUILD $EP/cards

# --- 1. the two allowed text overlays -------------------------------------
python3 scripts/social/make_ep1_cards.py $EP/cards

# --- 2. segments ----------------------------------------------------------
# name        source            in     dur    beat
segs=(
  "s01 $SRC/beat5.mp4  7.40 1.40"   # HOOK: the leap, sword raised (flash-forward)
  "s02 $SRC/beat1.mp4  1.00 2.00"   # signpost: Ralph yawns, king of a tiny island
  "s03 $SRC/beat1.mp4  7.00 4.60"   # naps -> Max snatches the leaf -> wakes horrified
  "s04 $SRC/beat2.mp4  4.50 4.00"   # rises furious, Max taunts with the leaf
  "s05 $SRC/beat3.mp4  3.00 4.50"   # the chase -> trips -> face-plant -> spent
  "s06 $SRC/beat4.mp4  1.00 2.50"   # the sword falls out of the sky
  "s07 $SRC/beat4.mp4  9.00 2.60"   # he pulls it free, hero stance
  "s08 $SRC/beat5.mp4  3.60 5.00"   # the charge and the leap
  "s09 $EP/clip1a_strike_v1.mp4 1.20 4.50"  # THE STRIKE (generated 2026-07-19)
  "s10 $SRC/tide.mp4   0.40 5.00"   # lands, reclaims the leaf, Max deflates
  "s11 $SRC/tide.mp4   8.60 3.00"   # the turn: water creeping over the footprints
  "s12 $EP/clip1b_ocean_v1.mp4 5.00 5.00"   # ENDING: ocean POV, they look at each other
)
# NOTE: beat5 grows a cape after ~8.7s and tide's usable tail ends at 11.6s —
# do not extend those in/out points without re-QAing for the cape.

rm -f $BUILD/concat.txt
for row in $segs; do
  set -- ${=row}; name=$1; f=$2; ss=$3; d=$4
  ffmpeg -y -v error -ss $ss -t $d -i $f \
    -vf "scale=720:1280:force_original_aspect_ratio=decrease,pad=720:1280:-1:-1,fps=30,setsar=1" \
    -an -c:v libx264 -crf 17 -preset medium -pix_fmt yuv420p $BUILD/$name.mp4
  echo "file '$name.mp4'" >> $BUILD/concat.txt
done

ffmpeg -y -v error -f concat -safe 0 -i $BUILD/concat.txt -c copy $BUILD/silent.mp4
DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 $BUILD/silent.mp4)
echo "cut length: ${DUR}s"

# --- 3. the two text overlays (hook 0.15-1.40, signpost 1.55-3.05) --------
ffmpeg -y -v error -i $BUILD/silent.mp4 -i $EP/cards/hook.png -i $EP/cards/signpost.png \
  -filter_complex "[0][1]overlay=0:0:enable='between(t,0.15,1.40)'[a]; \
                   [a][2]overlay=0:0:enable='between(t,1.55,3.05)'[v]" \
  -map "[v]" -c:v libx264 -crf 17 -preset medium -pix_fmt yuv420p $BUILD/titled.mp4

# --- 4. audio -------------------------------------------------------------
# battle theme under the action (its 3.5s buildup runs under the hook so the
# drop lands as the story returns), fading out across the turn; generated
# ocean wash carries the quiet ending; one impact on the bonk.
CONTACT_MS=28600   # sword meets skull, in finished-timeline milliseconds
SWING_MS=28150     # the whoosh just before it
MUSIC_FADE=33.50

ffmpeg -y -v error -i assets/music/battle_theme.mp3 \
  -af "atrim=0:36.5,afade=t=out:st=${MUSIC_FADE}:d=3.0,volume=0.62" \
  -ac 2 -ar 48000 $BUILD/music.wav

# ocean wash: brown noise, lowpassed, slow swell — carries the quiet ending,
# so it has to sit high enough that the tail doesn't read as broken audio.
ffmpeg -y -v error -f lavfi -i "anoisesrc=c=brown:r=48000:a=0.28:d=${DUR}" \
  -af "lowpass=f=520,highpass=f=90,tremolo=f=0.12:d=0.55,afade=t=in:st=31:d=4,afade=t=out:st=$(echo "$DUR-1.2"|bc):d=1.2,volume=2.6" \
  -ac 2 $BUILD/ocean.wav

# adelay takes milliseconds; a truncated "28s" silently lands the hit early.
ffmpeg -y -v error -i assets/sfx/swing.wav -af "adelay=${SWING_MS}:all=1,volume=2.2" \
  -ac 2 -ar 48000 -t $DUR $BUILD/swing.wav
ffmpeg -y -v error -i assets/sfx/drop_land.wav -af "adelay=${CONTACT_MS}:all=1,volume=1.5" \
  -ac 2 -ar 48000 -t $DUR $BUILD/impact.wav

ffmpeg -y -v error -i $BUILD/music.wav -i $BUILD/ocean.wav -i $BUILD/impact.wav -i $BUILD/swing.wav \
  -filter_complex "[0][1][2][3]amix=inputs=4:duration=longest:normalize=0[a]" \
  -map "[a]" -t $DUR $BUILD/mix.wav

# --- 5. mux + broadcast loudness -----------------------------------------
ffmpeg -y -v error -i $BUILD/titled.mp4 -i $BUILD/mix.wav \
  -af "loudnorm=I=-14:TP=-1.5:LRA=11" \
  -c:v copy -c:a aac -b:a 192k -shortest $OUT

echo "--- built $OUT"
ffprobe -v error -show_entries format=duration -of csv=p=0 $OUT
ffmpeg -hide_banner -nostats -i $OUT -af ebur128=framelog=verbose -f null - 2>&1 | tail -6
