Shader "NPR/NPR_ZS_Alpha"
{
    Properties
    {
        _MainTex ("_MainTex", 2D) = "white" {}
        _NormalMap ("_NormalMap", 2D) = "white" {}
        _LightMap("_LightMap",2D) ="black"{}
        _RampOffset ("_RampOffset",Range(-1,1)) =0
        _DarkIntensity("_DarkIntensity",Range(0,1)) =0.5
        _BrightIntensity("_BrightIntensity",Float) =1
        _Roughness("_Roughness",Range(0,1)) =0.5
        _Metallic("_Metallic",Range(0,1)) =0.1
        _SpecularIntensity("_SpecularIntensity",Float) =1
        _RimExp("_RimExp",Float) = 4
        
        [Space(10)]
        _RimIntensity("_RimScale",Float) = 1
        _RimWdith("_RimStep",Float) = 0.3
    
        [Space(10)]
        _Alpha("_Alpha",Range(0,1)) =0.5
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue" = "Transparent" "LightMode"="ForwardBase"}

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            //宏定义必须大写，否者定义不管用
            #pragma multi_compile_local MODE_VALUE MODE_TEX

            // make fog work

            // #include "UnityCG.cginc"
            // // _LightColor0 (declared in UnityLightingCommon.cginc)
            // #include "UnityLightingCommon.cginc" 
            // // #define UNITY_SPECCUBE_LOD_STEPS
            // #include "UnityStandardConfig.cginc"

            #include "UnityCG.cginc"
			#include "Lighting.cginc"
            #include "UnityGlobalIllumination.cginc"
            #include "TABrdf.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 tangent :TANGENT;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex       : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float3 tangent      : TEXCOORD1;
                float3 bitangent    : TEXCOORD2; 
                float3 normal       : TEXCOORD3; 
                float3 worldPosition: TEXCOORD4;
                float3 localPostion : TEXCOORD5;
            };

            sampler2D _MainTex,_NormalMap,_MixMap,_LightMap;
            float _RampOffset,_DarkIntensity,_BrightIntensity;
            float _Roughness,_Metallic,_SpecularIntensity;
            float _RimIntensity,_RimWdith;
            float _Alpha;
            
            v2f vert (appdata v)
            {
                v2f o= (v2f)0;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.worldPosition = mul(unity_ObjectToWorld,v.vertex);
                o.localPostion = v.vertex.xyz;
                o.tangent = UnityObjectToWorldDir(v.tangent);
                //o.bitangent = cross(o.normal,o.tangent) * v.tangent.w;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                //Variable
                float3 T = normalize(i.tangent);
                float3 N = normalize(i.normal);
                float3 B = normalize( cross(N,T));
                // float3 B = normalize( i.bitangent);
                float3 L = normalize( UnityWorldSpaceLightDir(i.worldPosition.xyz));
                float3 V = normalize( UnityWorldSpaceViewDir(i.worldPosition.xyz));
                float3 H = normalize(V+L);
                float2 uv = i.uv;

//================== PBR  ============================================== //
                float4 BaseColor = tex2D(_MainTex,uv);
                float Roughness = _Roughness;
                float Metallic = _Metallic;
                float3 F0 = lerp(0.04,BaseColor,Metallic);

//================== Rim Light  ============================================== //
                float3 RimLight = step(dot(N,V) , _RimWdith ) * _RimIntensity * BaseColor;
                
//================== Diffuse  ============================================== //
                float3 LightMap = tex2D(_LightMap,uv);
                // float RampAdd = LightMap.r;
                // // float ShadowAO = step(0.1,LightMap.g);
                // float ShadowAO = LightMap.g;
                // float SpecularMask = LightMap.b;
                
                float3 Diffuse = lerp( BaseColor*_DarkIntensity,BaseColor*_BrightIntensity,step( (_RampOffset + 0)*1,dot(N,L)));

//================== Normal Map  ============================================== //
                 float3 NormalMap = UnpackNormal(tex2D(_NormalMap,uv));
                 float3x3 TBN = float3x3(T,B,N);
                 N = normalize( mul (NormalMap,TBN));
                 N = normalize(N);

//================== Direct Light  ============================================== //
                //Specular
                //Cook-Torrance BRDF
                float3 Specular = Specular_GGX(N,L,H,V,Roughness,F0) *1*_SpecularIntensity;
                float4 FinalColor =0;
                FinalColor.xyz = Diffuse + Specular +RimLight;
                FinalColor.a = _Alpha * tex2D(_MainTex,uv).a;

                return FinalColor;
                
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}