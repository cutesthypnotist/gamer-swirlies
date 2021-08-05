Shader "Custom/Swirlies"
{
	Properties
	{

	[Header(Main Colors)]
	[Gamma]_Color ("Spectrum Color 1", Color) = (1., 0., 0., 1) // color
	[Gamma]_SubColor ("Spectrum Color 2", Color) = (1., 1., 0., 1) // color
	[Header(Additional Colors)]
	[Gamma]_Color2 ("Spectrum Color 3", Color) = (1., 0., 0., 1) // color
	[Gamma]_SubColor2 ("Spectrum Color 4", Color) = (0., 1., 1., 1) // color

	[Toggle] _UseTexturesInstead("Replace colors 3 & 4 with textures", Float) = 1	
	_MainTex ("Texture", 2D) = "white" {}
	_SubTex ("SubTexture", 2D) = "white" {}

	_TexZoom("Texture Zoom", Float) = 1.0
	_TexSpeed("Texture Speed", Float) = 1.0
	_TexTime("Texture Time Scale", Float) = 0.6

	[Header(UV settings)]

	_uvox("Offset UVx", float) = 0
	_uvoy("Offset UVy", float) = 0	
	_rotationUV("Rotate UVs", float) = 0
	_uvx("Resize UVx", float) = 0
	_uvy("Resize UVy", float) = 0

	[Header(Other Settings)]
	_Zoom("Spiral Zoom", float) = 1

	_BlurEdges("Blur Edges", float) = 8.3
	_TimeScale("Time Scale", float) = 1.0
	_TwistSpeed("Twist Speed", float) = 1.0
	_AngleTwist("Twist Angle", Int) = 1
	_Twistiness("Twistiness", Float) = 1.0


	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			#define mod(x,y) (x-y*floor(x/y)) // glsl mod
			struct appdata
			{
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};


			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _SubTex;
			float4 _SubTex_ST;
			uniform float _uvx;
			uniform float _uvy;
			uniform float _uvoy;
			uniform float _uvox;
			uniform float _Zoom;
			uniform float4 _SubColor;
			uniform float4 _Color;
			uniform float4 _SubColor2;
			uniform float4 _Color2;			
			uniform float _BlurEdges;
			uniform float _TimeScale;
			uniform float _TwistSpeed;
			uniform float _rotationUV;
			uniform float _AngleTwist;
			uniform float _Twistiness;
			uniform float _TexZoom;
			uniform float _TexSpeed;
			uniform float _TexTime;
			uniform float _UseTexturesInstead;
		
			
			static const float PI = 3.14159265;

			// folds 0>1>2>3>4... to 0>1<0>1<0...
			float fold(float x) {
				return abs(1. - (x-2.*floor(x/2.)));
			}

			float2 rotateUV(float2 uv, float rotation)
			{
				float mid = 0.5;

				float2x2 rotMatrix = float2x2(cos(rotation), sin(rotation), -sin(rotation), cos(rotation));

				return float2(
					cos(rotation) * (uv.x - mid) + sin(rotation) * (uv.y - mid) + mid,
					cos(rotation) * (uv.y - mid) - sin(rotation) * (uv.x - mid) + mid
				);
			}

			float3 spectrumTex(float x, float2 temp_cast_0) {
				x = mod(x, 3.);
				return lerp(
					lerp(_SubColor.rgb, tex2D( _MainTex, (temp_cast_0 + _MainTex_ST.zw) * _MainTex_ST.xy ).rgb, x),
					lerp(_Color.rgb, tex2D( _SubTex, (temp_cast_0 + _SubTex_ST.zw) * _SubTex_ST.xy).rgb, x-2.),
					x-1.
				);
			}

			float3 spectrum(float x) {
				x = mod(x, 3.);
				return lerp(
					lerp(_Color.rgb, _SubColor.rgb, x),
					lerp(_Color2.rgb, _SubColor2.rgb, x-2.),
					x-1.
				);
			}			

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord;
				return o;
			}

			float4 frag (v2f i) : SV_Target
			{
				float iTime = _Time.y;
    			float2 uv = rotateUV(i.uv,_rotationUV)-0.5;
				uv.x += _uvox;
    			uv.y += _uvoy;
				uv.x *= (1 + _uvx);
				uv.y *= (1 + _uvy);

				//Add blur
    			float2 uvR =  i.vertex.xy - _ScreenParams.xy;				
				float blur = _BlurEdges / max(0.1, length(uvR));

				// The basic 2d distance function for a spiral is length(uv) or uv.x*uv.x+uv.y*uv.y. 
				// You can use log(length(uv)) to add a wormhole effect.
				// There's also exp(length(uv)).
				// float len = length(uv);
    			float lenSq = log(length(uv)) * _Zoom;
				float angle = atan2(uv.x,uv.y) / PI;
				float spiral = smoothstep(0.5 - blur * 0.5, 0.5 + blur * 0.5, fold(
						lenSq * (PI/2.0 + _Twistiness 
										// Uncomment to have it loop back and forth.
										//* sin(iTime * _TwistSpeed)
								)
					- angle * floor(_AngleTwist)
					+ iTime * _TimeScale
				));
				int ring = int(iTime + log(length(uv)) * _TexTime);
				float4 col = float4(0.,0.,0.,1.);
				UNITY_BRANCH
				if(_UseTexturesInstead) {
					float2 temp_cast_0 = (( ( sin( length( ( (uv) * (float2( 1,1 ) - float2( -1,-1 )) / (float2( 1,1 ) - float2( 0,0 ))) ) ) 
						+ ( (0.5 + (_SinTime.x - -1.0) * (2.5 - 0.5) / (1.0 - -1.0)) * _TexSpeed ) + _TexSpeed ) 
						* ( _TexZoom * (0.5 + (_SinTime.x - -1.0) * (1.5 - 0.5) / (1.0 - -1.0)) 
						* (0.5 + (_SinTime.y - -1.0) * (1.5 - 0.5) / (1.0 - -1.0)) ) )).xx;
					col += float4(spectrumTex(spiral, temp_cast_0).rgb,1.0);
				} else {
					col += float4(spectrum(spiral).rgb,1.0);
				}

				col.rgb = LinearToGammaSpace(col.rgb);
				return col;

				//TODO: Try code from Pema below.
				//col = 0.5 * log(_Gamma+col);
				//col = clamp(col, 0.0, 1.0);
				//return col;	

			}
			ENDCG
		}
	}
}
