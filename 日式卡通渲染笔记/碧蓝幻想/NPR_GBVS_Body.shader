Shader "NPR/GBVS_Body"
{
    //推荐使用 RiderIDE 有语义分析 比VS &VSCode好用 :D
    ///SimpleShaderGUI: https://github.com/ipud2/Unity-Basic-Shader/tree/master/SimpleShaderGUI
    
    Properties
    {
        _MainTex ("BaseMap", 2D) = "white" {}
        _ShadowMap ("ShadowMap", 2D) = "white" {}
        _LightMap ("LightMap", 2D) = "white" {} 
        _DecalMap ("DecalMap", 2D) = "white" {}
        _DecalLerp("DecalLerp",Range(0,1)) =0
        [Space(30)]
        [Toggle(DebugMode)] _DebugMode ("DebugMode?", Float) = 0
        [KeywordEnum(None,Base,Layer,Base_A,ShadowMap,LM_R,LM_G,LM_B,LM_A,UV,UV2,VC_R,VC_G,VC_B,VC_A,Normal,Tangent,Decal)] _TestMode("Debug",Int) = 0
        [KeywordEnum(None,_Layer1,_Layer2,_Layer3,_Layer4,_Layer5,_Layer6,_Layer7,_Layer8,_Layer9,_Layer10,_Layer11 )] _TestModeLayer("DebugLayer",Int) = 0
        _LayerStep("LayerStep",Range(0 ,1)) =0

        [Space(30)]
        _LightThreshold("_LightThreshold",Range(-1,1))=0.5
        _RampOffset("RampOffset",Range(-1,1)) =0.5
//        _RampOffset2("RampOffset2",Range(-1,1)) =0.15

        _BrightIntensity("亮部强度",Float) =1
        _DarkIntensity("暗部强度",Float) =1
        
        [Space(30)]
        _OulineScale("_OulineScale",Float) =0.1
        _OutlineColor ("_OutlineColor",Color) = (0,0,0,0)
        
        //===========================Layer1 ======================================//
        [Main(Layer1)] _Layer1("_Layer1 基础材质",Float) = 0
        [SubToggle(Layer1,_Layer1_HasTwoSide)] _Layer1_HasTwoSide("有两层明暗面?",Float) = 0
        [SubToggleItem(Layer1,_Layer1_HasTwoSide)] _Layer1_RampOffset2("第二层Ramp偏移值",Float) = 0.15
        [Space(10)]
        [SubToggle(Layer1,_Layer1_HasSpecular)] _Layer1_HasSpecular("高光?",Float) = 0
        [SubToggleItem(Layer1,_Layer1_HasSpecular)] _Layer1_SpecularExp("高光 曲率",Float) =2
        [SubToggleItem(Layer1,_Layer1_HasSpecular)] _Layer1_SpecularIntensity("高光 强度",Float) =1
        [Space(10)]
        [SubToggle(Layer1,_Layer1_HasStepSpecular)] _Layer1_HasStepSpecular("裁边高光?",Float) = 0
        [SubToggleItem(Layer1,_Layer1_HasStepSpecular)] _Layer1_StepSpecular_Intensity("裁边高光 强度",Float) =1
        [SubToggleItem(Layer1,_Layer1_HasStepSpecular)] _Layer1_StepSpecular_Exp("裁边高光 曲率",Float) =1
        [SubToggleItem(Layer1,_Layer1_HasStepSpecular)] _Layer1_StepSpecular_Width("裁边高光 宽度",Float) =0.1
        [SubToggleEnum(Layer1,_Layer1_HasStepSpecular,NH,NV)] _Layer1_StepSpecularType("裁边高光类型",Float) =0
        [Space(10)]
        [SubToggle(Layer1,_Layer1_HasRim)] _Layer1_HasRim("边缘光?",Float) = 0
        [SubToggleItem(Layer1,_Layer1_HasRim)] _Layer1_Rim_Intensity("边缘光 强度",Float) =1
        [SubToggleItem(Layer1,_Layer1_HasRim)] _Layer1_Rim_Exp ("边缘光 曲率",Float) =1
        [SubToggleItem(Layer1,_Layer1_HasRim)] _Layer1_Rim_Width ("边缘光 宽度",Range(0,1)) =1
        [SubToggleEnum(Layer1,_Layer1_HasRim,Both,BrightSide,DarkSide)] _Layer1_RimType("RimType",Float) =0
        [Space(10)]
        [SubToggle(Layer1,_Layer1_HasViewLight)] _Layer1_HasViewLight("视角光?",Float) = 0
        [SubToggleItem(Layer1,_Layer1_HasViewLight)] _Layer1_ViewLight_Intensity("视角光 强度",Float) =1
        [SubToggleItem(Layer1,_Layer1_HasViewLight)] _Layer1_ViewLight_Exp ("视角光 曲率",Float) =1
        
        //===========================Layer2 ======================================//
        [Main(Layer2)] _Layer2("_Layer2 布料1",Float) = 0
        [SubToggle(Layer2,_Layer2_HasTwoSide)] _Layer2_HasTwoSide("有两层明暗面?",Float) = 0
        [SubToggleItem(Layer2,_Layer2_HasTwoSide)] _Layer2_RampOffset2("第二层Ramp偏移值",Float) = 0.15
        [Space(10)]
        [SubToggle(Layer2,_Layer2_HasSpecular)] _Layer2_HasSpecular("高光?",Float) = 0
        [SubToggleItem(Layer2,_Layer2_HasSpecular)] _Layer2_SpecularExp("高光 曲率",Float) =2
        [SubToggleItem(Layer2,_Layer2_HasSpecular)] _Layer2_SpecularIntensity("高光 强度",Float) =1
        [Space(10)]
        [SubToggle(Layer2,_Layer2_HasStepSpecular)] _Layer2_HasStepSpecular("裁边高光?",Float) = 0
        [SubToggleItem(Layer2,_Layer2_HasStepSpecular)] _Layer2_StepSpecular_Intensity("裁边高光 强度",Float) =1
        [SubToggleItem(Layer2,_Layer2_HasStepSpecular)] _Layer2_StepSpecular_Exp("裁边高光 曲率",Float) =1
        [SubToggleItem(Layer2,_Layer2_HasStepSpecular)] _Layer2_StepSpecular_Width("裁边高光 宽度",Float) =0.1
        [SubToggleEnum(Layer2,_Layer2_HasStepSpecular,NH,NV)] _Layer2_StepSpecularType("裁边高光类型",Float) =0

        [Space(10)]
        [SubToggle(Layer2,_Layer2_HasRim)] _Layer2_HasRim("边缘光?",Float) = 0
        [SubToggleItem(Layer2,_Layer2_HasRim)] _Layer2_Rim_Intensity("边缘光 强度",Float) =1
        [SubToggleItem(Layer2,_Layer2_HasRim)] _Layer2_Rim_Exp ("边缘光 曲率",Float) =1
        [SubToggleItem(Layer2,_Layer2_HasRim)] _Layer2_Rim_Width ("边缘光 宽度",Range(0,1)) =1
        [SubToggleEnum(Layer2,_Layer2_HasRim,Both,BrightSide,DarkSide)] _Layer2_RimType("RimType",Float) =0
        [Space(10)]
        [SubToggle(Layer2,_Layer2_HasViewLight)] _Layer2_HasViewLight("视角光?",Float) = 0
        [SubToggleItem(Layer2,_Layer2_HasViewLight)] _Layer2_ViewLight_Intensity("视角光 强度",Float) =1
        [SubToggleItem(Layer2,_Layer2_HasViewLight)] _Layer2_ViewLight_Exp ("视角光 曲率",Float) =1
        
        //===========================Layer3 ======================================//
        [Main(Layer3)] _Layer3("_Layer3 布料2",Float) = 0
        [SubToggle(Layer3,_Layer3_HasTwoSide)] _Layer3_HasTwoSide("有两层明暗面?",Float) = 0
        [SubToggleItem(Layer3,_Layer3_HasTwoSide)] _Layer3_RampOffset2("第二层Ramp偏移值",Float) = 0.15
        [Space(10)]
        [SubToggle(Layer3,_Layer3_HasSpecular)] _Layer3_HasSpecular("高光?",Float) = 0
        [SubToggleItem(Layer3,_Layer3_HasSpecular)] _Layer3_SpecularExp("高光 曲率",Float) =2
        [SubToggleItem(Layer3,_Layer3_HasSpecular)] _Layer3_SpecularIntensity("高光 强度",Float) =1
        [Space(10)]
        [SubToggle(Layer3,_Layer3_HasStepSpecular)] _Layer3_HasStepSpecular("裁边高光?",Float) = 0
        [SubToggleItem(Layer3,_Layer3_HasStepSpecular)] _Layer3_StepSpecular_Intensity("裁边高光 强度",Float) =1
        [SubToggleItem(Layer3,_Layer3_HasStepSpecular)] _Layer3_StepSpecular_Exp("裁边高光 曲率",Float) =1
        [SubToggleItem(Layer3,_Layer3_HasStepSpecular)] _Layer3_StepSpecular_Width("裁边高光 宽度",Float) =0.1
        [SubToggleEnum(Layer3,_Layer3_HasStepSpecular,NH,NV)] _Layer3_StepSpecularType("裁边高光类型",Float) =0
        [Space(10)]
        [SubToggle(Layer3,_Layer3_HasRim)] _Layer3_HasRim("边缘光?",Float) = 0
        [SubToggleItem(Layer3,_Layer3_HasRim)] _Layer3_Rim_Intensity("边缘光 强度",Float) =1
        [SubToggleItem(Layer3,_Layer3_HasRim)] _Layer3_Rim_Exp ("边缘光 曲率",Float) =1
        [SubToggleItem(Layer3,_Layer3_HasRim)] _Layer3_Rim_Width ("边缘光 宽度",Range(0,1)) =1
        [SubToggleEnum(Layer3,_Layer3_HasRim,Both,BrightSide,DarkSide)] _Layer3_RimType("RimType",Float) =0
        [Space(10)]
        [SubToggle(Layer3,_Layer3_HasViewLight)] _Layer3_HasViewLight("视角光?",Float) = 0
        [SubToggleItem(Layer3,_Layer3_HasViewLight)] _Layer3_ViewLight_Intensity("视角光 强度",Float) =1
        [SubToggleItem(Layer3,_Layer3_HasViewLight)] _Layer3_ViewLight_Exp ("视角光 曲率",Float) =1
        
        //===========================Layer4 ======================================//
        [Main(Layer4)] _Layer4("_Layer4 布料3",Float) = 0
        [SubToggle(Layer4,_Layer4_HasTwoSide)] _Layer4_HasTwoSide("有两层明暗面?",Float) = 0
        [SubToggleItem(Layer4,_Layer4_HasTwoSide)] _Layer4_RampOffset2("第二层Ramp偏移值",Float) = 0.15
        [Space(10)]
        [SubToggle(Layer4,_Layer4_HasSpecular)] _Layer4_HasSpecular("高光?",Float) = 0
        [SubToggleItem(Layer4,_Layer4_HasSpecular)] _Layer4_SpecularExp("高光 曲率",Float) =2
        [SubToggleItem(Layer4,_Layer4_HasSpecular)] _Layer4_SpecularIntensity("高光 强度",Float) =1
        [Space(10)]
        [SubToggle(Layer4,_Layer4_HasStepSpecular)] _Layer4_HasStepSpecular("裁边高光?",Float) = 0
        [SubToggleItem(Layer4,_Layer4_HasStepSpecular)] _Layer4_StepSpecular_Intensity("裁边高光 强度",Float) =1
        [SubToggleItem(Layer4,_Layer4_HasStepSpecular)] _Layer4_StepSpecular_Exp("裁边高光 曲率",Float) =1
        [SubToggleItem(Layer4,_Layer4_HasStepSpecular)] _Layer4_StepSpecular_Width("裁边高光 宽度",Float) =0.1
        [SubToggleEnum(Layer4,_Layer4_HasStepSpecular,NH,NV)] _Layer4_StepSpecularType("裁边高光类型",Float) =0
        [Space(10)]
        [SubToggle(Layer4,_Layer4_HasRim)] _Layer4_HasRim("边缘光?",Float) = 0
        [SubToggleItem(Layer4,_Layer4_HasRim)] _Layer4_Rim_Intensity("边缘光 强度",Float) =1
        [SubToggleItem(Layer4,_Layer4_HasRim)] _Layer4_Rim_Exp ("边缘光 曲率",Float) =1
        [SubToggleItem(Layer4,_Layer4_HasRim)] _Layer4_Rim_Width ("边缘光 宽度",Range(0,1)) =1
        [SubToggleEnum(Layer4,_Layer4_HasRim,Both,BrightSide,DarkSide)] _Layer4_RimType("RimType",Float) =0
        [Space(10)]
        [SubToggle(Layer4,_Layer4_HasViewLight)] _Layer4_HasViewLight("视角光?",Float) = 0
        [SubToggleItem(Layer4,_Layer4_HasViewLight)] _Layer4_ViewLight_Intensity("视角光 强度",Float) =1
        [SubToggleItem(Layer4,_Layer4_HasViewLight)] _Layer4_ViewLight_Exp ("视角光 曲率",Float) =1
        
        //===========================Layer5 ======================================//
        [Main(Layer5)] _Layer5("_Layer5 皮革1",Float) = 0
        [SubToggle(Layer5,_Layer5_HasTwoSide)] _Layer5_HasTwoSide("有两层明暗面?",Float) = 0
        [SubToggleItem(Layer5,_Layer5_HasTwoSide)] _Layer5_RampOffset2("第二层Ramp偏移值",Float) = 0.15
        [Space(10)]
        [SubToggle(Layer5,_Layer5_HasSpecular)] _Layer5_HasSpecular("高光?",Float) = 0
        [SubToggleItem(Layer5,_Layer5_HasSpecular)] _Layer5_SpecularExp("高光 曲率",Float) =2
        [SubToggleItem(Layer5,_Layer5_HasSpecular)] _Layer5_SpecularIntensity("高光 强度",Float) =1
        [Space(10)]
        [SubToggle(Layer5,_Layer5_HasStepSpecular)] _Layer5_HasStepSpecular("裁边高光?",Float) = 0
        [SubToggleItem(Layer5,_Layer5_HasStepSpecular)] _Layer5_StepSpecular_Intensity("裁边高光 强度",Float) =1
        [SubToggleItem(Layer5,_Layer5_HasStepSpecular)] _Layer5_StepSpecular_Exp("裁边高光 曲率",Float) =1
        [SubToggleItem(Layer5,_Layer5_HasStepSpecular)] _Layer5_StepSpecular_Width("裁边高光 宽度",Float) =0.1
        [SubToggleEnum(Layer5,_Layer5_HasStepSpecular,NH,NV)] _Layer5_StepSpecularType("裁边高光类型",Float) =0
        [Space(10)]
        [SubToggle(Layer5,_Layer5_HasRim)] _Layer5_HasRim("边缘光?",Float) = 0
        [SubToggleItem(Layer5,_Layer5_HasRim)] _Layer5_Rim_Intensity("边缘光 强度",Float) =1
        [SubToggleItem(Layer5,_Layer5_HasRim)] _Layer5_Rim_Exp ("边缘光 曲率",Float) =1
        [SubToggleItem(Layer5,_Layer5_HasRim)] _Layer5_Rim_Width ("边缘光 宽度",Range(0,1)) =1
        [SubToggleEnum(Layer5,_Layer5_HasRim,Both,BrightSide,DarkSide)] _Layer5_RimType("RimType",Float) =0

        [Space(10)]
        [SubToggle(Layer5,_Layer5_HasViewLight)] _Layer5_HasViewLight("视角光?",Float) = 0
        [SubToggleItem(Layer5,_Layer5_HasViewLight)] _Layer5_ViewLight_Intensity("视角光 强度",Float) =1
        [SubToggleItem(Layer5,_Layer5_HasViewLight)] _Layer5_ViewLight_Exp ("视角光 曲率",Float) =1
        
        //===========================Layer6 ======================================//
        [Main(Layer6)] _Layer6("_Layer6 皮革2",Float) = 0
        [SubToggle(Layer6,_Layer6_HasTwoSide)] _Layer6_HasTwoSide("有两层明暗面?",Float) = 0
        [SubToggleItem(Layer6,_Layer6_HasTwoSide)] _Layer6_RampOffset2("第二层Ramp偏移值",Float) = 0.15
        [Space(10)]
        [SubToggle(Layer6,_Layer6_HasSpecular)] _Layer6_HasSpecular("高光?",Float) = 0
        [SubToggleItem(Layer6,_Layer6_HasSpecular)] _Layer6_SpecularExp("高光 曲率",Float) =2
        [SubToggleItem(Layer6,_Layer6_HasSpecular)] _Layer6_SpecularIntensity("高光 强度",Float) =1
        [Space(10)]
        [SubToggle(Layer6,_Layer6_HasStepSpecular)] _Layer6_HasStepSpecular("裁边高光?",Float) = 0
        [SubToggleItem(Layer6,_Layer6_HasStepSpecular)] _Layer6_StepSpecular_Intensity("裁边高光 强度",Float) =1
        [SubToggleItem(Layer6,_Layer6_HasStepSpecular)] _Layer6_StepSpecular_Exp("裁边高光 曲率",Float) =1
        [SubToggleItem(Layer6,_Layer6_HasStepSpecular)] _Layer6_StepSpecular_Width("裁边高光 宽度",Float) =0.1
        [SubToggleEnum(Layer6,_Layer6_HasStepSpecular,NH,NV)] _Layer6_StepSpecularType("裁边高光类型",Float) =0
        [Space(10)]
        [SubToggle(Layer6,_Layer6_HasRim)] _Layer6_HasRim("边缘光?",Float) = 0
        [SubToggleItem(Layer6,_Layer6_HasRim)] _Layer6_Rim_Intensity("边缘光 强度",Float) =1
        [SubToggleItem(Layer6,_Layer6_HasRim)] _Layer6_Rim_Exp ("边缘光 曲率",Float) =1
        [SubToggleItem(Layer6,_Layer6_HasRim)] _Layer6_Rim_Width ("边缘光 宽度",Range(0,1)) =1
        [SubToggleEnum(Layer6,_Layer6_HasRim,Both,BrightSide,DarkSide)] _Layer6_RimType("RimType",Float) =0

        [Space(10)]
        [SubToggle(Layer6,_Layer6_HasViewLight)] _Layer6_HasViewLight("视角光?",Float) = 0
        [SubToggleItem(Layer6,_Layer6_HasViewLight)] _Layer6_ViewLight_Intensity("视角光 强度",Float) =1
        [SubToggleItem(Layer6,_Layer6_HasViewLight)] _Layer6_ViewLight_Exp ("视角光 曲率",Float) =1
        
        //===========================Layer7 ======================================//
        [Main(Layer7)] _Layer7("_Layer7 皮革3",Float) = 0
        [SubToggle(Layer7,_Layer7_HasTwoSide)] _Layer7_HasTwoSide("有两层明暗面?",Float) = 0
        [SubToggleItem(Layer7,_Layer7_HasTwoSide)] _Layer7_RampOffset2("第二层Ramp偏移值",Float) = 0.15
        [Space(10)]
        [SubToggle(Layer7,_Layer7_HasSpecular)] _Layer7_HasSpecular("高光?",Float) = 0
        [SubToggleItem(Layer7,_Layer7_HasSpecular)] _Layer7_SpecularExp("高光 曲率",Float) =2
        [SubToggleItem(Layer7,_Layer7_HasSpecular)] _Layer7_SpecularIntensity("高光 强度",Float) =1
        [Space(10)]
        [SubToggle(Layer7,_Layer7_HasStepSpecular)] _Layer7_HasStepSpecular("裁边高光?",Float) = 0
        [SubToggleItem(Layer7,_Layer7_HasStepSpecular)] _Layer7_StepSpecular_Intensity("裁边高光 强度",Float) =1
        [SubToggleItem(Layer7,_Layer7_HasStepSpecular)] _Layer7_StepSpecular_Exp("裁边高光 曲率",Float) =1
        [SubToggleItem(Layer7,_Layer7_HasStepSpecular)] _Layer7_StepSpecular_Width("裁边高光 宽度",Float) =0.1
        [SubToggleEnum(Layer7,_Layer7_HasStepSpecular,NH,NV)] _Layer7_StepSpecularType("裁边高光类型",Float) =0
        [Space(10)]
        [SubToggle(Layer7,_Layer7_HasRim)] _Layer7_HasRim("边缘光?",Float) = 0
        [SubToggleItem(Layer7,_Layer7_HasRim)] _Layer7_Rim_Intensity("边缘光 强度",Float) =1
        [SubToggleItem(Layer7,_Layer7_HasRim)] _Layer7_Rim_Exp ("边缘光 曲率",Float) =1
        [SubToggleItem(Layer7,_Layer7_HasRim)] _Layer7_Rim_Width ("边缘光 宽度",Range(0,1)) =1
        [SubToggleEnum(Layer7,_Layer7_HasRim,Both,BrightSide,DarkSide)] _Layer7_RimType("RimType",Float) =0

        [Space(10)]
        [SubToggle(Layer7,_Layer7_HasViewLight)] _Layer7_HasViewLight("视角光?",Float) = 0
        [SubToggleItem(Layer7,_Layer7_HasViewLight)] _Layer7_ViewLight_Intensity("视角光 强度",Float) =1
        [SubToggleItem(Layer7,_Layer7_HasViewLight)] _Layer7_ViewLight_Exp ("视角光 曲率",Float) =1
        
        //===========================Layer8 ======================================//
        [Main(Layer8)] _Layer8("_Layer8 金属1",Float) = 0
        [SubToggle(Layer8,_Layer8_HasTwoSide)] _Layer8_HasTwoSide("有两层明暗面?",Float) = 0
        [SubToggleItem(Layer8,_Layer8_HasTwoSide)] _Layer8_RampOffset2("第二层Ramp偏移值",Float) = 0.15
        [Space(10)]
        [SubToggle(Layer8,_Layer8_HasSpecular)] _Layer8_HasSpecular("高光?",Float) = 0
        [SubToggleItem(Layer8,_Layer8_HasSpecular)] _Layer8_SpecularExp("高光 曲率",Float) =2
        [SubToggleItem(Layer8,_Layer8_HasSpecular)] _Layer8_SpecularIntensity("高光 强度",Float) =1
        [Space(10)]
        [SubToggle(Layer8,_Layer8_HasStepSpecular)] _Layer8_HasStepSpecular("裁边高光?",Float) = 0
        [SubToggleItem(Layer8,_Layer8_HasStepSpecular)] _Layer8_StepSpecular_Intensity("裁边高光 强度",Float) =1
        [SubToggleItem(Layer8,_Layer8_HasStepSpecular)] _Layer8_StepSpecular_Exp("裁边高光 曲率",Float) =1
        [SubToggleItem(Layer8,_Layer8_HasStepSpecular)] _Layer8_StepSpecular_Width("裁边高光 宽度",Float) =0.1
        [SubToggleEnum(Layer8,_Layer8_HasStepSpecular,NH,NV)] _Layer8_StepSpecularType("裁边高光类型",Float) =0
        [Space(10)]
        [SubToggle(Layer8,_Layer8_HasRim)] _Layer8_HasRim("边缘光?",Float) = 0
        [SubToggleItem(Layer8,_Layer8_HasRim)] _Layer8_Rim_Intensity("边缘光 强度",Float) =1
        [SubToggleItem(Layer8,_Layer8_HasRim)] _Layer8_Rim_Exp ("边缘光 曲率",Float) =1
        [SubToggleItem(Layer8,_Layer8_HasRim)] _Layer8_Rim_Width ("边缘光 宽度",Range(0,1)) =1
        [SubToggleEnum(Layer8,_Layer8_HasRim,Both,BrightSide,DarkSide)] _Layer8_RimType("RimType",Float) =0

        [Space(10)]
        [SubToggle(Layer8,_Layer8_HasViewLight)] _Layer8_HasViewLight("视角光?",Float) = 0
        [SubToggleItem(Layer8,_Layer8_HasViewLight)] _Layer8_ViewLight_Intensity("视角光 强度",Float) =1
        [SubToggleItem(Layer8,_Layer8_HasViewLight)] _Layer8_ViewLight_Exp ("视角光 曲率",Float) =1
        //===========================Layer9 ======================================//
        [Main(Layer9)] _Layer9("_Layer9 金属2",Float) = 0
        [SubToggle(Layer9,_Layer9_HasTwoSide)] _Layer9_HasTwoSide("有两层明暗面?",Float) = 0
        [SubToggleItem(Layer9,_Layer9_HasTwoSide)] _Layer9_RampOffset2("第二层Ramp偏移值",Float) = 0.15
        [Space(10)]
        [SubToggle(Layer9,_Layer9_HasSpecular)] _Layer9_HasSpecular("高光?",Float) = 0
        [SubToggleItem(Layer9,_Layer9_HasSpecular)] _Layer9_SpecularExp("高光 曲率",Float) =2
        [SubToggleItem(Layer9,_Layer9_HasSpecular)] _Layer9_SpecularIntensity("高光 强度",Float) =1
        [Space(10)]
        [SubToggle(Layer9,_Layer9_HasStepSpecular)] _Layer9_HasStepSpecular("裁边高光?",Float) = 0
        [SubToggleItem(Layer9,_Layer9_HasStepSpecular)] _Layer9_StepSpecular_Intensity("裁边高光 强度",Float) =1
        [SubToggleItem(Layer9,_Layer9_HasStepSpecular)] _Layer9_StepSpecular_Exp("裁边高光 曲率",Float) =1
        [SubToggleItem(Layer9,_Layer9_HasStepSpecular)] _Layer9_StepSpecular_Width("裁边高光 宽度",Float) =0.1
        [SubToggleEnum(Layer9,_Layer9_HasStepSpecular,NH,NV)] _Layer9_StepSpecularType("裁边高光类型",Float) =0
        [Space(10)]
        [SubToggle(Layer9,_Layer9_HasRim)] _Layer9_HasRim("边缘光?",Float) = 0
        [SubToggleItem(Layer9,_Layer9_HasRim)] _Layer9_Rim_Intensity("边缘光 强度",Float) =1
        [SubToggleItem(Layer9,_Layer9_HasRim)] _Layer9_Rim_Exp ("边缘光 曲率",Float) =1
        [SubToggleItem(Layer9,_Layer9_HasRim)] _Layer9_Rim_Width ("边缘光 宽度",Range(0,1)) =1
        [SubToggleEnum(Layer9,_Layer9_HasRim,Both,BrightSide,DarkSide)] _Layer9_RimType("RimType",Float) =0

        [Space(10)]
        [SubToggle(Layer9,_Layer9_HasViewLight)] _Layer9_HasViewLight("视角光?",Float) = 0
        [SubToggleItem(Layer9,_Layer9_HasViewLight)] _Layer9_ViewLight_Intensity("视角光 强度",Float) =1
        [SubToggleItem(Layer9,_Layer9_HasViewLight)] _Layer9_ViewLight_Exp ("视角光 曲率",Float) =1
        //===========================Layer10 ======================================//
        [Main(Layer10)] _Layer10("_Layer10 金属3",Float) = 0
        [SubToggle(Layer10,_Layer10_HasTwoSide)] _Layer10_HasTwoSide("有两层明暗面?",Float) = 0
        [SubToggleItem(Layer10,_Layer10_HasTwoSide)] _Layer10_RampOffset2("第二层Ramp偏移值",Float) = 0.15
        [Space(10)]
        [SubToggle(Layer10,_Layer10_HasSpecular)] _Layer10_HasSpecular("高光?",Float) = 0
        [SubToggleItem(Layer10,_Layer10_HasSpecular)] _Layer10_SpecularExp("高光 曲率",Float) =2
        [SubToggleItem(Layer10,_Layer10_HasSpecular)] _Layer10_SpecularIntensity("高光 强度",Float) =1
        [Space(10)]
        [SubToggle(Layer10,_Layer10_HasStepSpecular)] _Layer10_HasStepSpecular("裁边高光?",Float) = 0
        [SubToggleItem(Layer10,_Layer10_HasStepSpecular)] _Layer10_StepSpecular_Intensity("裁边高光 强度",Float) =1
        [SubToggleItem(Layer10,_Layer10_HasStepSpecular)] _Layer10_StepSpecular_Exp("裁边高光 曲率",Float) =1
        [SubToggleItem(Layer10,_Layer10_HasStepSpecular)] _Layer10_StepSpecular_Width("裁边高光 宽度",Float) =0.1
        [SubToggleEnum(Layer10,_Layer10_HasStepSpecular,NH,NV)] _Layer10_StepSpecularType("裁边高光类型",Float) =0
        [Space(10)]
        [SubToggle(Layer10,_Layer10_HasRim)] _Layer10_HasRim("边缘光?",Float) = 0
        [SubToggleItem(Layer10,_Layer10_HasRim)] _Layer10_Rim_Intensity("边缘光 强度",Float) =1
        [SubToggleItem(Layer10,_Layer10_HasRim)] _Layer10_Rim_Exp ("边缘光 曲率",Float) =1
        [SubToggleItem(Layer10,_Layer10_HasRim)] _Layer10_Rim_Width ("边缘光 宽度",Range(0,1)) =1
        [SubToggleEnum(Layer10,_Layer10_HasRim,Both,BrightSide,DarkSide)] _Layer10_RimType("RimType",Float) =0

        [Space(10)]
        [SubToggle(Layer10,_Layer10_HasViewLight)] _Layer10_HasViewLight("视角光?",Float) = 0
        [SubToggleItem(Layer10,_Layer10_HasViewLight)] _Layer10_ViewLight_Intensity("视角光 强度",Float) =1
        [SubToggleItem(Layer10,_Layer10_HasViewLight)] _Layer10_ViewLight_Exp ("视角光 曲率",Float) =1
        
        //===========================Layer11 ======================================//
        [Main(Layer11)] _Layer11("_Layer11 金属4",Float) = 0
        [SubToggle(Layer11,_Layer11_HasTwoSide)] _Layer11_HasTwoSide("有两层明暗面?",Float) = 0
        [SubToggleItem(Layer11,_Layer11_HasTwoSide)] _Layer11_RampOffset2("第二层Ramp偏移值",Float) = 0.15
        [Space(10)]
        [SubToggle(Layer11,_Layer11_HasSpecular)] _Layer11_HasSpecular("高光?",Float) = 0
        [SubToggleItem(Layer11,_Layer11_HasSpecular)] _Layer11_SpecularExp("高光 曲率",Float) =2
        [SubToggleItem(Layer11,_Layer11_HasSpecular)] _Layer11_SpecularIntensity("高光 强度",Float) =1
        [Space(10)]
        [SubToggle(Layer11,_Layer11_HasStepSpecular)] _Layer11_HasStepSpecular("裁边高光?",Float) = 0
        [SubToggleItem(Layer11,_Layer11_HasStepSpecular)] _Layer11_StepSpecular_Intensity("裁边高光 强度",Float) =1
        [SubToggleItem(Layer11,_Layer11_HasStepSpecular)] _Layer11_StepSpecular_Exp("裁边高光 曲率",Float) =1
        [SubToggleItem(Layer11,_Layer11_HasStepSpecular)] _Layer11_StepSpecular_Width("裁边高光 宽度",Float) =0.1
        [SubToggleEnum(Layer11,_Layer11_HasStepSpecular,NH,NV)] _Layer11_StepSpecularType("裁边高光类型",Float) =0
        [Space(10)]
        [SubToggle(Layer11,_Layer11_HasRim)] _Layer11_HasRim("边缘光?",Float) = 0
        [SubToggleItem(Layer11,_Layer11_HasRim)] _Layer11_Rim_Intensity("边缘光 强度",Float) =1
        [SubToggleItem(Layer11,_Layer11_HasRim)] _Layer11_Rim_Exp ("边缘光 曲率",Float) =1
        [SubToggleItem(Layer11,_Layer11_HasRim)] _Layer11_Rim_Width ("边缘光 宽度",Range(0,1)) =1
        [SubToggleEnum(Layer11,_Layer11_HasRim,Both,BrightSide,DarkSide)] _Layer11_RimType("RimType",Float) =0

        [Space(10)]
        [SubToggle(Layer11,_Layer11_HasViewLight)] _Layer11_HasViewLight("视角光?",Float) = 0
        [SubToggleItem(Layer11,_Layer11_HasViewLight)] _Layer11_ViewLight_Intensity("视角光 强度",Float) =1
        [SubToggleItem(Layer11,_Layer11_HasViewLight)] _Layer11_ViewLight_Exp ("视角光 曲率",Float) =1
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque" "LightMode"="ForwardBase" "Queue" = "Geometry"
        }
        
        
        UsePass "NPR/OutLine/TANGENT"
        
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

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
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 tangent : TEXCOORD1;
                float3 bitangent : TEXCOORD2;
                float3 normal : TEXCOORD3;
                float3 worldPosition : TEXCOORD4;
                float3 localPosition : TEXCOORD5;
                float3 localNormal : TEXCOORD6;
                float4 vertexColor : TEXCOORD7;
                float2 uv2 : TEXCOORD8;
                LIGHTING_COORDS(9, 10)
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.uv2 = v.uv2;
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.worldPosition = mul(unity_ObjectToWorld, v.vertex);
                o.localPosition = v.vertex.xyz;
                o.tangent = UnityObjectToWorldDir(v.tangent);
                o.bitangent = cross(o.normal, o.tangent) * v.tangent.w;
                o.localNormal = v.normal;
                o.vertexColor = v.vertexColor;
                TRANSFER_VERTEX_TO_FRAGMENT(o);

                return o;
            }

            #pragma shader_feature DebugMode
            int _TestMode,_TestModeLayer;
            float _LayerStep;
            //通用参数
            sampler2D _MainTex, _ShadowMap, _LightMap, _DecalMap;
            float _LightThreshold, _RampOffset,_BrightIntensity, _DarkIntensity,_DecalLerp;

            
