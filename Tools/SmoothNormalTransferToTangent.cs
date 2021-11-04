using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.IO;

namespace TA
{
    ///将smoothNormalMesh的法线，转移到mesh的切线中，
    ///其中smoothNormalMesh的法线是经过处理过的平滑后的法线

    public class SmoothNormalTransferToTangent: MonoBehaviour
    {
        public static Mesh CombineMeshNormalToTangent(Mesh mesh, Mesh smoothNormalMesh)
        {
            // Mesh smoothNormalMesh = SmoothNormalObj.GetComponent<MeshFilter>().mesh;
            Dictionary<Vector3, Vector3> dic = new Dictionary<Vector3, Vector3>();

            for (int i = 0; i < smoothNormalMesh.normals.Length; i++)
            {
                Vector3 pos = smoothNormalMesh.vertices[i];
                Vector3 nor = smoothNormalMesh.normals[i];
                if (!dic.ContainsKey(pos))
                {
                    dic.Add(pos,nor);                
                }
            }
            

            Mesh combineMesh = new Mesh();

            Vector3[] normals = new Vector3[mesh.normals.Length];
            Vector4[] tangents = new Vector4[mesh.tangents.Length];
            
            for (int i = 0; i < mesh.tangents.Length; i++)
            {
                // normals[i] = Vector3.right;
                Vector3 pos = mesh.vertices[i];

                if (dic.ContainsKey(pos))
                {
                    tangents[i] = dic[pos];
                    tangents[i].w = 0;
                }
            }
            
            // Debug.Log("keys:"+dic.Keys.Count);
            
            combineMesh.vertices = mesh.vertices;
            combineMesh.normals = mesh.normals;
            combineMesh.tangents = tangents;
            combineMesh.uv = mesh.uv;
            combineMesh.triangles = mesh.triangles;

            return combineMesh;
        }

        public static void SaveMesh(Mesh mesh,string dir, string filename)
        {
            AssetDatabase.CreateAsset(mesh, $"{dir}/{filename}_{mesh.name}_smooth.asset");
        }

        [MenuItem("TA/Tools/合并平滑法线 导出Mesh(仅平滑法线的Mesh需命名以_SmoothNomral结尾)")]
        public static void NormalTransfer()
        {
            if (Selection.gameObjects.Length != 2)
            {
                Debug.LogError("需要选择两个模型");
                return;
            }
            
            bool first = Selection.gameObjects[0].name.EndsWith("_SmoothNomral");
            bool second = Selection.gameObjects[1].name.EndsWith("_SmoothNomral");

            int bit1 = first ? 1 : 0;
            int bit2 = second ? 1 : 0;
            
            if ((bit1+bit2)!=1)
            {
                Debug.LogError("需要选择两个模型,仅平滑法线的Mesh需命名以_SmoothNomral结尾");
                return;
            }

            GameObject MeshGo =Selection.gameObjects[0];
            GameObject MeshSmoothNormalGo =Selection.gameObjects[1];

            if (first)
            {
                MeshGo =Selection.gameObjects[1];
                MeshSmoothNormalGo =Selection.gameObjects[0];
            }
            
            Debug.Log("MeshGo:"+MeshGo.name+" || " +"MeshSmoothNormalGo:"+MeshSmoothNormalGo.name);
            
            var MeshGoInstance = GameObject.Instantiate(MeshGo);
            var MeshSmoothNormalGoInstance = GameObject.Instantiate(MeshSmoothNormalGo);
        
            var path = AssetDatabase.GetAssetPath(Selection.gameObjects[0]);
            var dir = Path.GetDirectoryName(path);
            var filename = Path.GetFileNameWithoutExtension(path);

            {
                var meshfilters = MeshGoInstance.GetComponentsInChildren<MeshFilter>();
                var meshfilters2 = MeshSmoothNormalGoInstance.GetComponentsInChildren<MeshFilter>();

                if (meshfilters==null || meshfilters2==null|| meshfilters.Length != meshfilters2.Length)
                {
                    Debug.LogError("物体不一致");
                    return;
                }

                for (int i = 0; i < meshfilters.Length; i++)
                {
                    if (meshfilters[i].sharedMesh != null && meshfilters2[i].sharedMesh != null)
                    {
                        var mesh = CombineMeshNormalToTangent(meshfilters[i].sharedMesh, meshfilters2[i].sharedMesh);
                        SaveMesh(mesh, dir, MeshGo.name + "_SmoothMesh");
                    }
                }
                
            }
            
            {
                var meshfilters = MeshGoInstance.GetComponentsInChildren<SkinnedMeshRenderer>();
                var meshfilters2 = MeshSmoothNormalGoInstance.GetComponentsInChildren<SkinnedMeshRenderer>();

                if (meshfilters==null || meshfilters2==null|| meshfilters.Length != meshfilters2.Length)
                {
                    Debug.LogError("物体不一致");
                    return;
                }

                for (int i = 0; i < meshfilters.Length; i++)
                {
                    if (meshfilters[i].sharedMesh != null && meshfilters2[i].sharedMesh != null)
                    {
                        var mesh = CombineMeshNormalToTangent(meshfilters[i].sharedMesh, meshfilters2[i].sharedMesh);
                        SaveMesh(mesh, dir, MeshGo.name + "_SmoothMesh");
                    }
                }

            }
            
            GameObject.DestroyImmediate( MeshGoInstance);
            GameObject.DestroyImmediate( MeshSmoothNormalGoInstance);

        }

    }
}