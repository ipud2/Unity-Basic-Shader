Shader "Unlit/Cloth"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [Space]
        _BaseColor ("_BaseColor",Color) = (0.5,0.0,0.3,1)

        [Space]
        _Metallic ("_Metallic",Range(0,1)) = 1
        _Roughness ("_Roughness",Range(0,1)) =1
        
        _SheenColor ("_SheenColor",Color) = (0.0,0.0,0.6,1)
        _SubsurfaceColor ("_SubsurfaceColor",Color) = (0.2,0.3,0.6,1)
        _SubsurfaceWeight("_SubsurfaceWeight",Float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "LightMode"="ForwardBase" "Queue" = "Geometry"}
//"LightMode"="ForwardBase" ForwardBase 让Shader接受主光源影响
        
        /*
        //Transparent Setup
         Tags { "Queue"="Transparent"  "RenderType"="Transparent" "LightMode"="ForwardBase"}
         Blend SrcAlpha OneMinusSrcAlpha
        */

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
            // #include "NPRBrdf.cginc"	
			

            #ifndef UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX
            //only defining to not throw compilation error over Unity 5.5
            #define UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input)
            #endif
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
                float4 tangent :TANGENT;
                float3 normal : NORMAL;
                float4 vertexColor : COLOR;
            };

            struct v2f
            {
                float4 pos              : SV_POSITION; // 必须命名为pos ，因为 TRANSFER_VERTEX_TO_FRAGMENT 是这么命名的，为了正确地获取到Shadow
                float2 uv               : TEXCOORD0;
                float3 tangent          : TEXCOORD1;
                float3 bitangent        : TEXCOORD2; 
                float3 normal           : TEXCOORD3; 
                float3 worldPosition    : TEXCOORD4;
                float3 localPosition    : TEXCOORD5;
                float3 localNormal      : TEXCOORD6;
                float4 vertexColor      : TEXCOORD7;
                float2 uv2              : TEXCOORD8;
                LIGHTING_COORDS(9,10)
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.uv2 = v.uv2;
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.worldPosition = mul(unity_ObjectToWorld,v.vertex);
                o.localPosition = v.vertex.xyz;
                o.tangent = UnityObjectToWorldDir(v.tangent);
                o.bitangent = cross(o.normal,o.tangent) * v.tangent.w;
                o.localNormal = v.normal;
                o.vertexColor = v.vertexColor;
                TRANSFER_VERTEX_TO_FRAGMENT(o);
                return o;
            }
	        sampler2D _MainTex;			float4 _MainTex_ST;

            float4 _BaseColor;
            float _Roughness,_Metallic;
            float4 _SheenColor,_SubsurfaceColor;
            float _SubsurfaceWeight;
            

            #ifndef PI
                #define PI 3.141592654
            #endif

            #define DIFFUSE_LAMBERT 0
            #define DIFFUSE_DISNEY_BURLEY 1

            #define BRDF_DIFFUSE   DIFFUSE_DISNEY_BURLEY

            //==== 布料BRDF ========//
            inline float pow5(float value)
            {
                return value*value*value*value*value;
            }

            float3 F_Schlick(float3 f0, float f90, float VoH) 
            {
                // Schlick 1994, "An Inexpensive BRDF Model for Physically-Based Rendering"
                return f0 + (f90 - f0) * pow5(1.0 - VoH);
            }

            float3 F_Schlick(float3 f0, float VoH) 
            {
                float f = pow(1.0 - VoH, 5.0);
                return f + f0 * (1.0 - f);
            }

            float F_Schlick(float f0, float f90, float VoH) {
                return f0 + (f90 - f0) * pow5(1.0 - VoH);
            }
            float Diffuse_Lambert(float NL) 
            {
                return NL / PI;
            }

            float Diffuse_Disney_Burley(float roughness, float NoV, float NoL, float LoH) 
            {
                // Burley 2012, "Physically-Based Shading at Disney"
                float f90 = 0.5 + 2.0 * roughness * LoH * LoH;
                float lightScatter = F_Schlick(1.0, f90, NoL);
                float viewScatter  = F_Schlick(1.0, f90, NoV);
                return lightScatter * viewScatter * (1.0 / PI);
            }

            // Energy conserving wrap diffuse term, does *not* include the divide by pi
            float Diffuse_Wrap(float NoL, float w) 
            {
                return saturate((NoL + w) / sqrt(1.0 + w));
            }

            //------------------------------------------------------------------------------
            // Diffuse BRDF dispatch
            //------------------------------------------------------------------------------
       
            float DiffuseLight(float roughness, float NoV, float NoL, float LoH) 
            {
            #if BRDF_DIFFUSE == DIFFUSE_LAMBERT
                return Diffuse_Lambert(NoL);
            #elif BRDF_DIFFUSE == DIFFUSE_DISNEY_BURLEY
                return Diffuse_Disney_Burley(roughness, NoV, NoL, LoH);
            #endif
            }
            
            float D_Ashikhmin(float roughness, float NH)
            {
                float m2    = roughness * roughness;
                float cos2h = NH * NH;
                float sin2h = 1.0 - cos2h;
                float sin4h = sin2h * sin2h;
                return (sin4h + 4.0 * exp(-cos2h / (sin2h * m2))) / (PI * (1.0 + 4. * m2) * sin4h);
            }
            
            float D_Charlie(float roughness, float NH)
            {
                float invR = 1.0 / roughness;
                float cos2h = NH * NH;
                float sin2h = 1. - cos2h;
                return (2.0 + invR) * pow(sin2h, invR * 0.5) / (2.0 * PI);
            }

            #define saturateMediump(x) min(x, 65504.0)

            float V_Ashikhmin(float NV, float NL)
            {
                return max( saturateMediump( ( 1.0 / (4.0 * (NL + NV - NL * NV)) ) ) ,0);
            }
            
            // //F
            float3 F_FrenelSchlick_Cloth(float HV,float3 F0)
            {
                return F0 +(1.0 - F0)*pow(1.0-HV,5);
            }

            float4 frag (v2f i ) : SV_Target
            {
                float3 T = normalize(i.tangent);
                float3 N = normalize(i.normal);
                //float3 B = normalize( cross(N,T));
                float3 B = normalize( i.bitangent);
                float3 L = normalize( UnityWorldSpaceLightDir(i.worldPosition.xyz));
                float3 V = normalize( UnityWorldSpaceViewDir(i.worldPosition.xyz));
                float3 H = normalize(V+L);
                float2 uv = i.uv;
                float2 uv2 = i.uv2;

                // return float4(uv2,0,0);
                float4 vertexColor = i.vertexColor;
                // return vertexColor.xyzz;
                float HV = dot(H,V);
                float NV = dot(N,V);
                float NL = dot(N,L);
                float NH = dot(N,H);
                float LH = dot(L,H);

                float4 FinalColor =0;
                float4 BaseColor = tex2D(_MainTex,uv);
                FinalColor.rgb = BaseColor.rgb;

                float shadow = SHADOW_ATTENUATION(i);
                // float2 lightmapUV = uv2 * unity_LightmapST.xy + unity_LightmapST.zw;
                // float3 LightMap = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap,lightmapUV));
                // float3 IrradianceSH = ShadeSH9(float4(N,1));

                _Roughness = max(_Roughness,0.01);
                //Diffuse 漫反射
                float3 Diffuse = DiffuseLight(_Roughness,NV,NL,LH);
                //受Fresnel影响
                float3 F0 = lerp(0.04,_BaseColor,_Metallic);
                float3 Fresnel = F_FrenelSchlick_Cloth(HV,F0);
                Diffuse *= (1-Fresnel);
                //Wrap Light
                Diffuse *= (NL+_SubsurfaceWeight/((1+_SubsurfaceWeight)*(1+_SubsurfaceWeight)))*(_SubsurfaceColor + NL);
                Diffuse *= _BaseColor/PI;

                //Specualr 高光
                float D = D_Charlie(_Roughness,NH);
                // float D = D_Ashikhmin(_Roughness,NH);
                float V_ = V_Ashikhmin(NV,NL);
                float3 F = _SheenColor;
                
                float3 Specular = D*F*V_* saturate( NL) ;

                // return Specular.xyzz;

                FinalColor.rgb = Diffuse + (Specular);


                return FinalColor;
            }
	    ENDCG
	    }
    }
    Fallback "Diffuse"
}
