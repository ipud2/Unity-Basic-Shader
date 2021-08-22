Shader "NPR/NPR_ZS_Eye_Code"
{
    Properties
    {
        _MainTex ("_MainTex", 2D) = "white" {}
        _RampOffset ("_RampOffset",Range(-1,1)) =0
        _DarkIntensity("_DarkIntensity",Range(0,1)) =0.5
        _BrightIntensity("_BrightIntensity",Float) =1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "LightMode"="ForwardBase"}

        Pass
        {
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

            sampler2D _MainTex;
            float _RampOffset,_DarkIntensity,_BrightIntensity;

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
                // float3 T = normalize(i.tangent);
                float3 N = normalize(i.normal);
                // float3 B = normalize( cross(N,T));
                // float3 B = normalize( i.bitangent);
                float3 L = normalize( UnityWorldSpaceLightDir(i.worldPosition.xyz));
                float3 V = normalize( UnityWorldSpaceViewDir(i.worldPosition.xyz));
                float2 uv = i.uv;

//================== PBR  ============================================== //
                float3 BaseColor = tex2D(_MainTex,uv);
//================== Diffuse  ============================================== //
                float3 Diffuse = lerp( BaseColor*_DarkIntensity,BaseColor*_BrightIntensity, step(_RampOffset,dot(N,L)));
                float4 FinalColor =0;
                FinalColor.xyz = Diffuse;

                return FinalColor;
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}