using UnityEngine;

public class WaterShaderToggler : MonoBehaviour
{
    public Material noTessMat;  
    public Material tessMat;     

    Renderer rend;
    bool useTess;

    void Start() { rend = GetComponent<Renderer>(); Toggle(false); }

    void Update()
    {
        if (Input.GetKeyDown(KeyCode.T))
            Toggle(!useTess);
    }

    void Toggle(bool enableTess)
    {
        useTess = enableTess;
        rend.sharedMaterial = useTess ? tessMat : noTessMat;
        //Debug.Log("Water shader: " + (useTess ? "TESSELLATED" : "NO-TESS"));
    }
}
