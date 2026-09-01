extends Node2D
## Stage-C polish: align loop with Phaser flappyWish (abstract art kept).

const W := 405.0
const H := 720.0
const GROUND_H := 60.0
const BIRD_X := 110.0
const PIPE_W := 69.0
const COIN_R := 14.0
const PRESPAWN := 3

@onready var _hud: Label = $UI/HUD
@onready var _diff_tag: Label = $UI/DiffTag
@onready var _hint: Label = $UI/Hint
@onready var _overlay: ColorRect = $UI/Overlay
@onready var _over_label: Label = $UI/Overlay/VBox/Msg
@onready var _retry: Button = $UI/Overlay/VBox/Retry
@onready var _home: Button = $UI/Overlay/VBox/Home
@onready var _bird: CharacterBody2D = $Bird
@onready var _bird_visual: Polygon2D = $Bird/Visual
@onready var _pipes: Node2D = $Pipes
@onready var _coins: Node2D = $Coins
@onready var _ground: ColorRect = $Ground
@onready var _sky: ColorRect = $Sky
@onready var _float_root: Node2D = $FloatScores
@onready var _ground_stripe: ColorRect = $GroundStripe

var _vy: float = 0.0
var _alive: bool = false
var _score: int = 0
var _pipe_points: int = 0
var _coin_points: int = 0
var _coins_collected: int = 0
var _cfg: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _scroll_x: float = 0.0
var _hint_t: float = 1.5
var _bird_w: float = 36.0
var _bird_h: float = 36.0

func _ready() -> void:
	_rng.randomize()
	_cfg = GameConfig.get_diff()
	_overlay.visible = false
	_retry.pressed.connect(_restart)
	_home.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/title.tscn")
	)
	_sky.color = Color(0.49, 0.74, 0.88)
	_ground.color = Color(0.35, 0.7, 0.35)
	_ground.position = Vector2(0, H - GROUND_H)
	_ground.size = Vector2(W, GROUND_H)
	_ground_stripe.position = Vector2(0, H - GROUND_H)
	_ground_stripe.size = Vector2(40, 8)
	_ground_stripe.color = Color(0.25, 0.55, 0.28)
	_diff_tag.text = str(_cfg["label"])
	_diff_tag.modulate = _cfg["color"]
	_reset_run()

func _restart() -> void:
	get_tree().reload_current_scene()

func _reset_run() -> void:
	_vy = 0.0
	_alive = true
	_score = 0
	_pipe_points = 0
	_coin_points = 0
	_coins_collected = 0
	_scroll_x = 0.0
	_hint_t = 1.5
	_hint.visible = true
	_hint.modulate.a = 1.0
	_hint.text = "点按起飞 · 吃金币加分"
	for c in _pipes.get_children():
		c.queue_free()
	for c in _coins.get_children():
		c.queue_free()
	for c in _float_root.get_children():
		c.queue_free()
	var bs: float = float(_cfg["bird_size"])
	var hs: float = float(_cfg["hitbox_scale"])
	_bird_w = bs * hs
	_bird_h = bs * hs
	_bird.position = Vector2(BIRD_X, H * 0.42)
	_bird_visual.color = _cfg["color"]
	_bird_visual.scale = Vector2(hs, hs)
	_bird_visual.rotation = 0.0
	var x := W + 40.0
	for i in PRESPAWN:
		_spawn_pipe_pair(x)
		x += float(_cfg["spawn_distance"])
	_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("flap") or (event is InputEventScreenTouch and event.pressed):
		_flap()
		get_viewport().set_input_as_handled()

func _flap() -> void:
	if not _alive:
		return
	_vy = float(_cfg["flap_impulse"])

func _physics_process(delta: float) -> void:
	if not _alive:
		return
	_vy = minf(_vy + float(_cfg["gravity"]) * delta, float(_cfg["max_fall"]))
	_bird.position.y += _vy * delta
	var tilt := clampf(_vy / float(_cfg["max_fall"]), -1.0, 1.0)
	_bird_visual.rotation = tilt * 0.7

	var speed: float = float(_cfg["pipe_speed"])
	_scroll_x += float(_cfg["ground_scroll"]) * delta
	_ground_stripe.position.x = fmod(-_scroll_x, 48.0)
	_sky.color = Color(0.49, 0.74, 0.88).lerp(Color(0.4, 0.65, 0.85), 0.15)

	if _hint_t > 0.0:
		_hint_t -= delta
		_hint.modulate.a = clampf(_hint_t / 0.4, 0.0, 1.0)
		if _hint_t <= 0.0:
			_hint.visible = false

	for p in _pipes.get_children():
		p.position.x -= speed * delta
		if not bool(p.get_meta("scored", false)):
			# Score when pipe center passes bird (matches original)
			if p.position.x + PIPE_W * 0.5 < BIRD_X:
				p.set_meta("scored", true)
				_pipe_points += GameConfig.PIPE_SCORE
				_score += GameConfig.PIPE_SCORE
				_float_score(Vector2(BIRD_X, _bird.position.y - 30), "+%d" % GameConfig.PIPE_SCORE, Color(1, 1, 1))
				_update_hud()
		if p.position.x < -PIPE_W - 20.0:
			p.queue_free()

	# Maintain pipe train
	var rightmost := -9999.0
	for p in _pipes.get_children():
		rightmost = maxf(rightmost, p.position.x)
	if rightmost < W - float(_cfg["spawn_distance"]):
		var nx := rightmost + float(_cfg["spawn_distance"])
		if rightmost < -100.0:
			nx = W + 40.0
		_spawn_pipe_pair(nx)

	for c in _coins.get_children():
		var coin := c as Node2D
		coin.position.x -= speed * delta
		var phase: float = float(coin.get_meta("bob", 0.0)) + 4.8 * delta
		coin.set_meta("bob", phase)
		var base_y: float = float(coin.get_meta("base_y"))
		coin.position.y = base_y + sin(phase) * 3.0
		coin.rotation += 2.4 * delta
		if coin.position.x < -40.0:
			coin.queue_free()
			continue
		if _aabb_hit_coin(coin):
			_coins_collected += 1
			_coin_points += GameConfig.COIN_SCORE
			_score += GameConfig.COIN_SCORE
			_float_score(coin.position, "+%d" % GameConfig.COIN_SCORE, Color(1.0, 0.88, 0.35))
			_update_hud()
			coin.queue_free()

	if _collides():
		_die()

