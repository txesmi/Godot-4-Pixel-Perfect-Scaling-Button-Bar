@tool
class_name PPSBBar
extends Container


enum LayoutModes {
	POSITION = 0,
	ANCHORS = 1,
	CONTAINER = 2
}


enum PositionPresets {
	FREE = -1, ## Free location. 
	TOP_LEFT = Control.PRESET_TOP_LEFT, ## Snap to top-left corner of its parent
	TOP = Control.PRESET_CENTER_TOP, ## Snap centered to the top of its parent
	TOP_RIGHT = Control.PRESET_TOP_RIGHT, ## Snap to top-right corner of its parent
	CENTER_LEFT = Control.PRESET_CENTER_LEFT, ## Snap centered to the left side of its parent
	CENTER = Control.PRESET_CENTER,  ## Snap centered to its parent
	CENTER_RIGHT = Control.PRESET_CENTER_RIGHT, ## Snap centered to the right side of its parent
	BOTTON_LEFT = Control.PRESET_BOTTOM_LEFT, ## Snap to bottom-left corner of its parent
	BOTTON = Control.PRESET_CENTER_BOTTOM, ## Snap centered to the bottom of its parent
	BOTTOM_RIGHT = Control.PRESET_BOTTOM_RIGHT ## Snap to bottom-right corner of its parent
}


## Time lapse of the animation
@export_range( 0.001, 1.0, 0.001, "or_greater") var animation_time : float = 0.1 :
	set( _value ):
		animation_time = _value
		for _child in get_children():
			if _child is PPSButton:
				_child.animation_time = _value


## Method used to locate the bar and animate the buttons
@export var positioning : PositionPresets = PositionPresets.FREE :
	set( _value ):
		positioning = _value
		
		#var _parent = get_parent()
		#if _parent is Container:
			#return
		
		if positioning == PositionPresets.FREE:
			layout_mode = int(LayoutModes.POSITION)
		else:
			layout_mode = int(LayoutModes.ANCHORS)
		
		do_refresh()


## Space between the bar and its anchor/pivot
@export var padding : int = 0 :
	set( _value ):
		padding = _value
		
		do_refresh()


## Press this 'button' if you see any discordance in the editor
@export_tool_button( "Refresh", "Callable" ) var refresh_action := Callable(do_refresh)



var already_sorted : bool = false
var already_refreshed : bool = false

var pointed_child : Variant = null
var animation_tween : Tween = null


func _validate_property( _property ):
	match _property.name:
		"size", "rotation", "custom_minimum_size", "clip_contents", \
		"layout_direction", "size_flags_horizontal", "size_flags_vertical","size_flags_stretch_ratio", \
		"layout_mode", "anchors_preset", "theme", "theme_type_variation":
			_property.usage = PROPERTY_USAGE_NO_EDITOR
		
		"position", "pivot_offset":
			if positioning != PositionPresets.FREE:
				_property.usage = PROPERTY_USAGE_NO_EDITOR
		
		"padding", "refresh":
			if positioning == PositionPresets.FREE:
				_property.usage = PROPERTY_USAGE_NO_EDITOR


func _init():
	tree_entered.connect( _on_tree_entered )
	child_entered_tree.connect( _on_child_entered_tree )
	child_exiting_tree.connect( _on_child_exiting_tree )
	child_order_changed.connect( _on_child_order_changed )


func _on_tree_entered():
	do_refresh()


func _on_tree_exited():
	if animation_tween != null:
		animation_tween.kill()
		animation_tween = null


func child_pivot_offset_from_anchors( _child ):
	var _vec : Vector2 = Vector2.ZERO
	_vec.x = floor( _child.custom_minimum_size.x * ( anchor_left + anchor_right ) * 0.5 )
	_vec.y = floor( _child.custom_minimum_size.y * ( anchor_top + anchor_bottom ) * 0.5 )
	_child.pivot_offset = _vec
	if _child is PPSButton:
		_child.origin = _child.pivot_offset


