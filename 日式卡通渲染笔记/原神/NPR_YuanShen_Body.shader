Shader "NPR/NPR_YuanShen_Body"
{
    Properties
    {
        [HDR]_Tint("Tint",Color) = (1,1,1,1)
        _BaseMap ("BaseMap", 2D) = "white" {}
        _LightMap ("LightMap", 2D) = "white" {}
        _RampMap ("RampMap", 2D) = "white" {}
        [Space(30)]
        _MetalMap ("MetalMatMap", 2D) = "white" {}
        _MetalMapV("金属MatCap范围",Range(0 ,1)) =0
        _MetalMapIntensity("金属MatCap强度",Float) =0.8

        _RampLerp("RampLerp",Range(0,1)) =0.5
        _ShadowRampLerp("ShadowRampLerp",Range(0,1)) =0.5

        [Space(30)]
        _LightThreshold("_LightThreshold",Range(-1,1))=1
        _RampOffset("RampOffset",Range(-1,1)) =0.5
        _RampOffset2("RampOffset2",Range(-1,1)) =0.1

        _BrightIntensity("亮部强度",Float) =1
        _DarkIntensity("暗部强度",Float) =1
        _RampIntensity("Ramp强度",Float) =1
        _CharacterIntensity("角色整体强度",Float) =1
        _RampIndex("RampIndex",Float) =1

        [Space(30)]
        _SpecularExp("高光曲率",Float) =64
        _SpecularIntensity("高光强度",Float) =6

        [Space(30)]
        _StepSpecularIntensity("裁边高光强度1(裁边高光区域1)",Float) =3
        _StepSpecularWidth("裁边高光宽度1(裁边高光区域1)",Float) =0.3
        
        [Space(10)]
        _StepSpecularIntensity2("裁边高光强度2(裁边高光区域2)(仅在亮部)",Float) =3
        _StepSpecularWidth2("裁边高光宽度2(裁边高光区域2)(仅在亮部)",Float) =0.3
        
        [Space(10)]
        _StepSpecularIntensity3("裁边高光强度3(裁边高光区域2)(常亮)",Float) =3
        _StepSpecularWidth3("裁边高光宽度3(裁边高光区域2)(常亮)",Float) =0.3
        
        [Space(30)]
        _OulineScale("_OulineScale",Float) =1
        _OutlineColor ("_OutlineColor",Color) = (0,0,0,0)

        [Space(30)]
        [Toggle(DebugMode)] _DebugMode ("DebugMode?", Float) = 0
        [KeywordEnum(None,Base,DebugLayer,LM_R,LM_G,LM_B,LM_A,UV,VC_R,VC_G,VC_B,VC_A,Normal,Tangent,Specular)] _TestMode("Debug",Int) = 0
        //        [KeywordEnum(None,_Layer1,_Layer2,_Layer3,_Layer4,_Layer5,_Layer6,_Layer7,_Layer8,_Layer9,_Layer10,_Layer11 )] _TestModeLayer("DebugLayer",Int) = 0
        _LayerStep("LayerStep",Range(0 ,1.1)) =0
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque" "LightMode"="ForwardBase" "Queue" = "Geometry"
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma fullforwardshadows
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "UnityGlobalIllumination.cginc"
            #include "AutoLight.cginc"
            // #include "NPRBrdf.cginc" 


            #ifndef UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX
        //only defining to not throw compilation error over Unity 5.5
        #define UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input)
            #endif
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #include "UnityCG.cginc"

            #define Black   float4(0,0,0,1)
            #define Red     float4(1,0,0,1)
            #define Green   float4(0,1,0,1)
            #define Blue    float4(0,0,1,1)
            #define Yellow  float4(1,1,0,1)
            #define Cyan    float4(0,0,1,1)
            #define Fuck    float4(0.6,0.2,0.1,1)

            //Debug
            #pragma shader_feature DebugMode
            int _TestMode, _TestModeLayer;
            float _LayerStep;
            //Maps
            sampler2D _BaseMap, _LightMap, _RampMap, _MetalMap;
            float4 _RampMap_TexelSize;
            float4 _LightMap_TexelSize;


            float _MetalMapV,_MetalMapIntensity;
            float _LightThreshold, _RampOffset, _RampOffset2, _BrightIntensity, _DarkIntensity, _RampIntensity,_CharacterIntensity;

            float _RampIndex;
            float _RampLerp, _ShadowRampLerp;

            float4 _Tint;

            //高光
            float _SpecularExp, _SpecularIntensity;
            //裁边高光
            float _StepSpecularIntensity, _StepSpecularWidth,_StepSpecularIntensity2,_StepSpecularWidth2,_StepSpecularIntensity3,_StepSpecularWidth3;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
                float4 tangent :TANGENT;
                float3 normal : NORMAL;
                float4 vertexColor : COLOR;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 tangent : TEXCOORD1;
                float3 bitangent : TEXCOORD2;
                float3 normal : TEXCOORD3;
                float3 worldPosition : TEXCOORD4;
                float3 localPosition : TEXCOORD5;
                float3 localNormal : TEXCOORD6;
                float4 vertexColor : TEXCOORD7;
                float2 uv2 : TEXCOORD8;
                LIGHTING_COORDS(9, 10)
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.uv2 = v.uv2;
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.worldPosition = mul(unity_ObjectToWorld, v.vertex);
                o.localPosition = v.vertex.xyz;
                o.tangent = UnityObjectToWorldDir(v.tangent);
                o.bitangent = cross(o.normal, o.tangent) * v.tangent.w;
                o.localNormal = v.normal;
                o.vertexColor = v.vertexColor;
                TRANSFER_VERTEX_TO_FRAGMENT(o);

                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float3 T = normalize(i.tangent);
                float3 N = normalize(i.normal);
                //float3 B = normalize( cross(N,T));
                float3 B = normalize(i.bitangent);
                float3 L = normalize(UnityWorldSpaceLightDir(i.worldPosition.xyz));
                float3 V = normalize(UnityWorldSpaceViewDir(i.worldPosition.xyz));
                float3 H = normalize(V + L);
                float2 uv = i.uv;
                float2 uv2 = i.uv2;

                // return float4(uv2,0,0);
                float4 VertexColor = i.vertexColor;
                // return vertexColor.xyzz;
                float HV = dot(H, V);
                float NV = dot(N, V);
                float NL = dot(N, L);
                float NH = dot(N, H);

                float4 FinalColor = 0;
                float4 BaseMap = tex2D(_BaseMap, uv);
                float4 LightMap = tex2D(_LightMap, uv);

                //float3 origin = mul(unity_ObjectToWorld,float4(0,0,0,1));
                //float3 VV = normalize( _WorldSpaceCameraPos.xyz - origin);
                // return step(_MetalMapV, dot(VV.xz,N.xz));

                // float3 N_VS = mul((float3x3)UNITY_MATRIX_V, T);
                // return 1-step(_MetalMapV, abs( N_VS.x) ); ;
                
                float MetalMap = saturate(tex2D(_MetalMap, mul((float3x3)UNITY_MATRIX_V, N).xy * 0.5f + 0.5f ).r);
                MetalMap = step(_MetalMapV,MetalMap)*_MetalMapIntensity;
                
                // float MetalMap =tex2D(_MetalMap, float2(abs(N.z * V.z) ,_MetalMapV)).r;
                FinalColor.rgb = BaseMap.rgb;

                float SpecularLayerMask         = LightMap.r; // 高光类型Layer
                float ShadowAOMask              = LightMap.g; //ShadowAOMask
                float SpecularIntensityMask     = LightMap.b; //SpecularIntensityMask
                float LayerMask                 = LightMap.a; //LayerMask Ramp类型Layer
                // return VertexColor.a;//描边大小
                float RampOffsetMask            = VertexColor.g; //Ramp偏移值,值越大的区域 越容易"感光"(在一个特定的角度，偏移光照明暗)
                float RampPixelY = 0.05; // 1.0/20.0;
                float RampPixelX = 0.00390625; //1.0/256.0
                float halfLambert = (NL * 0.5 + 0.5 + _RampOffset + RampOffsetMask);
                halfLambert = clamp(halfLambert, RampPixelX, 1 - RampPixelX);

                //头发Shader中,LightMap.A==1 为特殊材质
                float RampIndex = 1;
                if (LayerMask >= 0 && LayerMask <= 0.1)
                {
                    RampIndex = 6;
                }

                if (LayerMask >= 0.11 && LayerMask <= 0.33)
                {
                    RampIndex = 2;
                }

                if (LayerMask >= 0.34 && LayerMask <= 0.55)
                {
                    RampIndex = 3;
                }

                if (LayerMask >= 0.56 && LayerMask <= 0.9)
                {
                    RampIndex = 4;
                }

                if (LayerMask >= 0.95 && LayerMask <= 1.0)
                {
                    RampIndex = _RampIndex;
                }

                //漫反射分类 用于区别Ramp
                //高光也分类 用于区别高光

                float PixelInRamp = RampPixelY * (RampIndex * 2 - 1);

                ShadowAOMask = 1 - smoothstep(saturate(ShadowAOMask), 0.2, 0.6); //平滑ShadowAOMask,减弱锯齿

                //为了将ShadowAOMask区域常暗显示
                float3 ramp = tex2D(_RampMap, saturate(float2(halfLambert * lerp(0.5, 1.0, ShadowAOMask), PixelInRamp)));
                float3 BaseMapShadowed = lerp(BaseMap * ramp, BaseMap, ShadowAOMask);
                BaseMapShadowed = lerp(BaseMap, BaseMapShadowed, _ShadowRampLerp);
                float IsBrightSide = ShadowAOMask * step(_LightThreshold, halfLambert);
                float3 Diffuse = lerp(lerp(BaseMapShadowed, BaseMap * ramp, _RampLerp) * _DarkIntensity,_BrightIntensity * BaseMapShadowed,IsBrightSide * _RampIntensity * 1) * _CharacterIntensity;

                float3 FinalSpecular = 0;
                float3 Specular = 0;
                float3 StepSpecular = 0;
                float3 StepSpecular2 = 0;

                float LinearMask = pow(LightMap.r, 1 / 2.2); //图片格式全部去掉勾选SRGB
                float SpecularLayer = LinearMask * 255;

                //不同的高光层 LightMap.b 用途不一样
                //裁边高光 (高光在暗部消失)
                if (SpecularLayer > 100 && SpecularLayer < 150)
                {
                    StepSpecular = step(1 - _StepSpecularWidth, saturate(dot(N, V))) * 1 *_StepSpecularIntensity;
                    StepSpecular *= BaseMap;
                    // return Red;
                }

                //裁边高光 (StepSpecular2常亮 无视明暗部分)
                if (SpecularLayer > 150 && SpecularLayer < 250)
                {
                    float StepSpecularMask = step(200, pow(SpecularIntensityMask, 1 / 2.2) * 255);
                    StepSpecular = step(1 - _StepSpecularWidth2, saturate(dot(N, V))) * 1 *_StepSpecularIntensity2;
                    StepSpecular2 = step(1 - _StepSpecularWidth3 * 5, saturate(dot(N, V))) *StepSpecularMask * _StepSpecularIntensity3;
                    
                    StepSpecular = lerp(StepSpecular, 0, StepSpecularMask);
                    StepSpecular2 *= BaseMap;
                    StepSpecular *= BaseMap;
                }

                //BlinPhong高光
                if (SpecularLayer >= 250)
                {
                    Specular = pow(saturate(NH), 1 * _SpecularExp) * SpecularIntensityMask *_SpecularIntensity;
                    Specular = max(0, Specular);
                    Specular += MetalMap;
                    Specular *= BaseMap;
                    // return MetalMap;
                }

                Specular = lerp(StepSpecular, Specular, LinearMask);
                Specular = lerp(0, Specular, LinearMask);

                Specular = lerp(0, Specular, IsBrightSide) + StepSpecular2;

                FinalColor.rgb = Diffuse + Specular;

                // FinalColor.rgb = pow(FinalColor.rgb,1/2.2);

                //在外部看到的值需要 pow(,1/2.2)*255之后在比较
                // if(pow( LightMap.r,1/2.2) *256 < 128 +5 && pow( LightMap.r,1/2.2)  *256 > 128 -5  )
                //     return float4(1,0,0,0);

                // return  mul(unity_CameraToWorld,float4(0,0,1,0));

                #ifdef DebugMode
                {
                    //[KeywordEnum(None,Base,Layer,LM_R,LM_G,LM_B,UV,VC_R,VC_G,VC_B,VC_A,Normal,Tangent,Specular)] _TestMode("Debug",Int) = 0
                    int mode = 1;
                    // BaseMap*=10;//高亮显示
                    if (_TestMode == mode++)
                        return BaseMap.xyzz; //BaseColor
                    if (_TestMode == mode++)
                        return lerp(BaseMap, BaseMap * 10, 1 - step(_LayerStep, LayerMask));
                    if (_TestMode == mode++)
                        return LightMap.r;
                    if (_TestMode == mode++)
                        return LightMap.g; //阴影 Mask
                    if (_TestMode == mode++)
                        return LightMap.b; //漫反射 Mask
                    if (_TestMode == mode++)
                        return LightMap.a; //Layer
                    if (_TestMode == mode++)
                        return float4(uv, 0, 0); //uv
                    if (_TestMode == mode++)
                        return VertexColor.r; //vertexColor.r
                    if (_TestMode == mode++)
                        return VertexColor.g; //vertexColor.g
                    if (_TestMode == mode++)
                        return VertexColor.b; //vertexColor.b
                    if (_TestMode == mode++)
                        return VertexColor.a; //vertexColor.a
                    if (_TestMode == mode++)
                        return N.xyzz; //Normal
                    if (_TestMode == mode++)
                        return i.tangent.xyzz; //Tangent
                    if (_TestMode == mode++)
                        return Specular.xyzz; //Tangent
                }
                #endif

                return FinalColor;
            }
            ENDCG
        }
        
        Pass //"OutLine"
        {
            
            Name "TANGENT"
            Cull Front
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
          
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float4 vertexColor : COLOR;
                float4 tangent :TANGENT;
            };

            struct v2f
            {
                float4 pos : SV_POSITION; 
                float2 uv : TEXCOORD0;
            };

            float _OulineScale;
            float4 _OutlineColor;

            v2f vert(appdata v)
            {
                v2f o;
                 v.vertex.xyz += v.tangent.xyz *_OulineScale*0.01*v.vertexColor.a;
                o.pos = UnityObjectToClipPos(v.vertex);
                return o;
            }
      
            float4 frag(v2f i) : SV_Target
            {
                return _OutlineColor;
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}