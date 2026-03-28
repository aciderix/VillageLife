//  Shader_3D_UBER.fsh

precision highp float;

#define PIE	(3.141592653)
#define TWOPIE	(PIE*2.0)



#ifndef USEDEFINES

// these will be defined in the header to the new variant shader

#define DIFFUSEMAPENABLE					
#define SHADOWMAPENABLE					
#define USESPECULAR					
#define USEREFLECTION					
#define USEEMISSIVE					
#define USEEMISSIVEMAP				
#define USENORMALMAP					
#define USESPECULARINTENSITYMAP		
#define USEREFLECTIONINTENSITYMAP		
#define USEPHONG
#define USEBLENDDIFFMAPS							
#define USEDIFFUSEMAP2				
#define USEDIFFUSELIGHTING				

#define lightMaterial_uDiffuseUVSet						0
#define lightMaterial_uDiffuse2UVSet					3
#define lightMaterial_uReflectionIntensityUVSet			0
#define lightMaterial_uShadowUVSet						1
#define lightMaterial_uSpecularIntensityUVSet			0
#define lightMaterial_uNormalUVSet						0
#define lightMaterial_uEmissiveUVSet					2

#define VSUSENORMAL
#define VSUSETANGENTS
#define VSUSEVCOLOUR
#define VSUSETEX1
#define VSUSETEX2
#define VSUSETEX3
#define VSUSETEX4

//#define NUMLIGHTSTOUSE		4

#endif

#ifdef USEDIFFUSELIGHTING
#define LIGHTINGORREFLEC
#endif
#ifdef USEREFLECTION
#ifndef LIGHTINGORREFLEC
#define LIGHTINGORREFLEC
#endif
#endif
#ifdef USESPECULAR
#ifndef LIGHTINGORREFLEC
#define LIGHTINGORREFLEC
#endif
#endif


// No input data here, this is the fragment shader

// This is the vertex OUTPUT data which gets interpolated and fed into pixel shader per scanned screen pixel

varying highp vec4 v_position;
varying highp vec4 v_position_lig;

#ifdef VSUSECOLOUR
varying highp vec4 v_vertcol;
#endif

#ifdef USEPHONG
varying highp vec3 v_normal;
varying highp vec4 v_positionthro;
#endif
#ifdef VSUSETANGENTS
varying highp vec3 v_tangent;
varying highp vec3 v_binormal;
#endif

#ifdef VSUSETEX1
#ifdef VSUSETEX2
#ifdef VSUSETEX3
#ifdef VSUSETEX4
varying highp vec2 v_texCoords[4];		//scaled and passed through
#endif
#endif
#endif
#endif
#ifdef VSUSETEX1
#ifdef VSUSETEX2
#ifdef VSUSETEX3
#ifndef VSUSETEX4
varying highp vec2 v_texCoords[3];		//scaled and passed through
#endif
#endif
#endif
#endif
#ifdef VSUSETEX1
#ifdef VSUSETEX2
#ifndef VSUSETEX3
#ifndef VSUSETEX4
varying highp vec2 v_texCoords[2];		//scaled and passed through
#endif
#endif
#endif
#endif
#ifdef VSUSETEX1
#ifndef VSUSETEX2
#ifndef VSUSETEX3
#ifndef VSUSETEX4
varying highp vec2 v_texCoords[1];		//scaled and passed through
#endif
#endif
#endif
#endif
#ifdef VSUSEVCOLOUR
varying highp vec4 v_blend;
#endif

#ifndef USEPHONG
#ifdef USEREFLECTION	
varying highp vec3 v_reflecVec;
#endif
#ifdef USESPECULAR
varying highp vec3 v_colourSpec;
#endif
#ifdef USEDIFFUSELIGHTING
varying highp vec3 v_colour;
#endif
#endif



#define LIGHTMATERIAL_DIFFUSE		0
#define LIGHTMATERIAL_AMBIENT		1
#define LIGHTMATERIAL_SPECULAR		2
#define LIGHTMATERIAL_EMISSIVE		3
#define LIGHTMATERIAL_SPECULARPOWER	4
#define LIGHTMATERIAL_REFLECMULT	4
#define LIGHTMATERIAL_SHADOWMULT	4
#define LIGHTMATERIAL_NORMALHEIGHT	4
#define LIGHTMATERIAL_MULCOL		5

#define LIGHTMATERIAL_TOTALSIZE     6		// was 5 but we added mulcol

#define lightMaterial_diffuse			LightMaterial[LIGHTMATERIAL_DIFFUSE]
#define lightMaterial_ambient			LightMaterial[LIGHTMATERIAL_AMBIENT]
#define lightMaterial_specular			LightMaterial[LIGHTMATERIAL_SPECULAR]
#define lightMaterial_emissive			LightMaterial[LIGHTMATERIAL_EMISSIVE]
#define lightMaterial_specularpower		LightMaterial[LIGHTMATERIAL_SPECULARPOWER][0]
#define lightMaterial_reflecMult		LightMaterial[LIGHTMATERIAL_REFLECMULT][1]
#define lightMaterial_shadowMult		LightMaterial[LIGHTMATERIAL_SHADOWMULT][2]
#define lightMaterial_normalHeight		LightMaterial[LIGHTMATERIAL_NORMALHEIGHT][3]
#define lightMaterial_mulcol			LightMaterial[LIGHTMATERIAL_MULCOL]



uniform vec4 LightMaterial[LIGHTMATERIAL_TOTALSIZE];


