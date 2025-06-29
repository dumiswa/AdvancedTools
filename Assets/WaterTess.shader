Shader "Custom/WaterShader_Tess"
{

    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _NormalTex1 ("Normal texture 1", 2D) = "bump" {}
        _NormalTex2 ("Normal texture 2", 2D) = "bump" {}
        _NoiseTex ("Noise texture", 2D) = "white" {}

        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0

        _Scale ("Noise scale", Range(0.1,1)) = 1
        _Amplitude ("Wave Amplitude", Range(0.1,1)) = 0.01
        _Speed ("Wave Speed", Range(0.1,100)) = 0.15
        _NormalStrength ("Normal Strength", Range(0,1)) = 0.5

        _ShallowColor ("Shallow Water Color", Color) = (0.2,0.6,0.8,1)
        _DeepColor ("Deep Water Color", Color) = (0,0.2,0.4,1)
        _DepthColorDistance ("Depth Blend Distance", Range(0.1,10)) = 3

        _DepthFadeStrength ("Depth Fade Strength", Range(0,1)) = 0.25

        _FoamColor ("Foam Color", Color) = (1,1,1,1)
        _FoamThreshold ("Foam Threshold", Range(0.1,1)) = 0.2
        _FoamIntensity ("Foam Intensity", Range(0,1)) = 1
        _FoamWidth ("Foam Width", Range(0,10)) = 1

        _RefractionStrength ("Refraction Strength", Range(0,10)) = 0.1
        _BlendingStrength ("Blending Strength", Range(0,1)) = 0.1

        _RefractionsTexture ("Refractions Texture", 2D) = "bump" {}

        // Uniform tessellation factor (1 to 64)
        _TessFactor ("Tess Factor", Range(1,64)) = 4
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" "ForceNoShadowCasting"="True" }
        LOD 400
        GrabPass { "_RefractionTex" }

        CGPROGRAM
        #pragma target 5.0
        #pragma surface surf Standard fullforwardshadows alpha vertex:vert tessellate:TessUniform tessphong:_TessFactor

        sampler2D _NormalTex1, _NormalTex2, _NoiseTex;
        sampler2D _CameraDepthTexture, _RefractionTex, _RefractionsTexture;

        float _Scale, _Amplitude, _Speed, _NormalStrength;
        half  _Glossiness, _Metallic;
        fixed4 _Color, _FoamColor;
        fixed4 _ShallowColor, _DeepColor;
        float _DepthColorDistance, _DepthFadeStrength;
        float _FoamIntensity, _FoamThreshold, _FoamWidth;
        float _RefractionStrength, _BlendingStrength;
        float _TessFactor;

        struct Input
        {
            float2 uv_NormalTex1;
            float4 screenPos;
            float  eyeDepth : TEXCOORD1;
        };

        // Returns constant tessellation factor (1 to 64)
        float TessUniform(appdata_full v0, appdata_full v1, appdata_full v2)
        {
            return _TessFactor;
        }

        void vert(inout appdata_full v)
        {
            float3 wp = mul(unity_ObjectToWorld, v.vertex).xyz;
            float s = 0;
            [unroll]
            for (int i = 0; i < 6; ++i)
            {
                float a  = (float)i;
                float2 d = float2(cos(a), sin(a));
                float f  = frac(sin(i));
                float po = (float)i;
                float so = frac(cos(i));
                s += sin(dot(wp.xz, d) * _Scale * f + (_Time.y + po) * _Speed * so);
            }
            v.vertex.y += s / 6.0 * _Amplitude;

            float depth = -mul(UNITY_MATRIX_MV, v.vertex).z;
            v.texcoord1.x = depth;
        }

        void surf(Input IN, inout SurfaceOutputStandard o)
        {
            float rawZ   = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(IN.screenPos));
            float sceneZ = LinearEyeDepth(rawZ);
            float waterZ = LinearEyeDepth(IN.screenPos.z / IN.screenPos.w);
            float depthDiff = max(0.0, sceneZ - waterZ);

            float fade = smoothstep(0.0, _DepthColorDistance * 0.5, depthDiff);
            float2 screenUV = IN.screenPos.xy / IN.screenPos.w;
            o.Alpha = fade * _DepthFadeStrength;

            float depthBlend = saturate(depthDiff / _DepthColorDistance);
            o.Albedo = lerp(_ShallowColor.rgb, _DeepColor.rgb, depthBlend);

            float2 nUV1 = float2(IN.uv_NormalTex1.x + _Time.y * 0.05, IN.uv_NormalTex1.y);
            float2 nUV2 = float2(IN.uv_NormalTex1.x, IN.uv_NormalTex1.y + _Time.y * 0.03);
            o.Normal = UnpackNormal((tex2D(_NormalTex1, nUV1) + tex2D(_NormalTex2, nUV2)) * _NormalStrength * o.Alpha);

            o.Metallic   = _Metallic;
            o.Smoothness = _Glossiness;

            float foamMask = smoothstep(_FoamThreshold + _FoamWidth, _FoamThreshold, depthDiff) * _FoamIntensity;
            o.Albedo = lerp(o.Albedo, _FoamColor.rgb, foamMask);

            float2 refUV  = IN.uv_NormalTex1 * _Scale + float2(_Time.x * _Speed, _Time.y * _Speed);
            float2 disto  = tex2D(_RefractionsTexture, refUV).rg * 2.0 - 1.0;
            disto *= _RefractionStrength;
            disto.y = abs(disto.y);
            float2 refrUV = screenUV + disto * 0.01;
            float3 refrCol = tex2D(_RefractionTex, refrUV).rgb;
            o.Albedo = lerp(refrCol, o.Albedo, _BlendingStrength);
        }
        ENDCG
    }

    FallBack "Diffuse"
}
