Shader "Diffuse Vertex-Level"
{
	Properties
	{
		//color是属性类型
		_Diffuse ("Diffuse",Color) = (1,1,1,1)	//properties里面语句不需要分号结束
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
			float4 vertex : POSITION;
			float3 normal : NORMAL;	//变量存储模型顶点的法线信息
		};

		struct v2f
		{
			float4 pos : SV_POSITION;
			fixed3 color : COLOR;	//问：color为什么不是4而是3维，答：非半透明，a始终是1，为了把顶点着色器计算的光照颜色传给片元着色器，而且语义不一定非要用COLOR,可以用TEXCOORD0语义
		};

		v2f vert(a2v v)	//声明vert函数的输入参数a2v v,可以用v.xxxx访问a2v
		{
			v2f o;	//声明输出结构
			//o.pos = mul(UNITY_MARTIX_MVP, v.vertex);	//目前已不适用，改为下面这个方法
			o.pos = UnityObjectToClipPos(v.vertex);	//顶点坐标变换到裁剪空间

			fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;	//获得环境光信息（内置变量）

			//把模型空间顶点的法线转换成世界空间顶点的法线坐标，
			//并归一化（单位向量），等价fixed3 worldNormal = normalize(UnityObjectToWorldNormal(v.normal));
			fixed3 worldNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));

			fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);	//归一化世界空间灯光矢量 

			//计算法线跟光源点积时，要在统一坐标系，saturate限定输出[0，1]。
			fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLight));

			o.color = ambient + diffuse;

			return o;
		}

		fixed4 frag(v2f i) : SV_Target
		{
			return fixed4(i.color,1.0);
		}

		ENDCG

		}
	}

	Fallback"Diffuse"
}