using UnityEngine;

public class FloatingObject : MonoBehaviour
{
    [Header("Bob Settings")]
    [Range(0f, 1f)]
    [SerializeField] private float amplitude = 0.5f;
    [Range(0f, 5f)]
    [SerializeField] private float frequency = 1f;

    [Header("Rotation Settings")]
    [Range(0f, 5f)]
    [SerializeField] private float maxTiltAngle = 5f; 
    [Range(0f, 5f)]
    [SerializeField] private float tiltSpeed = 1f;

    private Vector3 startPos;
    private Quaternion startRot;
    private float offset;

    void Start()
    {
        startPos = transform.position;
        startRot = transform.rotation;
        offset = Random.Range(0f, 2f * Mathf.PI);
    }

    void Update()
    {
        float bob = Mathf.Sin(Time.time * frequency + offset) * amplitude;
        transform.position = startPos + Vector3.up * bob;

        float tiltX = Mathf.Sin(Time.time * tiltSpeed + offset) * maxTiltAngle;
        float tiltZ = Mathf.Cos(Time.time * tiltSpeed + offset) * maxTiltAngle;

        Quaternion tiltRotation = Quaternion.Euler(tiltX, 0f, tiltZ);
        transform.rotation = startRot * tiltRotation;
    }
}
