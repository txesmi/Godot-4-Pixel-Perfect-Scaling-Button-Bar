@tool
class_name PPSButton
extends BaseButton



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

var button_material : ShaderMaterial = preload( "animated_button_material.tres" )


## Texture used when the button is unhovered. Its size determines the size of the button
@export var normal_texture : Texture2D = null :
	set( _new_value ):
		if _new_value is AnimatedTexture:
			printerr("No animated texture support, sorry :(" )
			return
		
		if Engine.is_editor_hint():
			if normal_texture != null:
				if normal_texture.changed.is_connected( _on_normal_texture_changed ):
					normal_texture.changed.disconnect( _on_normal_texture_changed )
			
			normal_texture = _new_value
			
			if normal_texture != null:
				if not normal_texture.changed.is_connected( _on_normal_texture_changed ):
					normal_texture.changed.connect( _on_normal_texture_changed )
			
		else:
			normal_texture = _new_value
		
		do_refresh()


## Texture used when the button is hovered.
@export var hover_texture : Texture2D = null :
	set( _new_value ):
		if _new_value is AnimatedTexture:
			printerr("No animated texture support yet, sorry :(" )
			return
		
		if Engine.is_editor_hint():
			if hover_texture != null:
				if hover_texture.changed.is_connected( _on_hover_texture_changed ):
					hover_texture.changed.disconnect( _on_hover_texture_changed )
			
			hover_texture = _new_value
			
			if hover_texture != null:
				if not hover_texture.changed.is_connected( _on_hover_texture_changed ):
					hover_texture.changed.connect( _on_hover_texture_changed )
			
		else:
			hover_texture = _new_value
		
		do_refresh()


## Texture used when the button is pressed.
@export var pressed_texture : Texture2D = null :
	set( _new_value ):
		if _new_value is AnimatedTexture:
			printerr("No animated texture support yet, sorry :(" )
			return
		
		if Engine.is_editor_hint():
			if pressed_texture != null:
				if pressed_texture.changed.is_connected( _on_pressed_texture_changed ):
					pressed_texture.changed.disconnect( _on_pressed_texture_changed )
			
			pressed_texture = _new_value
			
			if pressed_texture != null:
				if not pressed_texture.changed.is_connected( _on_pressed_texture_changed ):
					pressed_texture.changed.connect( _on_pressed_texture_changed )
			
		else:
			pressed_texture = _new_value
		
		do_refresh()


## Time lapse of the animation
@export_range( 0.001, 1.0, 0.001, "or_greater") var animation_time : float = 0.1 :
	set( _value ):
		animation_time = _value
		resize_tween_time = _value


## Method used to locate and animate the button
@export var positioning : PositionPresets = PositionPresets.FREE :
	set( _value ):
		positioning = _value
		
		var _parent = get_parent()
		if _parent is Container:
			return
		
		if positioning == PositionPresets.FREE:
			layout_mode = int(LayoutModes.POSITION)
		else:
			layout_mode = int(LayoutModes.ANCHORS)
		
		do_refresh()


## Space between the button and its anchor/pivot
@export var padding : int = 0 :
	set( _value ):
		padding = _value
		
		do_refresh()


## Press this 'button' if you see any discordance in the editor
@export var refresh : bool = false :
	set( _value ):
		do_refresh()


func _validate_property( _property ):
	match _property.name:
		"size", "scale", "rotation", "custom_minimum_size", "clip_contents", \
		"disabled", "toggle_mode", "button_pressed", "keep_pressed_outside", \
		"layout_direction", "size_flags_horizontal", "size_flags_vertical","size_flags_stretch_ratio", \
		"layout_mode", "anchors_preset", "theme", "theme_type_variation":
			_property.usage = PROPERTY_USAGE_NO_EDITOR
		
		"position", "pivot_offset":
			if positioning != PositionPresets.FREE:
				_property.usage = PROPERTY_USAGE_NO_EDITOR
		
		"padding", "refresh":
			var _parent = get_parent()
			if _parent:
				if _parent is Container:
					_property.usage = PROPERTY_USAGE_NO_EDITOR
				elif positioning == PositionPresets.FREE:
					_property.usage = PROPERTY_USAGE_NO_EDITOR
		
		"positioning":
			var _parent = get_parent()
			if _parent:
				if _parent is Container:
					_property.usage = PROPERTY_USAGE_NO_EDITOR
		
		"animation_time":
			var _parent = get_parent()
			if _parent:
				if _parent is PPSBBar:
					_property.usage = PROPERTY_USAGE_NO_EDITOR



var already_refreshed : bool = false

var background : TextureRect = null

var origin : Vector2 = Vector2.ZERO
var hover_size : Vector2 = Vector2.ZERO
var pressed_size : Vector2 = Vector2.ZERO

var resize_tween : Tween = null
var resize_tween_time : float = animation_time
var resize_tween_factor : float = 0.0

var pressed_tween : Tween = null