func child_origin_from_pivot_offset( _child ):
	if size.x == 0 or size.y == 0:
		return
	_child.pivot_offset = floor( _child.custom_minimum_size * pivot_offset / size )
	if _child is PPSButton:
		_child.origin = _child.pivot_offset


func _on_child_mouse_entered( _child ):
	pointed_child = _child
	already_sorted = false
	sort_animated.call_deferred()


func _on_child_mouse_exited( _child ):
	if pointed_child == _child:
		pointed_child = null
	already_sorted = false
	sort_animated.call_deferred()


func _on_child_minimum_size_changed( _child ):
	if not _child is PPSButton:
		_child.size = _child.custom_minimum_size
		
		do_refresh()


func method_animate( _new_pos : float, _node : Variant ):
	_node.position.x = _new_pos - _node.pivot_offset.x


func sort_children():
	#if not already_sorted:
		already_sorted = true
		
		var _children = get_children()
		if _children.size() == 0:
			return
		
		var _anchor_x = pivot_offset.x / size.x
		
		var _grid := PackedInt32Array()
		_grid.resize( _children.size() )
		var _width : int = 0
		
		_grid[0] = int( pivot_offset.x )
		var _last_i = _children.size() - 1
		for _i in _last_i:
			var _child = _children[_i]
			if _child.is_queued_for_deletion():
				_grid[_i + 1] = _grid[_i]
				continue
			
			_grid[_i] += _child.pivot_offset.x
			_grid[_i + 1] = _grid[_i] + _child.custom_minimum_size.x - _child.pivot_offset.x
			_width += _child.custom_minimum_size.x
		
		var _last_child = _children[_last_i]
		if not _last_child.is_queued_for_deletion():
			_grid[_last_i] += _last_child.pivot_offset.x
			_width += _last_child.custom_minimum_size.x
		
		for _i in _children.size():
			var _child = _children[_i]
			if _child.is_queued_for_deletion():
				continue
			
			_child.position.x = _grid[_i] - _child.pivot_offset.x - floor( _width * _anchor_x )
			_child.position.y = pivot_offset.y - _child.pivot_offset.y


func sort_animated():
	already_sorted = false
	sort_animated_deferred.call_deferred()


func sort_animated_deferred():
	if not already_sorted:
		already_sorted = true
		
		var _children = get_children()
		if _children.size() == 0:
			return
		
		if animation_tween:
			animation_tween.kill()
		animation_tween = create_tween().set_parallel( true )
		
		var _anchor_x = pivot_offset.x / size.x
		
		var _grid := PackedInt32Array()
		_grid.resize( _children.size() )
		var _width : int = 0
		
		_grid[0] = int( pivot_offset.x )
		var _last_i = _children.size() - 1
		for _i in _last_i:
			var _child = _children[_i]
			if _child is PPSButton:
				_grid[_i] += _child.origin.x
				_grid[_i + 1] = _grid[_i] + _child.custom_minimum_size.x - _child.origin.x
				_width += _child.custom_minimum_size.x
			else:
				_grid[_i] += _child.pivot_offset.x
				_grid[_i + 1] = _grid[_i] + _child.custom_minimum_size.x - _child.pivot_offset.x
				_width += _child.custom_minimum_size.x
		var _last_child = _children[_last_i]
		if _last_child is PPSButton:
			_grid[_last_i] += _last_child.origin.x
			_width += _last_child.custom_minimum_size.x
		else:
			_grid[_last_i] += _last_child.pivot_offset.x
			_width += _last_child.custom_minimum_size.x
		
		if pointed_child:
			var _pointed_index = _children.find( pointed_child )
			animation_tween.tween_method( 
				method_animate.bind(pointed_child), 
				pointed_child.position.x + pointed_child.pivot_offset.x, 
				_grid[_pointed_index] - floor( _width * _anchor_x ), 
				animation_time 
			)
			
			var _offset_x = 0
			if pointed_child is PPSButton:
				_offset_x = pointed_child.hover_size.x - pointed_child.custom_minimum_size.x
			
			for _i in range( _pointed_index + 1, _children.size() ):
				var _child = _children[_i]
				animation_tween.tween_method( 
					method_animate.bind(_child), 
					_child.position.x + _child.pivot_offset.x, 
					_grid[_i] - floor( _width * _anchor_x - _offset_x * ( 1.0 - _anchor_x ) ), 
					animation_time 
				)
			
			for _i in range( _pointed_index - 1, -1, -1 ):
				var _child = _children[_i]
				animation_tween.tween_method( 
					method_animate.bind(_child), 
					_child.position.x + _child.pivot_offset.x, 
					_grid[_i] - floor( ( _width + _offset_x ) * _anchor_x ), 
					animation_time 
				)
			
		else:
			for _i in _children.size():
				var _child = _children[_i]
				animation_tween.tween_method( 
					method_animate.bind(_child), 
					_child.position.x + _child.pivot_offset.x, 
					_grid[_i] - floor( _width * _anchor_x ), 
					animation_time 
				)


