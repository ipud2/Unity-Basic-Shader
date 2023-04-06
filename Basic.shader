Shader "Unlit/Basic"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Value ("_Value",Float) =1
        _RangeValue("_RangeValue",Range(0,1)) = 0.5
        _Color ("_Color",Color) = (0.5,0.3,0.2,1)
//        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlendMode("Src Blend Mode", Float) = 5
//		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlendMode("Dst Blend Mode", Float) = 10
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque" "LightMode"="ForwardBase" "Queue" = "Geometry"
        }
        //"LightMode"="ForwardBase" ForwardBase 让Shader接受主光源影响

        /*
        //Transparent Setup
         Tags { "Queue"="Transparent"  "RenderType"="Transparent" "LightMode"="ForwardBase"}
         Blend [_SrcBlendMode][_DstBlendMode]
        */
        //CGINCLUDE
        //float _SrcBlendMode;
        //float _DstBlendMode;
        //ENDCG

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
	    
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
                float4 tangentOS :TANGENT;
                float3 normalOS : NORMAL;
                float4 vertexColor : COLOR;
            };

            struct v2f
            {
                float4 pos : SV_POSITION; // 必须命名为pos ，因为 TRANSFER_VERTEX_TO_FRAGMENT 是这么命名的，为了正确地获取到Shadow
                float2 uv : TEXCOORD0;
                float3 tangentWS : TEXCOORD1;
                float3 bitangentWS : TEXCOORD2;
                float3 normalWS : TEXCOORD3;
                float3 posWS : TEXCOORD4;
                float3 posOS : TEXCOORD5;
                float3 normalOS : TEXCOORD6;
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
                o.normalWS = UnityObjectToWorldNormal(v.normalOS);
                o.posWS = mul(unity_ObjectToWorld, v.vertex);
                o.posOS = v.vertex.xyz;
                o.tangentWS = UnityObjectToWorldDir(v.tangentOS);
                o.bitangentWS = cross(o.normalWS, o.tangentWS) * v.tangentOS.w;
                o.normalOS = v.normalOS;
                o.vertexColor = v.vertexColor;
                TRANSFER_VERTEX_TO_FRAGMENT(o);

                return o;
            }

            sampler2D _MainTex;
            float4 _MainTex_ST;
	
            float4 frag(v2f i) : SV_Target
            {
                float3 T = normalize(i.tangentWS);
                float3 N = normalize(i.normalWS);
                //float3 B = normalize( cross(N,T));
                float3 B = normalize(i.bitangentWS);
                float3 L = normalize(UnityWorldSpaceLightDir(i.posWS.xyz));
                float3 V = normalize(UnityWorldSpaceViewDir(i.posWS.xyz));
                float3 H = normalize(V + L);
                float2 uv = i.uv;
                float2 uv2 = i.uv2;

                // return float4(uv2,0,0);
                float4 vertexColor = i.vertexColor;
                // return vertexColor.xyzz;
                float HV = dot(H, V);
                float NV = dot(N, V);
                float NL = dot(N, L);
                float NH = dot(N, H);

                float4 FinalColor = 0;
                float4 BaseColor = tex2D(_MainTex, uv);
                FinalColor.rgb = BaseColor.rgb;

                float shadow = SHADOW_ATTENUATION(i);
                float2 lightmapUV = uv2 * unity_LightmapST.xy + unity_LightmapST.zw;
                float3 LightMap = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, lightmapUV));
                float3 IrradianceSH = ShadeSH9(float4(N, 1));

                return FinalColor;
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}