func _init():
	tree_entered.connect( _on_tree_entered )
	tree_exited.connect( _on_tree_exited )


func _on_tree_entered():
	if not background:
		background_create()
	
	update_normal_texture()
	update_hover_texture()
	update_pressed_texture()
	
	origin = pivot_offset
	
	if not Engine.is_editor_hint():
		if not mouse_entered.is_connected( _on_mouse_hover ):
			mouse_entered.connect( _on_mouse_hover.bind( 1.0 ) )
		if not mouse_exited.is_connected( _on_mouse_hover ):
			mouse_exited.connect( _on_mouse_hover.bind( 0.0 ) )
		if not button_down.is_connected( _on_button_down ):
			button_down.connect( _on_button_down )
		if not button_up.is_connected( _on_button_up ):
			button_up.connect( _on_button_up )


func _on_tree_exited():
	if mouse_entered.is_connected( _on_mouse_hover ):
		mouse_entered.disconnect( _on_mouse_hover )
	if mouse_exited.is_connected( _on_mouse_hover ):
		mouse_exited.disconnect( _on_mouse_hover )
	if button_down.is_connected( _on_button_down ):
		button_down.disconnect( _on_button_down )
	if button_up.is_connected( _on_button_up ):
		button_up.disconnect( _on_button_up )
	
	if resize_tween != null:
		resize_tween.kill()
		resize_tween = null
	if pressed_tween != null:
		pressed_tween.kill()
		pressed_tween = null


func _on_normal_texture_changed():
	do_refresh()


func _on_hover_texture_changed():
	update_hover_texture()
	notify_property_list_changed()
	queue_redraw()



func _on_pressed_texture_changed():
	update_pressed_texture()
	notify_property_list_changed()
	queue_redraw()


func pivot_offset_from_anchors():
	pivot_offset.x = floor( custom_minimum_size.x * ( anchor_left + anchor_right ) * 0.5 )
	pivot_offset.y = floor( custom_minimum_size.y * ( anchor_top + anchor_bottom ) * 0.5 )
	origin = pivot_offset


func background_create():
	background = TextureRect.new()
	add_child( background )
	background.show_behind_parent = true
	background.size = custom_minimum_size
	background.material = button_material.duplicate()


func update_normal_texture():
	#print( "update_normal_texture" )
	if normal_texture:
		if normal_texture is AtlasTexture:
			custom_minimum_size = normal_texture.region.size + normal_texture.margin.size
			
			if background:
				background.custom_minimum_size = custom_minimum_size
				background.size = custom_minimum_size
				background.texture = normal_texture
				
				if background.material:
					background.material.set_shader_parameter( "normal_tex", normal_texture )
					if normal_texture.atlas:
						var _tex_size : Vector2 = normal_texture.atlas.get_size()
						background.material.set_shader_parameter( "normal_uv", 
							Vector4( 
								( normal_texture.region.position.x - normal_texture.margin.position.x ) / _tex_size.x,
								( normal_texture.region.position.y - normal_texture.margin.position.y ) / _tex_size.y,
								custom_minimum_size.x / _tex_size.x,
								custom_minimum_size.y / _tex_size.y
							)
						)
			
		else:
			var _tex_size : Vector2 = normal_texture.get_size()
			custom_minimum_size = _tex_size
			
			if background:
				background.custom_minimum_size = custom_minimum_size
				background.size = custom_minimum_size
				background.texture = normal_texture
				
				if background.material:
					background.material.set_shader_parameter( "normal_tex", normal_texture )
					background.material.set_shader_parameter( "normal_uv", Vector4( 0.0, 0.0, 1.0, 1.0 ) )
		
	else:
		custom_minimum_size = Vector2.ZERO
		
		if background:
			background.custom_minimum_size = custom_minimum_size
			background.size = custom_minimum_size
			background.texture = normal_texture
			
			if background.material:
				background.material.set_shader_parameter( "normal_tex", normal_texture )
				background.material.set_shader_parameter( "normal_uv", Vector4( 0.0, 0.0, 1.0, 1.0 ) )


func update_hover_texture():
	if hover_texture:
		if hover_texture is AtlasTexture:
			hover_size.x = max( hover_texture.region.size.x + hover_texture.margin.size.x, custom_minimum_size.x )
			hover_size.y = max( hover_texture.region.size.y + hover_texture.margin.size.y, custom_minimum_size.y )
			
			if background:
				if background.material:
					background.material.set_shader_parameter( "hover_tex", hover_texture )
					
					if hover_texture.atlas:
						var _tex_size : Vector2 = hover_texture.atlas.get_size()
						background.material.set_shader_parameter( "hover_uv", 
							Vector4( 
								( hover_texture.region.position.x - hover_texture.margin.position.x ) / _tex_size.x,
								( hover_texture.region.position.y - hover_texture.margin.position.y ) / _tex_size.y,
								hover_size.x / _tex_size.x,
								hover_size.y / _tex_size.y
							)
						)
					else:
						background.material.set_shader_parameter( "hover_uv", Vector4( 0.0, 0.0, 1.0, 1.0 ) )
			
		else:
			var _tex_size : Vector2 = hover_texture.get_size()
			hover_size.x = max( _tex_size.x, custom_minimum_size.x )
			hover_size.y = max( _tex_size.y, custom_minimum_size.y )
			
			if background:
				if background.material:
					background.material.set_shader_parameter( "hover_tex", hover_texture )
					background.material.set_shader_parameter( "hover_uv", Vector4( 0.0, 0.0, 1.0, 1.0 ) )
		
	else:
		hover_size = custom_minimum_size
		if background:
			if background.material:
				background.material.set_shader_parameter( "hover_tex", hover_texture )
				background.material.set_shader_parameter( "hover_uv", Vector4( 0.0, 0.0, 1.0, 1.0 ) )


