   map_interior   	   MatrixPVW                                                                                SAMPLER    +         map_interior.vsc  uniform mat4 MatrixPVW;

attribute vec3 POSITION;
attribute vec2 TEXCOORD0;
attribute vec4 DIFFUSE;

varying vec2 PS_TEXCOORD;
varying vec4 PS_COLOUR;

void main()
{
	gl_Position = MatrixPVW * vec4( POSITION.xyz, 1.0 );
	PS_TEXCOORD.xy = TEXCOORD0.xy;
	PS_COLOUR.rgba = vec4( DIFFUSE.rgb * DIFFUSE.a, DIFFUSE.a ); // premultiply the alpha
}    map_interior.ps�  #extension GL_OES_standard_derivatives : enable
#if defined( GL_ES )
precision mediump float;
#endif

uniform sampler2D SAMPLER[1];
varying vec2 PS_TEXCOORD;
varying vec4 PS_COLOUR;

float mip_map_level(vec2 texcoords) {
	// The OpenGL Graphics System: A Specification 4.2
    //  - chapter 3.9.11, equation 3.21
    vec2 dx_vtc = dFdx(texcoords);
    vec2 dy_vtc = dFdy(texcoords);
    float delta_max_sqr = max(dot(dx_vtc, dx_vtc), dot(dy_vtc, dy_vtc));

    return 0.5 * log2(delta_max_sqr);
}

void main() {
	vec2 TEXCOORD_wrapped = fract(PS_TEXCOORD);
	float BIAS = mip_map_level(PS_TEXCOORD) - mip_map_level(TEXCOORD_wrapped);
	
	gl_FragColor = texture2D(SAMPLER[0], TEXCOORD_wrapped, BIAS);
}              