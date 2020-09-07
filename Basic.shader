Shader "Unlit/Basic"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Value ("_Value",Float) =1
        _RangeValue("_RangeValue",Range(0,1)) = 0.5
        _Color ("_Color",Color) = (0.5,0.3,0.2,1)
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
                float4 vertex       : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float3 tangent      : TEXCOORD1;
                float3 normal       : TEXCOORD2; 
                float3 worldPosition : TEXCOORD3;
                float3 localPostion  : TEXCOORD4;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float  _Value,_RangeValue;
            float4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.worldPosition = mul(unity_ObjectToWorld,v.vertex);
                o.localPostion = v.vertex.xyz;
                o.tangent = UnityObjectToWorldDir(v.tangent);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                //Variable
                float3 T = normalize(cross(i.normal ,i.tangent));
                float3 N = normalize(i.normal);
                float3 B = cross(N,T);
                
                float3 L = normalize( UnityWorldSpaceLightDir(i.worldPosition.xyz));
                float3 V = normalize( UnityWorldSpaceViewDir(i.worldPosition.xyz));
                float3 H = normalize(V+L);
                float2 uv = i.uv;

                // float3 L = normalize(WorldSpaceLightDir(float4(i.localSpace.xyz,1)));
                // float3 V = normalize(WorldSpaceViewDir(float4( i.localSpace.xyz,1)));

                // float3 L = normalize(_WorldSpaceLightPos0 );//获取方向光的方向
                // float3 L = normalize(_WorldSpaceLightPos0 -i.worldPosition.xyz );//获取非方向光的方向

                // float3 V = normalize(_WorldSpaceCameraPos.xyz-i.worldPosion.xyz);


                float4 FinalColor =0;
                

                return FinalColor;
            }
            ENDCG
        }
    }
}
