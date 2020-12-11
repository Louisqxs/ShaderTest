

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

//定义Shader的名字
Shader"Simple Shader"{

	//SubShader语句块
	SubShader{

		//Pass语句块
		Pass{

		//CG语句块
	 CGPROGRAM

	 //告诉Unity函数vert包含了顶点着色器的代码
		  #pragma vertex vert
	 //告诉Unity函数frag包含了片元着色器的代码
		  #pragma fragment frag

		  //顶点着色器函数，返回值是float4类型的变量，输入float4类型的参数v，
		  //POSITION告诉Unity把模型的定点坐标输入到v中
	  //SV_POSITION告诉Unity顶点着色器输出的是裁剪空间中的定点坐标
	  float4 vert(float4 v : POSITION) : SV_POSITION{

		//把顶点坐标从模型空间转换到裁剪空间
		return UnityObjectToClipPos(v);
		   }


		//片元着色器函数，返回值是fixed4类型的变量，无输入参数
		//SV_Target告诉渲染器把用户的输出颜色存储到一个渲染目标中
		fixed4 frag() : SV_Target{

			   //返回一个表示白色的fixed4类型变量，(R,G,B,A)
			   return fixed4(1.0,1.0,1.0,1.0);
				  }

				ENDCG

			 }
	}
}
