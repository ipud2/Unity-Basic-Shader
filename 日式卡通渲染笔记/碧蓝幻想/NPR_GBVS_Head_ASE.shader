// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "NPR_GBVS_Head_ASE"
{
	Properties
	{
		_BaseMap("BaseMap", 2D) = "white" {}
		_DecalMap("DecalMap", 2D) = "white" {}
		_ShadowMap("ShadowMap", 2D) = "white" {}
		_FaceStep("FaceStep", Range( -1 , 1)) = 0
		_MaskMap("MaskMap", 2D) = "white" {}
		_SpecularExp("SpecularExp", Float) = 1
		_SpecularExpScale("SpecularExpScale", Float) = 1
		_SpecularExpStepValue("SpecularExpStepValue", Float) = 1
		_SpecularIntensity("SpecularIntensity", Float) = 1
		_HairStep("HairStep", Range( -1 , 1)) = 0
		[HideInInspector] _texcoord( "", 2D ) = "white" {}

		 _OulineScale("_OulineScale",Float) =0.1
        _OutlineColor ("_OutlineColor",Color) = (0,0,0,0)
	}
	
	SubShader
	{
		
		
		Tags { "RenderType"="Opaque" }
	LOD 100

		CGINCLUDE
		#pragma target 3.0
		ENDCG
		Blend Off
		AlphaToMask Off
		Cull Back
		ColorMask RGBA
		ZWrite On
		ZTest LEqual
		Offset 0 , 0
		
		
		UsePass "NPR/OutLine/TANGENT"

		Pass
		{
			Name "Unlit"
			Tags { "LightMode"="ForwardBase" }
			CGPROGRAM

			

			#ifndef UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX
			//only defining to not throw compilation error over Unity 5.5
			#define UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input)
			#endif
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_instancing
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			#define ASE_NEEDS_FRAG_WORLD_POSITION


			struct appdata
			{
				float4 vertex : POSITION;
				float4 color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				float3 ase_normal : NORMAL;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			
			struct v2f
			{
				float4 vertex : SV_POSITION;
				#ifdef ASE_NEEDS_FRAG_WORLD_POSITION
				float3 worldPos : TEXCOORD0;
				#endif
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			//This is a late directive
			
			uniform sampler2D _BaseMap;
			uniform float4 _BaseMap_ST;
			uniform float _SpecularExpStepValue;
			uniform float _SpecularExp;
			uniform float _SpecularExpScale;
			uniform sampler2D _MaskMap;
			uniform float4 _MaskMap_ST;
			uniform float _SpecularIntensity;
			uniform sampler2D _ShadowMap;
			uniform float4 _ShadowMap_ST;
			uniform float _HairStep;
			uniform float _FaceStep;
			uniform sampler2D _DecalMap;

			
			v2f vert ( appdata v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

				float3 ase_worldNormal = UnityObjectToWorldNormal(v.ase_normal);
				o.ase_texcoord2.xyz = ase_worldNormal;
				
				o.ase_texcoord1.xy = v.ase_texcoord.xy;
				o.ase_color = v.color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord1.zw = 0;
				o.ase_texcoord2.w = 0;
				float3 vertexValue = float3(0, 0, 0);
				#if ASE_ABSOLUTE_VERTEX_POS
				vertexValue = v.vertex.xyz;
				#endif
				vertexValue = vertexValue;
				#if ASE_ABSOLUTE_VERTEX_POS
				v.vertex.xyz = vertexValue;
				#else
				v.vertex.xyz += vertexValue;
				#endif
				o.vertex = UnityObjectToClipPos(v.vertex);

				#ifdef ASE_NEEDS_FRAG_WORLD_POSITION
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				#endif
				return o;
			}
			
			fixed4 frag (v2f i ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
				fixed4 finalColor;
				#ifdef ASE_NEEDS_FRAG_WORLD_POSITION
				float3 WorldPosition = i.worldPos;
				#endif
				float2 uv_BaseMap = i.ase_texcoord1.xy * _BaseMap_ST.xy + _BaseMap_ST.zw;
				float4 tex2DNode1 = tex2D( _BaseMap, uv_BaseMap );
				float4 Base89 = tex2DNode1;
				float3 ase_worldNormal = i.ase_texcoord2.xyz;
				float3 ase_worldViewDir = UnityWorldSpaceViewDir(WorldPosition);
				ase_worldViewDir = normalize(ase_worldViewDir);
				float3 worldSpaceLightDir = UnityWorldSpaceLightDir(WorldPosition);
				float3 normalizeResult4_g3 = normalize( ( ase_worldViewDir + worldSpaceLightDir ) );
				float dotResult73 = dot( ase_worldNormal , normalizeResult4_g3 );
				float2 uv_MaskMap = i.ase_texcoord1.xy * _MaskMap_ST.xy + _MaskMap_ST.zw;
				float4 tex2DNode61 = tex2D( _MaskMap, uv_MaskMap );
				float4 MaskMap87 = tex2DNode61;
				float4 break85 = MaskMap87;
				float SpecularMask88 = break85.b;
				float Specular91 = ( step( _SpecularExpStepValue , ( ( pow( saturate( dotResult73 ) , _SpecularExp ) * _SpecularExpScale ) * SpecularMask88 ) ) * _SpecularIntensity );
				float2 uv_ShadowMap = i.ase_texcoord1.xy * _ShadowMap_ST.xy + _ShadowMap_ST.zw;
				float4 tex2DNode51 = tex2D( _ShadowMap, uv_ShadowMap );
				float4 Shadow90 = tex2DNode51;
				float RampOffset101 = break85.r;
				float dotResult34 = dot( ase_worldNormal , worldSpaceLightDir );
				float NL49 = dotResult34;
				float4 lerpResult97 = lerp( Shadow90 , Base89 , step( ( _HairStep + RampOffset101 ) , NL49 ));
				float4 Diffuse98 = ( lerpResult97 * i.ase_color.b );
				float4 Hair67 = ( ( Base89 * Specular91 ) + Diffuse98 );
				float4 lerpResult58 = lerp( tex2DNode51 , tex2DNode1 , step( _FaceStep , NL49 ));
				float Lambert38 = ( ( dotResult34 * 0.5 ) + 0.5 );
				float4 _Vector3 = float4(0,1,0.68,1);
				float2 appendResult42 = (float2(0.95 , (_Vector3.z + (Lambert38 - _Vector3.x) * (_Vector3.w - _Vector3.z) / (_Vector3.y - _Vector3.x))));
				float2 SkinUV43 = appendResult42;
				float4 Face64 = ( lerpResult58 * tex2D( _DecalMap, SkinUV43 ) );
				float FaceMask65 = step( 0.2 , tex2DNode61.g );
				float4 lerpResult69 = lerp( Hair67 , Face64 , FaceMask65);
				
				
				finalColor = lerpResult69;
				return finalColor;
			}
			ENDCG
		}
	}
	CustomEditor "ASEMaterialInspector"
	
	
}
/*ASEBEGIN
Version=18800
22.4;148.8;1734.4;917.4;798.3775;757.5935;1.3;True;False
Node;AmplifyShaderEditor.SamplerNode;61;-90.96438,906.2;Inherit;True;Property;_MaskMap;MaskMap;4;0;Create;True;0;0;0;False;0;False;-1;727944b6083a89a4190bcce0fae3934e;40d058ddbab325a49a0bc068655fcf53;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;87;361.286,970.8982;Inherit;False;MaskMap;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.CommentaryNode;60;-192.4935,3801.877;Inherit;False;1721.508;521.2524;Skin UV;11;35;36;34;37;41;38;40;39;42;49;43;;1,1,1,1;0;0
Node;AmplifyShaderEditor.GetLocalVarNode;86;-1136.676,1290.201;Inherit;False;87;MaskMap;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;36;-142.4935,4076.805;Inherit;False;False;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.FunctionNode;72;-1493.239,1730.078;Inherit;False;Blinn-Phong Half Vector;-1;;3;91a149ac9d615be429126c95e20753ce;0;0;1;FLOAT3;0
Node;AmplifyShaderEditor.WorldNormalVector;35;-103.4935,3898.806;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldNormalVector;83;-1404.082,1550.427;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.BreakToComponentsNode;85;-965.7654,1295.885;Inherit;False;COLOR;1;0;COLOR;0,0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.DotProductOpNode;34;155.3274,3943.099;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;73;-1097.239,1638.078;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;101;-747.5364,1276.465;Inherit;False;RampOffset;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;51;-291.0541,-60.7825;Inherit;True;Property;_ShadowMap;ShadowMap;2;0;Create;True;0;0;0;False;0;False;-1;f973318835b7cf246a87efb4e3bdeda1;6f11605625a70c04b855b29261edb769;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;95;-1393.745,3061.063;Inherit;False;Property;_HairStep;HairStep;9;0;Create;True;0;0;0;False;0;False;0;0.1;-1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;37;410.5057,4015.805;Inherit;False;Remap01;-1;;4;e576bd475d0540a489f939c914d7a50f;0;1;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;49;365.0877,3898.978;Inherit;False;NL;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;1;-300.8311,-280.4913;Inherit;True;Property;_BaseMap;BaseMap;0;0;Create;True;0;0;0;False;0;False;-1;debeb745adad58743a0b5b866f24d05b;a617da1677ec38747a4238ebf73f53b5;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;88;-748.7139,1377.898;Inherit;False;SpecularMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;102;-1308.859,3261.041;Inherit;False;101;RampOffset;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;76;-962.4952,1643.588;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;74;-1043.495,1891.587;Inherit;False;Property;_SpecularExpScale;SpecularExpScale;6;0;Create;True;0;0;0;False;0;False;1;2.96;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;75;-1046.495,1774.588;Inherit;False;Property;_SpecularExp;SpecularExp;5;0;Create;True;0;0;0;False;0;False;1;5.42;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;89;92.82739,-274.4603;Inherit;False;Base;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;90;115.8274,-112.4603;Inherit;False;Shadow;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;103;-994.8591,3139.041;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;94;-1021.542,3309.274;Inherit;False;49;NL;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;38;622.0059,4014.07;Inherit;False;Lambert;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector4Node;41;615.8738,4114.129;Inherit;False;Constant;_Vector3;Vector 3;7;0;Create;True;0;0;0;False;0;False;0,1,0.68,1;0,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.FunctionNode;77;-630.4952,1722.588;Inherit;False;PowerScale;-1;;5;5ba70760a40e0a6499195a0590fd2e74;0;3;1;FLOAT;1;False;2;FLOAT;1;False;3;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;84;-673.0881,1916.992;Inherit;False;88;SpecularMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;78;-725.0222,2050.833;Inherit;False;Property;_SpecularExpStepValue;SpecularExpStepValue;7;0;Create;True;0;0;0;False;0;False;1;0.15;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;92;-940.7813,2896.886;Inherit;False;89;Base;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;79;-371.0881,1774.992;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;96;-677.7454,3076.063;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;93;-932.7813,3008.886;Inherit;False;90;Shadow;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;39;907.6726,3851.877;Inherit;False;Constant;_Float1;Float 1;7;0;Create;True;0;0;0;False;0;False;0.95;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;40;911.1606,3993.893;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;80;-671.0222,2226.833;Inherit;False;Property;_SpecularIntensity;SpecularIntensity;8;0;Create;True;0;0;0;False;0;False;1;0.4;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;97;-452.7454,2936.063;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.VertexColorNode;104;-733.6592,3380.84;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;42;1136.212,3944.059;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.StepOpNode;81;-188.0222,1863.833;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;82;14.3107,1919.828;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;43;1304.213,3974.059;Inherit;False;SkinUV;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;105;-218.6612,3000.553;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;50;-386.3223,368.2817;Inherit;False;49;NL;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;55;-485.5475,258.8661;Inherit;False;Property;_FaceStep;FaceStep;3;0;Create;True;0;0;0;False;0;False;0;0;-1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;106;257.7341,1759.012;Inherit;False;89;Base;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;98;-92.65186,2901.957;Inherit;False;Diffuse;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;47;-423.3665,572.9216;Inherit;False;43;SkinUV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TexturePropertyNode;45;-662.3627,513.1191;Inherit;True;Property;_DecalMap;DecalMap;1;0;Create;True;0;0;0;False;0;False;None;3521583a700ae3f4cb99b7ce9c6f0737;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.RegisterLocalVarNode;91;247.0784,1892.316;Inherit;False;Specular;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;54;-73.54762,274.8661;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;46;-173.8752,518.1769;Inherit;True;Property;_TextureSample0;Texture Sample 0;4;0;Create;True;0;0;0;False;0;False;-1;fcbc7961f45d4154380c0cdac1e500cb;fcbc7961f45d4154380c0cdac1e500cb;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;58;238.8557,123.4701;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;63;56.08875,793.1622;Inherit;False;Constant;_Float2;Float 2;5;0;Create;True;0;0;0;False;0;False;0.2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;99;234.9958,2029.206;Inherit;False;98;Diffuse;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;107;486.7341,1788.012;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;59;489.5823,202.438;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.StepOpNode;62;249.3028,798.9063;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;100;570.9958,1970.206;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;64;760.6565,177.3819;Inherit;False;Face;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;65;497.6295,692.0648;Inherit;False;FaceMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;67;781.6418,1874.635;Inherit;False;Hair;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;70;864.5316,718.7283;Inherit;False;64;Face;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;71;866.7935,598.84;Inherit;False;67;Hair;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;66;850.3328,879.483;Inherit;False;65;FaceMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;69;1193.658,676.8805;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;0;1439.804,676.7861;Float;False;True;-1;2;ASEMaterialInspector;100;1;NPR_GBVS_Head_ASE;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;True;0;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;False;False;False;False;False;False;True;0;False;-1;True;0;False;-1;True;True;True;True;True;0;False;-1;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;RenderType=Opaque=RenderType;True;2;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=ForwardBase;False;0;;0;1;Above;NPR/OutLine/TANGENT;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;1;True;False;;False;0
WireConnection;87;0;61;0
WireConnection;85;0;86;0
WireConnection;34;0;35;0
WireConnection;34;1;36;0
WireConnection;73;0;83;0
WireConnection;73;1;72;0
WireConnection;101;0;85;0
WireConnection;37;1;34;0
WireConnection;49;0;34;0
WireConnection;88;0;85;2
WireConnection;76;0;73;0
WireConnection;89;0;1;0
WireConnection;90;0;51;0
WireConnection;103;0;95;0
WireConnection;103;1;102;0
WireConnection;38;0;37;0
WireConnection;77;1;76;0
WireConnection;77;2;75;0
WireConnection;77;3;74;0
WireConnection;79;0;77;0
WireConnection;79;1;84;0
WireConnection;96;0;103;0
WireConnection;96;1;94;0
WireConnection;40;0;38;0
WireConnection;40;1;41;1
WireConnection;40;2;41;2
WireConnection;40;3;41;3
WireConnection;40;4;41;4
WireConnection;97;0;93;0
WireConnection;97;1;92;0
WireConnection;97;2;96;0
WireConnection;42;0;39;0
WireConnection;42;1;40;0
WireConnection;81;0;78;0
WireConnection;81;1;79;0
WireConnection;82;0;81;0
WireConnection;82;1;80;0
WireConnection;43;0;42;0
WireConnection;105;0;97;0
WireConnection;105;1;104;3
WireConnection;98;0;105;0
WireConnection;91;0;82;0
WireConnection;54;0;55;0
WireConnection;54;1;50;0
WireConnection;46;0;45;0
WireConnection;46;1;47;0
WireConnection;58;0;51;0
WireConnection;58;1;1;0
WireConnection;58;2;54;0
WireConnection;107;0;106;0
WireConnection;107;1;91;0
WireConnection;59;0;58;0
WireConnection;59;1;46;0
WireConnection;62;0;63;0
WireConnection;62;1;61;2
WireConnection;100;0;107;0
WireConnection;100;1;99;0
WireConnection;64;0;59;0
WireConnection;65;0;62;0
WireConnection;67;0;100;0
WireConnection;69;0;71;0
WireConnection;69;1;70;0
WireConnection;69;2;66;0
WireConnection;0;0;69;0
ASEEND*/
//CHKSM=9F88B28F4B067D28EBCB4D5B50BB4E880F76D632