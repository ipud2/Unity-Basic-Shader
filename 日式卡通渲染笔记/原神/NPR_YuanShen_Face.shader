Shader "NPR/NPR_YuanShen_Face"
{
    Properties
    {
        _BaseMap ("_BaseMap", 2D) = "white" {}
        _LightMap ("_LightMap", 2D) = "white" {}
        _ShadowMap ("_ShadowMap", 2D) = "white" {}
        _ShadowColor("_ShadowColor",Color) = (0.896 ,0.7747725, 0.73024,1)
        _FaceLightmpOffset ("Face Lightmp Offset", Range(-1, 1)) = 0 //用来和 头发 身体的明暗过渡对齐
        [Toggle] _FlipFaceLight("翻转脸部光照",Float)= 0

        [KeywordEnum(None,LightMap,Normal,UV,UV2,VertexColor,BaseColor,BaseColor_A,ShadowMap,ShadowMap_A)] _TestMode("_TestMode",Int) = 0

        [Space(30)]
        [Toggle(ENABLE_FACE_SHADOW_MAP)] _UseFace("UseFace",Float) = 0
        _FaceShadowOffset("_FaceShadowOffset",Float)= 0
        _FaceShadowMapPow("_FaceShadowMapPow",Float)= 1
        
        [Space(30)]
        _OulineScale("_OulineScale",Float) =1
        _OutlineColor ("_OutlineColor",Color) = (0,0,0,0)
    }

    SubShader
    {
        Tags
        {
            "RenderType"="Opaque" "LightMode"="ForwardBase" "Queue" = "Geometry"
        }
        Cull Off
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

            #pragma shader_feature ENABLE_FACE_SHADOW_MAP

            // #define ENABLE_FACE_SHADOW_MAP

            sampler2D _BaseMap, _LightMap, _ShadowMap;

            int _TestMode;

            float _FaceLightmpOffset;
            float4 _ShadowColor;
            float _FlipFaceLight;


            float _FaceShadowOffset, _FaceShadowMapPow;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
                float4 tangent :TANGENT;
                float3 normal : NORMAL;
                float4 vertexColor : Color;
            };

            struct v2f
            {
                float4 pos : SV_POSITION; // 必须命名为pos ，因为 TRANSFER_VERTEX_TO_FRAGMENT 是这么命名的，为了正确地获取到Shadow
                float2 uv : TEXCOORD0;
                float3 tangent : TEXCOORD1;
                float3 bitangent : TEXCOORD2;
                float3 normal : TEXCOORD3;
                float3 worldPosition: TEXCOORD4;
                float3 localPosition : TEXCOORD5;
                float3 localNormal : TEXCOORD6;
                float4 vertexColor : TEXCOORD7;
                LIGHTING_COORDS(8, 9)
                float2 uv2 : TEXCOORD10;
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
                // return tex2D(_BaseMap, i.uv);

                //Variable
                float3 T = normalize(i.tangent);
                float3 N = normalize(i.normal);
                float3 B = normalize(cross(N, T));
                // float3 B = normalize( i.bitangent);
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

                /*==========================Texture ==========================*/

                float3 FinalColor = 0;
                float4 BaseColor = tex2D(_BaseMap, uv);
                float4 LightMap = tex2D(_LightMap, uv);
                float4 ShadowMap = tex2D(_ShadowMap, uv);

                // return BaseColor.xyzz;
                int mode = 1;
                if (_TestMode == mode++)
                    return LightMap.r;
                if (_TestMode == mode++)
                    return N.xyzz; //漫反射 Mask
                if (_TestMode == mode++)
                    return float4(uv, 0, 0); //uv
                if (_TestMode == mode++)
                    return float4(uv2, 0, 0); //uv2
                if (_TestMode == mode++)
                    return VertexColor.xyzz; //vertexColor
                if (_TestMode == mode++)
                    return BaseColor.xyzz; //BaseColor
                if (_TestMode == mode++)
                    return BaseColor.a; //BaseColor.a
                if (_TestMode == mode++)
                    return ShadowMap; //ShadowMap
                if (_TestMode == mode++)
                    return ShadowMap.a; //ShadowMap.a

                // return VertexColor.r;
                // return VertexColor.g;
                // return VertexColor.b;
                // return VertexColor.a;

                /*==========================Diffuse ==========================*/

                float halfLambert = 0.5 * NL + 0.5;
                // float3 ramp = tex2D(_LightMap, float2(saturate(halfLambert), 0.5));
                float3 faceLightMap = tex2D(_LightMap, float2(uv.x, uv.y));

                // return faceLightMap.y;
                // RTS rotation transform scal
                //float3 _Up    = float3(0,1,0);                          //人物上方向 用代码传进来
                //float3 _Front = float3(0,0,-1);                         //人物前方向 用代码传进来
                //float3 Left = cross(_Up,_Front);
                //float3 Right = -Left;

                //也可以直接从模型的世界矩阵中拿取出 各个方向
                //这要求模型在制作的时候得使用正确的朝向: X Y Z 分别是模型的 右 上 前
                float4 Front = mul(unity_ObjectToWorld, float4(0, 1, 0, 0));
                // float4 Right = mul(unity_ObjectToWorld, float4(lerp(-1, 1, _FlipFaceLight), 0, 0, 0));
                float4 Right = mul(unity_ObjectToWorld, float4(0, 0, -1, 0) );
                float4 Up = mul(unity_ObjectToWorld, float4(-1, 0, 0, 0));
                float3 Left = -Right;

                float FL = dot(normalize(Front.xz), normalize(L.xz));
                float LL = dot(normalize(Left.xz), normalize(L.xz));
                float RL = dot(normalize(Right.xz), normalize(L.xz));
                float faceLight = faceLightMap.r + _FaceLightmpOffset; //用来和 头发 身体的明暗过渡对齐
                float faceLightRamp = (FL > 0) * min((faceLight > LL), (1 > faceLight + RL));

                float3 Diffuse = lerp(_ShadowColor * BaseColor, BaseColor, faceLightRamp);

                FinalColor = Diffuse;
                // FaceLightMap
                #ifdef ENABLE_FACE_SHADOW_MAP

                // 计算光照旋转偏移
                float sinx = sin(_FaceShadowOffset);
                float cosx = cos(_FaceShadowOffset);
                float2x2 rotationOffset = float2x2(cosx, -sinx, sinx, cosx);

                float3 Front2 = unity_ObjectToWorld._12_22_32;
                float3 Right2 = unity_ObjectToWorld._13_23_33;
                float2 lightDir = mul(rotationOffset, L.xz);

                //计算xz平面下的光照角度
                float FrontL = dot(normalize(Front2.xz), normalize(lightDir));
                float RightL = dot(normalize(Right2.xz), normalize(lightDir));
                RightL = - (acos(RightL) / 3.141592654 - 0.5) * 2;

                //左右各采样一次FaceLightMap的阴影数据存于lightData
                float2 lightData = float2(tex2D(_LightMap, float2(uv.x, uv.y)).r,tex2D(_LightMap, float2(-uv.x, uv.y)).r);

                //修改lightData的变化曲线，使中间大部分变化速度趋于平缓。
                lightData = pow(abs(lightData), _FaceShadowMapPow);

                //根据光照角度判断是否处于背光，使用正向还是反向的lightData。
                float lightAttenuation = step(0, FrontL) * min(step(RightL, lightData.x), step(-RightL, lightData.y));

                half3 FaceColor = lerp(_ShadowColor * BaseColor, BaseColor, lightAttenuation);
                FinalColor.rgb = FaceColor;
                #endif

                return float4(FinalColor, 1);
            }
            ENDCG
        }
        
        UsePass "NPR/NPR_YuanShen_Body/TANGENT"
        
        
    }
    Fallback "Diffuse"
}