func update_pressed_texture():
	if pressed_texture:
		if pressed_texture is AtlasTexture:
			pressed_size.x = max( pressed_texture.region.size.x + pressed_texture.margin.size.x, custom_minimum_size.x )
			pressed_size.y = max( pressed_texture.region.size.y + pressed_texture.margin.size.y, custom_minimum_size.y )
			
			if background:
				if background.material:
					background.material.set_shader_parameter( "pressed_tex", pressed_texture )
					
					if pressed_texture.atlas:
						var _tex_size : Vector2 = pressed_texture.atlas.get_size()
						background.material.set_shader_parameter( "pressed_uv", 
							Vector4( 
								( pressed_texture.region.position.x - pressed_texture.margin.position.x ) / _tex_size.x,
								( pressed_texture.region.position.y - pressed_texture.margin.position.y ) / _tex_size.y,
								pressed_size.x / _tex_size.x,
								pressed_size.y / _tex_size.y
							)
						)
					else:
						background.material.set_shader_parameter( "pressed_uv", Vector4( 0.0, 0.0, 1.0, 1.0 ) )
			
		else:
			var _tex_size : Vector2 = pressed_texture.get_size()
			pressed_size.x = max( _tex_size.x, custom_minimum_size.x )
			pressed_size.y = max( _tex_size.y, custom_minimum_size.y )
			
			if background:
				if background.material:
					background.material.set_shader_parameter( "pressed_tex", pressed_texture )
					background.material.set_shader_parameter( "pressed_uv", Vector4( 0.0, 0.0, 1.0, 1.0 ) )
		
	else:
		pressed_size = custom_minimum_size
		if background:
			if background.material:
				background.material.set_shader_parameter( "pressed_tex", pressed_texture )
				background.material.set_shader_parameter( "pressed_uv", Vector4( 0.0, 0.0, 1.0, 1.0 ) )


func do_refresh():
	already_refreshed = false
	do_refresh_deferred.call_deferred()


func do_refresh_deferred():
	if already_refreshed:
		return
	
	already_refreshed = true
	
	update_normal_texture()
	update_hover_texture()
	update_pressed_texture()
	
	scale = Vector2(1.0, 1.0)
	size = custom_minimum_size
	rotation = 0.0
	
	var _parent = get_parent()
	if not _parent is Container:
		if positioning != PositionPresets.FREE:
			set_anchors_and_offsets_preset( int(positioning) as Control.LayoutPreset, Control.LayoutPresetMode.PRESET_MODE_KEEP_SIZE, padding )
			pivot_offset_from_anchors()
		
	
	notify_property_list_changed()
	queue_redraw()


# Animation ########################################################################################

func _on_mouse_hover( _factor_limit : float ):
	if custom_minimum_size.x == 0.0 or custom_minimum_size.y == 0.0:
		return
	
	var _time : float = animation_time
	if resize_tween != null:
		if resize_tween.is_running():
			_time *= resize_tween.get_total_elapsed_time() / resize_tween_time
		resize_tween.kill()
	
	resize_tween_time = _time
	
	resize_tween = create_tween()
	resize_tween.tween_method( method_resize, resize_tween_factor, _factor_limit, _time )


func method_resize( _factor : float ):
	resize_tween_factor = _factor
	
	var _pivot : Vector2 = position + pivot_offset
	
	size = custom_minimum_size + floor( _factor * ( hover_size - custom_minimum_size ) )
	pivot_offset = floor( size * origin / custom_minimum_size )
	
	background.size = size
	background.material.set_shader_parameter( "hover_factor", _factor )
	
	position = _pivot - pivot_offset


func _on_button_down():
	if pressed_tween != null:
		pressed_tween.kill()
	pressed_tween = null
	
	if background:
		if background.material:
			background.material.set_shader_parameter( "pressed_factor", 1.0 )


func _on_button_up():
	if pressed_tween != null:
		pressed_tween.kill()
	
	pressed_tween = create_tween() 
	pressed_tween.tween_method( method_pressed, 1.0, 0.0, animation_time )


func method_pressed( _factor : float ):
	if background:
		if background.material:
			background.material.set_shader_parameter( "pressed_factor", _factor )
