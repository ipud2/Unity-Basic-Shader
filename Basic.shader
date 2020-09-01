Shader "Unlit/Basic"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        scale ("Value",Float) = 1

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 tangent :TANGENT;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldPosion : TEXCOORD1;
                float3 tangent : TEXCOORD2;
                float3 normal :TEXCOORD3; 
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.worldPosion = mul(unity_ObjectToWorld,v.vertex);
                o.tangent = UnityObjectToWorldDir(v.tangent);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float3 T = normalize(cross(i.normal ,i.tangent));
                float3 N = i.normal;
                float3 L = WorldSpaceLightDir(float4(i.worldPosion.xyz,1));
                float3 V = WorldSpaceViewDir(float4( i.worldPosion.xyz,1));
                float3 H = normalize(L+V);
                float NV = dot(N,V);
                float NH = dot(N,H);
                float NL = dot(N,L);
                float2 uv = i.uv;
                

                // sample the texture
                // fixed4 col = tex2D(_MainTex, uv);

                return dot(N,L);

            }
            ENDCG
        }
    }
}