#define shadData_colour(_n)		ShaderEffs[2*_n + 0]
#define shadData_sat(_n)		ShaderEffs[2*_n + 1][0]
#define shadData_hue(_n)		ShaderEffs[2*_n + 1][1]
#define shadData_lig(_n)		ShaderEffs[2*_n + 1][2]
#define shadData_test(_n)		ShaderEffs[2*_n + 1][3]

uniform vec4 ShaderEffs[2*8];

#define MAXMODELLIGHTS NUMLIGHTSTOUSE

#define LIGHTS_NUMLIGHTS	0
#define LIGHTS_AMBIENT		1
#define LIGHTS_SIZE			2

#define LIGHT_DIFFUSE		0
#define LIGHT_SPECULAR		1
#define LIGHT_POSITION		2
#define LIGHT_DIRECTION		3
#define LIGHT_FALLOFF		4
#define LIGHT_ATTENUATION0	4
#define LIGHT_ATTENUATION1	4
#define LIGHT_ATTENUATION2	4
#define LIGHT_TYPE			5
#define LIGHT_RANGE			5
#define LIGHT_THETA			5
#define LIGHT_PHI			5
#define LIGHT_SIZE			6

#define LIGHTS_TOTALSIZE (LIGHTS_SIZE+MAXMODELLIGHTS*LIGHT_SIZE)

#define lights_numLights		Lights[LIGHTS_NUMLIGHTS][0]
#define lights_ambient			Lights[LIGHTS_AMBIENT]

#define light_diffuse(_n)		Lights[LIGHTS_SIZE + LIGHT_SIZE*_n + LIGHT_DIFFUSE]
#define light_specular(_n)		Lights[LIGHTS_SIZE + LIGHT_SIZE*_n + LIGHT_SPECULAR]
#define light_position(_n)		Lights[LIGHTS_SIZE + LIGHT_SIZE*_n + LIGHT_POSITION]
#define light_direction(_n)		Lights[LIGHTS_SIZE + LIGHT_SIZE*_n + LIGHT_DIRECTION]
#define light_falloff(_n)		Lights[LIGHTS_SIZE + LIGHT_SIZE*_n + LIGHT_FALLOFF][0]
#define light_attenuation0(_n)	Lights[LIGHTS_SIZE + LIGHT_SIZE*_n + LIGHT_ATTENUATION0][1]
#define light_attenuation1(_n)	Lights[LIGHTS_SIZE + LIGHT_SIZE*_n + LIGHT_ATTENUATION1][2]
#define light_attenuation2(_n)	Lights[LIGHTS_SIZE + LIGHT_SIZE*_n + LIGHT_ATTENUATION2][3]
#define light_type(_n)			Lights[LIGHTS_SIZE + LIGHT_SIZE*_n + LIGHT_TYPE][0]
#define light_range(_n)			Lights[LIGHTS_SIZE + LIGHT_SIZE*_n + LIGHT_RANGE][1]
#define light_theta(_n)			Lights[LIGHTS_SIZE + LIGHT_SIZE*_n + LIGHT_THETA][2]
#define light_phi(_n)			Lights[LIGHTS_SIZE + LIGHT_SIZE*_n + LIGHT_PHI][3]

uniform vec4 Lights[LIGHTS_TOTALSIZE];


#define SHADER_LIGHT_DIRECTIONAL	0.0
#define SHADER_LIGHT_POINT			1.0

uniform highp vec4 MulCol;
uniform highp vec4 Highlight;


// constants
uniform float	c_fTime;	
uniform float	c_uvDeltaU1;
uniform float	c_uvDeltaV1;
uniform float	c_uvDeltaU2;
uniform float	c_uvDeltaV2;
uniform float	c_uvMultiply;
uniform float	c_uvDeltaDiffuseU;
uniform float	c_uvDeltaDiffuseV;

uniform vec4	c_uvPosition[4];			//NOTE THis is per UV set, not per texture
uniform vec4	c_depthColour;

uniform float	c_waveFrequency;
uniform float	c_waveSpeed;
uniform float	c_waveIntensity;


//Mirror gShader values
uniform mat4 modelViewProjectionMatrix;			//not used in pshader
uniform mat4 modelViewProjShadowMatrix;			//not used in pshader
//UGH uniform mat4 modelViewMatrix;					//not used in pshader
//NOTUSED uniform mat4 modelViewNormalizedInvMatrix;		//not used in pshader
uniform mat4 viewNormalizedInvMatrix;			//pos IS used in pshader
uniform mat4 modelMatrix;						//mat IS used in pshader

uniform sampler2D s_texture1;
uniform sampler2D s_texture2;
uniform sampler2D s_texture3;
uniform sampler2D s_texture4;
uniform sampler2D s_texture5;
uniform sampler2D s_texture6;
uniform sampler2D s_texture7;
uniform samplerCube s_texture8;


//----------------------------------------------------------------------------------

// compatibility functions

vec4 lerp(vec4 a, vec4 b, float f)
{
	return vec4(a.x+(b.x-a.x)*f,a.y+(b.y-a.y)*f,a.z+(b.z-a.z)*f,a.w+(b.w-a.w)*f);
}

float lerpfloat(float a, float b, float f)
{
	return a+(b-a)*f;
}

float frac(float x)
{
	return x-floor(x);
}

vec4 saturate(vec4 v)
{
	v.x=clamp(v.x,0.0,1.0);
	v.y=clamp(v.y,0.0,1.0);
	v.z=clamp(v.z,0.0,1.0);
	v.w=clamp(v.w,0.0,1.0);
	return v;
}