///=================================================================//
///每层参数
///=================================================================//

//===========================Layer1 ======================================//
            bool _Layer1_HasTwoSide,_Layer1_HasSpecular,_Layer1_HasStepSpecular,_Layer1_HasRim,_Layer1_HasViewLight;
            float _Layer1_RampOffset2,_Layer1_SpecularExp,_Layer1_SpecularIntensity,_Layer1_StepSpecular_Intensity,_Layer1_StepSpecular_Exp,_Layer1_StepSpecular_Width,_Layer1_Rim_Intensity,_Layer1_Rim_Exp,_Layer1_Rim_Width,_Layer1_ViewLight_Intensity,_Layer1_ViewLight_Exp;
//===========================Layer2 ======================================//
            bool _Layer2_HasTwoSide,_Layer2_HasSpecular,_Layer2_HasStepSpecular,_Layer2_HasRim,_Layer2_HasViewLight;
            float _Layer2_RampOffset2,_Layer2_SpecularExp,_Layer2_SpecularIntensity,_Layer2_StepSpecular_Intensity,_Layer2_StepSpecular_Exp,_Layer2_StepSpecular_Width,_Layer2_Rim_Intensity,_Layer2_Rim_Exp,_Layer2_Rim_Width,_Layer2_ViewLight_Intensity,_Layer2_ViewLight_Exp;
