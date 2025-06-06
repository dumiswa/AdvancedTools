Shader "Custom/WaterShader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _NormalTex1 ("Normal texture 1", 2D) = "bump" {}
        _NormalTex2 ("Normal texture 2", 2D) = "bump" {}
        _NoiseTex ("Noise texture", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0

        _Scale ("Noise scale", Range(0.1, 1)) = 1
        _Amplitude ("Wave Amplitude", Range(0.1, 1)) = 0.01
        _Speed ("Wave Speed", Range(0.1, 5)) = 0.15
        _NormalStrength ("Normal Strength", Range(0, 1)) = 0.5
        _SoftFactor ("Soft Factor", Range(0.1, 3.0)) = 1.0

        _ShallowColor ("Shallow Water Color", Color) = (0.2, 0.6, 0.8, 1)
        _DeepColor ("Deep Water Color", Color) = (0.0, 0.2, 0.4, 1)
        _DepthColorDistance ("Depth Blend Distance", Range(0.1, 10)) = 3.0

        _FoamColor ("Foam Color", Color) = (1,1,1,1)
        _FoamThreshold ("Foam Threshold", Range(0.1, 1)) = 0.2
        _FoamIntensity ("Foam Intensity", Range(0, 1)) = 1
        _FoamWidth ("Foam Width", Range(0, 10)) = 1

        _RefractionStrength("Refraction Strength", Range(0, 1)) = 0.1
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "ForceNoShadowCasting" = "True" }
        LOD 200
        GrabPass { "_RefractionTex" }

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows alpha vertex:vert
        #pragma target 3.0

        sampler2D _NormalTex1;
        sampler2D _NormalTex2;
        sampler2D _NoiseTex;
        sampler2D _CameraDepthTexture;

        sampler2D _RefractionTex;
        float4 _RefractionTex_TexelSize;
        float _RefractionStrength;


        float _Scale;
        float _Amplitude;
        float _Speed;
        float _NormalStrength;
        float _SoftFactor;

        float _FoamIntensity;
        float _FoamThreshold;
        float _FoamWidth;

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        fixed4 _FoamColor;

        fixed4 _ShallowColor;
        fixed4 _DeepColor;
        float _DepthColorDistance;

        struct Input
        {
            float2 uv_NormalTex1;
            float4 screenPos;
            float eyeDepth;
        };

        void vert(inout appdata_full v, out Input o)
        {
            float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
            float waveSum = 0.0;
            int waveCount = 6;

            for (int i = 0; i < waveCount; ++i)
            {
                float angle = i * 2.39996;
                float2 dir = float2(cos(angle), sin(angle));
                float freq = 1.0 + frac(sin(i * 57.3) * 43758.5453);
                float phaseOffset = i * 1.23;
                float speedOffset = 0.8 + frac(cos(i * 91.7) * 23421.123) * 0.5;

                float waveCoord = dot(worldPos.xz, dir);
                float phase = waveCoord * _Scale * freq + (_Time.y + phaseOffset) * _Speed * speedOffset;

                waveSum += sin(phase);
            }

            waveSum /= waveCount;
            v.vertex.y += waveSum * _Amplitude;

            UNITY_INITIALIZE_OUTPUT(Input, o);
            COMPUTE_EYEDEPTH(o.eyeDepth);
        }

        void surf(Input IN, inout SurfaceOutputStandard o)
        {
            // Base lighting
            o.Albedo = _Color.rgb;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;

            // Depth fade
            float rawZ = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(IN.screenPos));
            float sceneZ = LinearEyeDepth(rawZ);
            float waterZ = IN.eyeDepth;
            float fade = saturate(_SoftFactor * (sceneZ - waterZ));
            o.Alpha = fade * 0.5;
            float depthBlend = saturate((sceneZ - waterZ) / _DepthColorDistance);
            float3 depthColor = lerp(_ShallowColor.rgb, _DeepColor.rgb, depthBlend);
            o.Albedo = depthColor;

            // Normal maps
            float normalUVX = IN.uv_NormalTex1.x + _Time.y * 0.05;
            float normalUVY = IN.uv_NormalTex1.y + _Time.y * 0.03;
            float2 normalUV1 = float2(normalUVX, IN.uv_NormalTex1.y);
            float2 normalUV2 = float2(IN.uv_NormalTex1.x, normalUVY);
            o.Normal = UnpackNormal((tex2D(_NormalTex1, normalUV1) + tex2D(_NormalTex2, normalUV2)) * _NormalStrength * fade);


            // Intersection foam only
            float depthDiff = sceneZ - waterZ;
            //float foamMask = saturate((_FoamThreshold - depthDiff) * _FoamIntensity);
            //foamMask *= tex2D(_NoiseTex, IN.uv_NormalTex1 * 6.0).r;
            float foamMask = smoothstep(_FoamThreshold + _FoamWidth, _FoamThreshold, depthDiff);

            // Blend foam
            o.Albedo = lerp(o.Albedo, _FoamColor.rgb, foamMask);


        }
        ENDCG
    }

    FallBack "Diffuse"
}
