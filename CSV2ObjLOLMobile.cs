using System;
using System.IO;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Csv2ObjLolMobile
{
    struct Vector3
    {
        public float x, y, z;
        public Vector3(float x, float y, float z)
        {
            this.x = x;
            this.y = y;
            this.z = z;
        }
    }
    struct Vector2
    {
        public float x, y;
        public Vector2(float x, float y)
        {
            this.x = x;
            this.y = y;
        }
    }

    struct Color
    {
        public float r, g, b, a;
        public Color(float r, float g, float b, float a)
        {
            this.r = r;
            this.g = g;
            this.b = b;
            this.a = a;
        }
    }

    class MeshData
    {
        public List<int> VTX;
        public List<int> IDX;
        public List<Vector3> Position;
        public List<Vector3> Normal;
        public List<Color> VertexColor;
        public List<Vector2> Texcoord0;
        public List<Vector2> Texcoord1;
        public MeshData()
        {
            this.VTX = new List<int>();
            this.IDX = new List<int>();
            this.Position = new List<Vector3>();
            this.Normal = new List<Vector3>();
            this.VertexColor = new List<Color>();
            this.Texcoord0 = new List<Vector2>();
            this.Texcoord1 = new List<Vector2>();
        }
    }

    class Csv2Obj
    {
        public Csv2Obj(string[] args)
        {
            foreach (string arg in args)
            {
                //Console.WriteLine("Begin");

                Console.WriteLine("Begin Parse:" + arg);

                if (Directory.Exists(arg))
                {
                    string[] files = Directory.GetFiles(arg);
                    ParseFolder(files);
                }
                else if (File.Exists(arg) && arg.EndsWith(".csv"))
                {
                    ParseFile(arg);
                }
            }

            Console.ReadKey();
        }

        public void ParseFolder(string[] files)
        {
            foreach (var file in files)
            {
                ParseFile(file);
            }

        }

        public void ParseFile(string path)
        {
            Console.WriteLine("Parse:   " + path);

            string[] lines = File.ReadAllLines(path);

            MeshData meshData = new MeshData();

            for (int i = 1; i < lines.Length; i++)
            {
                var line = lines[i];
                string[] words = line.Split(',');

                int index = 0;
                meshData.VTX.Add(int.Parse(words[index++]));
                meshData.IDX.Add(int.Parse(words[index++]));
                meshData.Position.Add(new Vector3(float.Parse(words[index++]), float.Parse(words[index++]), float.Parse(words[index++])));
                meshData.Texcoord0.Add(new Vector2(float.Parse(words[index++]), 1f - float.Parse(words[index++]))); //uv颠倒了
                meshData.Texcoord1.Add(new Vector2(float.Parse(words[index++]), 1f - float.Parse(words[index++])));//uv颠倒了
                meshData.Normal.Add(new Vector3(float.Parse(words[index++]), float.Parse(words[index++]), float.Parse(words[index++])));
                meshData.VertexColor.Add(new Color(float.Parse(words[index++]), float.Parse(words[index++]), float.Parse(words[index++]), float.Parse(words[index++])));
            }

            string objPath = path.Replace(".csv", ".obj");
            string objText = "";
            if (File.Exists(objPath))
            {
                File.Delete(objPath);
            }

            foreach (Vector3 v in meshData.Position)
            {
                objText += "v " + v.x + " " + v.y + " " + v.z + System.Environment.NewLine;
            }

            foreach (Vector2 v in meshData.Texcoord0)
            {
                objText += "vt " + v.x + " " + v.y + System.Environment.NewLine;
            }

            foreach (Vector3 v in meshData.Normal)
            {
                objText += "vn " + v.x + " " + v.y + " " + v.z + System.Environment.NewLine;
            }

            objText += "usemtl None" + System.Environment.NewLine;
            objText += "s off" + System.Environment.NewLine;

            for (int i = 0; i < meshData.VTX.Count; i += 3)
            {
                objText += "f ";
                int index = i;
                index++;
                objText += (index + "/" + index + "/" + index) + " ";
                index++;
                objText += (index + "/" + index + "/" + index) + " ";
                index++;
                objText += (index + "/" + index + "/" + index) + " ";
                objText += System.Environment.NewLine;
            }
            File.WriteAllText(objPath, objText);
            Console.WriteLine("Done:  " + path);
        }
    }

    class Program
    {
        static void Main(string[] args)
        {
            new Csv2Obj(args);
        }
    }
}
