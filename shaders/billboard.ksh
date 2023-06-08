	   billboard   	   MatrixPVW                                                                                MatrixV                                                                                MatrixW                                                                                SAMPLER    +         LIGHTMAP_WORLD_EXTENTS                                billboard.vs  // GLSL Hacker automatic uniforms:
uniform mat4 MatrixPVW;
uniform mat4 MatrixP;
uniform mat4 MatrixV;
uniform mat4 MatrixW;

attribute vec3 POSITION;
attribute vec4 POS2D_UV;

varying vec3 PS_TEXCOORD;
varying vec3 PS_POS;

vec3 extractEulerAngleXZY(mat4 m) {
	m[0][0] *= -1.0;
	float T1 = atan(m[1][2], m[1][1]);
	float C2 = sqrt(m[0][0]*m[0][0] + m[2][0]*m[2][0]);
	float T2 = atan(-m[1][0], C2);
	float S1 = sin(T1);
	float C1 = cos(T1);
	float T3 = atan(S1*m[0][1] - C1*m[0][2], C1*m[2][2] - S1*m[2][1]);
	return vec3(T1, T3, T2);
}

bool floatequals(float a, float b) {
	return abs(a - b) < 0.001;
}

mat4 rotate(mat4 m, float angle, vec3 v) {
	mat3 rotate;

	//precalculated yaws/pitches for the most common angles.
	if (floatequals(angle, 0.0)) {
		rotate = mat3(1.0);
		return m;
	//pitch
	} else if (floatequals(angle, 0.78539816339745) && v.y == 1.0) {
		rotate = mat3(0.70710678118655, 0, -0.70710678118655, 0, 1, 0, 0.70710678118655, 0, 0.70710678118655);
	} else if (floatequals(angle, 1.5707963267949) && v.y == 1.0) {
		rotate = mat3(6.1232339957368e-017, 0, -1, 0, 1, 0, 1, 0, 6.1232339957368e-017);
	} else if (floatequals(angle, 2.3561944901923) && v.y == 1.0) {
		rotate = mat3(-0.70710678118655, 0, -0.70710678118655, 0, 1, 0, 0.70710678118655, 0, -0.70710678118655);
	} else if (floatequals(angle, 3.1415926535898) && v.y == 1.0) {
		rotate = mat3(-1, 0, -1.2246467991474e-016, 0, 1, 0, 1.2246467991474e-016, 0, -1);
	} else if (floatequals(angle, 3.9269908169872) && v.y == 1.0) {
		rotate = mat3(-0.70710678118655, 0, 0.70710678118655, 0, 1, 0, -0.70710678118655, 0, -0.70710678118655);
	} else if (floatequals(angle, 4.7123889803847) && v.y == 1.0) {
		rotate = mat3(-1.836970198721e-016, 0, 1, 0, 1, 0, -1, 0, -1.836970198721e-016);
	} else if (floatequals(angle, 5.4977871437821) && v.y == 1.0) {
		rotate = mat3(0.70710678118655, 0, 0.70710678118655, 0, 1, 0, -0.70710678118655, 0, 0.70710678118655);
	//yaw
	} else if (floatequals(angle, 0.87266462599716) && v.x == 1.10) {
		//this is the cameras pitch in Depths And Dwellers, if the camera pitch changes, change this!
		rotate = mat3(1, 0, 0, 0, 0.64278760968654, 0.76604444311898, 0, -0.76604444311898, 0.64278760968654);
	} else if (floatequals(angle, 1.5707963267949) && v.x == 1.10) {
		rotate = mat3(1, 0, 0, 0, 6.1232339957368e-017, 1, 0, -1, 6.1232339957368e-017);
	} else {
		float c = cos(angle);
		float s = sin(angle);

		vec3 axis = vec3(normalize(v));
		vec3 temp = vec3((1.0 - c) * axis);
		rotate[0][0] = c + temp[0] * axis[0];
		rotate[0][1] = temp[0] * axis[1] + s * axis[2];
		rotate[0][2] = temp[0] * axis[2] - s * axis[1];

		rotate[1][0] = temp[1] * axis[0] - s * axis[2];
		rotate[1][1] = c + temp[1] * axis[1];
		rotate[1][2] = temp[1] * axis[2] + s * axis[0];

		rotate[2][0] = temp[2] * axis[0] + s * axis[1];
		rotate[2][1] = temp[2] * axis[1] - s * axis[0];
		rotate[2][2] = c + temp[2] * axis[2];
	}

	mat4 result;
	result[0] = m[0] * rotate[0][0] + m[1] * rotate[0][1] + m[2] * rotate[0][2];
	result[1] = m[0] * rotate[1][0] + m[1] * rotate[1][1] + m[2] * rotate[1][2];
	result[2] = m[0] * rotate[2][0] + m[1] * rotate[2][1] + m[2] * rotate[2][2];
	result[3] = m[3];
	return result;
}

