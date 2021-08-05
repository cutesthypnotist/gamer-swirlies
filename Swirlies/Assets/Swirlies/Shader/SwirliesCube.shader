Shader "Custom/SwirliesV2 Cubemaps"
{
	Properties
	{
    [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", Float) = 2
    [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest", Float) = 4        
	[Header(Main Colors)]
	[Gamma]_Color ("Spectrum Color 1", Color) = (1., 0., 0., 1) // color
	[Gamma]_SubColor ("Spectrum Color 2", Color) = (1., 1., 0., 1) // color
	[Header(Additional Colors)]
	[Gamma]_Color2 ("Spectrum Color 3", Color) = (1., 0., 0., 1) // color
	[Gamma]_SubColor2 ("Spectrum Color 4", Color) = (0., 1., 1., 1) // color

	[ToggleUI] _UseTexturesInstead("Replace colors 3 & 4 with textures", Float) = 1	
	_MainTex ("Texture", 2D) = "white" {}
	_SubTex ("SubTexture", 2D) = "white" {}

	_TexZoom("Texture Zoom", Float) = 1.0
	_TexSpeed("Texture Speed", Float) = 1.0
	_TexTime("Texture Time Scale", Float) = 0.6
	_SubTwistSpeed("Texture Twist Speed (0 is continuous)", float) = 1.0
	_AddTexSpeed("Texture Add Speed", Float) = 0.0

	[Header(UV settings)]

	_uvox("Offset UVx", float) = 0
	_uvoy("Offset UVy", float) = 0	
	_rotationUV("Rotate UVs", float) = 0
	_uvx("Resize UVx", float) = 0
	_uvy("Resize UVy", float) = 0

	[Header(Other Settings)]
	[Enum(Length, 0, Squared, 1, Logarithmic, 2, Base e Exponential, 3)] _SpiralMode("Spiral Mode", Int) = 2

	_Zoom("Spiral Zoom", float) = 1

	_BlurEdges("Blur Edges", float) = 8.3
	_TimeScale("Time Scale", float) = 1.0
	_TwistSpeed("Twist Speed (0 is continuous)", float) = 1.0
	_AngleTwist("Twist Angle", Int) = 1
	_Twistiness("Twistiness", Float) = 1.0

	[Header(Cubemap)]
	_Spherify("Spherify", Range(0,1)) = 0
	_SpherifyOffset("Spherify Offset", Range(0,1)) = 0.5

	_Metallic("Metallic", Float) = 0.0
	_Cube("Cube", Cube) = "_DitherMaskLOD2D" {}
	_Cube2("Cube2", Cube) = "_DitherMaskLOD2D" {}
	_Cube3("Cube3", Cube) = "_DitherMaskLOD2D" {}

	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
        Cull [_Cull]
        ZTest [_ZTest]  
		Pass
		{
			CGPROGRAM
			#pragma target 5.0
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
				float3 rd : TEXCOORD1;
				float4 wpos : TEXCOORD2;
			};            



			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _SubTex;
			float4 _SubTex_ST;
            samplerCUBE _Cube;
            samplerCUBE _Cube2;
            samplerCUBE _Cube3;
			float _uvx;
			float _uvy;
			float _uvoy;
			float _uvox;
			float _Zoom;
			float4 _SubColor;
			float4 _Color;
			float4 _SubColor2;
			float4 _Color2;			
			float _BlurEdges;
			float _TimeScale;
			float _TwistSpeed;
			float _rotationUV;
			float _AngleTwist;
			float _Twistiness;
			float _TexZoom;
			float _Metallic;
			float _TexSpeed;
			float _TexTime;
			float _UseTexturesInstead;
			int _SpiralMode;
			float _AddTexSpeed;
			float _SubTwistSpeed;
			float _Spherify;
			float _SpherifyOffset;
			
			static const float PI = 3.14159265;
            float2x2 Rot(float a)
            {
                float s = sin(a), c = cos(a);
                return transpose(float2x2(c, -s, s, c));
            }  
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
				o.wpos = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.));
				o.rd = normalize(_WorldSpaceCameraPos.xyz - o.wpos);
				return o;
			}
			float3 BlendOverlay (float3 base, float3 blend) // overlay
			{
				return base < 0.5 ? (2.0 * base * blend) : (1.0 - 2.0 * (1.0 - base) * (1.0 - blend));
			}

			float4 frag (v2f i) : SV_Target
			{
				float iTime = _Time.y;
				// normal from interpolated object space position
                float3 normal = normalize(i.vertex);
				float4 pos = i.vertex;

				//https://bgolus.medium.com/distinctive-derivative-differences-cce38d36797b#85c9
                // atan returns a value between -pi and pi
                // so we divide by pi * 2 to get -0.5 to 0.5
                float phi = atan2(normal.z, normal.x) / (UNITY_PI * 2.0);

                // 0.0 to 1.0 range
                float phi_frac = frac(phi);

                // acos returns 0.0 at the top, pi at the bottom
                // so we flip the y to align with Unity's OpenGL style
                // texture UVs so 0.0 is at the bottom
                float theta = acos(-normal.y) / UNITY_PI;

				
				//https://github.com/bgolus/EquirectangularSeamCorrection/issues/1
				// arbitrary non-zero value that is unique in each quad so the delta is never 0
				float magic = 1.0 + float(i.uv.x) + 2.0 * float(i.uv.y);
				float bad = (2.0*pos.x < pos.y) ? magic : 0.0;
				float badx1 = ddx_fine(bad);
				float bady1 = ddy_fine(bad);
				// Distribute "bad" value horizontally and vertically.
				// In case of coarse derivatives this also eliminates the value
				// calculated by the non-participating pixel, which is important
				bad = (badx1 != 0.0 || bady1 != 0.0) ? magic : 0.0;
				// For fine derivatives we need an extra step to distribute the value
				// to the diagonally opposite side.
				badx1 = ddx_fine(bad);
				if (badx1 != 0.0) bad = 1.0;
				float2 uv = float2(bad != 0.0 ? phi_frac : phi, theta);
				uv = lerp(i.uv, uv, _Spherify);
    			uv = rotateUV(uv,_rotationUV)-_SpherifyOffset;
				uv.x += _uvox;
    			uv.y += _uvoy;
				uv.x *= (1 + _uvx);
				uv.y *= (1 + _uvy);

				//Add blur
    			float2 uvR =  i.vertex.xy - _ScreenParams.xy;				
				float blur = _BlurEdges / max(0.1, length(uvR));

				float len = 0.;
				
				UNITY_BRANCH switch (_SpiralMode) {
					case 0:
						len = length(uv);
						break;
					case 1:
						len = uv.x*uv.x+uv.y*uv.y;
						break;
					case 2:
    					len = log(length(uv));
						break;
					case 3:
						len = exp(length(uv));
						break;
					default:
						// should never reach here
    					len = log(length(uv));
						break;
				}
				len *= _Zoom;
				float angle = atan2(uv.x,uv.y) / PI;
				float spiral = smoothstep(0.5 - blur * 0.5, 0.5 + blur * 0.5, fold(
						len * (PI/2.0 + _Twistiness 
										// Uncomment to have it loop back and forth.
										* sin(iTime * _TwistSpeed)
								)
					- angle * floor(_AngleTwist)
					+ iTime * _TimeScale
				));
				int ring = int(iTime + log(length(uv)) * _TexTime);
				float4 col = float4(0.,0.,0.,1.);
				UNITY_BRANCH
				if(_UseTexturesInstead) {
					float2 temp_cast_0 = (( ( sin( length( ( (uv) * (float2( 1,1 ) - float2( -1,-1 )) / (float2( 1,1 ) - float2( 0,0 ))) ) ) 
						+ ( (0.5 + (_SinTime.x - -1.0) * _SubTwistSpeed * (2.5 - 0.5) / (1.0 - -1.0)) * _TexSpeed ) + _TexSpeed ) 
						* ( _TexZoom * (0.5 + (_SinTime.x - -1.0) * _SubTwistSpeed * (1.5 - 0.5) / (1.0 - -1.0)) 
						* (0.5 + (_SinTime.y - -1.0) * _SubTwistSpeed * (1.5 - 0.5) / (1.0 - -1.0)) ) ) + _Time.y * _AddTexSpeed * UNITY_PI * 0.25).xx;
					col += float4(spectrumTex(spiral, temp_cast_0).rgb,1.0);
				} else {
					col += float4(spectrum(spiral).rgb,1.0);
				}
				
                float3 coob = texCUBE(_Cube, i.rd);
                float3 rd2 = i.rd;
                rd2.xy = mul(rd2.xy, Rot(UNITY_HALF_PI));
                float3 coob2 = texCUBE(_Cube2, rd2);
                rd2.xy = mul(rd2.xy, Rot(UNITY_HALF_PI));
                float3 coob3 = texCUBE(_Cube3, rd2);
				
                float3 nor = normalize(i.wpos);
				nor = reflect(i.rd, nor);
				float fre = pow(0.5 + clamp(dot(nor, i.rd), 0.0, 1.0), 3.0) * _Metallic;
				col.rgb += BlendOverlay(coob, BlendOverlay(coob2, coob3)) * fre;
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
