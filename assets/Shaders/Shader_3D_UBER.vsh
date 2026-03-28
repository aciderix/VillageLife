//  Shader_3D_UBER.vsh

precision highp float;

#ifndef USEDEFINES

// these will be defined in the header to the new variant shader

//#define DIFFUSEMAPENABLE					
//#define SHADOWMAPENABLE					
//#define USESPECULAR
//#define USEREFLECTION					
//#define USEEMISSIVE					
//#define USEEMISSIVEMAP				
//#define USENORMALMAP					
//#define USESPECULARINTENSITYMAP		
//#define USEREFLECTIONINTENSITYMAP		
//#define USEPHONG
//#define USEBLENDDIFFMAPS							
//#define USEDIFFUSEMAP2				
//#define USEDIFFUSELIGHTING				
//#define lightMaterial_uDiffuseUVSet						0
//#define lightMaterial_uDiffuse2UVSet					3
//#define lightMaterial_uReflectionIntensityUVSet			0
//#define lightMaterial_uShadowUVSet						1
//#define lightMaterial_uSpecularIntensityUVSet			0
//#define lightMaterial_uNormalUVSet						0
//#define lightMaterial_uEmissiveUVSet					2
//#define VSUSENORMAL
//#define VSUSETANGENTS
//#define VSUSEVCOLOUR
//#define VSUSETEX1
//#define VSUSETEX2
//#define VSUSETEX3
//#define VSUSETEX4
//#define NUMLIGHTSTOUSE		4

//#define VSUSEPOSITION									//we need this or wont pass position through

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


// This is the vertex INPUT data, pure mesh vertices. The vertex shader takes this in for each vertex, proxesses it and outputs it, interpolated into the pixel shader

#ifdef VSUSEPOSITION
attribute highp vec4 a_position;
#endif

#ifdef VSUSECOLOUR
attribute lowp vec4 a_colour;
#endif

#ifdef VSUSENORMAL
attribute highp vec4 a_normal;		//TODO 3
#endif
#ifdef VSUSETANGENTS
attribute highp vec4 a_tangent;
attribute highp vec4 a_binormal;
#endif
#ifdef VSUSEBONES
attribute highp vec4 a_boneweights;
attribute highp vec4 a_boneindices;
#endif


#if defined(VSUSETEX1) || defined(VSUSETEX2)
attribute highp vec4 a_texCoord12;
#endif
#if defined(VSUSETEX3) || defined(VSUSETEX4)
attribute highp vec4 a_texCoord34;
#endif

#ifdef VSUSEVCOLOUR
attribute highp vec4 a_vcolour;
#endif


// This is the vertex OUTPUT data which gets interpolated and fed into pixel shader per scanned screen pixel

varying highp vec4 v_position;
varying highp vec4 v_position_lig;

#ifdef USEPHONG
varying highp vec3 v_normal;
varying highp vec4 v_positionthro;
#endif
#ifdef VSUSETANGENTS
varying highp vec3 v_tangent;
varying highp vec3 v_binormal;
#endif

#ifdef VSUSECOLOUR
varying highp vec4 v_vertcol;
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


//struct cbMeshXObject
//{
//	mat4	MeshX[12];
//};

uniform mat4 MeshX[12];


#define LIGHTMATERIAL_DIFFUSE		0
#define LIGHTMATERIAL_AMBIENT		1
#define LIGHTMATERIAL_SPECULAR		2
#define LIGHTMATERIAL_EMISSIVE		3
#define LIGHTMATERIAL_SPECULARPOWER	4
#define LIGHTMATERIAL_REFLECMULT	4
#define LIGHTMATERIAL_SHADOWMULT	4
#define LIGHTMATERIAL_NORMALHEIGHT	4
#define LIGHTMATERIAL_MULCOL		5

#define LIGHTMATERIAL_TOTALSIZE     6

#define lightMaterial_specular			LightMaterial[LIGHTMATERIAL_SPECULAR]
#define lightMaterial_ambient			LightMaterial[LIGHTMATERIAL_AMBIENT]
#define lightMaterial_diffuse			LightMaterial[LIGHTMATERIAL_DIFFUSE]
#define lightMaterial_emissive			LightMaterial[LIGHTMATERIAL_EMISSIVE]
#define lightMaterial_specularpower		LightMaterial[LIGHTMATERIAL_SPECULARPOWER].x
#define lightMaterial_reflecMult		LightMaterial[LIGHTMATERIAL_REFLECMULT].y
#define lightMaterial_shadowMult		LightMaterial[LIGHTMATERIAL_SHADOWMULT].z
#define lightMaterial_normalHeight		LightMaterial[LIGHTMATERIAL_NORMALHEIGHT].w
#define lightMaterial_mulcol			LightMaterial[LIGHTMATERIAL_MULCOL]

uniform vec4 LightMaterial[LIGHTMATERIAL_TOTALSIZE];

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


// constants
uniform float	c_fTime;
uniform float	c_uvDeltaU1;
uniform float	c_uvDeltaV1;
uniform float	c_uvDeltaU2;
uniform float	c_uvDeltaV2;
uniform float	c_uvMultiply;
uniform vec4	c_uvPosition[4];			//NOTE THis is per UV set, not per texture

