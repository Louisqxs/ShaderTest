Shader "AlphaTest"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_Color("Color Tint", Color) = (1, 1, 1, 1)
		_Cutoff("Alpha Cutoff", Range(0, 1)) = 0.5
	}
		SubShader
		{
			Tags {"Queue" = "AlphaTest" "IgnoreProjector" = "True" "RenderType" = "TransparentCutout"}

			Pass
			{
				Tags {"LightMode" = "ForwardBase"}

				Cull Off

				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag

				#include "Lighting.cginc"

				sampler2D _MainTex;
				float4 _MainTex_ST;
				fixed4 _Color;
				fixed _Cutoff;

				struct appdata
				{
					float4 vertex : POSITION;
					float2 uv : TEXCOORD0;
					float3 normal : NORMAL;
				};

				struct v2f
				{
					float2 uv : TEXCOORD0;
					float4 vertex : SV_POSITION;
					float3 worldNormal : TEXCOORD1;
					float3 worldPos : TEXCOORD2;
				};

				v2f vert(appdata v)
				{
					v2f o;
					o.vertex = UnityObjectToClipPos(v.vertex);
					o.uv = TRANSFORM_TEX(v.uv, _MainTex);
					o.worldNormal = UnityObjectToWorldNormal(v.normal);
					o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
					return o;
				}

				fixed4 frag(v2f i) : SV_Target
				{
					fixed3 worldNormal = normalize(i.worldNormal);
					fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

					fixed4 texColor = tex2D(_MainTex, i.uv);

  //				if (texColor.a - _Cutoff < 0.0) {
  //					discard;
  //				}
					clip(texColor.a - _Cutoff);
					fixed3 albedo = texColor.rgb * _Color.rgb;

					fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
					fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));

					return fixed4(ambient + diffuse, 1.0);
				}
					ENDCG
		}
		}

			FallBack "Transparent/Cutout/VertexLit"
}