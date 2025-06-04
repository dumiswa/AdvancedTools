Shader "Custom/WaterShader"
{
    Properties
    {
        _Color ("Water Color", Color) = (0.0, 0.5, 1.0, 1.0)
        _Amplitude ("Wave Amplitude", Float) = 0.1
        _Frequency ("Wave Frequency", Float) = 1.0
        _Speed ("Wave Speed", Float) = 1.0

        _NormalTex1 ("Normal Map 1", 2D) = "bump" {}
        _NormalTex2 ("Normal Map 2", 2D) = "bump" {}
        _NoiseTex ("Noise Texture", 2D) = "white" {}
        _NormalSpeed1 ("Normal Speed 1", Vector) = (0.05, 0.02, 0, 0)
        _NormalSpeed2 ("Normal Speed 2", Vector) = (-0.03, 0.04, 0, 0)
        _NormalStrength ("Normal Strength", Float) = 1.0

        _FoamColor ("Foam Color", Color) = (1,1,1,1)
        _FoamThreshold ("Foam Threshold", Range(0, 1)) = 0.6
        _FoamIntensity ("Foam Intensity", Range(0, 2)) = 1.0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv1 : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
                float2 uvNoise : TEXCOORD2;
            };

            fixed4 _Color;
            float _Amplitude;
            float _Frequency;
            float _Speed;

            sampler2D _NormalTex1;
            sampler2D _NormalTex2;
            sampler2D _NoiseTex;
            float4 _NormalSpeed1;
            float4 _NormalSpeed2;
            float _NormalStrength;

            fixed4 _FoamColor;
            float _FoamThreshold;
            float _FoamIntensity;


            v2f vert(appdata v)
            {
                v2f o;

                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                float wave = sin((worldPos.x + worldPos.z) * _Frequency + _Time.y * _Speed) * _Amplitude;

                float3 displaced = v.vertex.xyz;
                displaced.y += wave;

                o.pos = UnityObjectToClipPos(float4(displaced, 1.0));

                // UV offset based on time and speed
                o.uv1 = v.uv + _Time.y * _NormalSpeed1.xy;
                o.uv2 = v.uv + _Time.y * _NormalSpeed2.xy;
                o.uvNoise = v.uv;

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // Sample and blend normals
                float3 n1 = UnpackNormal(tex2D(_NormalTex1, i.uv1));
                float3 n2 = UnpackNormal(tex2D(_NormalTex2, i.uv2));
                float3 blendedNormal = normalize(n1 + n2);
                blendedNormal.xy *= _NormalStrength;
                blendedNormal.z = sqrt(1.0 - saturate(dot(blendedNormal.xy, blendedNormal.xy)));
                blendedNormal = normalize(blendedNormal);

                // Lighting
                float3 lightDir = normalize(float3(0.3, 1, 0.5));
                float NdotL = saturate(dot(blendedNormal, lightDir));
                float ambient = 0.2;
                float rim = pow(1.0 - NdotL, 2.0);
                float lighting = lerp(ambient, 1.0, NdotL) + rim * 0.2;

                // Sample noise
                float noise = tex2D(_NoiseTex, i.uvNoise).r;

                // Foam mask based on normal steepness and noise
                float foamMask = saturate((1.0 - blendedNormal.z - _FoamThreshold) * _FoamIntensity);
                foamMask *= noise;

                // Combine foam and water color
                fixed4 waterColor = _Color * lighting;
                fixed4 foam = _FoamColor * foamMask;
                return lerp(waterColor, foam, foamMask);
            }
            ENDCG
        }
    }
}
