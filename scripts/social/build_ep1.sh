#!/bin/zsh
# Build RISING TIDE Ep1 "NOBODY TOUCHES THE LEAF" — v4.
#
# THE TWO IRON RULES (see NEXT_TWO_CLIPS.md):
#   1. NO SUBTITLES. The ONLY text is the hook card + the "12 SECONDS EARLIER"
#      signpost. A text card NEVER stands in for a missing beat.
#      NOTE: "no subtitles" is NOT "no narration" — Ep1 HAS a narrator. The
#      Arthur VO is audio-only, no captions. v3 threw the voice away with the
#      captions; that is the bug this version fixes.
#   2. Every frame is real generated footage. No stills, no zoompan push-ins.
#
# v4 changes vs v3 (Charlie's WhatsApp review of the unlisted v3):
#   - Arthur VO restored as audio (5 lines, wip/ep1/vo/), music sidechain-ducked
#     under the voice bus so he is never buried.
#   - tide.mp4 plays CONTINUOUSLY 0.40 -> 11.60. v3 skipped 5.4-8.6, which is
#     exactly the turn (camera drifts back, Ralph sees the sea, Max gets up) —
#     that cut is what made the ending read as rushed.
#   - Beats re-timed so the VO is the spine.
#
# Sources live in wip/ep1/src (re-downloadable from the Higgsfield library);
# VO wavs in wip/ep1/vo (gitignored — CDN URLs tabled in NEXT_TWO_CLIPS.md).
# Run from the repo root:  zsh scripts/social/build_ep1.sh
set -e

EP=wip/ep1
SRC=$EP/src
VO=$EP/vo
BUILD=$EP/build
OUT=$EP/ep1_v4.mp4
mkdir -p $BUILD $EP/cards

# --- 1. the two allowed text overlays -------------------------------------
python3 scripts/social/make_ep1_cards.py $EP/cards

# --- 2. segments ----------------------------------------------------------
# name  source                 in     dur      starts at   beat
segs=(
  "s01 $SRC/beat5.mp4  7.20 1.50"   #  0.00  HOOK: the leap, sword raised
  "s02 $SRC/beat1.mp4  0.60 3.00"   #  1.50  signpost: yawn, king of a tiny island
  "s03 $SRC/beat1.mp4  6.60 5.00"   #  4.50  naps -> Max snatches the leaf -> wakes
  "s04 $SRC/beat2.mp4  4.50 5.00"   #  9.50  rises furious, Max taunts with the leaf
  "s05 $SRC/beat3.mp4  3.00 4.50"   # 14.50  the chase -> trips
  "s06 $SRC/beat3.mp4  7.50 4.00"   # 19.00  spent on the sand, Max taunts
  "s07 $SRC/beat4.mp4  1.20 3.30"   # 23.00  the sword falls out of the sky (~24.3)
  "s08 $SRC/beat4.mp4  9.00 2.60"   # 26.30  he pulls it free, hero stance
  "s09 $SRC/beat5.mp4  3.60 5.10"   # 28.90  the charge and the leap
  "s10 $EP/clip1a_strike_v1.mp4 1.20 6.00"  # 34.00  THE STRIKE (contact ~35.85)
  "s11 $SRC/tide.mp4   0.40 11.20"  # 40.00  lands, leaf reclaimed, THE TURN, water
  "s12 $EP/clip1b_ocean_v1.mp4 3.50 7.00"   # 51.20  ENDING: ocean POV, the look
)
# The strike runs 6.0s (clip 1.20-7.20), not 5.0: contact is at clip t~3.0, the
# crossed X-eyes at 4.4 and the circling stars at 6.6. Cutting at 5.0s clipped
# the reaction off mid-beat, which is exactly the "wraps up too quick" note.
# TRAPS: beat5 grows an orange cape after ~8.7s and tide's usable tail ends at
# 11.6s — do not extend those out points without re-QAing.

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

# --- 4. narration (Arthur, locked take) -----------------------------------
# The VO is the spine of the cut — these offsets are what the picture is timed
# to. adelay takes MILLISECONDS; a truncated "28s" silently lands 600ms early.
#   vo1 @ 1.80 (8.11s) "This is Ralph! King of a very tiny island..."
#   vo2 @10.10 (1.34s) "Max touched the leaf!"
#   vo3 @12.80 (6.46s) "Now, Ralph is not the fastest... he's mostly just tiny!"
#   vo4 @19.60 (8.11s) "But this island takes care of its little king..."
#   vo5 @29.20 (4.34s) "And Max? Oh, Max was about to learn Ralph's SECOND rule!"
vo_lines=(
  "vo1_king.wav 1800"
  "vo2_touched.wav 10100"
  "vo3_tiny.wav 12800"
  "vo4_sky.wav 19600"
  "vo5_rule2.wav 29200"
)
vo_inputs=(); vo_filters=""; vo_labels=""; i=0
for row in $vo_lines; do
  set -- ${=row}; f=$1; ms=$2
  vo_inputs+=(-i $VO/$f)
  vo_filters="${vo_filters}[$i]adelay=${ms}:all=1,volume=1.6[v$i];"
  vo_labels="${vo_labels}[v$i]"
  i=$((i+1))