func pivot_offset_from_anchors():
	pivot_offset.x = floor( size.x * ( anchor_left + anchor_right ) * 0.5 )
	pivot_offset.y = floor( size.y * ( anchor_top + anchor_bottom ) * 0.5 )


func compute_minimum_size():
	var _children = get_children()
	var _size : Vector2 = Vector2.ZERO
	for _child in _children:
		if _child.is_queued_for_deletion():
			continue
		if not _child.visible:
			continue
		_size.x += _child.custom_minimum_size.x
		_size.y = max( _size.y, _child.custom_minimum_size.y )
	
	custom_minimum_size = _size
	size = custom_minimum_size


func _on_child_entered_tree( _child ):
	match layout_mode:
		LayoutModes.ANCHORS:
			child_pivot_offset_from_anchors( _child )
		LayoutModes.POSITION:
			child_origin_from_pivot_offset( _child )
	
	if _child is PPSButton:
		_child.animation_time = animation_time
		
		if not Engine.is_editor_hint():
			if not _child.mouse_entered.is_connected( _on_child_mouse_entered ):
				_child.mouse_entered.connect( _on_child_mouse_entered.bind(_child) )
			if not _child.mouse_exited.is_connected( _on_child_mouse_exited ):
				_child.mouse_exited.connect( _on_child_mouse_exited.bind(_child) )
		
	else:
		if not _child.minimum_size_changed.is_connected( _on_child_minimum_size_changed ):
			_child.minimum_size_changed.connect( _on_child_minimum_size_changed.bind(_child) )
	
	do_refresh()


func _on_child_exiting_tree( _child ):
	if _child.minimum_size_changed.is_connected( _on_child_minimum_size_changed ):
		_child.minimum_size_changed.disconnect( _on_child_minimum_size_changed )
	if _child.mouse_entered.is_connected( _on_child_mouse_entered ):
		_child.mouse_entered.disconnect( _on_child_mouse_entered.bind(_child) )
	if _child.mouse_exited.is_connected( _on_child_mouse_exited ):
		_child.mouse_exited.disconnect( _on_child_mouse_exited.bind(_child) )
	
	do_refresh()


func _on_child_order_changed():
	do_refresh()


func do_refresh():
	already_refreshed = false
	do_refresh_deferred.call_deferred()


func do_refresh_deferred():
	if already_refreshed:
		return
	
	already_refreshed = true
	
	compute_minimum_size()
	
	var _parent = get_parent()
	#if not _parent is Container:
	if positioning != PositionPresets.FREE:
		set_anchors_and_offsets_preset( 
			int(positioning) as Control.LayoutPreset, 
			Control.LayoutPresetMode.PRESET_MODE_KEEP_SIZE, 
			padding )
		pivot_offset_from_anchors()
		
		for _child in get_children():
			child_pivot_offset_from_anchors( _child )
		
	else:
		for _child in get_children():
			child_origin_from_pivot_offset( _child )
	
	sort_children()
	
	notify_property_list_changed()
	queue_redraw()
