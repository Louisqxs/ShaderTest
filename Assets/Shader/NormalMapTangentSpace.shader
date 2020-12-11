// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Normal Map In Tangent Space"
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
			LOD 100
			Tags { "LightMode" = "ForwardBase" }

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
					float3 lightDir :TEXCOORD1;
					float3 viewDir :TEXCOORD2;
				};

				v2f vert(appdata v)
				{
					v2f o;
					o.vertex = UnityObjectToClipPos(v.vertex);
					o.uv.xy = TRANSFORM_TEX(v.uv.xy, _MainTex);
  //                o.uv.zw = TRANSFORM_TEX(v.uv.zw, _BumpMap);   天哪还以为法线也可以这样写。。。其实是没用的
					o.uv.zw = v.uv.xy *_BumpMap_ST.xy + _BumpMap_ST.zw;

					//副法线 = 叉积（单位化的法向量，单位化的切线向量）*切线向量的w分量来确定副切线的方向性
					//float3 binormal = cross(normalize(v.normal,normalize(v.tangent.xyz))) * v.tangent.w;
					//构建一个矩阵使向量从对象空间转变到切线空间
					//float3x3 rotation = float3x3(v.tangent.xyz,binormal,v.normal );
					//或者使用unity提供的宏定义来直接计算得到rotation变换矩阵
					TANGENT_SPACE_ROTATION;

					//将光照方向和视角方向从对象空间转变到切线空间
					o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;
					o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;
					return o;
				}

				fixed4 frag(v2f i) : SV_Target
				{
					fixed3 tangentLightDir = normalize(i.lightDir);
					fixed3 tangentViewDir = normalize(i.viewDir);
					//将法线纹理中的颜色重新映射回正确的法线方向值
					fixed4 packedNormal = tex2D(_BumpMap,i.uv.zw);
					fixed3 tangentNormal;

					//如果我们把“Texture Type”不设置成“Normal Map”,未压缩的格式
  //                tangentNormal.xy = (packedNormal.xy * 2 - 1) * _BumpScale;
					//法线是单位向量， x^2+y^2+z^2 = 1.所以已知2个坐标可以求出第三个。只需2个通道 
  //                tangentNormal.z = sqrt(1.0- saturate(dot(tangentNormal.xy ,tangentNormal.xy)));

					//如果我们把“Texture Type”设置成“Normal Map”，那么上面2行代码与下面3行等价。使用内置函数UnpackNormal
					//。DXT5nm压缩格式，也就是unity使用的压缩格式
					tangentNormal = UnpackNormal(packedNormal);
					tangentNormal.xy *= _BumpScale;
					tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy ,tangentNormal.xy)));

					fixed3 albedo = tex2D(_MainTex, i.uv) * _Color.rgb;

					fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

					fixed3 diffuse = _LightColor0.rgb *albedo * max(0,dot(tangentNormal,tangentLightDir));
					fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);

					fixed3 specular = _LightColor0.rgb *_Specular * pow(max(0,dot(tangentNormal,tangentLightDir)),_Gloss);

					return fixed4(ambient + diffuse + specular,1.0);
				}
					ENDCG
		}
		}
			FallBack "Specular"
}