Shader "Unlit/TestGUI"
{
    Properties
    {
        [Main(GroupToggle)] GroupToggle("GroupToggle",float)= 1
        [SubToggle(GroupToggle,USERIM)] _UseRim("UseRim?",Float) = 0
        [SubToggleItem(GroupToggle,USERIM)] _RimScale("RimScale",Float) = 0
        
        [Main(g8,g8,1)] g8("Group_Main23333",Float) =0
        [Sub(g8)]_MainTex22233 ("_MainTex22233", 2D) = "white" {}
        [Sub(g8)] g9("ShadowColor",Color) = (1,0,0,0)
        [Sub(g8)] g10 ("这是一个浮点值",Float) =2
        
        [Header(Header)][NoScaleOffset]
        _MainTex ("Texture", 2D) = "white" {}

        [HDR] _Color("_Color",Color) = (1,1,1,1)
        [Tex(_,_mColor2)] _tex("tex color",2D) ="white"{}
        [HideInInspector]_mColor2("_mColor2",Color) = (0,0,1,0)

        [Main(g1,MainKey,1)] _group("Shadow1",Float) =1
        [Sub(g1)] _float ("这是一个浮点值",Float) =2
        [Sub(g1)]_MainTex2 ("_MainTex2", 2D) = "white" {}

        [Main(g2,MainKey2,1)] _group2("Shadow2",Float) =1
        [Sub(g2)] _float2 ("float",Float) =2
        [Sub(g2)]_MainTex22 ("_MainTex2", 2D) = "white" {}
        
        [Main(g3)] _UseShadow("UseShadow",Float) = 0
        [Sub(g3)]_M3 ("_MainTex22233", 2D) = "white" {}

        [Sub(g3)] _ShadowColor("ShadowColor",Color) = (1,0,0,0)
        [Sub(g3)] _ShadowRange("ShadowRange",Range(0,1)) = 0
        [Sub(g3)] [NoScaleOffset]_ShadowRamp("_ShadowRamp",2D) = "White"{}

        [SubKey(g3,k1,k2,k3)] _KeyDrawer("Key",Float) =0
        [SubKeyItem(g3,k1)] g3k1("g3k1",Float) = 1
        [SubKeyItem(g3,k2)] g3k2("g3k2",Float) = 1
        [SubKeyItem(g3,k3)] g3k3("g3k3",Float) = 1

        [Button(g3,b1,b2,b3,b4)] _Button("_Button",Float) =0
        [ButtomItem(g3,b1)] b1("b1",2D) = "Black"{}
        [ButtomItem(g3,b2)] b2("b2",2D) = "Black"{}
        [ButtomItem(g3,b3)] b3("b3",2D) = "Black"{}
        [ButtomItem(g3,b4)] b4("b4",2D) = "Black"{}
        //无组 Button
        [Button(_,sb1,sb2,sb3,sb4)] _SButton("_SButton",Float) =0
        [ButtomItem(_,sb1)] sb1("sb1",2D) = "Black"{}
        [ButtomItem(_,sb2)] sb2("sb2",2D) = "Black"{}
        [ButtomItem(_,sb3)] sb3("sb3",2D) = "Black"{}
        [ButtomItem(_,sb4)] sb4("sb4",2D) = "Black"{}
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
        }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma shader_feature KEY1 KEY2 KEY3
            #pragma shader_feature MAINKEY
            #pragma shader_feature B1 B2 B3 B4


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

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float4 col = tex2D(_MainTex, i.uv);

                #ifdef B1
                return float4(1, 0, 0, 1);
                #endif

                #ifdef B2
                return float4(0, 1, 0, 1);
                #endif

                #ifdef B3
                return float4(0, 0, 1, 1);
                #endif

                return col;
            }
            ENDCG
        }
    }
    //    CustomEditor "JTRP.ShaderDrawer.LWGUI"
    CustomEditor "TA.SimpleShaderGUI"
}