done
# apad to the FULL cut length is load-bearing, not cosmetic: this file is the
# sidechain key below, and sidechaincompress truncates its output to the
# SHORTER of its two inputs. Un-padded, voice.wav ends with VO5 at 33.5s and
# takes the whole music bed down with it — the strike and the landing then play
# over near-silence, which reads as the video breaking. (Caught by an ebur128
# sweep showing S=-143 LUFS at t=40.)
ffmpeg -y -v error $vo_inputs \
  -filter_complex "${vo_filters}${vo_labels}amix=inputs=5:duration=longest:normalize=0,apad[a]" \
  -map "[a]" -ac 2 -ar 48000 -t $DUR $BUILD/voice.wav

# --- 5. beds + SFX --------------------------------------------------------
# Battle theme under the action (its 3.5s buildup runs under the hook so the
# drop lands as the story returns), fading out across the turn; generated ocean
# wash carries the quiet ending; swing + impact on the bonk.
CONTACT_MS=35850   # sword meets skull, in finished-timeline milliseconds
SWING_MS=35400     # the whoosh just before it
MUSIC_FADE=45.00   # starts fading as the turn begins, gone before the ending

ffmpeg -y -v error -i assets/music/battle_theme.mp3 \
  -af "atrim=0:49.0,afade=t=out:st=${MUSIC_FADE}:d=4.0,volume=0.62" \
  -ac 2 -ar 48000 $BUILD/music.wav

# Music ducks under the voice bus so Arthur is never buried (v3's flat bed was
# the complaint). Sidechain key = the VO mix, not the master.
ffmpeg -y -v error -i $BUILD/music.wav -i $BUILD/voice.wav \
  -filter_complex "[0][1]sidechaincompress=threshold=0.02:ratio=9:attack=15:release=350[a]" \
  -map "[a]" -ac 2 -ar 48000 -t $DUR $BUILD/music_ducked.wav

# Ocean wash: brown noise, lowpassed, slow swell — carries the quiet ending, so
# it has to sit high enough that the tail doesn't read as broken audio. It rises
# under the turn (the tide segment starts at 39.0) as the music leaves.
ffmpeg -y -v error -f lavfi -i "anoisesrc=c=brown:r=48000:a=0.28:d=${DUR}" \
  -af "lowpass=f=520,highpass=f=90,tremolo=f=0.12:d=0.55,afade=t=in:st=40:d=5,afade=t=out:st=$(echo "$DUR-1.2"|bc):d=1.2,volume=2.6" \
  -ac 2 $BUILD/ocean.wav

ffmpeg -y -v error -i assets/sfx/swing.wav -af "adelay=${SWING_MS}:all=1,volume=2.2" \
  -ac 2 -ar 48000 -t $DUR $BUILD/swing.wav
ffmpeg -y -v error -i assets/sfx/drop_land.wav -af "adelay=${CONTACT_MS}:all=1,volume=1.5" \
  -ac 2 -ar 48000 -t $DUR $BUILD/impact.wav

ffmpeg -y -v error -i $BUILD/music_ducked.wav -i $BUILD/ocean.wav \
  -i $BUILD/impact.wav -i $BUILD/swing.wav -i $BUILD/voice.wav \
  -filter_complex "[0][1][2][3][4]amix=inputs=5:duration=longest:normalize=0[a]" \
  -map "[a]" -t $DUR $BUILD/mix.wav

# --- 6. mux + broadcast loudness -----------------------------------------
# DO NOT use a bare `loudnorm=I=-14`. This cut's natural loudness range is ~17 LU
# (loud action against a deliberately quiet ocean ending). loudnorm refuses
# LINEAR mode whenever the source LRA exceeds the target LRA, and silently falls
# back to DYNAMIC mode, which gates the quiet tail and lands the master at -16
# LUFS — 2 LU under spec and audibly quiet next to other Shorts. Both v3 and the
# first v4 attempt were quiet for exactly this reason.
#
# Instead: a gentle wideband compressor pulls the range into the low teens (so
# the ending survives a phone speaker without squashing the strike), then ONE
# deterministic measured gain hits -14, then a limiter guards true peak.
COMP="acompressor=threshold=-20dB:ratio=2:attack=25:release=450:makeup=1"
MEAS=$(ffmpeg -hide_banner -nostats -i $BUILD/mix.wav \
  -af "${COMP},loudnorm=I=-14:TP=-1.5:LRA=11:print_format=json" -f null - 2>&1 | \
  python3 -c "import sys,json; s=sys.stdin.read(); print(json.loads(s[s.rindex('{'):s.rindex('}')+1])['input_i'])")
GAIN=$(python3 -c "print(round(-14.0 - float('$MEAS'), 2))")
echo "measured I=${MEAS} LUFS -> applying ${GAIN} dB"

ffmpeg -y -v error -i $BUILD/titled.mp4 -i $BUILD/mix.wav \
  -af "${COMP},volume=${GAIN}dB,alimiter=limit=0.84:level=disabled" \
  -c:v copy -c:a aac -b:a 192k -shortest $OUT

echo "--- built $OUT"
ffprobe -v error -show_entries format=duration -of csv=p=0 $OUT
ffmpeg -hide_banner -nostats -i $OUT -af ebur128=framelog=verbose -f null - 2>&1 | tail -6