//===========================Layer3 ======================================//
            bool _Layer3_HasTwoSide,_Layer3_HasSpecular,_Layer3_HasStepSpecular,_Layer3_HasRim,_Layer3_HasViewLight;
            float _Layer3_RampOffset2,_Layer3_SpecularExp,_Layer3_SpecularIntensity,_Layer3_StepSpecular_Intensity,_Layer3_StepSpecular_Exp,_Layer3_StepSpecular_Width,_Layer3_Rim_Intensity,_Layer3_Rim_Exp,_Layer3_Rim_Width,_Layer3_ViewLight_Intensity,_Layer3_ViewLight_Exp;
//===========================Layer4 ======================================//
            bool _Layer4_HasTwoSide,_Layer4_HasSpecular,_Layer4_HasStepSpecular,_Layer4_HasRim,_Layer4_HasViewLight;
            float _Layer4_RampOffset2,_Layer4_SpecularExp,_Layer4_SpecularIntensity,_Layer4_StepSpecular_Intensity,_Layer4_StepSpecular_Exp,_Layer4_StepSpecular_Width,_Layer4_Rim_Intensity,_Layer4_Rim_Exp,_Layer4_Rim_Width,_Layer4_ViewLight_Intensity,_Layer4_ViewLight_Exp;
//===========================Layer5 ======================================//
            bool _Layer5_HasTwoSide,_Layer5_HasSpecular,_Layer5_HasStepSpecular,_Layer5_HasRim,_Layer5_HasViewLight;
            float _Layer5_RampOffset2,_Layer5_SpecularExp,_Layer5_SpecularIntensity,_Layer5_StepSpecular_Intensity,_Layer5_StepSpecular_Exp,_Layer5_StepSpecular_Width,_Layer5_Rim_Intensity,_Layer5_Rim_Exp,_Layer5_Rim_Width,_Layer5_ViewLight_Intensity,_Layer5_ViewLight_Exp;
