Shader "Secular Pixel-Level"
{
	Properties
	{
		_Diffuse("Diffuse",Color) = (1,1,1,1)	//properties里面语句不需要分号结束
	}

	SubShader
	{
		pass
		{
			Tags
			{
				"LightMode" = "ForwardBase"	//没有这个会导致光影有闪烁问题，后面的_LightColor0也要定义这个标签
			}

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#include "Lighting.cginc"	//内置文件，为了使用（获得）一些Untiy的内置灯光变量，比如_LightColor0

			fixed4 _Diffuse;	//定义漫反射颜色

			struct a2v
			{
				float4 vertex:POSITION;
				float3 normal:NORMAL;
			};

			struct v2f
			{
				float4 pos:SV_POSITION;
				float3 worldNormal:TEXCOORD0;
				float3 worldPos:TEXCOORD1;
			};

			v2f vert(a2v v)	//顶点着色器只需要计算世界空间下的法线方向和顶点坐标，并传递给片元着色器
			{
				v2f o;

				o.pos = UnityObjectToClipPos(v.vertex);	

				o.worldNormal = mul(v.normal,(float3x3)unity_WorldToObject);
				//等价于o.worldNormal = UnityObjectToWorldNormal(v.normal);
				//等价于o.worldNormal = mul((float3x3)unity_ObjectToWorld, v.normal);

				o.worldPos = UnityObjectToClipPos(v.vertex);

				return o;
			}

			fixed4 frag(v2f i) :SV_Target	//计算关键的光照模型
			{
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;	//LIGHTMODEL，获得环境光信息
				fixed3 worldNormal = normalize(i.worldNormal);	//归一化法线
				fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);	//归一化世界空间灯光方向

				//获得光源方向，这种获得光源方向不具有通用性，仅仅局限于只有一盏平行光，且只有一个光源情况下
				fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLightDir));
				//漫反射公式
				fixed3 color = ambient + diffuse;
				return fixed4(color,1.0);
			}
	
			ENDCG

		}
	}

	Fallback"Diffuse"
}