uniform vec4	c_depthColour;

uniform float	c_waveFrequencyy;
uniform float	c_waveSpeed;
uniform float	c_waveIntensity;


//Mirror gShader values
uniform mat4 modelViewProjectionMatrix;			//USED in Vshader
uniform mat4 modelViewProjShadowMatrix;			//USED in Vshader
//UGH   uniform mat4 modelViewMatrix;					//USED in shader
//NOTUSED uniform mat4 modelViewNormalizedInvMatrix;
uniform mat4 viewNormalizedInvMatrix;			//USED in Vshader
uniform mat4 modelMatrix;						//USED in VSHader

uniform sampler2D s_texture1;
uniform sampler2D s_texture2;
uniform sampler2D s_texture3;
uniform sampler2D s_texture4;
uniform sampler2D s_texture5;
uniform sampler2D s_texture6;
uniform sampler2D s_texture7;
uniform samplerCube s_texture8;


//-----------------------------------------------------
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


//
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

//


/*

// work out lights and reflection vector for point - either in vertex shader or pixel shader

Uber_cLightAndReflec gLightAndReflec;
void Uber_DoLightsAndReflec(
						 vec3 pos_ms,									//pos in model space
						 vec3 nrm_ms)									//nrm in model space
{
	Uber_cLightAndReflec C;												//output

#ifdef USESPECULAR
	vec3 pos_cs = ( modelViewMatrix * vec4(pos_ms,1.0)).xyz;			//pos in camera space
#endif
	vec3 nrm_cs = ( modelViewMatrix * vec4(nrm_ms,0.0)).xyz;			//nrm in camera space
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
#ifdef USESPECULAR
	pos_cs=normalize(pos_cs);											//normalize as only used in reflec of dir specular
#endif
	nrm_cs=normalize(nrm_cs);

	vec3 ptoc_ws = normalize(pos_ws.xyz-viewNormalizedInvMatrix[3].xyz);			//note used later in specular

#ifdef USEREFLECTION
	vec3 Nw = normalize(nrm_ws);										//reflection vec
	C.reflecVec.rgb = normalize( reflect ( ptoc_ws, nrm_ws ) );				//vector for cubemap lookup
#endif

	for (int n=0;n<NUMLIGHTSTOUSE;n++)
	{
#ifdef USEDIFFUSELIGHTING
		vec3 colour=vec3(0.0);
#endif
#ifdef USESPECULAR
		vec3 colourSpec=vec3(0.0);
#endif

		if (light_type(n)==SHADER_LIGHT_DIRECTIONAL)										//work out in camera space
		{
			vec4 L = vec4(-light_direction(n).xyz,0.0) * viewNormalizedInvMatrix ;					//Light in camera space - note mat mul done other way round as inv ?
			L.xyz=normalize(L.xyz);
			float NdotL = dot(nrm_cs, L.xyz);
			if (NdotL>0.0)																				//only add if light dot normal > 0, else point facing away from light
			{
#ifdef USEDIFFUSELIGHTING
				colour.rgb = NdotL * light_diffuse(n).rgb;											//diffuse - dont mul by material diffuse colour until later
#endif
#ifdef USESPECULAR
				vec3 r=normalize(reflect(L.xyz,nrm_cs));
				float d = dot ( pos_cs , r);														//dot the angle
				float specpow=pow(max(0.0, d), lightMaterial_specularpower);
				colourSpec.rgb = specpow * light_specular(n).rgb;									//dont mul by material specular colour until later
#endif
			}
		}
		else if (light_type(n)==SHADER_LIGHT_POINT)										//work out in world space
		{
			vec3 ltop_ws=light_position(n).xyz-pos_ws.xyz;								//light to pos world space
			vec3 ltop_wsn=normalize(ltop_ws);															//normalised
			float NdotL=dot(nrm_ws,ltop_wsn);															//dot to see if light facing normal
			if (NdotL>0.0)																				//Must be facing for anything at all
			{
#ifdef USEDIFFUSELIGHTING
				colour.rgb=NdotL * light_diffuse(n).rgb;
#endif
#ifdef USESPECULAR
				vec3 r=normalize(reflect(ltop_wsn,nrm_ws));
				float d = dot ( ptoc_ws , r);														//dot the angle
				float specpow=pow(max(0.0, d), lightMaterial_specularpower);
				colourSpec.rgb = specpow * light_specular(n).rgb;						//dont mul by material specular colour until later
#endif
				float fAtten=1.0;
				float LD=length(ltop_ws);
				if (LD>light_range(n))
				{
					fAtten=0.0;
				}
				else
				{
					fAtten=1.0/(light_attenuation0(n) + light_attenuation1(n)*LD + light_attenuation2(n)*LD*LD);
				}
#ifdef USEDIFFUSELIGHTING
				colour.rgb*=fAtten;																		//attenuate
#endif
#ifdef USESPECULAR
				colourSpec.rgb*=fAtten;
#endif
			}
		}
#ifdef USEDIFFUSELIGHTING
		C.colour.rgb+=colour.rgb;
#endif
#ifdef USESPECULAR
		C.colourSpec.rgb+=colourSpec.rgb;
#endif
	}

#ifdef USEDIFFUSELIGHTING
	C.colour.rgb*=lightMaterial_diffuse.rgb;															//do ONCE now not in light accumulation code
#endif
#ifdef USESPECULAR
	C.colourSpec.rgb*=lightMaterial_specular.rgb;
#endif

	gLightAndReflec=C;
	//return(C);
}

*/

