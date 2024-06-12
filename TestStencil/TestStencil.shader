Shader "Unlit/TestStencil"
{
    SubShader
    {
        Pass
        {
            Stencil
            {
                Ref 255
                Comp equal
                Pass keep
            }

            //关闭深度测试，让这个mesh渲染在最前面
            ZTest Off
//            ZWrite Off
            
            //设置为双面渲染，防止三角形顺序出错
            Cull off
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 posOS : POSITION;
            };

            struct v2f
            {
                float4 posCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                //o.posCS = UnityObjectToClipPos(v.posOS);
                o.posCS = float4(v.posOS.xy,0,1.0);
                o.uv = v.posOS.xy*0.5+0.5;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                return float4(i.uv,0,0);
                float4 col = tex2D(_MainTex, i.uv);
                return col;
            }
            ENDCG
        }
    }
}