vec3 saturate(vec3 v)
{
	v.x=clamp(v.x,0.0,1.0);
	v.y=clamp(v.y,0.0,1.0);
	v.z=clamp(v.z,0.0,1.0);
	return v;
}

float saturate(float x)
{
	x=clamp(x,0.0,1.0);
	return x;
}
//----------------------------------------------------------------------------------

vec3 blend2(vec3 left, vec3 right, float pos)
{
	vec3 res;
	res.r=left.r*(1.0-pos)+right.r*(pos);
	res.g=left.g*(1.0-pos)+right.g*(pos);
	res.b=left.b*(1.0-pos)+right.b*(pos);
	return res;
}
	
//----------------------------------------------------------------------------------

vec3 blend3(vec3 left, vec3 main, vec3 right, float pos)
{
	if(pos<0.0)
		return blend2(left,main,pos+1.0);
	else if (pos>0.0)
		return blend2(main,right,pos);
	else
		return main;
}

//----------------------------------------------------------------------------------

vec3 LightenColour(vec3 col, float lig)
{
	vec3 blk=vec3(0.0,0.0,0.0);
	vec3 wht=vec3(1.0,1.0,1.0);
	vec3 outcol;

	if(lig>0.0)
		outcol=blend2(col,wht,lig);				//mid to white 2 * ( 0-1 ) * (brt-1) + 1 
	else
		outcol=blend2(blk,col,1.0+lig);			//blk to mid   2 * ( 0-1 ) * (brt) - 1
	return outcol;
}

//----------------------------------------------------------------------------------

vec3 SaturateColour(vec3 col, float sat)
{
	float invr=(0.30)*(1.0-sat);
	float invg=(0.59)*(1.0-sat);
	float invb=(0.11)*(1.0-sat);
	float red=col.r*(invr+sat)+col.g*(invg)+col.b*(invb);
	float grn=col.r*(invr)+col.g*(invg+sat)+col.b*(invb);
	float blu=col.r*(invr)+col.g*(invg)+col.b*(invb+sat);
	vec3 outcol=vec3(red,grn,blu);
	return outcol;
}

//----------------------------------------------------------------------------------

vec3 ConvRGBtoHSV(vec3 RGB) 
{
    vec3 HSV = vec3(0.0,0.0,0.0);
    HSV.z = max(RGB.r, max(RGB.g, RGB.b));
    float M = min(RGB.r, min(RGB.g, RGB.b));
    float CC = HSV.z - M;
    if (CC != 0.0)
{
        HSV.y = CC / HSV.z;
        vec3 Delta = (HSV.z - RGB) / CC;
        Delta.rgb -= Delta.brg;
        Delta.rg += vec2(2.0,4.0);
        if (RGB.r >= HSV.z)
            HSV.x = Delta.b;
        else if (RGB.g >= HSV.z)
			HSV.x = Delta.r;
        else
            HSV.x = Delta.g;
		HSV.x = frac(HSV.x / 6.0);
    }
	return HSV;
}

vec3 ConvHSVtoRGB(vec3 hsv)
{
	float R = abs(hsv.x * 6.0 - 3.0) - 1.0;
    float G = 2.0 - abs(hsv.x * 6.0 - 2.0);
    float B = 2.0 - abs(hsv.x * 6.0 - 4.0);
    vec3 scol=saturate(vec3(R,G,B));
	vec3 col=((scol-1.0)*hsv.y+1.0)*hsv.z;
	return col;
}

//----------------------------------------------------------------------------------

vec3 Colorize(vec3 col,vec3 tint,float sat,float lig)
{
	vec3 grey=vec3(0.5,0.5,0.5);
	vec3 midcol=blend2(grey,tint,sat*0.5);

	vec3 outcol;
	vec3 blk=vec3(0.0,0.0,0.0);
	vec3 wht=vec3(1.0,1.0,1.0);

	float value=col.r*0.30+col.g*0.59+col.b*0.11;		//input intensity 0-1
	if(lig>0.0)
		outcol=blend3(blk,midcol,wht,2.0*(1.0-lig)*(value-1.0)+1.0);		//mid to white 2 * ( 0-1 ) * (brt-1) + 1
	else
		outcol=blend3(blk,midcol,wht,2.0*(1.0+lig)*(value)-1.0);			//blk to mid   2 * ( 0-1 ) * (brt) - 1

	return outcol;
			}

//----------------------------------------------------------------------------------
//----------------------------------------------------------------------------------
//----------------------------------------------------------------------------------

#ifdef USEPHONG				//none of this if not phong
#ifdef LIGHTINGORREFLEC
			
struct Uber_cLightAndReflec
				{
#ifdef USEDIFFUSELIGHTING
	 vec3	colour;
#endif				
#ifdef USESPECULAR
	 vec3	colourSpec;
#endif
#ifdef USEREFLECTION
	 vec3	reflecVec;
#endif
};



// work out lights and reflection vector for point - either in vertex shader or pixel shader

