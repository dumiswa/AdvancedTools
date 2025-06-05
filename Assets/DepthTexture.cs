using UnityEngine;

public class DepthTexture : MonoBehaviour
{
    void Start()
    {
        Camera.main.depthTextureMode = DepthTextureMode.Depth;
    }
}
