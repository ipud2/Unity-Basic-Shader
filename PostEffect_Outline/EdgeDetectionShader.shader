Shader "Hidden/EdgeDetectionShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Threshold("Threshold", float) = 0.01
        _EdgeColor("Edge color", Color) = (0,0,0,1)
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always
 
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
             
            #include "UnityCG.cginc"
 
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };
 
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };
 
            sampler2D _CameraDepthNormalsTexture;
            sampler2D _CameraDepthTexture;
 
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
             
            sampler2D _MainTex;
            float4 _MainTex_TexelSize;
            float _Threshold;
            float4 _EdgeColor;
 
            float4 GetPixelValue(in float2 uv)
            {
                half3 normal;
                float depth;
                DecodeDepthNormal(tex2Dlod(_CameraDepthNormalsTexture, float4(uv,0,0)), depth, normal);
                return float4(normal, depth);
            }
 
            float4 frag (v2f i) : SV_Target
            {

                //read depthnormal
                // float4 depthnormal = tex2D(_CameraDepthTexture, i.uv);
                // return depthnormal;
                //
                // float2 uv = i.uv;
                // half3 normal;
                // float depth;
                // DecodeDepthNormal(tex2Dlod(_CameraDepthNormalsTexture, float4(uv,0,0)), depth, normal);
                // return normal.xyzz;
                
                
                float4 col = tex2D(_MainTex, i.uv);
                
                float4 orValue = GetPixelValue(i.uv);
                float2 offsets[8] = {
                    float2(-1, -1),
                    float2(-1, 0),
                    float2(-1, 1),
                    float2(0, -1),
                    float2(0, 1),
                    float2(1, -1),
                    float2(1, 0),
                    float2(1, 1)
                };
                float4 sampledValue = float4(0,0,0,0);
                for(int j = 0; j < 8; j++)
                {
                    sampledValue += GetPixelValue(i.uv + offsets[j] * _MainTex_TexelSize.xy);
                }
                sampledValue /= 8;
                 
                return lerp(col, _EdgeColor, step(_Threshold, length(orValue - sampledValue)));
            }
            ENDCG
        }
    }
}