Uber_cLightAndReflec gLightAndReflec;
void Uber_DoLightsAndReflec(
						 vec3 pos_ms,									//pos in model space
						 vec3 nrm_ms)									//nrm in model space
{
	Uber_cLightAndReflec C;												//output

	vec3 pos_ws = ( modelMatrix * vec4(pos_ms,1.0)).xyz;				//pos in world space
	vec3 nrm_ws = ( modelMatrix * vec4(nrm_ms,0.0)).xyz;				//nrm in world space

#ifdef USEDIFFUSELIGHTING
	C.colour.rgb=lights_ambient.rgb;									//ambient
#endif
#ifdef USESPECULAR
	C.colourSpec.rgb=vec3(0.0);
#endif
#ifdef USEREFLECTION
	C.reflecVec.rgb=vec3(0.0);
#endif	

	nrm_ws=normalize(nrm_ws);
	
	vec3 ptoc_wsn = normalize(pos_ws.xyz-viewNormalizedInvMatrix[3].xyz);			//note used later in specular	
	
#ifdef USEREFLECTION
	C.reflecVec.rgb = normalize( reflect ( ptoc_wsn, nrm_ws ) );				//vector for cubemap lookup
#endif

	float NdotL;
	vec3 hv_wsn;
	float d;
	float specpow;
	vec3 L_wsn;
	vec3 r;
	vec3 ltop_ws;
	vec3 ltop_wsn;
	float fAtten;
	float LD;
	

//<#INSERTLIGHTS#>

	
#ifdef USEDIFFUSELIGHTING
	C.colour.rgb*=lightMaterial_diffuse.rgb;															//do ONCE now not in light accumulation code
#endif
#ifdef USESPECULAR
	C.colourSpec.rgb*=lightMaterial_specular.rgb;
#endif	

	gLightAndReflec=C;
	//return(C);
}

#endif		//if LIGHTINGORREFLEC
#endif		//if PHONG



//----------------------------------------------------------------------------------
//----------------------------------------------------------------------------------
//----------------------------------------------------------------------------------

//----------------------------------------------------------------------------------

