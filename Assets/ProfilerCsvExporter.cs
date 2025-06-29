
using System.IO;
using System.Text;
using Unity.EditorCoroutines.Editor;
using Unity.Profiling;
using UnityEditor;
using UnityEngine;
using UnityEngine.Profiling;

public class ProfilerCsvExporter : EditorWindow
{

    [MenuItem("Tools/Export Profiler CSV/Record 10 s")]
    private static void Record10() => RecordSeconds(10);

    [MenuItem("Tools/Export Profiler CSV/Record 30 s")]
    private static void Record30() => RecordSeconds(30);

    [MenuItem("Tools/Export Profiler CSV/Record 60 s")]
    private static void Record60() => RecordSeconds(60);


    private static void RecordSeconds(int seconds)
    {
        if (!EditorApplication.isPlaying)
        {
            Debug.LogWarning("Enter Play Mode first, then run the exporter.");
            return;
        }

        EditorCoroutineUtility.StartCoroutineOwnerless(RecordCoroutine(seconds));
    }


    private static System.Collections.IEnumerator RecordCoroutine(int seconds)
    {
        var cpuRec = ProfilerRecorder.StartNew(
            ProfilerCategory.Internal, "Main Thread", 1);
        var gpuRec = ProfilerRecorder.StartNew(
            ProfilerCategory.Render, "GPU Frame Time", 1);

        float endTime = Time.realtimeSinceStartup + seconds;
        int frame = 0;


        var cpuCsv = new StringBuilder("Frame,TimeMs\n");
        var gpuCsv = new StringBuilder("Frame,TimeMs\n");
        var dtCsv = new StringBuilder("Frame,TimeMs\n");
        var fpsCsv = new StringBuilder("Frame,FPS\n");

        Debug.Log($"[CSV Export] Recording for {seconds} seconds …");

        while (Time.realtimeSinceStartup < endTime)
        {
            yield return new WaitForEndOfFrame();

 
            float dtMs = Time.deltaTime * 1000f;
            dtCsv.Append(frame).Append(',').Append(dtMs).Append('\n');
            fpsCsv.Append(frame).Append(',').Append(1000f / dtMs).Append('\n');

      
            float cpuMs = cpuRec.LastValue / 1_000_000f;
            cpuCsv.Append(frame).Append(',').Append(cpuMs).Append('\n');

       
            if (gpuRec.LastValue > 0)
            {
                float gpuMs = gpuRec.LastValue / 1_000_000f;
                gpuCsv.Append(frame).Append(',').Append(gpuMs).Append('\n');
            }
            frame++;
        }

        cpuRec.Dispose();
        gpuRec.Dispose();

        WriteCsv("Profiler_CPU.csv", cpuCsv);
        WriteCsv("Profiler_GPU.csv", gpuCsv);
        WriteCsv("Profiler_Delta.csv", dtCsv);
        WriteCsv("Profiler_FPS.csv", fpsCsv);

        Debug.Log($"[CSV Export] Done. {frame} frames captured.");
    }


    private static void WriteCsv(string fileName, StringBuilder sb)
    {
        string path = Path.GetFullPath(
            Path.Combine(Application.dataPath, "..", fileName));
        File.WriteAllText(path, sb.ToString(), Encoding.UTF8);
        AssetDatabase.Refresh();
    }
}
