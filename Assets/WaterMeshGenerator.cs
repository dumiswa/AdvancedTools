using UnityEngine;

[RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
public class WaterMeshGenerator : MonoBehaviour
{
    [Header("Plane Settings")]
    public int sizeOfPlane = 2000;         
    public int vertexDensity = 1;            

    void Start()
    {
        GenerateMesh();
    }

    void GenerateMesh()
    {
        int verticesPerLine = sizeOfPlane * vertexDensity + 1;
        int vertexCount = verticesPerLine * verticesPerLine;

        Vector3[] vertices = new Vector3[vertexCount];
        Vector2[] uvs = new Vector2[vertexCount];
        int[] triangles = new int[(verticesPerLine - 1) * (verticesPerLine - 1) * 6];

        float spacing = 1f / vertexDensity;
        float halfSize = (verticesPerLine - 1) * spacing / 2f;

        int triIndex = 0;
        for (int z = 0; z < verticesPerLine; z++)
        {
            for (int x = 0; x < verticesPerLine; x++)
            {
                int i = z * verticesPerLine + x;
                float worldX = x * spacing - halfSize;
                float worldZ = z * spacing - halfSize;

                vertices[i] = new Vector3(worldX, -4.5f, worldZ);
                uvs[i] = new Vector2((float)x / (verticesPerLine - 1), (float)z / (verticesPerLine - 1));

                if (x < verticesPerLine - 1 && z < verticesPerLine - 1)
                {
                    int a = i;
                    int b = i + verticesPerLine;
                    int c = i + verticesPerLine + 1;
                    int d = i + 1;

                    triangles[triIndex++] = a;
                    triangles[triIndex++] = b;
                    triangles[triIndex++] = c;

                    triangles[triIndex++] = a;
                    triangles[triIndex++] = c;
                    triangles[triIndex++] = d;
                }
            }
        }

        Mesh mesh = new Mesh();
        mesh.indexFormat = vertexCount > 65535 ? UnityEngine.Rendering.IndexFormat.UInt32 : UnityEngine.Rendering.IndexFormat.UInt16;
        mesh.name = "Procedural Water Plane";
        mesh.vertices = vertices;
        mesh.triangles = triangles;
        mesh.uv = uvs;
        mesh.RecalculateNormals();
        mesh.RecalculateBounds();

        MeshFilter mf = GetComponent<MeshFilter>();
        mf.mesh = mesh;

        // Ensure this GameObject is at world origin
        transform.position = Vector3.zero;
    }

}