void main()
{

#ifndef USEDEFINES

	gl_FragColor=vec4(1.0,0.0,0.0,1.0);		//DEFAULT RED

#endif

#ifdef USEDEFINES

	vec4 outcol;
	vec3 usenormal;
	vec4 decal;
	vec3 usecolour;
	vec3 useReflecVec;
	vec3 usecolourspec;
	vec4 decal2;
	vec4 temp;
	vec4 maskcol;
	
//----------------------------------------------------------------------------------
	
// temps for shader defined once so can be used multiple times

	vec3 tempHSV;			// temps for shader/effects defined once so can be used multiple times
	vec3 tempRGB;
	float tempV;
	float fog;

//----------------------------------------------------------------------------------

#ifdef BUILDSHADOWMAP

	outcol.r=v_position.z;				//test shader to see if it renders to texture
	outcol.g=v_position.z;				//test shader to see if it renders to texture
	outcol.b=v_position.z;				//test shader to see if it renders to texture
	outcol.a=1.0;

#endif

//----------------------------------------------------------------------------------

#ifdef USEUBER

#ifdef FASTSHADER

#ifdef USESPECIAL_BEACH

	outcol=vec4(0.5,0.5,0.5,1.0);
	
#endif

#ifdef	USESPECIAL_OCEAN

	vec4 reflection=textureCube(s_texture8, v_reflecVec);					//this shoudl be interpolated
	outcol=reflection;

#endif

#ifdef	USESPECIAL_SHALLOW

	outcol=vec4(0.5,0.5,0.5,1.0);

#endif

#endif

//----------------------------------------------------------------------------------

#ifndef FASTSHADER

//----------------------------------------------------------------------------------

#ifdef USESPECIAL_BEACH

	vec4 tex=texture2D(s_texture1, v_texCoords[0]);									//lightMaterial_uDiffuseUVSet not set - this is the sand

	//vec4 reflTex=texture2D(s_texture5, v_texCoords[1]);								//the gradient
	vec4 reflTex=vec4(1.0-v_texCoords[1].x);
	reflTex.a=1.0;
	
	//OLD float wavePhase = sin((c_fTime * TWOPIE  * c_waveFrequency) + (v_blend.g * TWOPIE ));
	float wavePhase = sin((c_fTime * TWOPIE  * c_waveFrequency) + (v_blend.g * PIE ));

	//OLD float normalPhase = sin((c_fTime * TWOPIE  * c_waveFrequency) + ((v_blend.g + 0.75) * TWOPIE ));
	float normalPhase = 1.0- sin(((c_fTime-1.0) * TWOPIE  * c_waveFrequency) + ((v_blend.g ) * PIE ));
	//OLD float wetPhase = 1.0 - frac(((c_fTime * c_waveFrequency) + v_blend.g) - 0.75);
	float wetPhase = 1.0 - frac(((c_fTime * c_waveFrequency) + (v_blend.g*0.5)) - 0.75);
	
	vec4 texN=texture2D(s_texture7, v_texCoords[1] + vec2(wavePhase * 0.1 * c_waveSpeed, 0.0));								//the waves coming in

	vec4 waveTex=texture2D(s_texture4,  vec2((v_texCoords[1].x * 0.5) + 0.5, v_texCoords[1].y) + vec2(wavePhase * 0.15 * (1.0 - v_blend.r), 0.0));					//the foam wave

	vec4 wetTex=texture2D(s_texture4, vec2((v_texCoords[1].x * 0.5) + (0.35), v_texCoords[1].y) );				//the foam wave

	vec3 localCoords = normalize(vec3(((2.0 * texN.rg) - 1.0) * lightMaterial_normalHeight * (0.2 + (saturate(normalPhase) * 0.8)), 1.0));				//the offset normal
		
	mat3 tbn = mat3(v_tangent.xyz,v_binormal.xyz,vec3(0.0,0.0,1.0));
	usenormal = normalize(tbn * localCoords);				

	Uber_DoLightsAndReflec(v_positionthro.xyz, usenormal.xyz);						// override interpolated values
	Uber_cLightAndReflec C = gLightAndReflec;
	vec3 reflectedDir = C.reflecVec;

	vec4 cubeMap=textureCube(s_texture8, reflectedDir);
	
	float wetSandM = 1.0 - saturate((wetTex.g *  wetPhase)-0.1);
	vec4 wetSand = lerp(lightMaterial_diffuse,vec4(1.0,1.0,1.0,1.0),wetSandM);
	float waveRefAmount = 0.3;

	float waveFoamMask = waveTex.g * waveTex.r * (1.0 - wavePhase) * (1.0 - reflTex.x);
	
	vec4 sand = lerp(tex * wetSand, lerp(tex, c_depthColour, reflTex.x), waveTex.g);

	vec4 diff = lerp(sand, vec4(1.0, 1.0, 1.0, 1.0), waveFoamMask);

	vec4 refl = cubeMap * waveTex.g * waveRefAmount * (1.0 - waveFoamMask);

	outcol=diff + refl;
	
// shadowmap
	vec4 shadow=texture2D(s_texture2, v_texCoords[2]);					//1 Lightmap  lightMaterial_uShadowUVSet not set
	outcol.rgb*=shadow.rgb * lightMaterial_shadowMult;
		
#endif

//----------------------------------------------------------------------------------

#ifdef USESPECIAL_SHALLOW

	//float wavePhase = sin((c_fTime * TWOPIE  * c_waveFrequency) + (v_blend.g * TWOPIE ));
	float wavePhase = sin((c_fTime * TWOPIE  * c_waveFrequency) + (v_blend.g * PIE ));

	//float normalPhase = sin((c_fTime * TWOPIE  * c_waveFrequency) + ((v_blend.g + 0.75) * TWOPIE ));
	float normalPhase = 1.0-sin(((c_fTime+1.0) * TWOPIE  * c_waveFrequency) + ((v_blend.g ) * PIE ));
	
	vec4 tex=texture2D(s_texture1, v_texCoords[0]);									//lightMaterial_uDiffuseUVSet not set

	vec4 reflTex=texture2D(s_texture5, v_texCoords[1]);								//the gradient
	//vec4 reflTex=vec4(1.0-v_texCoords[1].x);
	//reflTex.a=1.0;

	vec4 normaldelta1=texture2D(s_texture7,vec2(v_texCoords[0].x+c_uvDeltaU1,v_texCoords[0].y+c_uvDeltaV1));			
	vec4 normaldelta2=texture2D(s_texture7,vec2((v_texCoords[0].x+c_uvDeltaU2)*c_uvMultiply,(v_texCoords[0].y+c_uvDeltaV2)*c_uvMultiply));			
	vec4 texN=(normaldelta1+normaldelta2)*0.5;									

	vec4 texN3=texture2D(s_texture3, v_texCoords[1] + vec2(wavePhase * 0.1 * c_waveSpeed, 0.0));								//the waves coming in

	vec2 n1=((2.0*texN.rg)-1.0) *  lightMaterial_normalHeight;
	vec2 n2=((2.0*texN3.rg)-1.0) *  c_waveIntensity * (0.2 + (saturate(normalPhase) * 0.8) );
	vec3 localCoords = vec3 ( n1 * reflTex.x + n2* (1.0 - reflTex.x),1.0);
	
	mat3 tbn = mat3(v_tangent.xyz,v_binormal.xyz,vec3(0.0,0.0,1.0));
	usenormal = normalize(tbn * localCoords);				
	Uber_DoLightsAndReflec(v_positionthro.xyz, usenormal.xyz);						// override interpolated values
	Uber_cLightAndReflec C = gLightAndReflec;
	vec3 reflectedDir = C.reflecVec;

	vec4 cubeMap=textureCube(s_texture8, reflectedDir);
		
	//float rintocean=lightMaterial_reflecMult() ;
	//float rintuse=1.0+(rintocean-1.0)*(reflTex.x);
	//cubeMap.rgb*= rintuse;										//NEW EDITED

	vec4 waterColour=texture2D(s_texture1, vec2(0.0,0.0));					//NEW EDITED4
	//float wcolint=reflTex.x;
	//waterColour*=wcolint;

	//cubeMap+=waterColour;
	
	float waterReflAmount = 0.3;

	//vec4 refl = cubeMap * (((1.0 - waterReflAmount) * reflTex.x) + waterReflAmount);
	//vec4 diff = c_depthColour * (1.0 - reflTex.x);

	//here 
	//SQ
	vec4 refl = cubeMap * lerpfloat(waterReflAmount, lightMaterial_reflecMult, reflTex.x);
	//SQ
	vec4 diff = lerp(c_depthColour, waterColour, reflTex.x);

	outcol = diff+refl;

// shadowmap
	vec4 shadow=texture2D(s_texture2, v_texCoords[2]);					//1 Lightmap  lightMaterial_uShadowUVSet not set
	outcol.rgb*=shadow.rgb * lightMaterial_shadowMult;

#endif		//USESPECIAL_SHALLOW

//----------------------------------------------------------------------------------

#ifdef USESPECIAL_OCEAN

// get average normal deltaof two scrolling uvs
	vec4 normaldelta1=texture2D(s_texture7,vec2(v_texCoords[0].x+c_uvDeltaU1,v_texCoords[0].y+c_uvDeltaV1));			
	vec4 normaldelta2=texture2D(s_texture7,vec2((v_texCoords[0].x+c_uvDeltaU2)*c_uvMultiply,(v_texCoords[0].y+c_uvDeltaV2)*c_uvMultiply));			
	vec4 texN=(normaldelta1+normaldelta2)*0.5;									
	vec2 n1=((2.0*texN.rg)-1.0)*lightMaterial_normalHeight* (1.0-v_blend.b);
	vec3 localCoords = vec3 (n1,1.0);
	
	// get normal and reflection and read cubemap
	mat3 tbn = mat3(v_tangent.xyz,v_binormal.xyz,vec3(0.0,0.0,1.0));
	usenormal = normalize(tbn * localCoords);				
	Uber_DoLightsAndReflec(v_positionthro.xyz, usenormal.xyz);						// override interpolated values
	Uber_cLightAndReflec C = gLightAndReflec;
	vec3 reflectedDir = C.reflecVec;
	outcol=textureCube(s_texture8, reflectedDir);

	outcol.rgb*= lightMaterial_reflecMult;												//NEW EDITED

	vec4 waterColour=texture2D(s_texture1, vec2(0.0,0.0));					//NEW EDITED
	outcol+=waterColour;

	// shadowmap and lerp to horizon
	vec4 shadow=texture2D(s_texture2, v_texCoords[2]);					//1 Lightmap  lightMaterial_uShadowUVSet not set
	outcol.rgb*=shadow.rgb * lightMaterial_shadowMult;						
	//outcol.rgb=outcol.rgb+(lightMaterial_diffuse().rgb-outcol.rgb)*v_blend.b;

#endif		//USESPECIAL_OCEAN

//----------------------------------------------------------------------------------

#endif		//#ifndef FASTSHADER

//----------------------------------------------------------------------------------

#ifndef USESPECIAL_BEACH
#ifndef USESPECIAL_OCEAN
#ifndef USESPECIAL_SHALLOW

//----------------------------------------------------------------------------------

//----------------------------------------------------------------------------------
// if phong, get interpolated normal, if normal map, adjust it
//----------------------------------------------------------------------------------

#ifdef USEPHONG
	usenormal=v_normal.xyz;
#ifdef VSUSETANGENTS
#ifdef USENORMALMAP
	mat3 tbn = mat3(v_tangent.xyz,v_binormal.xyz,usenormal);
	vec4 normaldelta=texture2D(s_texture7, v_texCoords[lightMaterial_uNormalUVSet]);					//normal delta map
	vec3 pixoff= normalize( normaldelta.xyz * 2.0 - 1.0 );
	pixoff.xy*=lightMaterial_normalHeight;
	vec3 pixelNormal = tbn * pixoff ;															//other way round
	usenormal=pixelNormal;
#endif
#endif
#endif


//----------------------------------------------------------------------------------
// work out colour, spec and ereflec - either interpolated or reworked out per pixel
//----------------------------------------------------------------------------------

#ifndef USEPHONG
#ifdef USEDIFFUSELIGHTING
	usecolour=v_colour.rgb;
#endif
#ifdef USESPECULAR
	usecolourspec=v_colourSpec.rgb;
#endif
#ifdef USEREFLECTION
	useReflecVec=v_reflecVec.xyz;
#endif
#endif

#ifdef USEPHONG
#ifdef LIGHTINGORREFLEC
	Uber_DoLightsAndReflec(v_positionthro.xyz, usenormal.xyz);						// override interpolated values
	Uber_cLightAndReflec C = gLightAndReflec;
#ifdef USEDIFFUSELIGHTING
	usecolour=C.colour;
#endif
#ifdef USESPECULAR
	usecolourspec=C.colourSpec;
#endif
#ifdef USEREFLECTION
	useReflecVec=C.reflecVec;
#endif
#endif
#endif

//----------------------------------------------------------------------------------
//----------------------------------------------------------------------------------

// main texture
	
#ifdef DIFFUSEMAPENABLE
	decal=texture2D(s_texture1, v_texCoords[lightMaterial_uDiffuseUVSet]);							
#endif
#ifndef DIFFUSEMAPENABLE
	decal=vec4(1.0);
#endif	

// blended to second

#ifdef VSUSEVCOLOUR
#ifdef USEDIFFUSEMAP2
	decal2=texture2D(s_texture4, v_texCoords[lightMaterial_uDiffuse2UVSet]);
#ifdef USEBLENDDIFFMAPS																		
	
	vec4	decalx=texture2D(s_texture4, v_texCoords[1]);					
	decal.rgb=decal.rgb*(decalx.a) + decal2.rgb*(1.0-decalx.a);
	
	//decal.rgb=decal.rgb*(v_blend.r) + decal2.rgb*(1.0-v_blend.r);
#endif
#endif
#endif

// lighting

#ifdef USEDIFFUSELIGHTING
	outcol.rgb=decal.rgb*usecolour.rgb;																// this is the calculated lighting
	outcol.a=decal.a*lightMaterial_ambient.a;
#endif
#ifndef USEDIFFUSELIGHTING
	outcol.rgba=decal.rgba;

	outcol.rgb*=lightMaterial_diffuse.rgb;			//the new line

#endif


#ifdef USEALPHATEST
	if (outcol.a<0.5)	//alphaTest
    {
		discard;
	}
#endif

//----------------------------------------------------------------------------------
// shadowmap
//----------------------------------------------------------------------------------

#ifdef SHADOWMAPENABLE
	vec4 shadow=texture2D(s_texture2, v_texCoords[lightMaterial_uShadowUVSet]);						//T1(0-7) //Lightmap
	outcol.rgb*=shadow.rgb * lightMaterial_shadowMult ;
#endif
	
//----------------------------------------------------------------------------------
// add reflection
//----------------------------------------------------------------------------------
	
#ifdef USEREFLECTION
	vec4 reflection=textureCube(s_texture8, useReflecVec.xyz);								//TODO CUBE !!!
	float rf=lightMaterial_reflecMult;
	vec3 rc=vec3(rf);
#ifdef USEREFLECTIONINTENSITYMAP
	vec4 reflectivity=texture2D(s_texture5, v_texCoords[lightMaterial_uReflectionIntensityUVSet]);	//);			//T4(0-7)
	rc*=reflectivity.rgb;
#endif
	//vec3 irc=vec3(1.0-rc.x,1.0-rc.y,1.0-rc.z);
	//outcol.rgb=(outcol.rgb*(irc))+(reflection.rgb*(rc));
	outcol.rgb=outcol.rgb+(reflection.rgb*(rc));
#endif
	
//----------------------------------------------------------------------------------
// add specular
//----------------------------------------------------------------------------------
	
#ifdef USESPECULAR
#ifdef USESPECULARINTENSITYMAP
	vec4 speccol=texture2D(s_texture3, v_texCoords[lightMaterial_uSpecularIntensityUVSet]);	//);				//T2(0-7)  spec int
	outcol.rgb+=usecolourspec.rgb * speccol.rgb;
#endif		
#ifndef USESPECULARINTENSITYMAP
	outcol.rgb+=usecolourspec.rgb;
#endif
#endif
	
//----------------------------------------------------------------------------------
// add emissive
//----------------------------------------------------------------------------------
	
#ifdef USEEMISSIVE																
#ifdef USEEMISSIVEMAP
	vec4 emisscol=texture2D(s_texture6, v_texCoords[lightMaterial_uEmissiveUVSet]);
	outcol.rgb+=lightMaterial_emissive.rgb * emisscol.rgb;
#endif
#ifndef USEEMISSIVEMAP
	outcol.rgb+=lightMaterial_emissive.rgb;
#endif
#endif

//----------------------------------------------------------------------------------

#endif //#ifndef USESPECIAL_BEACH
#endif //#ifndef USESPECIAL_OCEAN
#endif //#ifndef USESPECIAL_SHALLOW

//----------------------------------------------------------------------------------

#endif		//USEUBER

//----------------------------------------------------------------------------------
//----------------------------------------------------------------------------------
//----------------------------------------------------------------------------------

#ifdef USE2D


#ifdef TEXBLEND2D_T1
	decal=texture2D(s_texture1, v_texCoords[0]);	
#endif

#ifdef TEXBLEND2D_T1_X_C1
	decal=texture2D(s_texture1, v_texCoords[0]) * v_vertcol;
#endif

#ifdef TEXBLEND2D_T1_X_T2
	decal=texture2D(s_texture1, v_texCoords[0]) * v_vertcol;
	decal2=texture2D(s_texture2, v_texCoords[1]);
	decal=decal*decal2;
#endif

#ifdef TEXBLEND2D_T1_X_C1_MASK
	decal=texture2D(s_texture1, v_texCoords[0]) * v_vertcol;
	maskcol=texture2D(s_texture2, v_texCoords[1]);
	decal.a*=maskcol.a;
#endif

#ifdef TEXBLEND2D_C1
	decal=texture2D(s_texture1, v_texCoords[0]);	
	decal.rgb=v_vertcol.rgb;
	decal.a*=v_vertcol.a;
#endif

#ifdef TEXBLEND2D_T1_X_C2
	decal=texture2D(s_texture1, v_texCoords[1]);				//the one to use for colour
	maskcol=texture2D(s_texture2, v_texCoords[0]);				//the 'split' alpha
	decal.a=maskcol.a*decal.a;
	decal*=v_vertcol;
#endif

	outcol.rgba=decal.rgba;
	
#ifdef USEALPHATEST
	if (outcol.a<0.5)	//alphaTest
    {
		discard;
	}
#endif

#endif	 //USE2D

//----------------------------------------------------------------------------------
//----------------------------------------------------------------------------------
//----------------------------------------------------------------------------------
	//Okay LG phone won't upload the lightmaterial array correctly without this line
	//It's like by not using the last vec4 in the array something gets optimized out and breaks things
	//shows as the golf arc going wrong (grey)
	outcol.r+=0.0*lightMaterial_mulcol.r;

#ifdef PREMULCOLENABLE
	outcol.rgba*=MulCol.rgba;		//PreMulCol now - use for objects in model
#endif

#ifdef PREHIGHLIGHTENABLE
	outcol.rgb+=(Highlight.rgb-outcol.rgb)*Highlight.w;		//PreHighlight now - use for tilemap objects
#endif

#ifdef USESHADOWMAP

	vec2 projectTexCoord;															// assuming that this is in proj space			
	projectTexCoord.x=(0.5+(0.5*v_position_lig.x/v_position_lig.w));
	projectTexCoord.y=(0.5+(0.5*v_position_lig.y/v_position_lig.w));		//two -s cancel out

//	projectTexCoord.x=0.5+0.5*v_position.x/v_position.w;		//actual screen pos converted into 0/1 texture
//	projectTexCoord.y=0.5+0.5*v_position.y/v_position.w;
//	outcol.r+=projectTexCoord.x;								//seems to move round, so suggests that the uvs are correct
//	outcol.g+=projectTexCoord.y;
	
//	if(0)		//(saturate(projectTexCoord.x) == projectTexCoord.x) && (saturate(projectTexCoord.y) == projectTexCoord.y))
    {
		vec4 tex=texture2D(s_texture6, projectTexCoord);		

		float lightDepthValue = v_position_lig.z / v_position_lig.w;		//hmm this may be -1 +1 on GL
		float depthValue=tex.r;
		if(lightDepthValue-0.01 > depthValue-0.5)
        {
			outcol.rgb *=0.5;
		}
	}

#endif

	//<#INSERTSHADEREFFS#>

	gl_FragColor=outcol;

//----------------------------------------------------------------------------------

#endif		//USEDEFINES

}



