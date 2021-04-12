using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

namespace TATools
{
    public class TextureArrayObject : ScriptableObject
    {
        public Texture2DArray texture2DArray;
        public List<string> names = new List<string>();
        public List<int> indexs = new List<int>();
    }

    public class TextureArrayCreator
    {
        // public static string ParentFold = "Assets/ArtAssets/Troop/Other/Shadow/";
        public static string Fold_ShadowParent = "Assets/ArtAssets/Troop/";
        public static string Fold_Texrue = "Assets/ArtAssets/Troop/Other/Shadow/ShadowTexture/";
        public static string Fold_ShadowPrefab = "Assets/ArtAssets/Troop/Other/Shadow/ShadowPrefab/";
        public static string Fold_ShadowMaterial = "Assets/ArtAssets/Troop/Other/Shadow/ShadowMaterial/";
        public static string Fold_ShadowData = "Assets/ArtAssets/Troop/Other/Shadow/ShadowData/";

        public static TextureFormat textureFormat = TextureFormat.ASTC_6x6;
        public static int Size = 256;

        public static TextureArrayObject textureArrayObject;

        [MenuItem("Tools/TA/生成阴影贴图Array")]
        public static TextureArrayObject BuildTextureArray()
        {
            // LoadTexturesScanFolder(Fold_ShadowParent);
            // return null;
            
            TextureArrayCreatorAsset asset = new TextureArrayCreatorAsset();
            // asset.m_allTextures = LoadTextures(Fold_Texrue);
            asset.m_allTextures = LoadTexturesScanFolder(Fold_ShadowParent);
            CreateFolders();
            BuildArray(asset);
            return textureArrayObject;
        }

        public static void CreateFolders()
        {
            List<string> folders = new List<string>();
            folders.Add(Fold_Texrue);
            folders.Add(Fold_ShadowPrefab);
            folders.Add(Fold_ShadowMaterial);
            folders.Add(Fold_ShadowData);

            foreach (string folder in folders)
            {
                if (!System.IO.Directory.Exists(folder))
                {
                    System.IO.Directory.CreateDirectory(folder);
                    Debug.Log("has folder:" + folder);
                }
                else
                {
                    Debug.Log("no folder:" + folder);
                }
            }
        }
        
        /// <summary>
        /// 计算MD5
        /// </summary>
        /// <param name="path"></param>
        /// <returns></returns>
        public static string CalcMD5(string path)
        {
            try
            {
                if (string.IsNullOrEmpty(path))
                    return string.Empty;
                if (md5Dict.TryGetValue(path, out var md5))
                    return md5;
                md5 = MD5Creater.MD5File(path);
                md5Dict.Add(path, md5);
                return md5;
            }
            catch (System.Exception e)
            {
                Debug.LogError(path + "\n " + e.ToString());
                return string.Empty;
            }
        }
        
        /// <summary>
        /// 路径->Md5
        /// </summary>
        static Dictionary<string, string> md5Dict = new Dictionary<string, string>();
        
        public static List<Texture2D> LoadTextures(string path)
        {
            List<Texture2D> array = GetAllAssetAtPath<Texture2D>(path);
            return array;
        }
        
        public static List<Texture2D> LoadTexturesScanFolder(string path)
        {
            List<Texture2D> allArray = new List<Texture2D>();
            
            allDirs.Clear();
            allDirs = new List<string>();
            
            GetAllDirectoriesAthPath (path);

            List<string> md5s = new List<string>();

            foreach (var dir in allDirs)
            {
                string[] files = System.IO.Directory.GetFiles(dir);
                foreach (var file in files)
                {
                    if (file.EndsWith("_S.png"))
                    {
                        string md5 = CalcMD5(file);
                        if (!md5s.Contains(md5))
                        {
                            Debug.Log("ShaodwFile:"+file);
                            Debug.Log("md5:"+md5);                            
                            md5s.Add(md5);
                            Texture2D array = UnityEditor.AssetDatabase.LoadAssetAtPath<Texture2D>(file);
                            allArray.Add(array);
                        }
                    }                    
                }
            }
            return allArray;
        }

        private static List<string> allDirs = new List<string>();
        
