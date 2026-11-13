class_name PerfOverlay
extends CanvasLayer
## The built-in performance overlay (F3), for when a GPU overlay can't hook the game: frames per second, the frame
## time with a small graph of the last couple of seconds, the CPU and GPU time of a frame (when the renderer
## reports them), draw calls, the graphics tier, the frame-rate cap and the resolution. Small, in the top-right
## corner.

const MS: float = 1000.0
const MARGIN: int = 10
const GRAPH_LINE: Color = Color(1.0, 0.78, 0.4)
const GRAPH_BACK: Color = Color(0.05, 0.05, 0.1, 0.7)
const TARGET_LINE: Color = Color(0.5, 0.9, 0.6, 0.6)

var _label: Label
var _graph: Control
var _times: PackedFloat32Array = PackedFloat32Array()
var _refresh: float = 0.0
var _display: DisplaySettings
var _graphics: GraphicsSettings


func setup(display: DisplaySettings, graphics: GraphicsSettings) -> void:
	name = "PerfOverlay"
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_display = display
	_graphics = graphics
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_KEEP_SIZE, MARGIN)
	box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	add_child(box)
	_label = UiStyle.label("", Tuning.i("perf_overlay", "font_size"))
	box.add_child(_label)
	_graph = Control.new()
	var size: Array = Tuning.doc("tuning")["perf_overlay"]["graph_size"]
	_graph.custom_minimum_size = Vector2(float(size[0]), float(size[1]))
	_graph.draw.connect(_draw_graph)
	box.add_child(_graph)
	visible = false
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)


func toggle() -> void:
	visible = not visible


func _process(delta: float) -> void:
	_times.append(delta * MS)
	var keep: int = int(Tuning.f("perf_overlay", "graph_seconds") / maxf(delta, 1.0 / MS))
	if _times.size() > keep:
		_times = _times.slice(_times.size() - keep)
	_refresh -= delta
	if not visible or _refresh > 0.0:
		return
	_refresh = Tuning.f("perf_overlay", "refresh_seconds")
	_label.text = text()
	_graph.queue_redraw()


## The overlay's lines (also used by the smoke test).
func text() -> String:
	var viewport: RID = get_viewport().get_viewport_rid()
	var cpu: float = RenderingServer.viewport_get_measured_render_time_cpu(viewport)
	var gpu: float = RenderingServer.viewport_get_measured_render_time_gpu(viewport)
	var size: Vector2i = get_viewport().get_visible_rect().size
	var window: Vector2i = DisplayServer.window_get_size() if DisplayServer.get_name() != "headless" else size
	var cap: String = "uncapped" if _display.frame_cap == DisplaySettings.UNCAPPED else "%d fps" % _display.frame_cap
	var mean: float = 0.0
	for value: float in _times:
		mean += value / maxf(_times.size(), 1.0)
	return "%d fps   %.1f ms\nCPU %.1f ms   GPU %.1f ms\nDraw calls %d\n%s   cap %s   VSync %s\n%dx%d" % [
		Engine.get_frames_per_second(), mean, cpu, gpu, RenderingServer.get_rendering_info(
		RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), _graphics.tier.capitalize(), cap,
		"on" if _display.vsync else "off", window.x, window.y]


func _draw_graph() -> void:
	var size: Vector2 = _graph.size
	_graph.draw_rect(Rect2(Vector2.ZERO, size), GRAPH_BACK)
	var top: float = Tuning.f("perf_overlay", "graph_ms_top")
	var target: float = size.y * (1.0 - (MS / maxf(_display.frame_cap, 1.0)) / top)
	if _display.frame_cap != DisplaySettings.UNCAPPED:
		_graph.draw_line(Vector2(0.0, target), Vector2(size.x, target), TARGET_LINE)
	var points := PackedVector2Array()
	for index: int in _times.size():
		points.append(Vector2(size.x * index / maxf(_times.size() - 1, 1.0), size.y * (1.0 - minf(_times[index] /
			top, 1.0))))
	if points.size() > 1:
		_graph.draw_polyline(points, GRAPH_LINE)