vec4 UnviewRotate(vec4 POS) {
    vec3 Vangle = extractEulerAngleXZY(MatrixV);

	mat4 MatrixR = mat4(1.0);
	MatrixR = rotate(MatrixR, Vangle.x, vec3(1.0, 0.0, 0.0));
	MatrixR = rotate(MatrixR, Vangle.y, vec3(0.0, 1.0, 0.0));

	return MatrixR * POS;
}

vec4 Rotate3D(vec4 POS, float pitch, float yaw) {
	mat4 MatrixR = mat4(1.0);
	MatrixR = rotate(MatrixR, radians(mod(yaw + 180.0, 360.0)), vec3(0.0, 1.0, 0.0));
	MatrixR = rotate(MatrixR, radians(pitch), vec3(1.0, 0.0, 0.0));

	return MatrixR * POS;
}

void main()
{
    float samplerIndex = floor(POS2D_UV.z/2.0);
    vec3 TEXCOORD0 = vec3(POS2D_UV.z - 2.0*samplerIndex, POS2D_UV.w, samplerIndex);

	vec4 world_pos = MatrixW * vec4( POSITION.xyz, 1.0 );
	vec4 ORIGIN_POS = UnviewRotate(vec4(POSITION.xyz, 1.0));
	vec4 ROTATED_POS = Rotate3D(ORIGIN_POS, 45., 90.);

	gl_Position = MatrixPVW * ROTATED_POS * 5.;
	PS_POS = world_pos.xyz;
	PS_TEXCOORD = TEXCOORD0;
}    billboard.ps�  #define QUALITY 3
#extension GL_OES_standard_derivatives : enable
#ifdef GL_ES
precision mediump float;
#endif

uniform sampler2D SAMPLER[4];

varying vec2 PS_TEXCOORD;

#ifdef ALPHAPATTERN
varying vec2 PS_TEXCOORDALPHA;
#endif

const float LIFETIME_LENGTH = 60.0;
// Lighting
varying vec3 PS_POS;

// xy = min, zw = max
uniform vec4 LIGHTMAP_WORLD_EXTENTS;

#define LIGHTMAP_TEXTURE SAMPLER[3]

#ifndef LIGHTMAP_TEXTURE
	#error If you use lighting, you must #define the sampler that the lightmap belongs to
#endif

vec3 CalculateLightingContribution()
{
	vec2 uv = ( PS_POS.xz - LIGHTMAP_WORLD_EXTENTS.xy ) * LIGHTMAP_WORLD_EXTENTS.zw;

	return texture2D( LIGHTMAP_TEXTURE, uv.xy ).rgb;
}

vec3 CalculateLightingContribution( vec3 normal )
{
	return vec3( 1, 1, 1 );
}
float round(float a) {
	return floor(a + 0.5);
}

vec4 round(vec4 a) {
	return floor(a + 0.5);
}

mat4 translate(mat4 m, vec3 v) {
	mat4 result = m;
	result[3] = m[0] * v.x + m[1] * v.y + m[2] * v.z + m[3];
	return result;
}

mat4 scale(mat4 m, vec3 v) {
	mat4 result;
	result[0] = m[0] * v.x;
	result[1] = m[1] * v.y;
	result[2] = m[2] * v.z;
	result[3] = m[3];
	return m;
}

float mip_map_level(vec2 texcoords) {
	// The OpenGL Graphics System: A Specification 4.2
    //  - chapter 3.9.11, equation 3.21
    vec2 dx_vtc = dFdx(texcoords);
    vec2 dy_vtc = dFdy(texcoords);
    float delta_max_sqr = max(dot(dx_vtc, dx_vtc), dot(dy_vtc, dy_vtc));

    //return max(0.0, 0.5 * log2(delta_max_sqr) - 1.0); // == log2(sqrt(delta_max_sqr));
    return 0.5 * log2(delta_max_sqr); // == log2(sqrt(delta_max_sqr));
}
void main() {

#ifdef ALPHAPATTERN
	float alpha = texture2D(SAMPLER[0], PS_TEXCOORDALPHA.xy).a;
	#define RENDER_CONDITION alpha > 0.5 && gl_FrontFacing
#else
	#define RENDER_CONDITION gl_FrontFacing
#endif

	if (RENDER_CONDITION) {
		vec2 TEXCOORD = PS_TEXCOORD;
		vec2 TEXCOORD_wrapped = fract(TEXCOORD);
		float BIAS = mip_map_level(TEXCOORD) - mip_map_level(TEXCOORD_wrapped);


		gl_FragColor = texture2D(SAMPLER[0], TEXCOORD);

#if QUALITY >= 2
		gl_FragColor.rgb *= CalculateLightingContribution();
#endif

	} else {
		discard;
	}
}                       