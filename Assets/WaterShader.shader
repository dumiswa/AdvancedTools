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
        _SoftFactor("Soft Factor", Range(0.1, 3.0)) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "ForceNoShadowCasting" = "True"}
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows alpha vertex:vert

        #pragma target 3.0

        sampler2D _NormalTex1;
        sampler2D _NormalTex2;
        sampler2D _NoiseTex;
        sampler2D _CameraDepthTexture;

        float _Scale;
        float _Amplitude;
        float _Speed;
        float _NormalStrength;
        float _SoftFactor;

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

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
                // Pseudo-random per-wave direction
                float angle = i * 2.39996; // golden angle in radians (to break symmetry)
                float2 dir = float2(cos(angle), sin(angle));

                // Per-wave frequency, phase, and speed modulation
                float freq = 1.0 + frac(sin(i * 57.3) * 43758.5453) * 1.0;
                float phaseOffset = i * 1.23;
                float speedOffset = 0.8 + frac(cos(i * 91.7) * 23421.123) * 0.5;

                float waveCoord = dot(worldPos.xz, dir);
                float phase = waveCoord * _Scale * freq + (_Time.y + phaseOffset) * _Speed * speedOffset;

                waveSum += sin(phase);
            }

            waveSum /= waveCount;
            v.vertex.y += waveSum * _Amplitude;

            COMPUTE_EYEDEPTH(o.eyeDepth);
            UNITY_INITIALIZE_OUTPUT(Input, o);
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            o.Albedo = _Color.rgb;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;

            // Depth
            float rawZ = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(IN.screenPos));
            float sceneZ = LinearEyeDepth(rawZ);
            float partZ = IN.eyeDepth;
            float fade = saturate(_SoftFactor * (sceneZ - partZ));  
            o.Alpha = fade * 0.5;

            //Normal Maps
            float normalUVX = IN.uv_NormalTex1.x + _Time.y * 0.05;
            float normalUVY = IN.uv_NormalTex1.y + _Time.y * 0.03;
            float2 normalUV1 = float2(normalUVX, IN.uv_NormalTex1.y);
            float2 normalUV2 = float2(IN.uv_NormalTex1.x, normalUVY);

            o.Normal = UnpackNormal((tex2D(_NormalTex1, normalUV1) + tex2D(_NormalTex2, normalUV2)) * _NormalStrength * fade);
        }
        ENDCG
    }
    FallBack "Diffuse"
}