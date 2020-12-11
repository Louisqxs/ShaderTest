// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Normal Map In World Space"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_Color("Color",Color) = (1,1,1,1)
		_BumpMap("Normal Map", 2D) = "white" {}
		_BumpScale("Bump Scale", Float) = 1.0
		_Specular("Specular",Color) = (1,1,1,1)   //高光反射颜色
		_Gloss("gloss", Range(5,30)) = 10     //高光区域大小
	}
		SubShader
		{
			Tags { "LightMode" = "ForwardBase" }
			LOD 100

			Pass
			{
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag

				#include "UnityCG.cginc"
				#include "Lighting.cginc"

				sampler2D _MainTex;
				float4 _MainTex_ST;
				fixed4 _Specular;
				fixed4 _Color;
				float _Gloss;
				float _BumpScale;
				sampler2D _BumpMap;
				float4 _BumpMap_ST;

				struct appdata
				{
					float4 vertex : POSITION;
					float4 uv : TEXCOORD0;
					float3 normal:NORMAL;
					float4 tangent: TANGENT;
				};

				struct v2f
				{
					float4 uv : TEXCOORD0;
					float4 vertex : SV_POSITION;
					float4 TtoW0 :TEXCOORD1;
					float4 TtoW1 :TEXCOORD2;
					float4 TtoW2 :TEXCOORD3;
				};

				v2f vert(appdata v)
				{
					v2f o;
					o.vertex = UnityObjectToClipPos(v.vertex);
					o.uv.xy = TRANSFORM_TEX(v.uv.xy, _MainTex);
					o.uv.zw = v.uv.xy *_BumpMap_ST.xy + _BumpMap_ST.zw;

					//对象空间坐标系转换到世界空间坐标系
					float3 worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
					fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
					fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
					fixed3 worldBinormal = cross(worldNormal,worldTangent) * v.tangent.w;

					//TtoW切线空间到世界空间的变换矩阵，按列摆放依次存放：切线，副切线，法线，顶点位置.（都是世界空间下的） 
					o.TtoW0 = float4(worldTangent.x,worldBinormal.x,worldNormal.x,worldPos.x);
					o.TtoW1 = float4(worldTangent.y,worldBinormal.y,worldNormal.y,worldPos.y);
					o.TtoW2 = float4(worldTangent.z,worldBinormal.z,worldNormal.z,worldPos.z);

					return o;
				}

				fixed4 frag(v2f i) : SV_Target
				{
					//获得世界空间中的坐标
					float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);
					//计算光照和视角方向在世界坐标系中
					fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
					fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));

					//获得切线空间下的法线，法线纹理“Texture Type”设置成“Normal Map”
					fixed3 bump = UnpackNormal(tex2D(_BumpMap,i.uv.zw));
					bump.xy *= _BumpScale;
					bump.z = sqrt(1.0 - saturate(dot(bump.xy,bump.xy)));
					//将法线从切线空间转换到世界空间，单位化（矩阵每一行的xyz 与 法线点积）
					bump = normalize(half3(dot(i.TtoW0.xyz,bump),dot(i.TtoW1.xyz,bump),dot(i.TtoW2.xyz,bump)));

					fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;

					fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

					fixed3 halfDir = normalize(lightDir + viewDir);
					fixed3 diffuse = _LightColor0.rgb * albedo * max(0,dot(bump,lightDir));


					fixed3 specular = _LightColor0.rgb *_Specular * pow(max(0,dot(bump,halfDir)),_Gloss);

					return fixed4(ambient + diffuse + specular,1.0);
				}
				ENDCG
			}
		}
			FallBack "Specular"
}