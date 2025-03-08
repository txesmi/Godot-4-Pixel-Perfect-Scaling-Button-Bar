@tool
extends EditorPlugin


const PPSBUTTON : String = "PPSButton"
const PPSBBAR : String = "PPSBBar"


func _enter_tree():
	add_custom_type( PPSBUTTON, "BaseButton", preload( "pixel_perfect_scaling_button.gd" ), EditorInterface.get_editor_theme().get_icon( "Button", "EditorIcons" ) )
	add_custom_type( PPSBBAR, "Container", preload( "pixel_perfect_scaling_button_bar.gd" ), EditorInterface.get_editor_theme().get_icon( "Container", "EditorIcons" ) )


func _exit_tree():
	remove_custom_type( PPSBUTTON )
	remove_custom_type( PPSBBAR )