#endif		//if LIGHTINGORREFLEC
//-----------------------------------------------------


void main()
{

#ifndef VSUSEBONES
	vec4 pos=vec4(a_position.xyz,1.0);
#ifdef VSUSENORMAL
	vec4 norm;
	norm.xyz=a_normal.xyz;
	norm.w=0.0;
#endif
#endif

#ifdef VSUSEBONES
	float weight;
	highp vec4 t;
	vec3 norm;
	int i;
	highp vec4 pos;
	highp vec4 p;

	p=a_position;
	pos=vec4(0.0,0.0,0.0,1.0);
	norm=vec3(0.0,0.0,0.0);

//	for (int b=0;b<4;b++) //EMS-Firefox has to have 'int b' decleration here
//	{
		i=int(a_boneindices[0]);
		weight=a_boneweights[0];
		if (weight!=0.0)
		{
			t=MeshX[i]*p;
			pos.xyz+=t.xyz*weight;
#ifdef VSUSENORMAL
			t.xyz=mat3(MeshX[i])*a_normal.xyz;
			norm+=t.xyz*weight;
#endif
		}
		i=int(a_boneindices[1]);
		weight=a_boneweights[1];
		if (weight!=0.0)
		{
			t=MeshX[i]*p;
			pos.xyz+=t.xyz*weight;
#ifdef VSUSENORMAL
			t.xyz=mat3(MeshX[i])*a_normal.xyz;
			norm+=t.xyz*weight;
#endif
		}
		i=int(a_boneindices[2]);
		weight=a_boneweights[2];
		if (weight!=0.0)
		{
			t=MeshX[i]*p;
			pos.xyz+=t.xyz*weight;
#ifdef VSUSENORMAL
			t.xyz=mat3(MeshX[i])*a_normal.xyz;
			norm+=t.xyz*weight;
#endif
		}
		i=int(a_boneindices[3]);
		weight=a_boneweights[3];
		if (weight!=0.0)
		{
			t=MeshX[i]*p;
			pos.xyz+=t.xyz*weight;
#ifdef VSUSENORMAL
			t.xyz=mat3(MeshX[i])*a_normal.xyz;
			norm+=t.xyz*weight;
#endif
		}
//	}
#endif

#ifdef VSUSEPOSITION
	gl_Position = modelViewProjectionMatrix*pos;
	v_position=modelViewProjectionMatrix*pos;

	v_position_lig=modelViewProjShadowMatrix*pos;			//pos is interpolated pixel pos across mesh triangle
														//output is where this pixel would appear on distance texture
#endif
#ifdef VSUSECOLOUR
	v_vertcol=vec4(a_colour.b,a_colour.g,a_colour.r,a_colour.a);		//This line didn't work on iPhone 4's so changed to floats
#endif
		
#ifdef USEPHONG
	v_normal.xyz   = norm.xyz;		//a_normal.xyz;
	v_positionthro.xyz = pos.xyz;		//a_position;
#endif
#ifdef VSUSETANGENTS
	v_tangent.xyz  = a_tangent.xyz;
	v_binormal.xyz = a_binormal.xyz;
#endif

#ifndef USEPHONG																					//not done here if phong
#ifdef LIGHTINGORREFLEC
	Uber_DoLightsAndReflec(pos.xyz, norm.xyz);				//work out lights per vertex
	Uber_cLightAndReflec C=gLightAndReflec;
#endif
#ifdef USEREFLECTION
	v_reflecVec.xyz = C.reflecVec.xyz;		
#endif
#ifdef USEDIFFUSELIGHTING
	v_colour.rgb=C.colour.rgb;
#endif
#ifdef USESPECULAR
	v_colourSpec.rgb=C.colourSpec.rgb;
#endif
#endif



#ifdef VSUSETEX1
	//v_texCoords[0] = a_texCoord12.xy;	
	v_texCoords[0]=(a_texCoord12.xy+c_uvPosition[0].xy)*c_uvPosition[0].zw;		
#endif
#ifdef VSUSETEX2
#ifdef VSUSETEX1
	v_texCoords[1] = a_texCoord12.zw;
#endif
#ifndef VSUSETEX1
	v_texCoords[1] = a_texCoord12.xy;
#endif
#endif

#ifdef VSUSETEX3
	v_texCoords[2] = a_texCoord34.xy;
#endif
#ifdef VSUSETEX4
#ifdef VSUSETEX3
	v_texCoords[3] = a_texCoord34.zw;
#endif
#ifndef VSUSETEX3
	v_texCoords[3] = a_texCoord34.xy;
#endif
#endif


#ifdef VSUSEVCOLOUR
	v_blend = a_vcolour;
#endif
}


	
