#!/bin/zsh
# Build RISING TIDE Ep1 "NOBODY TOUCHES THE LEAF" — v5.
#
# THE TWO IRON RULES (see NEXT_TWO_CLIPS.md):
#   1. NO SUBTITLES. The only text in the picture is the hook card, the
#      "12 SECONDS EARLIER" signpost, and the logo outro card at the very end.
#      A text card NEVER stands in for a missing beat.
#      NOTE: "no subtitles" is NOT "no narration" — Ep1 HAS a narrator. The
#      Arthur VO is audio-only, no captions.
#   2. Every frame of the STORY is real generated footage. No stills, no zoompan
#      push-ins. The logo card is branding furniture after the story has ended,
#      not a story beat standing in for action.
#
# v4 (Charlie's review of the unlisted v3): narration restored as audio, music
# ducked under the voice bus, tide.mp4 played continuously so the turn survives.
#
# v6 adds the BRIDGE clip (see the segment block). v5 (Charlie's review of the unlisted v4): "the end takes too long to wrap up",
# "I want the outro back", "I want them to end in a scuffle looking at the
# camera and then go into our logo outro". The wrap-up is 5.4s shorter, the
# mix-up is two new generated clips, and the logo card is back. See the block
# above the segment list for why each of those is shaped the way it is.
#
# Sources live in wip/ep1/src (re-downloadable from the Higgsfield library);
# VO wavs in wip/ep1/vo (gitignored — CDN URLs tabled in NEXT_TWO_CLIPS.md).
# Run from the repo root:  zsh scripts/social/build_ep1.sh
set -e

EP=wip/ep1
SRC=$EP/src
VO=$EP/vo
MIX=$EP/mixup
BRG=$EP/bridge
BUILD=$EP/build
OUT=$EP/ep1_v6.mp4
mkdir -p $BUILD $EP/cards

# --- 1. the two allowed text overlays -------------------------------------
python3 scripts/social/make_ep1_cards.py $EP/cards

# --- 2. segments ----------------------------------------------------------
# A 5th field is an optional PUNCH-IN (centre-crop factor, then rescaled to
# full frame). The scuffle clips generated wide — the model pulled the camera
# back and the dust cloud sits small in a big seascape — so they get punched in
# to read at phone size. This is the same crop trick the earlier cuts used to
# keep anything from sitting still too long.
#
# name  source                 in     dur   [crop]     starts at   beat
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
  "s10 $EP/clip1a_strike_v1.mp4 1.20 5.00"  # 34.00  THE STRIKE (contact ~35.80)
  "s11 $SRC/tide.mp4   0.80 8.40"   # 39.00  lands, leaf reclaimed, THE TURN
  "s12 $BRG/bridge.mp4 1.20 2.60"           # 47.40  THE BRIDGE: water at their feet
  "s13 $EP/clip1b_ocean_v1.mp4 3.50 3.20"   # 50.00  the look between them
  "s14 $MIX/mixupA.mp4 0.60 2.40 0.72"      # 53.20  THE MIX-UP: they pile in
  "s15 $MIX/mixupB.mp4 1.60 2.60 0.72"      # 55.60  they clock the camera
  "s16 $BUILD/outro.mp4 0.00 1.40"          # 58.20  the logo card
)
#                                                    ends 59.60 (under the 60s line)
#
# WHY THE ENDING IS SHAPED LIKE THIS (Charlie, after watching v4 unlisted):
# "the end takes too long to wrap up", "I want the outro back", and "I want them
# to end in a scuffle looking at the camera and then go into our logo outro".
#   - The wrap-up lost 5.4s. NOT by cutting tide's middle again (that was the v3
#     mistake that killed the turn) — tide still plays continuously from 0.40,
#     it just stops at 9.20 instead of 11.60, dropping only the slow water-over-
#     footprints tail. The turn itself (5.4-8.6) is untouched. clip1b drops from
#     7.0s to 4.0s: it only has to deliver the look now, not carry the ending.
#   - The scuffle is TWO clips, not one, on purpose. The camera look is the
#     button and it cannot be lost, but chronologically it comes second — and
#     Seedance renders front-to-back and drops the tail when it runs out of
#     clip. One clip asking for "scuffle THEN look at camera" puts the punchline
#     in exactly the drop zone. Split in two, each clip's un-losable beat is
#     first: A erupts, B looks down the lens.
#   - THE BRIDGE (v6). tide ended on a wide DRY beach with footprints and
#     clip1b opened on a nearly-submerged patch — one hard cut across a big
#     world-state change. The fix follows the production law exactly: generate
#     the changed world as a cheap STILL (nano_banana edit of tide's own last
#     frame, water risen to their feet, ~1.5cr), then use that still as a video
#     START FRAME so the model only has to continue an already-changed world.
#     Everything else gave back the 2.6s it costs, so the runtime held under 60.
#   - The outro card is back. It was cut at v5 because it broke the loop, but
#     the RISING TIDE reboot deliberately ended that: the episode now stops dead
#     on a cliffhanger instead of looping to its first frame, so the reason the
#     card was removed no longer exists.
#
# TRAPS: beat5 grows an orange cape after ~8.7s; tide's usable tail ends at
# 11.6s; mixupA goes featureless after ~4.0s (the cloud loses its limbs); and
# mixupB does NOT look at the camera until ~2.8s — its first 1.5s is just the
# dust cloud again, which clip A already showed. Starting mixupB at 1.60 catches
# the burst-apart and lands on the held camera look.

