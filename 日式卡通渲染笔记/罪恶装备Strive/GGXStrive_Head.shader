Shader "NPR/GGXStrive_Head"
{
    Properties
    {
        _BaseMap    ("_BaseMap", 2D)    = "white" {}
        _LightMap   ("_LightMap", 2D)   = "white" {}
        _LineMap    ("_LineMap", 2D)    = "white" {}
        _MixMap     ("_MixMap", 2D)     = "black" {}
        _ShadowMap  ("_ShadowMap", 2D)  = "white" {}
        _DecalMap   ("_DecalMap", 2D)  = "white" {}
        
        _LightThreshold("_LightThreshold",Range(-2,2))=1
        _RampOffset("RampOffset",Range(-2,2)) =0
        _DarkIntensity("暗部强度",Range(0,1)) = 0
        
        [Space(30)]
        [KeywordEnum(Tex,Color)] FaceShadowMode("脸部暗部模式",Float) = 0
        _FaceShadowColor("脸部暗部颜色",Color) = (0.5,0.5,0.5,0.5)
        
        [Space(30)]
        _HairSpecularBrightIntensity("头发高光亮部强度",Float) =1
        _HairSpecularDarkIntensity("头发高光暗部强度",Float) =0.1
        
        [Space(30)]
        _LineIntensity("损旧线条强度",Range(0,1)) = 0
        
        [Space(30)]
        _RimWidth("边缘光宽度",Float) =0.5
        _RimIntensity("边缘光强度",Float) =0.3
        
        [Space(30)]
        _OulineScale("_OulineScale",Float) =1
        _OutlineColor ("_OutlineColor",Color) = (0,0,0,0)

        [KeywordEnum(None,Base,Base_A,Shadow,Shadow_A,Line,Mix,LM_R,LM_G,LM_B,LM_A,UV,UV2,VC,VC_R,VC_G,VC_B,VC_A,Decal)] _TestMode("_TestMode",Int) = 0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "LightMode"="ForwardBase" "Queue" = "Geometry"}
        
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

            #define Black   float4(0,0,0,1)
            #define Red     float4(1,0,0,1)
            #define Green   float4(0,1,0,1)
            #define Blue    float4(0,0,1,1)
            #define Yellow  float4(1,1,0,1)
            #define Cyan    float4(0,0,1,1)
            #define Fuck    float4(0.6,0.2,0.1,1)

            #define ReturnBlack     return Black
            #define ReturnRed       return Red
            #define ReturnGreen     return Green
            #define ReturnBlue      return Blue
            #define ReturnYellow    return Yellow
            #define ReturnCyan      return Cyan
            #define ReturnFuck      return Fuck

            sampler2D _BaseMap,_LightMap,_LineMap,_MixMap,_ShadowMap,_DecalMap;

            int _TestMode;
            #pragma shader_feature _TESTMODE_NONE

            float4 _ShadowColor,_SpecularColor;

            float _LightThreshold,_RampOffset;
            float _LineIntensity;
            float _DarkIntensity;
            
            //高光
            float _HairSpecularBrightIntensity,_HairSpecularDarkIntensity;
            //边缘光
            float _RimWidth,_RimIntensity;


            #pragma shader_feature FACESHADOWMODE_TEX FACESHADOWMODE_COLOR
            
            float4 _FaceShadowColor;
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
                float4 tangent :TANGENT;
                float3 normal : NORMAL;
                float4 vertexColor : Color;
            };

            struct v2f
            {
                float4 pos          : SV_POSITION; // 必须命名为pos ，因为 TRANSFER_VERTEX_TO_FRAGMENT 是这么命名的，为了正确地获取到Shadow
                float2 uv           : TEXCOORD0;
                float3 tangent      : TEXCOORD1;
                float3 bitangent    : TEXCOORD2; 
                float3 normal       : TEXCOORD3; 
                float3 worldPosition: TEXCOORD4;
                float3 localPosition : TEXCOORD5;
                float3 localNormal  : TEXCOORD6;
                float4 vertexColor  : TEXCOORD7;
                LIGHTING_COORDS(8,9)
                float2 uv2          : TEXCOORD10;

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

            float4 frag (v2f i) : SV_Target
            {
                //Variable
                float3 T = normalize(i.tangent);
                // float3 N = normalize(i.normal);
                float3 N = normalize(i.tangent);
                float3 B = normalize( cross(N,T));
                // float3 B = normalize( i.bitangent);
                float3 L = normalize( UnityWorldSpaceLightDir(i.worldPosition.xyz));
                float3 V = normalize( UnityWorldSpaceViewDir(i.worldPosition.xyz));
                float3 H = normalize(V+L);
                float2 uv = i.uv;
                //uv.y = 1-uv.y;  //uv颠倒了,如果在 Csv2Obj阶段已经反转了，这里就不需要再转了
                float2 uv2 = i.uv2;

                // return float4(uv2,0,0);
                float4 VertexColor = i.vertexColor;
                // return VertexColor.xyzz;
                float HV = dot(H,V);
                float NV = dot(N,V);
                float NL = dot(N,L);
                float NH = dot(N,H);

                float TL = dot(T,L);
                float TH = dot(T,H);

/*==========================Texture ==========================*/

                float3 FinalColor   = 0;
                float4 BaseMap      = tex2D(_BaseMap,uv);
                float4 LightMap     = tex2D(_LightMap,uv);
                float4 LineMap      = tex2D(_LineMap,uv);
                float4 MixMap       = tex2D(_MixMap,uv);
                float4 ShadowMap    = tex2D(_ShadowMap,uv);
                float4 DecalMap     = tex2D(_DecalMap,uv);

                // return LightMap.r;//材质区分 or 高光区分
                //return LightMap.g;//RampOffset
                //return LightMap.b;//高光Mask
                // return LightMap.a;//内勾线

                //BaseMap.a 用途未知
                //ShadowMap.a 用途未知
                
                float SpecularLayerMask         = LightMap.r;//高光类型
                float RampOffsetMask            = LightMap.g;//Ramp偏移值
                float SpecularIntensityMask     = LightMap.b;//高光强度mask
                float InnerLineMask             = LightMap.a;//内勾线Mask

                float ShadowAOMask                = VertexColor.r;//AO 常暗部分
                                                 // VertexColor.g;//用来区分身体的部位, 比如 脸部=88
                                                 // VertexColor.b;//渲染无用
                float OutlineIntensity            = VertexColor.a;//描边粗细

                //罪恶装备Strive的特殊材质,单独做Shader
                //自发光单独做的Mesh

                {
                #ifndef  _TESTMODE_NONE
                // [KeywordEnum(None,Base,Base_A,Shadow,Shadow_A,Line,Mix,LM_R,LM_G,LM_B,LM_A,UV,UV2,VC,VC_R,VC_G,VC_B,VC_A)] _TestMode("_TestMode",Int) = 0
                // return BaseColor.xyzz;
                int mode = 1;
                if(_TestMode == mode++)
                    return BaseMap;
                if(_TestMode == mode++)
                    return BaseMap.a;
                if(_TestMode == mode++)
                    return ShadowMap;
                if(_TestMode == mode++)
                    return ShadowMap.a;
                if(_TestMode == mode++)
                    return LineMap;
                if(_TestMode == mode++)
                    return MixMap;
                if(_TestMode == mode++)
                    return LightMap.r;
                if(_TestMode ==mode++)
                    return LightMap.g; //阴影 Mask
                if(_TestMode ==mode++)
                    return LightMap.b; //漫反射 Mask
                if(_TestMode ==mode++)
                    return LightMap.a; //漫反射 Mask
                if(_TestMode ==mode++)
                    return float4(uv,0,0); //uv
                if(_TestMode ==mode++)
                    return float4(uv2,0,0); //uv2
                if(_TestMode ==mode++)
                    return VertexColor.xyzz; //VertexColor
                 if(_TestMode ==mode++)
                    return VertexColor.r; //VertexColor
                 if(_TestMode ==mode++)
                    return VertexColor.g; //VertexColor
                 if(_TestMode ==mode++)
                    return VertexColor.b; //VertexColor
                 if(_TestMode ==mode++)
                    return VertexColor.a; //VertexColor
                  if(_TestMode ==mode++)
                  {
                    clip (0.1-DecalMap.r );
                    return DecalMap; //VertexColor
                  }
                #endif
                }

/*==========================Diffuse ==========================*/
                //脸部
                if (VertexColor.g<0.9)
                {
                    NL = dot(T.xz,L.xz);
                    float halfLambert = 0.5*NL+0.5;
                    float Threshold = step(_LightThreshold,(halfLambert + _RampOffset +0 )*ShadowAOMask);
                    float3 FaceShadowSide = 0;
                    #ifdef FACESHADOWMODE_TEX
                        FaceShadowSide =  ShadowMap*BaseMap;
                    #endif

                    #ifdef FACESHADOWMODE_COLOR
                        FaceShadowSide =  BaseMap*_FaceShadowColor;
                    #endif
                    
                    float3 Diffuse = lerp( lerp( FaceShadowSide ,BaseMap,_DarkIntensity),BaseMap,Threshold);
                    
                    return Diffuse.xyzz;
                }

                //头发 漫反射
                float NL01 = 0.5*NL+0.5;
                float Threshold = step(_LightThreshold,(NL01 + _RampOffset +RampOffsetMask )*ShadowAOMask);
                BaseMap*= InnerLineMask;
                BaseMap = lerp(BaseMap,BaseMap*LineMap,_LineIntensity); 
                float3 Diffuse = lerp( lerp(  ShadowMap*BaseMap,BaseMap,_DarkIntensity),BaseMap,Threshold);
                //头发 高光
                float3 Specular =0;
                Specular = SpecularIntensityMask*BaseMap*lerp(_HairSpecularDarkIntensity,_HairSpecularBrightIntensity,Threshold);
                //高光仅在亮部显示
                FinalColor = Diffuse + Specular;

    /*==========================边缘光 ==========================*/
                float3 N_VS = mul((float3x3)UNITY_MATRIX_V, T);
                float3 Rim = step(1-_RimWidth,abs( N_VS.x))*_RimIntensity*BaseMap;
                Rim = lerp(Rim,0,Threshold);
                Rim = max(0,Rim);

                FinalColor.rgb += Rim;
                // return Rim.xyzz;
                
                return float4(FinalColor,1);
            }
            ENDCG
        }
        
        Pass
        {
            
            Name "TANGENT"
            Cull Front
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
          
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float4 vertexColor : COLOR;
                float4 tangent :TANGENT;
            };

            struct v2f
            {
                float4 pos : SV_POSITION; 
                float2 uv : TEXCOORD0;
            };

            float _OulineScale;
            float4 _OutlineColor;

            v2f vert(appdata v)
            {
                v2f o;
                v.vertex.xyz += v.tangent.xyz *_OulineScale*0.01*v.vertexColor.a;
                o.pos = UnityObjectToClipPos(v.vertex);
                return o;
            }
      
            float4 frag(v2f i) : SV_Target
            {
                return _OutlineColor;
            }
            ENDCG
        }
       
    }
    Fallback "Diffuse"
}