//===========================Layer6 ======================================//
            bool _Layer6_HasTwoSide,_Layer6_HasSpecular,_Layer6_HasStepSpecular,_Layer6_HasRim,_Layer6_HasViewLight;
            float _Layer6_RampOffset2,_Layer6_SpecularExp,_Layer6_SpecularIntensity,_Layer6_StepSpecular_Intensity,_Layer6_StepSpecular_Exp,_Layer6_StepSpecular_Width,_Layer6_Rim_Intensity,_Layer6_Rim_Exp,_Layer6_Rim_Width,_Layer6_ViewLight_Intensity,_Layer6_ViewLight_Exp;
//===========================Layer7 ======================================//
            bool _Layer7_HasTwoSide,_Layer7_HasSpecular,_Layer7_HasStepSpecular,_Layer7_HasRim,_Layer7_HasViewLight;
            float _Layer7_RampOffset2,_Layer7_SpecularExp,_Layer7_SpecularIntensity,_Layer7_StepSpecular_Intensity,_Layer7_StepSpecular_Exp,_Layer7_StepSpecular_Width,_Layer7_Rim_Intensity,_Layer7_Rim_Exp,_Layer7_Rim_Width,_Layer7_ViewLight_Intensity,_Layer7_ViewLight_Exp;
//===========================Layer8 ======================================//
            bool _Layer8_HasTwoSide,_Layer8_HasSpecular,_Layer8_HasStepSpecular,_Layer8_HasRim,_Layer8_HasViewLight;
            float _Layer8_RampOffset2,_Layer8_SpecularExp,_Layer8_SpecularIntensity,_Layer8_StepSpecular_Intensity,_Layer8_StepSpecular_Exp,_Layer8_StepSpecular_Width,_Layer8_Rim_Intensity,_Layer8_Rim_Exp,_Layer8_Rim_Width,_Layer8_ViewLight_Intensity,_Layer8_ViewLight_Exp;