# the logo outro card, as a real 1.6s video segment
ffmpeg -y -v error -loop 1 -t 2.0 -i assets/concept/brand/outro_cast.png \
  -vf "scale=720:1280:force_original_aspect_ratio=decrease,pad=720:1280:-1:-1,fps=30,setsar=1" \
  -an -c:v libx264 -crf 17 -preset medium -pix_fmt yuv420p $BUILD/outro.mp4

rm -f $BUILD/concat.txt
for row in $segs; do
  set -- ${=row}; name=$1; f=$2; ss=$3; d=$4; crop=$5
  if [[ -n "$crop" ]]; then
    VF="crop=iw*${crop}:ih*${crop},scale=720:1280:force_original_aspect_ratio=decrease,pad=720:1280:-1:-1,fps=30,setsar=1"
  else
    VF="scale=720:1280:force_original_aspect_ratio=decrease,pad=720:1280:-1:-1,fps=30,setsar=1"
  fi
  ffmpeg -y -v error -ss $ss -t $d -i $f \
    -vf "$VF" \
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
# The ending changed shape, so the music does too. It is now TWO stems:
#   music1  the action bed, from the top, fading out into the quiet turn
#   music2  the button — the beat comes BACK for the scuffle and carries the
#           logo card out. Without it the funniest beat in the episode plays
#           over ocean noise and the outro lands on nothing.
# Between them the ocean wash carries the turn alone, which is the point: the
# quiet is what makes the scuffle land.
CONTACT_MS=35800   # sword meets skull, in finished-timeline milliseconds
SWING_MS=35350     # the whoosh just before it
SCUFFLE_IN=53.20   # the mix-up starts here
MUSIC_FADE=42.00   # music1 starts leaving as the turn begins

ffmpeg -y -v error -i assets/music/battle_theme.mp3 \
  -af "atrim=0:46.0,afade=t=out:st=${MUSIC_FADE}:d=4.0,volume=0.62" \
  -ac 2 -ar 48000 $BUILD/music.wav

# music1 ducks under the voice bus so Arthur is never buried (v3's flat bed was
# the complaint). Sidechain key = the VO mix, not the master.
ffmpeg -y -v error -i $BUILD/music.wav -i $BUILD/voice.wav \
  -filter_complex "[0][1]sidechaincompress=threshold=0.02:ratio=9:attack=15:release=350[a]" \
  -map "[a]" -ac 2 -ar 48000 -t $DUR $BUILD/music_ducked.wav

# music2: pulled from 30s into the track (past the buildup, full groove) so the
# scuffle re-enters ON energy instead of on another slow ramp. No ducking needed
# — all five VO lines are done by 33.5s.
ffmpeg -y -v error -i assets/music/battle_theme.mp3 \
  -af "atrim=30:37.5,asetpts=PTS-STARTPTS,adelay=53000:all=1,afade=t=in:st=53.0:d=0.4,volume=0.66" \
  -ac 2 -ar 48000 -t $DUR $BUILD/music2.wav

# Ocean wash: brown noise, lowpassed, slow swell — carries the turn on its own.
# It now bows OUT under the scuffle rather than running to the end.
ffmpeg -y -v error -f lavfi -i "anoisesrc=c=brown:r=48000:a=0.28:d=${DUR}" \
  -af "lowpass=f=520,highpass=f=90,tremolo=f=0.12:d=0.55,afade=t=in:st=40:d=4,afade=t=out:st=53.0:d=1.5,volume=2.6" \
  -ac 2 $BUILD/ocean.wav

ffmpeg -y -v error -i assets/sfx/swing.wav -af "adelay=${SWING_MS}:all=1,volume=2.2" \
  -ac 2 -ar 48000 -t $DUR $BUILD/swing.wav
ffmpeg -y -v error -i assets/sfx/drop_land.wav -af "adelay=${CONTACT_MS}:all=1,volume=1.5" \
  -ac 2 -ar 48000 -t $DUR $BUILD/impact.wav

# Scuffle hits: four quick comic thumps inside the dust cloud, alternating two
# different sounds so it reads as a tussle and not a metronome. Kept well under
# the music so it is texture, not percussion.
scuffle=(
  "hit_chomp.wav 53450 1.0"
  "hit_claw.wav  53950 0.9"
  "hit_chomp.wav 54500 0.95"
  "hit_claw.wav  55050 0.85"
)
sc_inputs=(); sc_filters=""; sc_labels=""; i=0
for row in $scuffle; do
  set -- ${=row}; f=$1; ms=$2; vol=$3
  sc_inputs+=(-i assets/sfx/$f)
  sc_filters="${sc_filters}[$i]adelay=${ms}:all=1,volume=${vol}[c$i];"
  sc_labels="${sc_labels}[c$i]"
  i=$((i+1))
done
ffmpeg -y -v error $sc_inputs \
  -filter_complex "${sc_filters}${sc_labels}amix=inputs=4:duration=longest:normalize=0[a]" \
  -map "[a]" -ac 2 -ar 48000 -t $DUR $BUILD/scuffle.wav

ffmpeg -y -v error -i $BUILD/music_ducked.wav -i $BUILD/music2.wav -i $BUILD/ocean.wav \
  -i $BUILD/impact.wav -i $BUILD/swing.wav -i $BUILD/scuffle.wav -i $BUILD/voice.wav \
  -filter_complex "[0][1][2][3][4][5][6]amix=inputs=7:duration=longest:normalize=0[a]" \
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
