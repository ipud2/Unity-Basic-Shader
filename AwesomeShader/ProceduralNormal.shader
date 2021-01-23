Shader "Unlit/ProceduralNormal"
{
    Properties
    {
        // _MainTex ("Texture", 2D) = "white" {}
        _PowerValue("_PowerValue",Float) = 4 
        _PowerScale("_PowerScale",Float) = 1
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
                 float3 worldPosition    : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float _PowerValue ,_PowerScale;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPosition = mul(unity_ObjectToWorld,v.vertex);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                // sample the texture
                //float4 col = tex2D(_MainTex, i.uv);

                float3 L = normalize( UnityWorldSpaceLightDir(i.worldPosition.xyz));
                float3 V = normalize( UnityWorldSpaceViewDir(i.worldPosition.xyz));
                float3 H = normalize(V+L);
                
                float2 uv = i.uv;

                float r  = 0.5;

                float3 center = float3(0.5,0.5,0);

                float a = center.x;
                float b = center.y;
                float c = center.z;
                
                float x = uv.x;
                float y = uv.y;
                
                float delta = sqrt(r*r - (x-a)*(x-a) -(y-b)*(y-b));
                float z1 = c + delta;
                float z2 = c - delta;

                float3 N = normalize( float3(x-center.x,y-center.y,z2) );

                if(distance(center,uv)>r) discard;

                float Diffuse  =  dot(N,L);

                float Specular = pow(dot(N,H),_PowerValue*128)*_PowerScale;      

                Diffuse = max(Diffuse,0);
                Specular = max(Specular,0);

                return Diffuse + Specular;           

            }
            ENDCG
        }
    }
}