        public static void GetAllDirectoriesAthPath(string path)
        {
            // List<string> dirs = new List<string>();
            string[] ds = System.IO.Directory.GetDirectories(path);
            if (ds.Length > 0)
            {
                for (int i = 0; i < ds.Length; i++)
                {
                    ds[i] += "/";
                }
                foreach (var d in ds)
                {
                    // Debug.Log("in dir:"+d);
                    allDirs.Add(d);
                    GetAllDirectoriesAthPath(d);
                }
            }
        }

        private static void CopyToArray(ref Texture2D from, ref Texture2DArray to, int arrayIndex, int mipLevel,
            bool compressed = true)
        {
            if (compressed)
            {
                Graphics.CopyTexture(from, 0, mipLevel, to, arrayIndex, mipLevel);
            }
            else
            {
                to.SetPixels(from.GetPixels(), arrayIndex, mipLevel);
                to.Apply();
            }
        }

        private static List<TextureFormat> UncompressedFormats = new List<TextureFormat>()
        {
            TextureFormat.RGBAFloat,
            TextureFormat.RGBAHalf,
            TextureFormat.ARGB32,
            TextureFormat.RGBA32,
            TextureFormat.RGB24,
            TextureFormat.Alpha8
        };

        private static void BuildArray(TextureArrayCreatorAsset asset)
        {
            int sizeX = asset.SizeX;
            int sizeY = asset.SizeY;
            string m_message = "";
            Texture m_lastSaved = null;

            Texture2DArray textureArray = new Texture2DArray(sizeX, sizeY, asset.AllTextures.Count,
                asset.SelectedFormatEnum, asset.MipMaps, asset.LinearMode);
            textureArray.wrapMode = asset.WrapMode;
            textureArray.filterMode = asset.FilterMode;
            textureArray.anisoLevel = asset.AnisoLevel;
            textureArray.Apply(false);
            RenderTexture cache = RenderTexture.active;
            RenderTexture rt = new RenderTexture(sizeX, sizeY, 0, RenderTextureFormat.ARGBFloat,
                RenderTextureReadWrite.Default);
            rt.Create();

            // shadowTextureArrayScriptObject shadowTextureArrayScriptObject =ScriptableObject.CreateInstance<shadowTextureArrayScriptObject>();

            for (int i = 0; i < asset.AllTextures.Count; i++)
            {
                // build report
                int widthChanges = asset.AllTextures[i].width < sizeX ? -1 : asset.AllTextures[i].width > sizeX ? 1 : 0;
                int heightChanges = asset.AllTextures[i].height < sizeY ? -1 :
                    asset.AllTextures[i].height > sizeY ? 1 : 0;
                if ((widthChanges < 0 && heightChanges <= 0) || (widthChanges <= 0 && heightChanges < 0))
                    m_message += asset.AllTextures[i].name + " was upscaled\n";
                else if ((widthChanges > 0 && heightChanges >= 0) || (widthChanges >= 0 && heightChanges > 0))
                    m_message += asset.AllTextures[i].name + " was downscaled\n";
                else if ((widthChanges > 0 && heightChanges < 0) || (widthChanges < 0 && heightChanges > 0))
                    m_message += asset.AllTextures[i].name + " changed dimensions\n";

                // blit image to upscale or downscale the image to any size
                RenderTexture.active = rt;

                bool cachedsrgb = GL.sRGBWrite;
                GL.sRGBWrite = !asset.LinearMode;
                Graphics.Blit(asset.AllTextures[i], rt);
                GL.sRGBWrite = cachedsrgb;

                bool isCompressed = UncompressedFormats.FindIndex(x => x.Equals(asset.SelectedFormatEnum)) < 0;
                TextureFormat validReadPixelsFormat = isCompressed ? TextureFormat.RGBAFloat : asset.SelectedFormatEnum;
                Texture2D t2d = new Texture2D(sizeX, sizeY, validReadPixelsFormat, asset.MipMaps, asset.LinearMode);
                t2d.ReadPixels(new Rect(0, 0, sizeX, sizeY), 0, 0, asset.MipMaps);
                RenderTexture.active = null;

                // TextureFormat
                if (isCompressed)
                {
                    EditorUtility.CompressTexture(t2d, asset.SelectedFormatEnum, asset.Quality);
                    t2d.Apply(false);
                }

                if (asset.MipMaps)
                {
                    int maxSize = Mathf.Max(sizeX, sizeY);
                    int numLevels = 1 + (int) Mathf.Floor(Mathf.Log(maxSize, 2));
                    for (int mip = 0; mip < numLevels; mip++)
                    {
                        CopyToArray(ref t2d, ref textureArray, i, mip, isCompressed);
                    }
                }
                else
                {
                    CopyToArray(ref t2d, ref textureArray, i, 0, isCompressed);
                }
            }

            rt.Release();
            RenderTexture.active = cache;
            if (m_message.Length > 0)
                m_message = m_message.Substring(0, m_message.Length - 1);

            // string path = ParentFold + Fold_ShadowData + asset.FileName + ".asset";
            string path = asset.FolderPath + asset.FileName + ".asset";
            Texture2DArray outfile = AssetDatabase.LoadMainAssetAtPath(path) as Texture2DArray;
            if (outfile != null)
            {
                EditorUtility.CopySerialized(textureArray, outfile);
                AssetDatabase.SaveAssets();
                EditorGUIUtility.PingObject(outfile);
                m_lastSaved = outfile;
                // CreateTextureArrayObject(asset, outfile, asset.FolderPath + asset.FileName + "Object.asset");
            }
            else
            {
                AssetDatabase.CreateAsset(textureArray, Fold_ShadowData + asset.FileName + ".asset");
                EditorGUIUtility.PingObject(textureArray);
                m_lastSaved = textureArray;
                // CreateTextureArrayObject(asset, textureArray, asset.FolderPath + asset.FileName + "Object.asset");
            }

            CreateTextureArrayObject(asset, m_lastSaved as Texture2DArray, asset.FolderPath + asset.FileName);
        }

