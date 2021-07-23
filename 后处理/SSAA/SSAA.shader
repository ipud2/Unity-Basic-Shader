Shader "TA/SSAA"
{
    Properties
    {
    }

    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
        }

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

            sampler2D_float SSAART;
            // float4 SSAART_TexelSize;
            float4 SSAART_TexelSize;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float4 pixel = 0;
                float num = 9;

                float2 ops[] =
                {
                    float2(0,0),
                    float2(1, 1),float2(-1, 1),float2(1, -1),float2(-1, -1),
                    float2(0, 1),float2(0, -1),float2(1, 0),float2(-1, 0),
                };

                for (int j=0;j<num;j++)
                {
                    float4 weight = tex2D(SSAART, i.uv + ops[j] * SSAART_TexelSize);
                    pixel += weight;
                }

                pixel /= num;

                return pixel;
                
                //
                //
                // float4 c0 = tex2D(SSAART, i.uv + float2(1, 1) * SSAART_TexelSize);
                // float4 c1 = tex2D(SSAART, i.uv + float2(-1, 1) * SSAART_TexelSize);
                // float4 c2 = tex2D(SSAART, i.uv + float2(1, -1) * SSAART_TexelSize);
                // float4 c3 = tex2D(SSAART, i.uv + float2(-1, -1) * SSAART_TexelSize);
                // cc = (cc + c0 + c1 + c2 + c3) * 0.2;
            }

            ENDCG
        }
    }
}