//===========================Layer9 ======================================//
            bool _Layer9_HasTwoSide,_Layer9_HasSpecular,_Layer9_HasStepSpecular,_Layer9_HasRim,_Layer9_HasViewLight;
            float _Layer9_RampOffset2,_Layer9_SpecularExp,_Layer9_SpecularIntensity,_Layer9_StepSpecular_Intensity,_Layer9_StepSpecular_Exp,_Layer9_StepSpecular_Width,_Layer9_Rim_Intensity,_Layer9_Rim_Exp,_Layer9_Rim_Width,_Layer9_ViewLight_Intensity,_Layer9_ViewLight_Exp;
//===========================Layer10 ======================================//
            bool _Layer10_HasTwoSide,_Layer10_HasSpecular,_Layer10_HasStepSpecular,_Layer10_HasRim,_Layer10_HasViewLight;
            float _Layer10_RampOffset2,_Layer10_SpecularExp,_Layer10_SpecularIntensity,_Layer10_StepSpecular_Intensity,_Layer10_StepSpecular_Exp,_Layer10_StepSpecular_Width,_Layer10_Rim_Intensity,_Layer10_Rim_Exp,_Layer10_Rim_Width,_Layer10_ViewLight_Intensity,_Layer10_ViewLight_Exp;
//===========================Layer11 ======================================//
            bool _Layer11_HasTwoSide,_Layer11_HasSpecular,_Layer11_HasStepSpecular,_Layer11_HasRim,_Layer11_HasViewLight;
            float _Layer11_RampOffset2,_Layer11_SpecularExp,_Layer11_SpecularIntensity,_Layer11_StepSpecular_Intensity,_Layer11_StepSpecular_Exp,_Layer11_StepSpecular_Width,_Layer11_Rim_Intensity,_Layer11_Rim_Exp,_Layer11_Rim_Width,_Layer11_ViewLight_Intensity,_Layer11_ViewLight_Exp;

