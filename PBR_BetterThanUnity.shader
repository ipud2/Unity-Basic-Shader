Shader "Unlit/MyPBR"
{
    Properties
    {
        // _MainTex ("Texture", 2D) = "white" {}
        _BRDFLUTTex ("_BRDFLUTTex", 2D) = "white" {}
        // _Value ("_Value",Float) =1
        // _RangeValue("_RangeValue",Range(0,1)) = 0.5
        // _Color ("_Color",Color) = (0.5,0.3,0.2,1)
        _BaseColor ("_BaseColor",Color) = (0.5,0.3,0.2,1)

        _Roughness("_Roughness",Range(0,1)) = 0.5
        [Gamma]_Metallic("_Metallic",Range(0,1)) = 0.5

        _EnvCubeMap("_EnvCubeMap",CUBE) = ""

        [Space]
        [Space]
        [Space]

        _BaseColorTex ("_BaseColorTex", 2D) = "white" {}
        _MetallicTex ("_MetallicTex", 2D) = "white" {}
        _RoughnessTex ("_RoughnessTex", 2D) = "white" {}

        _EmissionTex ("_EmissionTex", 2D) = "white" {}
        _NormalTex ("_NormalTex", 2D) = "black" {}
        _AOTex ("_AOTex", 2D) = "white" {}


    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "LightMode"="ForwardBase"}

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work

            // #include "UnityCG.cginc"
            // // _LightColor0 (declared in UnityLightingCommon.cginc)
            // #include "UnityLightingCommon.cginc" 
            // // #define UNITY_SPECCUBE_LOD_STEPS
            // #include "UnityStandardConfig.cginc"

            #include "UnityCG.cginc"
			#include "Lighting.cginc"
            #include "UnityGlobalIllumination.cginc"

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
            float4 _MainTex_ST;

            float  _Value,_RangeValue;
            float4 _Color,_BaseColor;

            float _Metallic,_Roughness;
            sampler2D _BRDFLUTTex;

            samplerCUBE _EnvCubeMap;

            sampler2D _BaseColorTex,_MetallicTex,_RoughnessTex;
            sampler2D _EmissionTex,_AOTex,_NormalTex;

         
            #define PI 3.141592654

            //D
            float D_DistributionGGX(float3 N,float3 H,float Roughness)
            {
                float a             = Roughness*Roughness;
                // float a             = Roughness;
                float a2            = a*a;
                float NH            = max(dot(N,H),0);
                float NH2           = NH*NH;
                float nominator     = a2;
                float denominator   = (NH2 * (a2-1.0) +1.0);
                denominator         = PI * denominator*denominator;
                
                return              nominator/ max(denominator,0.0000001) ;//防止分母为0
                // return              nominator/ (denominator) ;//防止分母为0
            }
            //G
            float GeometrySchlickGGX(float NV,float Roughness)
            {
                float r = Roughness +1.0;
                float k = r*r / 8.0;
                float nominator = NV;
                float denominator = k + (1.0-k) * NV;
                // return nominator/ max(denominator,0.001) ;//防止分母为0
                return              nominator/ max(denominator,0.0000001) ;//防止分母为0
            }

            float G_GeometrySmith(float3 N,float3 V,float3 L,float Roughness)
            {
                float NV = max(dot(N,V),0);
                float NL = max(dot(N,L),0);

                float ggx1 = GeometrySchlickGGX(NV,Roughness);
                float ggx2 = GeometrySchlickGGX(NL,Roughness);

                return ggx1*ggx2;

            }

            //F
            float3 F_FrenelSchlick(float HV,float3 F0)
            {
                return F0 +(1.0 - F0)*pow(1.0-HV,5);
            }

            float3 FresnelSchlickRoughness(float NV,float3 F0,float Roughness)
            {
                return F0 + (max(float3(1.0 - Roughness, 1.0 - Roughness, 1.0 - Roughness), F0) - F0) * pow(1.0 - NV, 5.0);
            }

            //UE4 Black Ops II modify version
            float2 EnvBRDFApprox(float Roughness, float NoV )
            {
                // [ Lazarov 2013, "Getting More Physical in Call of Duty: Black Ops II" ]
                // Adaptation to fit our G term.
                const float4 c0 = { -1, -0.0275, -0.572, 0.022 };
                const float4 c1 = { 1, 0.0425, 1.04, -0.04 };
                float4 r = Roughness * c0 + c1;
                float a004 = min( r.x * r.x, exp2( -9.28 * NoV ) ) * r.x + r.y;
                float2 AB = float2( -1.04, 1.04 ) * a004 + r.zw;
                return AB;
            }

            // Black Ops II
            // float2 EnvBRDFApprox(float Roughness, float NV)
            // {
            //     float g = 1 -Roughness;
            //     float4 t = float4(1/0.96, 0.475, (0.0275 - 0.25*0.04)/0.96, 0.25);
            //     t *= float4(g, g, g, g);
            //     t += float4(0, 0, (0.015 - 0.75*0.04)/0.96, 0.75);
            //     float A = t.x * min(t.y, exp2(-9.28 * NV)) + t.z;
            //     float B = t.w;
            //     return float2 ( t.w-A,A);
            // }如果

            float3 ACESToneMapping(float3 x)
            {
                float a = 2.51f;
                float b = 0.03f;
                float c = 2.43f;
                float d = 0.59f;
                float e = 0.14f;
                return saturate((x*(a*x+b))/(x*(c*x+d)+e));
            }
            float4 ACESToneMapping(float4 x)
            {
                float a = 2.51f;
                float b = 0.03f;
                float c = 2.43f;
                float d = 0.59f;
                float e = 0.14f;
                return saturate((x*(a*x+b))/(x*(c*x+d)+e));
            }

            v2f vert (appdata v)
            {
                v2f o;
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

//================== Normal Map  ============================================== //
                float3 NormalMap = UnpackNormal(tex2D(_NormalTex,uv));

                float3x3 TBN = float3x3(T,B,N);
                // TBN = transpose(TBN);
                // N = normalize( mul (TBN,NormalMap) );
                N = normalize( mul (NormalMap,TBN));
                // N.x = dot(float3(T.x,B.x,N.x),NormalMap);
                // N.y = dot(float3(T.y,B.y,N.y),NormalMap);
                // N.z = dot(float3(T.z,B.z,N.z),NormalMap);
                N = normalize(N);

//================== PBR  ============================================== //
                // float3 BaseColor = _BaseColor;
                // float Roughness = _Roughness;
                // float Metallic = _Metallic;

                float3 BaseColor = tex2D(_BaseColorTex,uv);

                // return BaseColor.xyzz;
                float Roughness = tex2D(_RoughnessTex,uv).r;
                float Metallic = tex2D(_MetallicTex,uv).r;
                
                float3 Emission = tex2D(_EmissionTex,uv);
                float3 AO = tex2D(_AOTex,uv);

                float3 F0 = lerp(0.04,BaseColor,Metallic);
                float3 Radiance = _LightColor0.xyz;

//================== Direct Light  ============================================== //
                //Specular
                //Cook-Torrance BRDF
                float HV = max(dot(H,V),0);
                float NV = max(dot(N,V),0);
                float NL = max(dot(N,L),0);
               
                float D = D_DistributionGGX(N,H,Roughness);
                float3 F = F_FrenelSchlick(HV,F0);
                float G = G_GeometrySmith(N,V,L,Roughness);

                float3 KS = F;
                float3 KD = 1-KS;
                KD*=1-Metallic;
                float3 nominator = D*F*G;
                float denominator = max(4*NV*NL,0.001);
                float3 Specular = nominator/denominator;
                // Specular =max( Specular,0);

                //Diffuse
                // float3 Diffuse = KD * BaseColor / PI;
                float3 Diffuse = KD * BaseColor ; //没有除以 PI

                float3 DirectLight = (Diffuse + Specular)*NL *Radiance;
    

//================== Indirect Light  ============================================== //
                float3 IndirectLight = 0;

                //Specular
                float3 R = reflect(-V,N);
                float3 F_IndirectLight = FresnelSchlickRoughness(NV,F0,Roughness);
                // return F_IndirectLight.xyzz;
                // float3 F_IndirectLight = F_FrenelSchlick(NV,F0);
                float mip = Roughness * (1.7 - 0.7 * Roughness) * UNITY_SPECCUBE_LOD_STEPS ;
                float4 rgb_mip = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0,R,mip);

                //间接光镜面反射采样的预过滤环境贴图
                float3 EnvSpecularPrefilted = DecodeHDR(rgb_mip, unity_SpecCube0_HDR);
               
                //LUT采样
                // float2 env_brdf = tex2D(_BRDFLUTTex, float2(NV, Roughness)).rg; //0.356
                // float2 env_brdf = tex2D(_BRDFLUTTex, float2(lerp(0, 0.99, NV), lerp(0, 0.99, Roughness))).rg;
             
                //数值近似
                float2 env_brdf = EnvBRDFApprox(Roughness,NV);

                float3 Specular_Indirect = EnvSpecularPrefilted  * (F_IndirectLight * env_brdf.r + env_brdf.g);
            
                //Diffuse           
                float3 KD_IndirectLight = float3(1,1,1) - F_IndirectLight;
                // return KD_IndirectLight.xyzz;
                KD_IndirectLight *= 1 - Metallic;

                float3 irradianceSH = ShadeSH9(float4(N,1));
                // return irradianceSH.rgbb;
                // float3 Diffuse_Indirect = irradianceSH * BaseColor *KD_IndirectLight / PI;
                float3 Diffuse_Indirect = irradianceSH * BaseColor *KD_IndirectLight; //没有除以 PI
             
                IndirectLight = (Diffuse_Indirect + Specular_Indirect)*AO;

                float4 FinalColor =0;

                FinalColor.rgb = DirectLight + IndirectLight;

                FinalColor.rgb += Emission;


                //HDR => LDR aka ToneMapping
                // return G;
                FinalColor.rgb = ACESToneMapping(FinalColor.rgb);

                //Linear => Gamma
                // FinalColor = pow(FinalColor,1/2.2);
                
                return FinalColor;
            }
            ENDCG
        }
    }
}