func _spawn_pipe_pair(x: float) -> void:
	var gap: float = float(_cfg["pipe_gap"])
	var playable_h := H - GROUND_H
	var margin := 90.0
	var gap_y := _rng.randf_range(margin + gap * 0.5, playable_h - margin - gap * 0.5)

	var pair := Node2D.new()
	pair.position = Vector2(x, 0)
	pair.set_meta("scored", false)
	pair.set_meta("gap_y", gap_y)
	pair.set_meta("gap", gap)
	_pipes.add_child(pair)

	var top := ColorRect.new()
	top.color = Color(0.24, 0.55, 0.43)
	top.size = Vector2(PIPE_W, gap_y - gap * 0.5)
	top.position = Vector2(0, 0)
	pair.add_child(top)

	var bot := ColorRect.new()
	bot.color = Color(0.24, 0.55, 0.43)
	var bot_top := gap_y + gap * 0.5
	bot.position = Vector2(0, bot_top)
	bot.size = Vector2(PIPE_W, playable_h - bot_top)
	pair.add_child(bot)

	for y in [gap_y - gap * 0.5 - 12.0, bot_top]:
		var cap := ColorRect.new()
		cap.color = Color(0.16, 0.38, 0.29)
		cap.position = Vector2(-4, y)
		cap.size = Vector2(PIPE_W + 8, 18)
		pair.add_child(cap)

	# 1–3 coins vertically in gap (original rule)
	var count := 1 + _rng.randi_range(0, 2)
	var usable := maxf(24.0, gap - 36.0)
	var step := 0.0 if count == 1 else usable / float(count - 1)
	var start_y := gap_y - usable * 0.5
	for i in count:
		var cy := gap_y if count == 1 else start_y + step * float(i)
		var coin := Polygon2D.new()
		coin.color = Color(1.0, 0.85, 0.2)
		coin.polygon = PackedVector2Array([
			Vector2(0, -COIN_R), Vector2(COIN_R, 0), Vector2(0, COIN_R), Vector2(-COIN_R, 0)
		])
		coin.position = Vector2(x + PIPE_W * 0.5, cy)
		coin.set_meta("base_y", cy)
		coin.set_meta("bob", _rng.randf() * TAU)
		_coins.add_child(coin)

func _bird_box() -> Rect2:
	return Rect2(
		_bird.position.x - _bird_w * 0.5,
		_bird.position.y - _bird_h * 0.5,
		_bird_w,
		_bird_h
	)

func _aabb_hit_coin(coin: Node2D) -> bool:
	var cbox := Rect2(coin.position.x - COIN_R, coin.position.y - COIN_R, COIN_R * 2.0, COIN_R * 2.0)
	return _bird_box().intersects(cbox)

func _collides() -> bool:
	var playable_h := H - GROUND_H
	var box := _bird_box()
	if box.position.y < 0.0 or box.position.y + box.size.y > playable_h:
		return true
	for p in _pipes.get_children():
		var gap_y: float = float(p.get_meta("gap_y"))
		var gap: float = float(p.get_meta("gap"))
		var px: float = p.position.x
		var top_h := gap_y - gap * 0.5
		var bot_y := gap_y + gap * 0.5
		var top_box := Rect2(px, 0.0, PIPE_W, top_h)
		var bot_box := Rect2(px, bot_y, PIPE_W, playable_h - bot_y)
		if box.intersects(top_box) or box.intersects(bot_box):
			return true
	return false

func _float_score(pos: Vector2, text: String, color: Color) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.position = pos
	lbl.modulate = color
	lbl.add_theme_font_size_override("font_size", 18)
	_float_root.add_child(lbl)
	var tw := create_tween()
	tw.tween_property(lbl, "position:y", pos.y - 40.0, 0.6)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.6)
	tw.tween_callback(lbl.queue_free)

func _die() -> void:
	_alive = false
	var rec: Dictionary = SaveData.record(GameConfig.current_id, _score)
	_overlay.visible = true
	var title := "新纪录！" if bool(rec["is_new"]) else "旅途暂停"
	_over_label.text = "%s\n总分 %d\n穿管 %d  ·  金币 %d枚(+%d)\n本难度最高 %d" % [
		title, _score, _pipe_points, _coins_collected, _coin_points, int(rec["best"])
	]

func _update_hud() -> void:
	_hud.text = str(_score)