//===========================补充参数 ======================================//
            float _Layer1_RimType,_Layer2_RimType,_Layer3_RimType,_Layer4_RimType,_Layer5_RimType,_Layer6_RimType,_Layer7_RimType,_Layer8_RimType,_Layer9_RimType,_Layer10_RimType,_Layer11_RimType;
            float _Layer1_StepSpecularType,_Layer2_StepSpecularType,_Layer3_StepSpecularType,_Layer4_StepSpecularType,_Layer5_StepSpecularType,_Layer6_StepSpecularType,_Layer7_StepSpecularType,_Layer8_StepSpecularType,_Layer9_StepSpecularType,_Layer10_StepSpecularType,_Layer11_StepSpecularType;
            
            struct NPRData
            {
                //每层不一样的参数
                bool HasTwoSide,HasRim,HasSpecular,HasStepSpecular,HasViewLight;
                float SpecularExp,SpecularIntensity,StepSpecular_Intensity,StepSpecular_Exp,StepSpecular_Width,Rim_Intensity,Rim_Exp,Rim_Width,ViewLight_Intensity,ViewLight_Exp,RampOffset2,RimType,StepSpecularType;
                //每层通用参数
                float3 BaseMap,ShadowMap;
                float ShadowMask, RampOffsetMask, SpecularIntensityMask, SpecularExpMask , HalfLambert, NH, NV,NL;
            };

            //两层明暗面 裁边边缘光 高光 高光 裁边高光 
            float3 NPRLighting(in NPRData nprData)
            {
                float stepValue = 0;
                float3 Final =0;

                float3 DarkSide = nprData.ShadowMap * _DarkIntensity;
                float3 BrightSide = nprData.BaseMap * _BrightIntensity;

                //边缘光
                if(nprData.HasRim)
                {
                    float RimType = nprData.RimType; //0:两边 1:亮部 2:暗部
                    bool BothSideRim = RimType == 0;
                    bool OnlyBrightSideRim = RimType == 1;
                    bool OnlyDarkSideRim = RimType == 2;
                    
                    float3 Rim = pow(step(1-nprData.Rim_Width, 1 - nprData.NV), nprData.Rim_Exp) * nprData.Rim_Intensity*nprData.ShadowMask;

                    if(BothSideRim) Final += Rim*nprData.BaseMap;
                    if(OnlyBrightSideRim) BrightSide += Rim*nprData.BaseMap;
                    if(OnlyDarkSideRim) DarkSide += Rim*nprData.BaseMap;
                    
                    // Final += Rim*nprData.BaseMap;
                }

                //代码可优化，但为了直观易读性 省略这一步
                //漫反射
                if (nprData.HasTwoSide)
                {
                    if (_LightThreshold < nprData.ShadowMask * (nprData.HalfLambert + _RampOffset +  nprData.RampOffset2 + nprData.RampOffsetMask))
                    {
                        stepValue = 0.5;
                    }
                }
                
                if (_LightThreshold < nprData.ShadowMask * (nprData.HalfLambert + _RampOffset + 0 + nprData.RampOffsetMask))
                {
                    stepValue = 1;
                }

                if (nprData.HasViewLight)
                {
                    float3 ViewLight = saturate( pow(saturate(nprData.NV), nprData.ViewLight_Exp) * nprData.ViewLight_Intensity);
                    BrightSide *= ViewLight;
                    DarkSide *= ViewLight;
                }
                
                float3 Diffuse = lerp(DarkSide, BrightSide, saturate(stepValue));
                Final+=Diffuse;
                
                float3 FinalSpecular =0;
                //高光
                if(nprData.HasSpecular)
                {
                    float3 Specular = max(0, pow((nprData.NH), nprData.SpecularExp * nprData.SpecularExpMask) * nprData.SpecularIntensity * nprData.SpecularIntensityMask);
                    FinalSpecular += Specular*nprData.BaseMap;
                    // Final += Specular;
                }
                //无边高光
                if(nprData.HasStepSpecular)
                {
                    float stepSpecularTypeValue = nprData.StepSpecularType ==0 ? nprData.NH:nprData.NV;
                    float3 StepSpecular = step(1 - nprData.StepSpecular_Width, pow(stepSpecularTypeValue, nprData.StepSpecular_Exp)) * nprData.StepSpecular_Intensity;// * nprData.SpecularIntensityMask;
                    FinalSpecular = max(FinalSpecular,  StepSpecular* Diffuse);//两部亮一点 暗部暗一点
                    // Final += StepSpecular;
                }
                Final += FinalSpecular;
                
                return Final;
            }

            float4 frag(v2f i) : SV_Target
            {
                float3 T = normalize(i.tangent);
                // float3 N = normalize(i.normal);
                float3 N = T;
                //float3 B = normalize( cross(N,T));
                float3 B = normalize(i.bitangent);
                float3 L = normalize(UnityWorldSpaceLightDir(i.worldPosition.xyz));
                float3 V = normalize(UnityWorldSpaceViewDir(i.worldPosition.xyz));
                float3 H = normalize(V + L);
                float2 uv = i.uv;
                float2 uv2 = i.uv2;

                // return float4(uv2,0,0);
                float4 VertexColor = i.vertexColor;
                // return vertexColor.xyzz;
                float HV = dot(H, V);
                float NV = dot(N, V);
                float NL = dot(N, L); //tanget 是平滑后的法线
                float NH = dot(N, H);

                float4 BaseMap      = tex2D(_MainTex, uv);
                float4 ShadowMap    = tex2D(_ShadowMap, uv);
                float4 LightMap     = tex2D(_LightMap, uv);
                float4 DecalMap     = tex2D(_DecalMap, uv);

                float SpecularExpMask = LightMap.r; //高光曲率
                float RampOffsetMask = LightMap.g; //Ramp偏移值,值越大的区域 越容易"感光"(在一个特定的角度，偏移光照明暗)
                float SpecularIntensityMask = LightMap.b; //高光强度Mask
                float InnerLine = LightMap.a; //内勾线

                float ShadowMask = VertexColor.b; //常暗区域,不管光照如何移动，这部分处于暗部

                float Layer = BaseMap.a;
                float HalfLambert = NL * 0.5 + 0.5;

                BaseMap.rgb = lerp(BaseMap.rgb, DecalMap * BaseMap.rgb, _DecalLerp)*InnerLine;
                ShadowMap.rgb = lerp(ShadowMap.rgb, DecalMap * ShadowMap.rgb, _DecalLerp)*InnerLine;
                
                #ifdef DebugMode
                {
                    int mode = 1;
                    BaseMap*=10;//高亮显示
                    if (_TestMode == mode++)
                        return tex2D(_MainTex, uv).xyzz; //BaseColor
                    if (_TestMode == mode++)
                        return lerp(ShadowMap, BaseMap, step(_LayerStep, BaseMap.a)); //test layer
                    if (_TestMode == mode++)
                        return  tex2D(_MainTex, uv).a; //BaseMap.a
                    if (_TestMode == mode++)
                        return tex2D(_ShadowMap, uv); //阴影 Mask
                    if (_TestMode == mode++)
                        return LightMap.r;
                    if (_TestMode == mode++)
                        return LightMap.g; //阴影 Mask
                    if (_TestMode == mode++)
                        return LightMap.b; //漫反射 Mask
                    if (_TestMode == mode++)
                        return LightMap.a; //漫反射 Mask
                    if (_TestMode == mode++)
                        return float4(uv, 0, 0); //uv
                    if (_TestMode == mode++)
                        return float4(uv2, 0, 0); //uv2
                    if (_TestMode == mode++)
                        return VertexColor.r; //vertexColor.r
                    if (_TestMode == mode++)
                        return VertexColor.g; //vertexColor.g
                    if (_TestMode == mode++)
                        return VertexColor.b; //vertexColor.b
                    if (_TestMode == mode++)
                        return VertexColor.a; //vertexColor.a
                    if (_TestMode == mode++)
                        return N.xyzz;        //Normal
                    if (_TestMode == mode++)
                        return i.tangent.xyzz; //Tangent
                    if (_TestMode == mode++)
                        return tex2D(_DecalMap,i.uv); //Decal
                    
                    mode = 1;
                    int index =-1;
                    float2 Layers[] = { float2(0.0,0.2),float2(0.21,0.25),float2(0.26,0.30) , float2(0.31,0.46),float2(0.47, 0.55),float2(0.56 , 0.57 ) ,float2(0.58,0.61),float2(0.62, 0.66),float2( 0.67, 0.71) ,float2(0.72 ,0.87),float2(0.88,1.0) };

                    index++;
                    if (_TestModeLayer == mode++)//1
                        return lerp( ShadowMap,BaseMap, (Layer>=Layers[index].x && Layer <=Layers[index].y ));
                    index++;
                    if (_TestModeLayer == mode++)//2
                        return lerp( ShadowMap,BaseMap, (Layer>=Layers[index].x && Layer <=Layers[index].y ));
                    index++;
                    if (_TestModeLayer == mode++)//3
                        return lerp( ShadowMap,BaseMap, (Layer>=Layers[index].x && Layer <=Layers[index].y ));
                    index++;
                    if (_TestModeLayer == mode++)//4
                        return lerp( ShadowMap,BaseMap, (Layer>=Layers[index].x && Layer <=Layers[index].y ));
                    index++;
                    if (_TestModeLayer == mode++)//5
                        return lerp( ShadowMap,BaseMap, (Layer>=Layers[index].x && Layer <=Layers[index].y ));
                    index++;
                    if (_TestModeLayer == mode++)//6
                        return lerp( ShadowMap,BaseMap, (Layer>=Layers[index].x && Layer <=Layers[index].y ));
                    index++;
                    if (_TestModeLayer == mode++)//7
                        return lerp( ShadowMap,BaseMap, (Layer>=Layers[index].x && Layer <=Layers[index].y ));
                    index++;
                    if (_TestModeLayer == mode++)//8
                        return lerp( ShadowMap,BaseMap, (Layer>=Layers[index].x && Layer <=Layers[index].y ));
                    index++;
                    if (_TestModeLayer == mode++)//9
                        return lerp( ShadowMap,BaseMap, (Layer>=Layers[index].x && Layer <=Layers[index].y ));
                    index++;
                    if (_TestModeLayer == mode++)//10
                        return lerp( ShadowMap,BaseMap, (Layer>=Layers[index].x && Layer <=Layers[index].y ));
                    index++;
                    if (_TestModeLayer == mode++)//11
                        return lerp( ShadowMap,BaseMap, (Layer>=Layers[index].x && Layer <=Layers[index].y ));
                }
                #endif

                //通用参数设置
                NPRData nprData;
                nprData.NH                      = NH;
                nprData.NL                      = NL;
                nprData.NV                      = NV;
                nprData.BaseMap                 = BaseMap;
                nprData.ShadowMap               = ShadowMap;
                nprData.ShadowMask              = ShadowMask;
                nprData.HalfLambert             = HalfLambert;
                nprData.RampOffsetMask          = RampOffsetMask;
                nprData.SpecularExpMask         = SpecularExpMask;
                nprData.SpecularIntensityMask   = SpecularIntensityMask;
                
                //层叫什么名字并不重要，重要的是层里面的特性
                //10层 5个特性
                
                //0.0  - 0.2    => 基础材质: 一个明暗面 无边缘光 无高光Mask 无裁边高光 无视角光 无裁边视角光  (可能包含皮肤 布料 金属)
                //0.21 - 0.25   => 布料1  : 两层明暗面 裁边缘光 无高光Mask 无裁边高光 无视角光 无裁边视角光
                //0.26 - 0.30   => 布料2  : 两层明暗面 裁边缘光 有高光Mask 无裁边高光 无视角光 无裁边视角光
                //0.31 - 0.46   => 布料3  : 两层明暗面 裁边缘光 无高光Mask 无裁边高光 无视角光 无裁边视角光
                //0.47 - 0.55   => 皮革1  : 一层明暗面 无边缘光 有高光Mask 无裁边高光 无视角光 无裁边视角光
                //0.56 - 0.57   => 皮革2  : 两层明暗面 裁边缘光 有高光Mask 有裁边高光 无视角光 无裁边视角光
                //0.58 - 0.61   => 皮革3  : 两层明暗面 裁边缘光 有高光Mask 无裁边高光 无视角光 无裁边视角光     (可能包含 皮革 金属)
                //0.62 - 0.66   => 金属1  : 两层明暗面 裁边缘光 有高光Mask 有裁边高光 无视角光 无裁边视角光
                //0.67 - 0.71   => 金属2  : 两层明暗面 裁边缘光 有高光Mask 无裁边高光 无视角光 无裁边视角光
                //0.72 - 0.87   => 金属3  : 一层明暗面 裁边缘光 有高光Mask 无裁边高光 无视角光 无裁边视角光
                //0.88 - 1.0    => 金属4  : 一层明暗面 裁边缘光 有高光Mask 无裁边高光 无视角光 无裁边视角光  (布料 金属 英雄就一层基础材质+金属4材质)

                
//======材质分层==========================
//float2 Layers[] = { float2(0.0,0.2),float2(0.21,0.25),float2(0.26,0.30) , float2(0.31,0.46),float2(0.47, 0.55),float2(0.56 , 0.57 ) ,float2(0.58,0.61),float2(0.62, 0.66),float2( 0.67, 0.71) ,float2(0.72 ,0.87),float2(0.88,1.0) };
//Layer1
//0.0  - 0.2    => 基础材质: 一个明暗面 无边缘光 无高光Mask 无边高光 无视角光    (可能包含皮肤 布料 金属)
                if(Layer>=0.0 && Layer <=0.2 )
                {
                    // return  1;
                     //每层不一样的参数
                    nprData.HasTwoSide              = _Layer1_HasTwoSide;
                    nprData.HasRim                  = _Layer1_HasRim;
                    nprData.HasSpecular             = _Layer1_HasSpecular;
                    nprData.HasStepSpecular         = _Layer1_HasStepSpecular;
                    nprData.HasViewLight            = _Layer1_HasViewLight;

                    nprData.RampOffset2             = _Layer1_RampOffset2;
                    nprData.SpecularExp             = _Layer1_SpecularExp;
                    nprData.SpecularIntensity       = _Layer1_SpecularIntensity;
                    nprData.StepSpecular_Intensity  = _Layer1_StepSpecular_Intensity;
                    nprData.StepSpecular_Exp        = _Layer1_StepSpecular_Exp;
                    nprData.StepSpecular_Width      = _Layer1_StepSpecular_Width;
                    nprData.Rim_Intensity           = _Layer1_Rim_Intensity;
                    nprData.Rim_Exp                 = _Layer1_Rim_Exp;
                    nprData.Rim_Width               = _Layer1_Rim_Width;
                    nprData.ViewLight_Intensity     = _Layer1_ViewLight_Intensity;
                    nprData.ViewLight_Exp           = _Layer1_ViewLight_Exp;
                    nprData.RimType                 = _Layer1_RimType;
                    nprData.StepSpecularType        = _Layer1_StepSpecularType;
                    
                    float3 Light = NPRLighting(nprData);
                    
                    return Light.xyzz;
                }
//Layer2
//0.21 - 0.25   => 布料1  : 两层明暗面 裁边缘光 无高光Mask 无边高光 无视角光
                if(Layer>=0.21 && Layer <= 0.25)
                {
                     //每层不一样的参数
                    nprData.HasTwoSide              = _Layer2_HasTwoSide;
                    nprData.HasRim                  = _Layer2_HasRim;
                    nprData.HasSpecular             = _Layer2_HasSpecular;
                    nprData.HasStepSpecular         = _Layer2_HasStepSpecular;
                    nprData.HasViewLight            = _Layer2_HasViewLight;

                    nprData.RampOffset2             = _Layer2_RampOffset2;
                    nprData.SpecularExp             = _Layer2_SpecularExp;
                    nprData.SpecularIntensity       = _Layer2_SpecularIntensity;
                    nprData.StepSpecular_Intensity  = _Layer2_StepSpecular_Intensity;
                    nprData.StepSpecular_Exp        = _Layer2_StepSpecular_Exp;
                    nprData.StepSpecular_Width      = _Layer2_StepSpecular_Width;
                    nprData.Rim_Intensity           = _Layer2_Rim_Intensity;
                    nprData.Rim_Exp                 = _Layer2_Rim_Exp;
                    nprData.Rim_Width               = _Layer2_Rim_Width;
                    nprData.ViewLight_Intensity     = _Layer2_ViewLight_Intensity;
                    nprData.ViewLight_Exp           = _Layer2_ViewLight_Exp;
                    nprData.RimType                 = _Layer2_RimType;
                    nprData.StepSpecularType        = _Layer2_StepSpecularType;

                    float3 Light = NPRLighting(nprData);
                    
                    return Light.xyzz;
                }
//Layer3
//0.26 - 0.30   => 布料2  : 两层明暗面 裁边缘光 有高光Mask 无边高光 无视角光
                if(Layer>=0.26 && Layer <=0.30 )
                {
                     //每层不一样的参数
                    nprData.HasTwoSide              = _Layer3_HasTwoSide;
                    nprData.HasRim                  = _Layer3_HasRim;
                    nprData.HasSpecular             = _Layer3_HasSpecular;
                    nprData.HasStepSpecular         = _Layer3_HasStepSpecular;
                    nprData.HasViewLight            = _Layer3_HasViewLight;

                    nprData.RampOffset2             = _Layer3_RampOffset2;
                    nprData.SpecularExp             = _Layer3_SpecularExp;
                    nprData.SpecularIntensity       = _Layer3_SpecularIntensity;
                    nprData.StepSpecular_Intensity  = _Layer3_StepSpecular_Intensity;
                    nprData.StepSpecular_Exp        = _Layer3_StepSpecular_Exp;
                    nprData.StepSpecular_Width      = _Layer3_StepSpecular_Width;
                    nprData.Rim_Intensity           = _Layer3_Rim_Intensity;
                    nprData.Rim_Exp                 = _Layer3_Rim_Exp;
                    nprData.Rim_Width               = _Layer3_Rim_Width;
                    nprData.ViewLight_Intensity     = _Layer3_ViewLight_Intensity;
                    nprData.ViewLight_Exp           = _Layer3_ViewLight_Exp;
                    nprData.RimType                 = _Layer3_RimType;
                    nprData.StepSpecularType        = _Layer3_StepSpecularType;

                    float3 Light = NPRLighting(nprData);
                    
                    return Light.xyzz;
                }
//Layer4
//0.31 - 0.46   => 布料3  : 两层明暗面 裁边缘光 无高光Mask 无边高光 无视角光
                if(Layer>=0.31 && Layer <= 0.46)
                {
                     //每层不一样的参数
                    nprData.HasTwoSide              = _Layer4_HasTwoSide;
                    nprData.HasRim                  = _Layer4_HasRim;
                    nprData.HasSpecular             = _Layer4_HasSpecular;
                    nprData.HasStepSpecular         = _Layer4_HasStepSpecular;
                    nprData.HasViewLight            = _Layer4_HasViewLight;

                    nprData.RampOffset2             = _Layer4_RampOffset2;
                    nprData.SpecularExp             = _Layer4_SpecularExp;
                    nprData.SpecularIntensity       = _Layer4_SpecularIntensity;
                    nprData.StepSpecular_Intensity  = _Layer4_StepSpecular_Intensity;
                    nprData.StepSpecular_Exp        = _Layer4_StepSpecular_Exp;
                    nprData.StepSpecular_Width      = _Layer4_StepSpecular_Width;
                    nprData.Rim_Intensity           = _Layer4_Rim_Intensity;
                    nprData.Rim_Exp                 = _Layer4_Rim_Exp;
                    nprData.Rim_Width               = _Layer4_Rim_Width;
                    nprData.ViewLight_Intensity     = _Layer4_ViewLight_Intensity;
                    nprData.ViewLight_Exp           = _Layer4_ViewLight_Exp;
                    nprData.RimType                 = _Layer4_RimType;
                    nprData.StepSpecularType        = _Layer4_StepSpecularType;
                    
                    float3 Light = NPRLighting(nprData);
                    
                    return Light.xyzz;
                }
//Layer5
//0.47 - 0.55   => 皮革1  : 一层明暗面 无边缘光 有高光Mask 无边高光 无视角光
                if(Layer>= 0.47 && Layer <= 0.55)
                {
                     //每层不一样的参数
                    nprData.HasTwoSide              = _Layer5_HasTwoSide;
                    nprData.HasRim                  = _Layer5_HasRim;
                    nprData.HasSpecular             = _Layer5_HasSpecular;
                    nprData.HasStepSpecular         = _Layer5_HasStepSpecular;
                    nprData.HasViewLight            = _Layer5_HasViewLight;

                    nprData.RampOffset2             = _Layer5_RampOffset2;
                    nprData.SpecularExp             = _Layer5_SpecularExp;
                    nprData.SpecularIntensity       = _Layer5_SpecularIntensity;
                    nprData.StepSpecular_Intensity  = _Layer5_StepSpecular_Intensity;
                    nprData.StepSpecular_Exp        = _Layer5_StepSpecular_Exp;
                    nprData.StepSpecular_Width      = _Layer5_StepSpecular_Width;
                    nprData.Rim_Intensity           = _Layer5_Rim_Intensity;
                    nprData.Rim_Exp                 = _Layer5_Rim_Exp;
                    nprData.Rim_Width               = _Layer5_Rim_Width;
                    nprData.ViewLight_Intensity     = _Layer5_ViewLight_Intensity;
                    nprData.ViewLight_Exp           = _Layer5_ViewLight_Exp;
                    nprData.RimType                 = _Layer5_RimType;
                    nprData.StepSpecularType        = _Layer5_StepSpecularType;
                    
                    float3 Light = NPRLighting(nprData);
                    
                    return Light.xyzz;
                }
//Layer6
//0.56 - 0.57   => 皮革2  : 两层明暗面 裁边缘光 有高光Mask 裁边高光 无视角光
                if(Layer>=0.56 && Layer <= 0.57)
                {
                     //每层不一样的参数
                    nprData.HasTwoSide              = _Layer6_HasTwoSide;
                    nprData.HasRim                  = _Layer6_HasRim;
                    nprData.HasSpecular             = _Layer6_HasSpecular;
                    nprData.HasStepSpecular         = _Layer6_HasStepSpecular;
                    nprData.HasViewLight            = _Layer6_HasViewLight;

                    nprData.RampOffset2             = _Layer6_RampOffset2;
                    nprData.SpecularExp             = _Layer6_SpecularExp;
                    nprData.SpecularIntensity       = _Layer6_SpecularIntensity;
                    nprData.StepSpecular_Intensity  = _Layer6_StepSpecular_Intensity;
                    nprData.StepSpecular_Exp        = _Layer6_StepSpecular_Exp;
                    nprData.StepSpecular_Width      = _Layer6_StepSpecular_Width;
                    nprData.Rim_Intensity           = _Layer6_Rim_Intensity;
                    nprData.Rim_Exp                 = _Layer6_Rim_Exp;
                    nprData.Rim_Width               = _Layer6_Rim_Width;
                    nprData.ViewLight_Intensity     = _Layer6_ViewLight_Intensity;
                    nprData.ViewLight_Exp           = _Layer6_ViewLight_Exp;
                    nprData.RimType                 = _Layer6_RimType;
                    nprData.StepSpecularType        = _Layer6_StepSpecularType;
                    
                    float3 Light = NPRLighting(nprData);
                    
                    return Light.xyzz;
                }
//Layer7
//0.58 - 0.61   => 皮革3  : 两层明暗面 裁边缘光 有高光Mask 无边高光 无视角光    (可能包含 皮革 金属)
                if(Layer>=0.58 && Layer <= 0.61)
                {
                     //每层不一样的参数
                    nprData.HasTwoSide              = _Layer7_HasTwoSide;
                    nprData.HasRim                  = _Layer7_HasRim;
                    nprData.HasSpecular             = _Layer7_HasSpecular;
                    nprData.HasStepSpecular         = _Layer7_HasStepSpecular;
                    nprData.HasViewLight            = _Layer7_HasViewLight;

                    nprData.RampOffset2             = _Layer7_RampOffset2;
                    nprData.SpecularExp             = _Layer7_SpecularExp;
                    nprData.SpecularIntensity       = _Layer7_SpecularIntensity;
                    nprData.StepSpecular_Intensity  = _Layer7_StepSpecular_Intensity;
                    nprData.StepSpecular_Exp        = _Layer7_StepSpecular_Exp;
                    nprData.StepSpecular_Width      = _Layer7_StepSpecular_Width;
                    nprData.Rim_Intensity           = _Layer7_Rim_Intensity;
                    nprData.Rim_Exp                 = _Layer7_Rim_Exp;
                    nprData.Rim_Width               = _Layer7_Rim_Width;
                    nprData.ViewLight_Intensity     = _Layer7_ViewLight_Intensity;
                    nprData.ViewLight_Exp           = _Layer7_ViewLight_Exp;
                    nprData.RimType                 = _Layer7_RimType;
                    nprData.StepSpecularType        = _Layer7_StepSpecularType;
                    
                    float3 Light = NPRLighting(nprData);
                    
                    return Light.xyzz;
                }
//Layer8
//0.62 - 0.66   => 金属1  : 两层明暗面 裁边缘光 有高光Mask 裁边高光 无视角光
                if(Layer>= 0.62 && Layer <= 0.66)
                {
                     //每层不一样的参数
                    nprData.HasTwoSide              = _Layer8_HasTwoSide;
                    nprData.HasRim                  = _Layer8_HasRim;
                    nprData.HasSpecular             = _Layer8_HasSpecular;
                    nprData.HasStepSpecular         = _Layer8_HasStepSpecular;
                    nprData.HasViewLight            = _Layer8_HasViewLight;

                    nprData.RampOffset2             = _Layer8_RampOffset2;
                    nprData.SpecularExp             = _Layer8_SpecularExp;
                    nprData.SpecularIntensity       = _Layer8_SpecularIntensity;
                    nprData.StepSpecular_Intensity  = _Layer8_StepSpecular_Intensity;
                    nprData.StepSpecular_Exp        = _Layer8_StepSpecular_Exp;
                    nprData.StepSpecular_Width      = _Layer8_StepSpecular_Width;
                    nprData.Rim_Intensity           = _Layer8_Rim_Intensity;
                    nprData.Rim_Exp                 = _Layer8_Rim_Exp;
                    nprData.Rim_Width               = _Layer8_Rim_Width;
                    nprData.ViewLight_Intensity     = _Layer8_ViewLight_Intensity;
                    nprData.ViewLight_Exp           = _Layer8_ViewLight_Exp;
                    nprData.RimType                 = _Layer8_RimType;
                    nprData.StepSpecularType        = _Layer8_StepSpecularType;
                    
                    float3 Light = NPRLighting(nprData);
                    
                    return Light.xyzz;
                }
//Layer9
//0.67 - 0.71   => 金属2  : 两层明暗面 裁边缘光 有高光Mask 无边高光 无视角光
                if(Layer>= 0.67&& Layer <= 0.71)
                {
                     //每层不一样的参数
                    nprData.HasTwoSide              = _Layer9_HasTwoSide;
                    nprData.HasRim                  = _Layer9_HasRim;
                    nprData.HasSpecular             = _Layer9_HasSpecular;
                    nprData.HasStepSpecular         = _Layer9_HasStepSpecular;
                    nprData.HasViewLight            = _Layer9_HasViewLight;

                    nprData.RampOffset2             = _Layer9_RampOffset2;
                    nprData.SpecularExp             = _Layer9_SpecularExp;
                    nprData.SpecularIntensity       = _Layer9_SpecularIntensity;
                    nprData.StepSpecular_Intensity  = _Layer9_StepSpecular_Intensity;
                    nprData.StepSpecular_Exp        = _Layer9_StepSpecular_Exp;
                    nprData.StepSpecular_Width      = _Layer9_StepSpecular_Width;
                    nprData.Rim_Intensity           = _Layer9_Rim_Intensity;
                    nprData.Rim_Exp                 = _Layer9_Rim_Exp;
                    nprData.Rim_Width               = _Layer9_Rim_Width;
                    nprData.ViewLight_Intensity     = _Layer9_ViewLight_Intensity;
                    nprData.ViewLight_Exp           = _Layer9_ViewLight_Exp;
                    nprData.RimType                 = _Layer9_RimType;
                    nprData.StepSpecularType        = _Layer9_StepSpecularType;
                    
                    float3 Light = NPRLighting(nprData);
                    
                    return Light.xyzz;
                }
//Layer10
//0.72 - 0.87   => 金属3  : 一层明暗面 裁边缘光 有高光Mask 无边高光 无视角光
                if(Layer>=0.72 && Layer <= 0.87)
                {
                     //每层不一样的参数
                    nprData.HasTwoSide              = _Layer10_HasTwoSide;
                    nprData.HasRim                  = _Layer10_HasRim;
                    nprData.HasSpecular             = _Layer10_HasSpecular;
                    nprData.HasStepSpecular         = _Layer10_HasStepSpecular;
                    nprData.HasViewLight            = _Layer10_HasViewLight;

                    nprData.RampOffset2             = _Layer10_RampOffset2;
                    nprData.SpecularExp             = _Layer10_SpecularExp;
                    nprData.SpecularIntensity       = _Layer10_SpecularIntensity;
                    nprData.StepSpecular_Intensity  = _Layer10_StepSpecular_Intensity;
                    nprData.StepSpecular_Exp        = _Layer10_StepSpecular_Exp;
                    nprData.StepSpecular_Width      = _Layer10_StepSpecular_Width;
                    nprData.Rim_Intensity           = _Layer10_Rim_Intensity;
                    nprData.Rim_Exp                 = _Layer10_Rim_Exp;
                    nprData.Rim_Width               = _Layer10_Rim_Width;
                    nprData.ViewLight_Intensity     = _Layer10_ViewLight_Intensity;
                    nprData.ViewLight_Exp           = _Layer10_ViewLight_Exp;
                    nprData.RimType                 = _Layer10_RimType;
                    nprData.StepSpecularType        = _Layer10_StepSpecularType;
                    
                    float3 Light = NPRLighting(nprData);
                    
                    return Light.xyzz;
                }
//Layer11
//0.88 - 1.0    => 金属4  : 一层明暗面 裁边缘光 有高光Mask 无边高光 无视角光    (布料 金属 英雄就一层基础材质+金属4材质)
                if(Layer>=0.88 && Layer <= 1.0)
                {
                     //每层不一样的参数
                    nprData.HasTwoSide              = _Layer11_HasTwoSide;
                    nprData.HasRim                  = _Layer11_HasRim;
                    nprData.HasSpecular             = _Layer11_HasSpecular;
                    nprData.HasStepSpecular         = _Layer11_HasStepSpecular;
                    nprData.HasViewLight            = _Layer11_HasViewLight;

                    nprData.RampOffset2             = _Layer11_RampOffset2;
                    nprData.SpecularExp             = _Layer11_SpecularExp;
                    nprData.SpecularIntensity       = _Layer11_SpecularIntensity;
                    nprData.StepSpecular_Intensity  = _Layer11_StepSpecular_Intensity;
                    nprData.StepSpecular_Exp        = _Layer11_StepSpecular_Exp;
                    nprData.StepSpecular_Width      = _Layer11_StepSpecular_Width;
                    nprData.Rim_Intensity           = _Layer11_Rim_Intensity;
                    nprData.Rim_Exp                 = _Layer11_Rim_Exp;
                    nprData.Rim_Width               = _Layer11_Rim_Width;
                    nprData.ViewLight_Intensity     = _Layer11_ViewLight_Intensity;
                    nprData.ViewLight_Exp           = _Layer11_ViewLight_Exp;
                    nprData.RimType                 = _Layer11_RimType;
                    nprData.StepSpecularType        = _Layer11_StepSpecularType;
                    
                    float3 Light = NPRLighting(nprData);
                    
                    return Light.xyzz;
                }

                return BaseMap;
                
                // float shadow = SHADOW_ATTENUATION(i);
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
    CustomEditor "TA.SimpleShaderGUI"
}