#!/bin/zsh
# Build RISING TIDE Ep2 "HIGH WATER MARK".
#
# Plan: EP2_PLAN.md. Story: SAGA_OUTLINE.md.
#
# EP2 IS WORDLESS — no narrator, no speech bubbles, NO ON-SCREEN TEXT AT ALL,
# not even a hook card. Arthur cannot generate new lines ever, and the script
# itself says "neither speaks". The silence is also deliberate format variety
# against the channel-level "interchangeable videos" risk: Ep1 was 60s,
# narrated, action. This is 20s, silent, still.
#
# Because there is no text, the text sweep on the finished file must find
# NOTHING. That is the check, not an afterthought.
#
# The three clips each lead with their un-losable beat, because Seedance
# renders front-to-back and drops the tail when it runs out of clip.
#
# Run from the repo root:  zsh scripts/social/build_ep2.sh
set -e

EP=wip/ep2_den
BUILD=$EP/build
OUT=$EP/ep2_v1.mp4
mkdir -p $BUILD

# --- 1. segments ----------------------------------------------------------
# A 5th field is an optional punch-in (centre-crop factor, rescaled to full).
#
# name  source              in    dur   [crop]   starts at   beat
segs=(
  "s01 $EP/clip1_mark.mp4    0.60 7.00"   #  0.00  he scratches the mark, looks at it
  "s02 $EP/clip2_visitor.mp4 0.40 7.50"   #  7.00  Max sets the ice down, steps back
  "s03 $EP/clip3_ice.mp4     0.30 5.50"   # 14.50  it melts, alone. END on the ice.
)
#                                                 ends ~20.00
# NOTE: in/dur are FIRST GUESSES. QA each clip and retune — the un-losable
# beat must land inside its window, and clip3 must end ON the ice, not drift
# off it.

rm -f $BUILD/concat.txt
for row in $segs; do
  set -- ${=row}; name=$1; f=$2; ss=$3; d=$4; crop=$5
  if [[ -n "$crop" ]]; then
    VF="crop=iw*${crop}:ih*${crop},scale=720:1280:force_original_aspect_ratio=decrease,pad=720:1280:-1:-1,fps=30,setsar=1"
  else
    VF="scale=720:1280:force_original_aspect_ratio=decrease,pad=720:1280:-1:-1,fps=30,setsar=1"
  fi
  ffmpeg -y -v error -ss $ss -t $d -i $f -vf "$VF" \
    -an -c:v libx264 -crf 17 -preset medium -pix_fmt yuv420p $BUILD/$name.mp4
  echo "file '$name.mp4'" >> $BUILD/concat.txt
done

ffmpeg -y -v error -f concat -safe 0 -i $BUILD/concat.txt -c copy $BUILD/silent.mp4
DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 $BUILD/silent.mp4)
echo "cut length: ${DUR}s"

# --- 2. sound -------------------------------------------------------------
# Ambience-led, because silence is the point. The loudest thing in the episode
# is the claw on stone — it is the title.
SCRATCH_MS=2600     # claw meets stone (inside s01)
ICE_SET_MS=10200    # the ice touches the sand (inside s02)

# distant surf, low and constant — the tide that just went out
ffmpeg -y -v error -f lavfi -i "anoisesrc=c=brown:r=48000:a=0.30:d=${DUR}" \
  -af "lowpass=f=420,highpass=f=70,tremolo=f=0.09:d=0.5,volume=1.5,\
afade=t=in:st=0:d=2,afade=t=out:st=$(echo "$DUR-1.5"|bc):d=1.5" \
  -ac 2 $BUILD/surf.wav

# den drips — sparse, irregular, wet stone. Synthesised: short filtered blips.
drips=""
inputs=""
i=0
for ms in 900 2100 4300 5800 8400 11900 13600 16100 17800 19200; do
  inputs="$inputs -f lavfi -i sine=frequency=$((1400 + (i % 4) * 260)):duration=0.05"
  drips="${drips}[$i]adelay=${ms}:all=1,volume=0.30[d$i];"
  i=$((i+1))
done
labels=""; for ((j=0;j<i;j++)); do labels="${labels}[d$j]"; done
ffmpeg -y -v error ${=inputs} \
  -filter_complex "${drips}${labels}amix=inputs=${i}:duration=longest:normalize=0,\
lowpass=f=3000,aecho=0.6:0.5:60:0.25[a]" \
  -map "[a]" -ac 2 -ar 48000 -t $DUR $BUILD/drips.wav

# the scratch — the episode's loudest moment
ffmpeg -y -v error -i assets/sfx/hit_claw.wav \
  -af "adelay=${SCRATCH_MS}:all=1,atempo=0.72,volume=2.4" \
  -ac 2 -ar 48000 -t $DUR $BUILD/scratch.wav

# the ice touching down — soft, deliberate
ffmpeg -y -v error -i assets/sfx/drop_land.wav \
  -af "adelay=${ICE_SET_MS}:all=1,lowpass=f=1800,volume=0.85" \
  -ac 2 -ar 48000 -t $DUR $BUILD/iceset.wav

ffmpeg -y -v error -i $BUILD/surf.wav -i $BUILD/drips.wav \
  -i $BUILD/scratch.wav -i $BUILD/iceset.wav \
  -filter_complex "[0][1][2][3]amix=inputs=4:duration=longest:normalize=0[a]" \
  -map "[a]" -t $DUR $BUILD/mix.wav

# --- 3. master ------------------------------------------------------------
# NOT a bare loudnorm — on quiet, wide-range material it refuses linear mode
# and gates the silence, landing well under target. Compress -> one measured
# gain -> limiter, same as Ep1.
COMP="acompressor=threshold=-22dB:ratio=2:attack=25:release=450:makeup=1"
MEAS=$(ffmpeg -hide_banner -nostats -i $BUILD/mix.wav \
  -af "${COMP},loudnorm=I=-14:TP=-1.5:LRA=11:print_format=json" -f null - 2>&1 | \
  python3 -c "import sys,json; s=sys.stdin.read(); print(json.loads(s[s.rindex('{'):s.rindex('}')+1])['input_i'])")
GAIN=$(python3 -c "print(round(-14.0 - float('$MEAS'), 2))")
echo "measured I=${MEAS} LUFS -> applying ${GAIN} dB"

ffmpeg -y -v error -i $BUILD/silent.mp4 -i $BUILD/mix.wav \
  -af "${COMP},volume=${GAIN}dB,alimiter=limit=0.84:level=disabled" \
  -c:v copy -c:a aac -b:a 192k -shortest $OUT

echo "--- built $OUT"
ffprobe -v error -show_entries format=duration -of csv=p=0 $OUT
ffmpeg -hide_banner -nostats -i $OUT -af ebur128=framelog=verbose -f null - 2>&1 | tail -6
