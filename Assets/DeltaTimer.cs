using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DeltaTimer : MonoBehaviour
{
    void Update()
    {
        Debug.Log("Delta Time: " + Time.deltaTime * 1000f);
    }
}