//----------------------------------------------------------------------------------
//----------------------------------------------------------------------------------

#ifdef PASTEINCODE		// pasted in code - only definition

/*<ShaderEff>

#ifdef USESHADEREFFMULCOL<n>
	outcol.rgba *= shadData_colour(n);
#endif

#ifdef USESHADEREFFADDCOL<n>
	outcol.rgba += shadData_colour(n);
#endif

#ifdef USESHADEREFFSATURATE<n>
	outcol.rgb=SaturateColour(outcol.rgb,shadData_sat(n));
#endif

#ifdef USESHADEREFFBLENDCOL<n>
	outcol.rgb+=(shadData_colour(n).rgb-outcol.rgb)*shadData_colour(n).a;		//sat(n);
#endif

#ifdef USESHADEREFFCOLORIZE<n>
	outcol.rgb=Colorize(outcol.rgb,shadData_colour(n).rgb,shadData_sat(n),shadData_lig(n));
#endif

#ifdef USESHADEREFFHUESHIFT<n>
	tempHSV=ConvRGBtoHSV(outcol.rgb);		// convert from RGB to HSV
	tempHSV.x+=shadData_hue(n);				//hue DELTA was offset to 0.5 not now
	tempHSV.x-=floor(tempHSV.x);
	tempRGB=ConvHSVtoRGB(tempHSV);
	tempRGB=SaturateColour(tempRGB,shadData_sat(n));		//now saturate
	outcol.rgb=LightenColour(tempRGB,shadData_lig(n));		//and lighten
#endif

#ifdef USESHADEREFFCONTRAST<n>
	outcol.rgb = ((outcol.rgb - 0.5) * shadData_sat(n)) + 0.5;
#endif

#ifdef USESHADEREFFADDCOLPROP<n>
	tempV=outcol.r*0.30+outcol.g*0.59+outcol.b*0.11;		//input intensity 0-1
	outcol.rgb+=,shadData_colour(n)*tempV;
#endif
	
#ifdef USESHADEREFFFOG<n>
	fog=saturate((v_position.z-shadData_sat(n))/(shadData_lig(n)-shadData_sat(n)));		//v_position.z is actual distance
	outcol.rgb+=(shadData_colour(n).rgb-outcol.rgb)*fog;
#endif
*/


