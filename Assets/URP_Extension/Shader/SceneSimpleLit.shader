﻿Shader "Bioum/Scene/SimpleLit"
{
    Properties
    {
        [MainColor]_BaseColor("颜色", Color) = (1,1,1,1)
        [HDR]_EmiColor("自发光颜色", Color) = (0,0,0,1)
        [MainTexture]_BaseMap ("贴图", 2D) = "grey" {}
        [NoScaleOffset]_MAESMap ("(R)AO (A)自发光", 2D) = "white" {}

        _DitherCutoff("Dither范围", Range(0.0, 1.0)) = 0.2
        _Cutoff("透贴强度", Range(0.0, 1.0)) = 0.5
        _Transparent("透明度", Range(0.0, 1.0)) = 1

        [NoScaleOffset]_NormalMap ("法线贴图", 2D) = "bump" {}
        _NormalScale("法线强度", Range(-2.0, 2.0)) = 1.0
        [Toggle] _NormalMapDXGLSwitch ("OpenGL/DX Switch", float) = 0

        _AOStrength("AO强度", Range(0.0, 1.0)) = 1.0

        [Toggle(_SSS)] _sssToggle ("SSS开关", float) = 0
        _SSSColor ("SSS颜色", Color) = (0.7, 0.07, 0.01, 1)

        [Toggle(_WIND)] _WindToggle ("风开关", float) = 0
        _WindScale ("缩放", float) = 0.2
        _WindSpeed ("速度", float) = 0.5
        _WindDirection ("风向", range(0,90)) = 40
        _WindIntensity ("强度", range(0, 1)) = 0.2
        _WindParam ("风参数", vector) = (0.2, 0, 0.2, 0.5)

        [HDR]_RimColor ("边缘光颜色", Color) = (0,0,0,1)
        _RimPower ("边缘光范围", range(1, 20)) = 4

        [Toggle(_DITHER_CLIP)] _DitherClip ("_DitherClip", float) = 0

        [HideInInspector] _BlendMode ("_BlendMode", float) = 0
        [HideInInspector] _CullMode ("_CullMode", float) = 0
        [HideInInspector] _SrcBlend ("_SrcBlend", float) = 1
        [HideInInspector] _DstBlend ("_DstBlend", float) = 0
        [HideInInspector] _ZWrite ("_ZWrite", float) = 1
        [HideInInspector][Toggle] _TransparentZWrite ("_TransparentZWrite", float) = 0
        [HideInInspector] _Cull ("_Cull", float) = 2
        [HideInInspector] _Color("Color", Color) = (1,1,1,1)
        [HideInInspector] _MainTex ("Main Tex", 2D) = "white" {}
    }
    SubShader
    {
        HLSLINCLUDE
            #include "SceneSimpleLitInput.hlsl"
        ENDHLSL
        
        LOD 300
        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"}
        Pass
        {
            Name "ForwardLit"
            Tags{"LightMode"="UniversalForward"}
            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite] Cull[_Cull]

            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma multi_compile_fog
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile _ GREY

            #pragma shader_feature _ _ALPHATEST_ON _ALPHAPREMULTIPLY_ON
            #pragma shader_feature _ _DITHER_CLIP
            #pragma shader_feature _ _NORMALMAP
            #pragma shader_feature _ _MASEMAP
            #pragma shader_feature _ _SSS
            #pragma shader_feature _ _RIM
            #pragma shader_feature _ _WIND
            
            #pragma vertex SimpleLitVert
            #pragma fragment SimpleLitFrag

            #include "SceneSimpleLitPass.hlsl"
            ENDHLSL
        }
        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On ZTest LEqual
            Cull Off ColorMask 0

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            //#pragma multi_compile_instancing

            #pragma shader_feature _ _ALPHATEST_ON
            #pragma shader_feature _ _DITHER_CLIP
            #pragma shader_feature _ _DITHER_TRANSPARENT
            #pragma shader_feature _ _WIND
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "../Shader/ShaderLibrary/ShadowCasterPass.hlsl"
            ENDHLSL
        }
        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 3.5

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            #pragma shader_feature _ _ALPHATEST_ON
            #pragma shader_feature _ _DITHER_CLIP
            #pragma shader_feature _ _WIND

            #include "../Shader/ShaderLibrary/DepthOnlyPass.hlsl"
            ENDHLSL
        }
        Pass
        {
            Name "Meta"
            Tags{"LightMode" = "Meta"}

            Cull Off

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma vertex MetaPassVertex
            #pragma fragment MetaPassFragment

            //--------------------------------------
            // GPU Instancing
            //#pragma multi_compile_instancing

            #include "CommonMetaPass.hlsl"
            ENDHLSL
        }
    }

    
    CustomEditor "SceneSimpleLitGUI"
}
