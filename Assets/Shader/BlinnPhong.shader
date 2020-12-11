Shader "Blinn-Phong"
{
	Properties
	{
		_Diffuse("Diffuse", Color) = (1, 1, 1, 1)
		_Specular("Specular", Color) = (1, 1, 1, 1)
		_Gloss("Gloss", Range(8.0, 256)) = 20
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
			fixed4 _Specular;
			float _Gloss;

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

				o.worldPos = UnityObjectToClipPos(v.vertex);
				//o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				//Get ambient term
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);

				//Compute diffuse term
				//max(x,y)  跟saturate(x) 参数不一样
				//max(0, dot(worldNormal, worldLightDir)等价于saturate(dot(worldNormal,worldLightDir)
				fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));

				//Get the view direction in world space
				fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
				//Get the half direction in world space
				fixed3 halfDir = normalize(worldLightDir + viewDir);
				//Compute specular term
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

				return fixed4(ambient + diffuse + specular, 1.0);
			}

			ENDCG

	    }
	}

	Fallback"Diffuse"
}