        /// <summary>
        /// 生成TextureArrayScriptObject
        /// </summary>
        /// <param name="asset"></param>
        /// <param name="textureArray"></param>
        /// <param name="path"></param>
        private static void CreateTextureArrayObject(TextureArrayCreatorAsset asset, Texture2DArray textureArray,
            string path)
        {
            TextureArrayObject outfile = AssetDatabase.LoadMainAssetAtPath(path) as TextureArrayObject;
            if (outfile != null)
            {
                AssetDatabase.DeleteAsset(path);
                AssetDatabase.Refresh();
            }

            TextureArrayObject arrayObject = ScriptableObject.CreateInstance<TextureArrayObject>();
            for (int i = 0; i < asset.AllTextures.Count; i++)
            {
                // arrayObject.dic.Add( asset.AllTextures[ i ].name,i);
                arrayObject.names.Add(asset.AllTextures[i].name);
                arrayObject.indexs.Add(i);
            }

            arrayObject.texture2DArray = textureArray;
            string textureArrayPath = asset.FolderPath + asset.FileName + "Object.asset";
            AssetDatabase.CreateAsset(arrayObject, Fold_ShadowData + asset.FileName + "Object.asset");
            EditorGUIUtility.PingObject(arrayObject);

            //生成阴影QuadPrefab

            // string shadowQuadPath = asset.FolderPath + asset.FileName;
            // string shadowQuadPath = asset.FolderPath;

            for (int i = 0; i < arrayObject.names.Count; i++)
            {
                CreateShadowQuad(Fold_ShadowPrefab, arrayObject.names[i], arrayObject.indexs[i],
                    arrayObject.texture2DArray);
            }

            textureArrayObject = arrayObject;
        }

