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
        _Scale ("Noise scale", Range(0.1,1)) = 1
        _Amplitude ("Wave Amplitude", Range(0.1,1)) = 0.01
        _Speed ("Wave Speed", Range(0.1,5)) = 0.15
        _NormalStrength ("Normal Strength", Range(0,1)) = 0.5

        _ShallowColor ("Shallow Water Color", Color) = (0.2,0.6,0.8,1)
        _DeepColor ("Deep Water Color", Color) = (0,0.2,0.4,1)
        _DepthColorDistance ("Depth Blend Distance", Range(0.1,10)) = 3

        _DepthFadeStrength ("Depth-Fade Strength", Range(0,1)) = 0.25

        _FoamColor ("Foam Color", Color) = (1,1,1,1)
        _FoamThreshold ("Foam Threshold", Range(0.1,1)) = 0.2
        _FoamIntensity ("Foam Intensity", Range(0,1)) = 1
        _FoamWidth ("Foam Width", Range(0,10)) = 1

        _RefractionStrength ("Refraction Strength", Range(0,1)) = 0.1
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" "ForceNoShadowCasting"="True" }
        LOD 200
        GrabPass { "_RefractionTex" }

        CGPROGRAM
        #pragma target 3.0
        #pragma surface surf Standard fullforwardshadows alpha vertex:vert

        sampler2D _NormalTex1,_NormalTex2,_NoiseTex,_CameraDepthTexture;

        float _Scale,_Amplitude,_Speed,_NormalStrength;
        half  _Glossiness,_Metallic;
        fixed4 _Color,_FoamColor;
        fixed4 _ShallowColor,_DeepColor;
        float _DepthColorDistance,_DepthFadeStrength;
        float _FoamIntensity,_FoamThreshold,_FoamWidth;

        struct Input
        {
            float2 uv_NormalTex1;
            float4 screenPos;
            float  eyeDepth;
        };

        void vert(inout appdata_full v,out Input o)
        {
            float3 wp=mul(unity_ObjectToWorld,v.vertex).xyz;
            float s=0;
            for(int i=0;i<6;++i){
                float a=i*2.39996;
                float2 d=float2(cos(a),sin(a));
                float f=1+frac(sin(i*57.3)*43758.5453);
                float po=i*1.23;
                float so=0.8+frac(cos(i*91.7)*23421.123)*0.5;
                s+=sin(dot(wp.xz,d)*_Scale*f+(_Time.y+po)*_Speed*so);
            }
            v.vertex.y+=s/6*_Amplitude;
            UNITY_INITIALIZE_OUTPUT(Input,o);
            COMPUTE_EYEDEPTH(o.eyeDepth);
        }

        void surf(Input IN,inout SurfaceOutputStandard o)
        {
            float rawZ=SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture,UNITY_PROJ_COORD(IN.screenPos));
            float sceneZ=LinearEyeDepth(rawZ);
            float waterZ=IN.eyeDepth;
            float depthDiff=sceneZ-waterZ;

            o.Alpha=saturate(depthDiff*_DepthFadeStrength);

            float depthBlend=saturate(depthDiff/_DepthColorDistance);
            o.Albedo=lerp(_ShallowColor.rgb,_DeepColor.rgb,depthBlend);

            float2 nUV1=float2(IN.uv_NormalTex1.x+_Time.y*0.05,IN.uv_NormalTex1.y);
            float2 nUV2=float2(IN.uv_NormalTex1.x,IN.uv_NormalTex1.y+_Time.y*0.03);
            o.Normal=UnpackNormal((tex2D(_NormalTex1,nUV1)+tex2D(_NormalTex2,nUV2))*_NormalStrength*o.Alpha);

            o.Metallic=_Metallic;
            o.Smoothness=_Glossiness;

            float foamMask=smoothstep(_FoamThreshold+_FoamWidth,_FoamThreshold,depthDiff)*_FoamIntensity;
            o.Albedo=lerp(o.Albedo,_FoamColor.rgb,foamMask);
        }
        ENDCG
    }

    FallBack "Diffuse"
}
