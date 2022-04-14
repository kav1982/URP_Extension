Shader "Bioum/RenderFeature/SimpleDOF"
{
    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"
        }
        Cull Off ZWrite Off ZTest Always

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"

        TEXTURE2D(_SimpleDOFBlurTarget); float4 _SimpleDOFBlurTarget_TexelSize;
        SAMPLER(sampler_Linear_Clamp);

        #if _TAA
            TEXTURE2D(_TAA_TempTexture); float4 _TAA_TempTexture_TexelSize;
            #define _SourceTex _TAA_TempTexture
            #define _SourceTex_TexelSize _TAA_TempTexture_TexelSize
        #else
            TEXTURE2D(_CameraColorTexture); float4 _CameraColorTexture_TexelSize;
            #define _SourceTex _CameraColorTexture
            #define _SourceTex_TexelSize _CameraColorTexture_TexelSize
        #endif

        half4 _SimpleDOFParam;
        #define _DOF_Start _SimpleDOFParam.x
        #define _DOF_End _SimpleDOFParam.y
        #define _DOF_Intensity _SimpleDOFParam.z
        #define _DOF_Debug _SimpleDOFParam.w


        struct Attributes
        {
            float3 positionHCS : POSITION;
            float2 uv : TEXCOORD0;
        };

        struct Varyings
        {
            float2 uv : TEXCOORD0;
            float4 positionCS : SV_POSITION;
            UNITY_VERTEX_OUTPUT_STEREO
        };

        Varyings vertBlur(Attributes input)
        {
            Varyings output;

            // Note: The pass is setup with a mesh already in CS
            // Therefore, we can just output vertex position
            output.positionCS = float4(input.positionHCS.xyz, 1.0);

            #if UNITY_UV_STARTS_AT_TOP
            output.positionCS.y *= -1;
            #endif

            output.uv = input.uv;

            return output;
        }

        half4 fragBlur(Varyings input) : SV_Target
        {
            float offset = _DOF_Intensity;
            float4 d = _SourceTex_TexelSize.xyxy * float4(-offset, -offset, offset, offset);
            half3 blur;
            blur =  SAMPLE_TEXTURE2D_X(_SourceTex, sampler_Linear_Clamp, input.uv + d.xy).rgb;
            blur += SAMPLE_TEXTURE2D_X(_SourceTex, sampler_Linear_Clamp, input.uv + d.zy).rgb;
            blur += SAMPLE_TEXTURE2D_X(_SourceTex, sampler_Linear_Clamp, input.uv + d.xw).rgb;
            blur += SAMPLE_TEXTURE2D_X(_SourceTex, sampler_Linear_Clamp, input.uv + d.zw).rgb;
            blur *= 0.25;

            return half4(blur, 1);
        }


        Varyings vertBlend(Attributes input)
        {
            Varyings output = (Varyings)0;

            output.positionCS = TransformObjectToHClip(input.positionHCS);
            output.uv = input.uv;

            return output;
        }

        half4 fragBlend(Varyings input) : SV_Target
        {
            float offset = _DOF_Intensity;
            float4 d = _SourceTex_TexelSize.xyxy * float4(-offset, -offset, offset, offset);
            half3 blured;
            blured =  SAMPLE_TEXTURE2D_X(_SimpleDOFBlurTarget, sampler_Linear_Clamp, input.uv + d.xy).rgb;
            blured += SAMPLE_TEXTURE2D_X(_SimpleDOFBlurTarget, sampler_Linear_Clamp, input.uv + d.zy).rgb;
            blured += SAMPLE_TEXTURE2D_X(_SimpleDOFBlurTarget, sampler_Linear_Clamp, input.uv + d.xw).rgb;
            blured += SAMPLE_TEXTURE2D_X(_SimpleDOFBlurTarget, sampler_Linear_Clamp, input.uv + d.zw).rgb;
            blured *= 0.25;

            half4 source = SAMPLE_TEXTURE2D(_SourceTex, sampler_Linear_Clamp, input.uv);

            float depth = SampleSceneDepth(input.uv);
            depth = LinearEyeDepth(depth, _ZBufferParams);
            half coc = (depth - _DOF_Start) / (_DOF_End - _DOF_Start);
            coc = saturate(coc);

            source.rgb = (bool)_DOF_Debug ? coc : lerp(source.rgb, blured, coc);

            return source;
        }
        ENDHLSL

        Pass
        {
            HLSLPROGRAM
            #pragma multi_compile _ _TAA
            #pragma vertex vertBlur
            #pragma fragment fragBlur
            ENDHLSL
        }

        Pass
        {
            HLSLPROGRAM
            #pragma multi_compile _ _TAA
            #pragma vertex vertBlur
            #pragma fragment fragBlend
            ENDHLSL
        }
    }
}