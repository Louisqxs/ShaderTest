Shader "MaskTexture"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_BumpTex("BumpTex", 2D) = "white" {}
		_MaskTex("MaskTex", 2D) = "white" {}
		_BumpScale("BumpScale", Float) = 1.0
		_MaskScale("MaskScale", Float) = 1.0
		_Color("Color Tint", Color) = (1, 1, 1, 1)
		_Specular("Specular", Color) = (1, 1, 1, 1)
		_Gloss("Gloss", Range(8.0, 256)) = 20
	}
		SubShader
		{
			Pass
			{
				Tags {"LightMode" = "ForwardBase"}

				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag

				#include "Lighting.cginc"

				sampler2D _MainTex;
				float4 _MainTex_ST;
				sampler2D _BumpTex;
				float4 _BumpTex_ST;
				sampler2D _MaskTex;
				float4 _MaskTex_ST;
				float _BumpScale;
				float _MaskScale;
				fixed4 _Color;
				fixed4 _Specular;
				float _Gloss;

				struct appdata
				{
					float4 vertex : POSITION;
					float2 uv : TEXCOORD0;
					float3 normal : NORMAL;
					float4 tangent : TANGENT;
				};

				struct v2f
				{
					float2 uv : TEXCOORD0;
					float4 vertex : SV_POSITION;
					float3 lightDir : TEXCOORD1;
					float3 viewDir : TEXCOORD2;
				};

				v2f vert(appdata v)
				{
					v2f o;
					o.vertex = UnityObjectToClipPos(v.vertex);
					o.uv = TRANSFORM_TEX(v.uv, _MainTex);

					TANGENT_SPACE_ROTATION;
					o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;
					o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;

					return o;
				}

				fixed4 frag(v2f i) : SV_Target
				{
					fixed3 lightDir = normalize(i.lightDir);
					fixed3 viewDir = normalize(i.viewDir);

					fixed4 bumpColor = tex2D(_BumpTex, i.uv);
					fixed3 tangentNormal = UnpackNormal(bumpColor);
					tangentNormal.xy *= _BumpScale;
					tangentNormal.z = sqrt(1 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

					fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;

					fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
					fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentNormal, lightDir));

					fixed mask = tex2D(_MaskTex, i.uv).r * _MaskScale;
					fixed3 halfDir = normalize(viewDir + lightDir);
					fixed3 specular = _LightColor0.rgb * _Specular * pow(max(0, dot(tangentNormal, halfDir)), _Gloss) * mask;

					return fixed4(ambient + diffuse + specular, 1.0);
				}
				ENDCG
			}
		}

			FallBack "Specular"
}