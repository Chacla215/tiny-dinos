extends Node
## Throwaway FEEL probe for the rig wobble PROFILES (dino_rig.gd). Builds each
## dino's DinoRig in isolation, drives _process with a fixed timestep (headless,
## instant — no real-time waits), kicks it with a standard hit, and measures the
## spring response that defines each dino's CHARACTER:
##   idle teeter amplitude, peak whole-body lean on a hit, lean settle time, lean
##   wobble count (drunk oscillations), peak head + tail deflection.
## Intent (PROGRESS): raptor/pterry wobbliest; trike/bronto/anky planted/immovable.
## Headless:  /opt/homebrew/bin/godot --headless --quit-after 300 scenes/rig_dynamics_probe.tscn
## Delete with the other floppy throwaways once the rig feel is locked.

const DT := 1.0 / 60.0

func _ready() -> void:
	print("rig wobble dynamics — standard hit (dir +x, power 1.0)")
	print("%-8s %7s %8s %9s %7s %8s %8s" % [
		"dino", "teeter", "pk_lean", "settle_s", "wobbles", "pk_head", "pk_tail"])
	for dino in ["raptor", "pterry", "ralph", "trike", "bronto", "anky"]:
		_probe(dino)
	get_tree().quit()

func _probe(dino: String) -> void:
	var r := DinoRig.new()
	add_child(r)
	if not r.build_for(dino, null):
		print("%-8s  (rig invalid — parts missing?)" % dino)
		r.queue_free()
		return
	r.set_process(false)   # we tick it ourselves for determinism + speed
	r.set_facing(true)
	r.play("idle")

	# --- idle teeter: settle, then measure the standing-sway amplitude ---
	for i in 120:
		r._process(DT)
	var teeter := 0.0
	for i in 180:                       # ~3s, covers a teeter cycle
		r._process(DT)
		teeter = maxf(teeter, absf(r._lean))

	# --- standard hit, then watch the lean spring ring down ---
	r.reset_pose()
	r._process(DT)
	r.hit(Vector2(1.0, -0.25), 1.0)
	var pk_lean := 0.0
	var pk_head := 0.0
	var pk_tail := 0.0
	# wobble = a full swing past upright: count lean zero-crossings where the swing
	# since the last crossing actually reached a meaningful angle (ignore teeter).
	var wobbles := 0
	var prev_lean := r._lean
	var swing_peak := 0.0
	var settle_s := -1.0
	var calm_run := 0
	for i in 240:                       # 4s
		r._process(DT)
		var t := i * DT
		pk_lean = maxf(pk_lean, absf(r._lean))
		swing_peak = maxf(swing_peak, absf(r._lean))
		if r._limbs.has("head"):
			pk_head = maxf(pk_head, absf(r._limbs["head"].angle))
		if r._limbs.has("tail"):
			pk_tail = maxf(pk_tail, absf(r._limbs["tail"].angle))
		if signf(r._lean) != signf(prev_lean) and prev_lean != 0.0:
			if swing_peak > 2.0:
				wobbles += 1
			swing_peak = 0.0
		prev_lean = r._lean
		# settle = first time |lean| stays under 1.5 deg for 0.25s straight
		if absf(r._lean) < 1.5:
			calm_run += 1
			if calm_run >= 15 and settle_s < 0.0:
				settle_s = t - 0.25
		else:
			calm_run = 0

	var settle_str := "%.2f" % settle_s if settle_s >= 0.0 else ">4"
	print("%-8s %7.1f %8.1f %9s %7d %8.1f %8.1f" % [
		dino, teeter, pk_lean, settle_str, wobbles, pk_head, pk_tail])
	r.queue_free()
