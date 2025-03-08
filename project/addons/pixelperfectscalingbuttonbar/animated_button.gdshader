shader_type canvas_item;

uniform sampler2D normal_tex : filter_nearest;
uniform sampler2D hover_tex : filter_nearest;
uniform sampler2D pressed_tex : filter_nearest;
uniform vec4 normal_uv = vec4( 0.0, 0.0, 1.0, 1.0 );
uniform vec4 hover_uv = vec4( 0.0, 0.0, 1.0, 1.0 );
uniform vec4 pressed_uv = vec4( 0.0, 0.0, 1.0, 1.0 );
uniform float hover_factor = 0.0;
uniform float pressed_factor = 0.0;


void vertex() {
	UV = ( UV - normal_uv.xy ) / normal_uv.zw;
}


void fragment() {
	vec4 normal = texture( TEXTURE, normal_uv.xy + UV * normal_uv.zw );
	vec4 hover = texture( hover_tex, hover_uv.xy + UV * hover_uv.zw );
	vec4 pressed = texture( pressed_tex, pressed_uv.xy + UV * pressed_uv.zw );
	COLOR = mix( mix( normal, hover, hover_factor ), pressed, pressed_factor );
}