/*<DirectionalLight>

#ifdef USELIGHT<n>

#ifndef USEPOINT<n>
			NdotL = dot(nrm_ws, -light_direction(n).xyz);
			if (NdotL>0.0)														//only add if light dot normal > 0, else point facing away from light
			{
#ifdef USEDIFFUSELIGHTING
				C.colour.rgb+= NdotL * light_diffuse(n).rgb;					//diffuse - dont mul by material diffuse colour until later
#endif
#ifdef USESPECULAR
#ifdef USESPECULAR<n>
#ifdef FASTSPEC
				hv_wsn=normalize(-light_direction(n).xyz - ptoc_wsn);			//todo interpolate this
				d = dot ( hv_wsn , nrm_ws);	
				specpow=pow(max(0.0, d), lightMaterial_specularpower*4.0);
#endif
#ifndef FASTSPEC
				L_wsn=-light_direction(n).xyz;
				r=normalize(reflect(L_wsn.xyz,nrm_ws));
				d = dot ( ptoc_wsn , r);										//dot the angle
				specpow=pow(max(0.0, d), lightMaterial_specularpower);
#endif
				C.colourSpec.rgb+= specpow * light_specular(n).rgb;				//dont mul by material specular colour until later
#endif
#endif
			}
#endif


#ifdef USEPOINT<n>

			ltop_ws=light_position(n).xyz-pos_ws.xyz;							//light to pos world space
			ltop_wsn=normalize(ltop_ws);										//normalised
			NdotL=dot(nrm_ws,ltop_wsn);											//dot to see if light facing normal
			if (NdotL>0.0)														//Must be facing for anything at all
			{
				LD=length(ltop_ws);
				if (LD<=light_range(n))
				{
					fAtten=1.0/(light_attenuation0(n) + light_attenuation1(n)*LD + light_attenuation2(n)*LD*LD);
#ifdef USEDIFFUSELIGHTING
					C.colour.rgb+=NdotL * light_diffuse(n).rgb * fAtten;
#endif				
#ifdef USESPECULAR
					r=normalize(reflect(ltop_wsn,nrm_ws));
					d = dot ( ptoc_wsn , r);										//dot the angle
					specpow=pow(max(0.0, d), lightMaterial_specularpower);
					C.colourSpec.rgb+= specpow * light_specular(n).rgb * fAtten;	//dont mul by material specular colour until later
#endif
				}
			}

#endif
	
#endif

*/		

#endif  //PASTEINCODE

//----------------------------------------------------------------------------------
//----------------------------------------------------------------------------------
//----------------------------------------------------------------------------------