        private static void CreateShadowQuad(string shadowQuadPath, string name, int index,
            Texture2DArray texture2DArray)
        {
            string pathName = shadowQuadPath + name + ".prefab";

            GameObject go = new GameObject(name);
            // GameObject go = GameObject.CreatePrimitive((PrimitiveType.Quad));
            // go.AddComponent(typeof(Animation));
            //go.SetActiveRecursively(false);

            float width = 0.1f;
            float height = 0.1f;
            MeshRenderer meshRenderer = go.AddComponent<MeshRenderer>();
            meshRenderer.sharedMaterial = new Material(Shader.Find("TheWar/ShadowTextureArray"));
            MeshFilter meshFilter = go.AddComponent<MeshFilter>();
            Mesh mesh = new Mesh();
            Vector3[] vertices = new Vector3[4]
            {
                new Vector3(0, 0, 0),
                new Vector3(width, 0, 0),
                new Vector3(0, 0, height),
                new Vector3(width, 0, height)
            };
            mesh.vertices = vertices;

            int[] tris = new int[6]
            {
                // lower left triangle
                0, 2, 1,
                // upper right triangle
                2, 3, 1
            };
            mesh.triangles = tris;

            Vector3[] normals = new Vector3[4] {Vector3.up, Vector3.up, Vector3.up, Vector3.up};
            mesh.normals = normals;

            Vector2[] uv = new Vector2[4]
            {
                new Vector2(0, 0),
                new Vector2(1, 0),
                new Vector2(0, 1),
                new Vector2(1, 1)
            };
            mesh.uv = uv;
            meshFilter.mesh = mesh;

            Material material = new Material(Shader.Find("TheWar/ShadowTextureArray"));
            material.SetFloat("_Index", index);
            material.SetTexture("_TexArray", texture2DArray);

            AssetDatabase.CreateAsset(material, Fold_ShadowMaterial + name + "_Mat.Asset");
            AssetDatabase.CreateAsset(mesh, Fold_ShadowData + "ShadowQuadMesh.Asset");
            AssetDatabase.Refresh();
            meshRenderer.material = material;
            bool success;
            // PrefabUtility.SaveAsPrefabAsset(go, shadowQuadPath  +name+".Asset",out success);
            PrefabUtility.SaveAsPrefabAssetAndConnect(go, Fold_ShadowPrefab + name + ".Prefab",
                UnityEditor.InteractionMode.AutomatedAction);
            // AssetDatabase.CreateAsset(go, pathName);
            //Debug.Log("State:"+success);
            GameObject.DestroyImmediate(go);
        }

        public static List<T> GetAllAssetAtPath<T>(string path) where T : UnityEngine.Object
        {
            List<T> assetsFound = new List<T>();

            string[] filePaths = System.IO.Directory.GetFiles(path);
            int countFound = 0;

            if (filePaths != null && filePaths.Length > 0)
            {
                for (int i = 0; i < filePaths.Length; i++)
                {
                    UnityEngine.Object obj = UnityEditor.AssetDatabase.LoadAssetAtPath(filePaths[i], typeof(T));
                    if (obj is T asset)
                    {
                        countFound++;
                        if (!assetsFound.Contains(asset))
                        {
                            assetsFound.Add(asset);
                        }
                    }
                }
            }

            return assetsFound;
        }
    }

    public class TextureArrayCreatorAsset
    {
        [SerializeField] private int m_selectedSize = 4;

        [SerializeField] private bool m_lockRatio = true;

        [SerializeField] private int m_sizeX = 256;

        [SerializeField] private int m_sizeY = 256;

        [SerializeField] private bool m_tex3DMode = false;

        [SerializeField] private bool m_linearMode = false;

        [SerializeField] private bool m_mipMaps = false;

        [SerializeField] private TextureWrapMode m_wrapMode = TextureWrapMode.Repeat;

        [SerializeField] private FilterMode m_filterMode = FilterMode.Bilinear;

        [SerializeField] private int m_anisoLevel = 1;

        [SerializeField] private TextureFormat m_selectedFormatEnum = TextureFormat.ASTC_6x6;

        [SerializeField] private int m_quality = 100;

        [SerializeField] public string m_folderPath = "Assets/";

        [SerializeField] private string m_fileName = "ShadowTextureArray";

        [SerializeField] private bool m_filenameChanged = false;

        [SerializeField] public List<Texture2D> m_allTextures = new List<Texture2D>();

        public int SelectedSize
        {
            get { return m_selectedSize; }
        }

        public int SizeX
        {
            get { return m_sizeX; }
        }

        public int SizeY
        {
            get { return m_sizeY; }
        }

        public bool Tex3DMode
        {
            get { return m_tex3DMode; }
        }

        public bool LinearMode
        {
            get { return m_linearMode; }
        }

        public bool MipMaps
        {
            get { return m_mipMaps; }
        }

        public TextureWrapMode WrapMode
        {
            get { return m_wrapMode; }
        }

        public FilterMode FilterMode
        {
            get { return m_filterMode; }
        }

        public int AnisoLevel
        {
            get { return m_anisoLevel; }
        }

        public TextureFormat SelectedFormatEnum
        {
            get { return m_selectedFormatEnum; }
        }

        public int Quality
        {
            get { return m_quality; }
        }

        public string FolderPath
        {
            get { return m_folderPath; }
        }

        public string FileName
        {
            get { return m_fileName; }
        }

        public List<Texture2D> AllTextures
        {
            get { return m_allTextures; }
        }
    }
}