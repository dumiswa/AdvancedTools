using UnityEngine;

[RequireComponent(typeof(MeshFilter))]
[ExecuteInEditMode]
public class MeshGenerator : MonoBehaviour
{
    [SerializeField] int sizeOfPlane = 10;
    [SerializeField] int totalVertices;

    Mesh mesh;
    Vector3[] vertices;
    int[] triangles;
    Vector2[] uvs;

    void Start()
    {
        mesh = new Mesh();
        GetComponent<MeshFilter>().mesh = mesh;

        CreateShape();
        UpdateMesh();
    }

    void CreateShape()
    {
        totalVertices = (sizeOfPlane + 1) * (sizeOfPlane + 1);
        vertices = new Vector3[totalVertices];
        triangles = new int[sizeOfPlane * sizeOfPlane * 6];
        uvs = new Vector2[totalVertices];

        // Create vertices and UVs
        int i = 0;
        for (int z = 0; z <= sizeOfPlane; z++)
        {
            for (int x = 0; x <= sizeOfPlane; x++)
            {
                vertices[i] = new Vector3(x, 0, z);
                uvs[i] = new Vector2((float)x / sizeOfPlane, (float)z / sizeOfPlane); // Normalized UV
                i++;
            }
        }

        // Create triangles
        int vert = 0;
        int tris = 0;
        for (int z = 0; z < sizeOfPlane; z++)
        {
            for (int x = 0; x < sizeOfPlane; x++)
            {
                int topLeft = vert;
                int topRight = vert + 1;
                int bottomLeft = vert + sizeOfPlane + 1;
                int bottomRight = vert + sizeOfPlane + 2;

                // First triangle
                triangles[tris] = topLeft;
                triangles[tris + 1] = bottomLeft;
                triangles[tris + 2] = topRight;

                // Second triangle
                triangles[tris + 3] = topRight;
                triangles[tris + 4] = bottomLeft;
                triangles[tris + 5] = bottomRight;

                vert++;
                tris += 6;
            }
            vert++;
        }

    }


    void UpdateMesh()
    {
        mesh.Clear();
        mesh.vertices = vertices;
        mesh.triangles = triangles;
        mesh.uv = uvs;
        mesh.RecalculateNormals();
    }
}