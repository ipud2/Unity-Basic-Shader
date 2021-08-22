using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;

//using System.Drawing;//需要引用 System.Drawing.Dll 才能读取bmp

using Bitmap = System.Drawing.Bitmap;
using BitmapColor = System.Drawing.Color;
using System.Diagnostics;

namespace FaceSDFConsole
{
    class FaceSDF
    {
        static void Main(string[] args)
        {
            Console.WriteLine("拖一张图片则生成该图片的SDF，拖一个文件夹则生成SDF过渡图");
            Console.WriteLine();
            Console.WriteLine("贴图命名必须是数字，且是bmp格式，图片数量至少15张，(15张1024像素的图片大概需要90s)");

            Console.WriteLine();

            //Console.WriteLine("等待时间可以喝一杯瑞幸咖啡...");

            Console.WriteLine();

            /*
            string path = @"E:\Project\VSPRoject\FaceSDFConsole\test.bmp";
            Bitmap bitmap = new Bitmap(path);
            //颜色范围 0-255
            BitmapColor color = bitmap.GetPixel(2, 2);

            Console.WriteLine("width: "+ color);
            */



            //new TA.FaceSDF(args);
            DateTime beforDT = System.DateTime.Now;

           //new TA.FaceSDF(new string[]{ @"E:\Project\VSPRoject\FaceSDFConsole\bin\Debug\SDF" });
           new TA.FaceSDF(args);

            DateTime afterDT = System.DateTime.Now;
            TimeSpan ts = afterDT.Subtract(beforDT);
            Console.WriteLine("用时{0}s.", (int)(ts.TotalMilliseconds*0.001f));

            Console.ReadKey();

        }
    }
}

namespace TA
{
    public class Mathf
    {
        public static float SmoothUnion(float d1, float d2, float k)
        {
            float h = TA.Mathf.Clamp(0.5f + 0.5f * (d2 - d1) / k, 0.0f, 1.0f);
            return TA.Mathf.Clamp (TA.Mathf.Lerp(d2, d1, h) - k * h * (1.0f - h),0f,1f);
        }

        public static float Clamp(float value,float min,float max)
        {
            if (value > max) value = max;
            if (value < min) value = min;
            return value;
        }

        public static float Lerp(float beign, float end, float percent)
        {
            return beign * (1 - percent) + end * percent;
        }

        public static float Sqrt(float Square)
        {
            return (float)System.Math.Sqrt((double)Square);
        }
    }

    public class Color
    {
        public float r, g, b;
        public Color(float r, float g, float b)
        {
            this.r = r;
            this.g = g;
            this.b = b;
        }

        public Color(BitmapColor bitmapColor)
        {
            this.r = (float)(bitmapColor.R) / 255.0f;
            this.g = (float)(bitmapColor.G) / 255.0f;
            this.b = (float)(bitmapColor.B) / 255.0f;
        }

        public static BitmapColor ColorToBitmapColor(Color color)
        {
            return BitmapColor.FromArgb((int)(color.r * 255), (int)(color.g * 255), (int)(color.b * 255));
        }
    }

    public class Texture2D
    {
        public Bitmap bitmap;

        public int width
        {
            get
            {
                return bitmap.Width;
            }
        }

        public int height
        {
            get
            {
                return bitmap.Height;
            }
        }

        public void Save(string path)
        {
            bitmap.Save(path);
        }


        public Texture2D(Texture2D other)
        {
            //bitmap = other.bitmap.Clone(new System.Drawing.Rectangle(0,0, other.bitmap.Width, other.bitmap.Height), other.bitmap.PixelFormat);
            bitmap = new Bitmap( other.bitmap);
        }

        public static Texture2D Load(string file)
        {
            Texture2D newTex = new Texture2D();
            newTex.bitmap =new Bitmap(file);
            return newTex;
        }

        public Texture2D()
        {

        }

        public Texture2D(int width, int height)
        {
            bitmap = new Bitmap(width, height);
        }

        public Color GetPixel(int x, int y)
        {
            BitmapColor bitmapColor = bitmap.GetPixel(x, y);
            return new Color(bitmapColor);
        }

        public void SetPixel(int x, int y, Color color)
        {
            bitmap.SetPixel(x, y, Color.ColorToBitmapColor(color));
        }

        public void SetPixels(Color[] pixels)
        {
            for (int y = 0; y < height; y++)
            {
                for (int x = 0; x < width; x++)
                {
                    bitmap.SetPixel(x, y, Color.ColorToBitmapColor(pixels[y*width+x]));
                }
            }
        }
    }

    public class FaceSDF
    {
        string sdfFolderPath = "";
        int copyCount = 0;

        public FaceSDF(string[] args)
        {
            if (args == null || args.Length == 0)
                return;

            this.sdfFolderPath = args[0];

            //如果是单张图片则 直接生成一个SDF
            if(File.Exists(this.sdfFolderPath))
            {
                Texture2D tex = Texture2D.Load(this.sdfFolderPath);

                Texture2D SDFTex = GenSDFSingle(tex);

                string SDFName = Path.GetFileNameWithoutExtension(sdfFolderPath);
                SDFName += "_SDF.bmp";
                SDFTex.Save(SDFName);
                return;
            }

            List<Texture2D> TexList = null;

            if (Directory.Exists(this.sdfFolderPath))
            {
                string[] files = Directory.GetFiles(this.sdfFolderPath);

                TexList = GetTextures(files);
            }

            string name = Path.GetFileNameWithoutExtension(sdfFolderPath);

            string parent = Path.GetDirectoryName(sdfFolderPath);
            if (Directory.Exists(parent))
            {
                string[] files = Directory.GetFiles(parent);
                foreach (string file in files)
                {
                    //Console.WriteLine("@ " + file);
                    if (file.EndsWith("FaceSDF.bmp")) copyCount++;
                }
            }

            Console.WriteLine("重复命名数量:"+ copyCount);

            /*
            string append = copyCount > 0 ? copyCount.ToString() : "";
            Console.WriteLine("@ " + this.sdfFolderPath + append + "_FaceSDF.bmp");
            return;
            */


            Console.WriteLine("开始: " + sdfFolderPath);
            


            /*
            SDFGenerator sdfMaker = new SDFGenerator();
            Texture2D testTest = sdfMaker.GenerateSDF8ssedt(TexList[0]);
            testTest.Save(this.sdfFolderPath + "_SDF8ssedt.bmp");
            Console.WriteLine("SDF8ssedt 已经完成!!!");
            return;
            */

            if (TexList!=null)
            {
                //Test();
                BeginSDF(TexList);
            }
            else
            {
                Console.WriteLine("贴图错误！！！");
            }

            Console.WriteLine("SDF 已经完成!!!");
        }

        void Test(List<Texture2D> TexList)
        {
            if (TexList.Count == 0) return;
            Texture2D tex = TexList[0];

            //tex = GetBaseMask(tex);

            tex = Blur_Box(tex, 10);
            tex.Save(this.sdfFolderPath + "_BaseMask.bmp");

        }

        List<Texture2D> GetTextures(string[] files)
        {
            //Texture2D tex = Texture2D.Load(files[0]);

            //名字排序
            Dictionary<int, string> dic = new Dictionary<int, string>();
            List<int> FileIndexArray = new List<int>();

            for (int i = 0; i < files.Length; i++)
            {
                int fileName;
                if (!int.TryParse(Path.GetFileNameWithoutExtension(files[i]), out fileName))
                    continue;
                FileIndexArray.Add(fileName);
                dic.Add(fileName, files[i]);
            }

            if(FileIndexArray.Count<15)
            {
                Console.WriteLine("贴图数量必须15张以上!!");
                return null;
            }

            FileIndexArray = FileIndexArray.OrderBy(a=>a).ToList();

            List<Texture2D> texs = new List<Texture2D>();
            foreach (var index in FileIndexArray)
            {
                string file = dic[index];
                texs.Add( Texture2D.Load(file));
            }

            return texs;
        }

        void BeginSDF(List<Texture2D> TexList)
        {
            if (TexList.Count == 0) return;

          

            Texture2D tex = GenSDF(TexList);
          

            Texture2D BaseMask = GetBaseMask(tex);

            tex = Blur_Box(tex, 1f);
            tex = Blur_Box(tex, 3f);
            tex = Blur_Box(tex, 5f);

            tex = Multiply(BaseMask, tex);

            //TODO Save
            string append = copyCount > 0 ? copyCount.ToString() : "";
            string outputPath = this.sdfFolderPath + append + "_FaceSDF.bmp";
            FileUtility.SaveBMP(tex, outputPath);
        }

        Texture2D GenSDFSingle(Texture2D Tex)
        {
            SDFGenerator sdfMaker = new SDFGenerator();
            Texture2D sdf = sdfMaker.GenerateSDF8ssedt(Tex);
            return sdf;
        }

        Texture2D GenSDF(List<Texture2D> TexList)
        {
            SDFGenerator sdfMaker = new SDFGenerator();
            List<Texture2D> SDFTextures = new List<Texture2D>();

            for (int i = 0; i < TexList.Count; i++)
            {
                Console.WriteLine("SDF进度:" + ((float)(i) / (float)(TexList.Count)).ToString());
                Texture2D sdf = sdfMaker.GenerateSDF8ssedt(TexList[i]);
                SDFTextures.Add(sdf);
            }

            List<Texture2D> BlurTexs = new List<Texture2D>();
            for (int i = 0; i < SDFTextures.Count - 1; i++)
            {
                Console.WriteLine("SDF Blend进度:" + ((float)(i) / (float)(TexList.Count)).ToString());
                Texture2D blurTex = SDFBlend(SDFTextures[i], SDFTextures[i + 1], 400);
                BlurTexs.Add(blurTex);
            }

            Texture2D averageTexture = AverageTexture(BlurTexs);
            return averageTexture;
        }

        private Texture2D AverageTexture(List<Texture2D> texs)
        {
            Console.WriteLine("SDF 正在混合!");
            int WIDTH = texs[0].width;
            int HEIGHT = texs[0].height;
            Color[] pixels = new Color[WIDTH * HEIGHT];

            for (int y = 0; y < HEIGHT; y++)
            {
                for (int x = 0; x < WIDTH; x++)
                {
                    float c = 0;
                    foreach (Texture2D tex in texs)
                    {
                        c += tex.GetPixel(x, y).r;
                    }
                    c /= texs.Count;
                    pixels[y * WIDTH + x] = new Color(c, c, c);
                }
            }

            Texture2D outTex = new Texture2D(WIDTH, HEIGHT);
            outTex.SetPixels(pixels);
            //outTex.Apply();
            return outTex;
        }

        private Texture2D SDFBlend(Texture2D sdf1, Texture2D sdf2, int sampletimes)
        {
            int WIDTH = sdf1.width;
            int HEIGHT = sdf1.height;
            Color[] pixels = new Color[WIDTH * HEIGHT];
            for (int y = 0; y < HEIGHT; y++)
            {
                for (int x = 0; x < WIDTH; x++)
                {
                    var dis1 = sdf1.GetPixel(x, y);
                    var dis2 = sdf2.GetPixel(x, y);
                    var c = SDFLerp(sampletimes, dis1.r, dis2.r);
                    pixels[y * WIDTH + x] = new Color(c, c, c);
                }
            }
            Texture2D outTex = new Texture2D(WIDTH, HEIGHT);
            outTex.SetPixels(pixels);
            //outTex.Apply();
            return outTex;
        }

        private float SDFLerp(int sampletimes, float dis1, float dis2)
        {
            //float SampleTimes = 400;//400次效果比较好
            float res = 0f;
            if (dis1 < 0.5f && dis2 < 0.5f)
                return 1.0f;
            if (dis1 >= 0.5f && dis2 >= 0.5f)
                return 0f;
            for (int i = 0; i < sampletimes; i++)
            {
                float lerpValue = (float)i / sampletimes;
                res += Mathf.Lerp(dis1, dis2, lerpValue) < 0.5f ? 1 : 0;
            }
            return res / sampletimes;
        }

        private Texture2D GetBaseMask(Texture2D Tex)
        {
            int WIDTH = Tex.width;
            int HEIGHT = Tex.height;
            Color[] pixels = new Color[WIDTH * HEIGHT];
            for (int y = 0; y < HEIGHT; y++)
            {
                for (int x = 0; x < WIDTH; x++)
                {
                    float c = Tex.GetPixel(x, y).r > 0 ? 1 : 0;
                    pixels[y * WIDTH + x] = new Color(c, c, c);
                }
            }
            Texture2D outTex = new Texture2D(WIDTH, HEIGHT);

           

            outTex.SetPixels(pixels);
            //Console.WriteLine("width: " + outTex.bitmap.GetPixel(25,25));
            //return null;

            //outTex.Apply();
            return outTex;
        }

        private Texture2D Multiply(Texture2D Tex1, Texture2D Tex2)
        {
            int WIDTH = Tex1.width;
            int HEIGHT = Tex1.height;
            Color[] pixels = new Color[WIDTH * HEIGHT];
            for (int y = 0; y < HEIGHT; y++)
            {
                for (int x = 0; x < WIDTH; x++)
                {
                    float c = Tex1.GetPixel(x, y).r * Tex2.GetPixel(x, y).r;
                    pixels[y * WIDTH + x] = new Color(c, c, c);
                }
            }
            Texture2D outTex = new Texture2D(WIDTH, HEIGHT);
            outTex.SetPixels(pixels);
            //outTex.Apply();
            return outTex;
        }


        /// <summary>
        /// 均值模糊
        /// </summary>
        /// <param name="Tex"></param>
        /// <param name="Radius"></param>
        /// <returns></returns>
        private Texture2D Blur_Box(Texture2D Tex, float Radius = 1)
        {
            int WIDTH = Tex.width;
            int HEIGHT = Tex.height;
            Color[] pixels = new Color[WIDTH * HEIGHT];
            for (int y = 0; y < HEIGHT; y++)
            {
                for (int x = 0; x < WIDTH; x++)
                {
                    float SampleCount = 0;
                    float ConvolutionValue = 0;
                    for (int dy = -1; dy <= Radius; dy++)
                    {
                        for (int dx = -1; dx <= Radius; dx++)
                        {
                            int posX = x + dx;
                            int posY = y + dy;
                            if (0 <= posX && posX < WIDTH && 0 <= posY && posY < HEIGHT)
                            {
                                SampleCount++;
                                ConvolutionValue += Tex.GetPixel(posX, posY).r;
                            }
                        }
                    }

                    float c = ConvolutionValue / SampleCount;
                    pixels[y * WIDTH + x] = new Color(c, c, c);
                }
            }

            Texture2D outTex = new Texture2D(WIDTH, HEIGHT);
            outTex.SetPixels(pixels);
            //outTex.Apply();
            return outTex;
        }

        private Texture2D Blur_Gauss(Texture2D Tex, float Radius = 1)
        {
            return null;
        }
    }

    public class FileUtility
    {
        public static Texture2D DuplicateTexture(Texture2D source)
        {
            return new Texture2D(source);
        }

        public static void SaveBMP(Texture2D src, string outpath)
        {
            src.Save(outpath);
        }
    }

    public class SDFGenerator
    {
        private class Point
        {
            public int dx, dy;

            public Point(int x, int y)
            {
                dx = x;
                dy = y;
            }

            public Point(Point p)
            {
                dx = p.dx;
                dy = p.dy;
            }

            public float DistSq
            {
                get { return dx * dx + dy * dy; }
            }
        }

        private class Grid
        {
            public Point[,] outsideGrid;
            public Point[,] insideGrid;

            public Grid(int height, int width)
            {
                outsideGrid = new Point[height, width];
                insideGrid = new Point[height, width];
            }
        }

        private Point inside = new Point(0, 0);
        private Point empty = new Point(999, 999);
        private int WIDTH, HEIGHT;

        public Texture2D GenerateSDF8ssedt(Texture2D source)
        {
            WIDTH = source.width;
            HEIGHT = source.height;
            var srcTex = FileUtility.DuplicateTexture(source);

            //var bitmap = source.bitmap.Clone(new System.Drawing.Rectangle(0, 0, source.bitmap.Width, source.bitmap.Height), source.bitmap.PixelFormat);
            //Console.WriteLine("@ " + srcTex.bitmap.GetPixel(14, 15));
            //return null;

            Grid sdf_grid = new Grid(WIDTH, HEIGHT);
            for (int x = 0; x < WIDTH; x++)
            {
                for (int y = 0; y < HEIGHT; y++)
                {
                    Color pixel = srcTex.GetPixel(x, y);
                    if (pixel.r > 0.1f)
                    {
                        sdf_grid.insideGrid[x, y] = inside;
                        sdf_grid.outsideGrid[x, y] = empty;
                    }
                    else
                    {
                        sdf_grid.insideGrid[x, y] = empty;
                        sdf_grid.outsideGrid[x, y] = inside;
                    }
                }
            }

            var insideMax = SDF8ssedtCore(ref sdf_grid.insideGrid);
            var outsideMax = SDF8ssedtCore(ref sdf_grid.outsideGrid);

            Color[] pixels = new Color[WIDTH * HEIGHT];
            for (int y = 0; y < HEIGHT; y++)
            {
                for (int x = 0; x < WIDTH; x++)
                {
                    float dist1 = Mathf.Sqrt(sdf_grid.insideGrid[x, y].DistSq);
                    float dist2 = Mathf.Sqrt(sdf_grid.outsideGrid[x, y].DistSq);

                    float dist = dist1 - dist2;
                    float c = 0.5f;

                    if (dist < 0) //pixel inside,color range 0-0.5
                    {
                        c += dist / outsideMax * 0.5f;
                    }
                    else //pixel outside,color range 0.5-1
                    {
                        c += dist / insideMax * 0.5f;
                    }

                    // pixels[y*WIDTH +x] = new Color((float)c, Mathf.Clamp01(insideMax / maxBase), Mathf.Clamp01(outsideMax / maxBase));
                    pixels[y * WIDTH + x] = new Color((float)c, c, c);
                }
            }

            Texture2D outTex = new Texture2D(WIDTH, HEIGHT);
            outTex.SetPixels(pixels);
            //outTex.Apply();
            return outTex;
        }

        private Point Get(Point[,] grid, int x, int y)
        {
            if (x >= 0 && y >= 0 && x < WIDTH && y < HEIGHT)
                return new Point(grid[y, x]);
            return new Point(empty);
        }

        private void Compare(ref Point[,] grid, ref Point p, int x, int y, int offsetx, int offsety)
        {
            Point other = Get(grid, offsetx + x, offsety + y);
            other.dx += offsetx;
            other.dy += offsety;

            if (other.DistSq < p.DistSq)
                p = other;
        }

        private float SDF8ssedtCore(ref Point[,] g)
        {
            float maxValue = -1f;
            // Pass 0
            for (int y = 0; y < HEIGHT; y++)
            {
                for (int x = 0; x < WIDTH; x++)
                {
                    Point p = Get(g, x, y);
                    Compare(ref g, ref p, x, y, -1, 0);
                    Compare(ref g, ref p, x, y, 0, -1);
                    Compare(ref g, ref p, x, y, -1, -1);
                    Compare(ref g, ref p, x, y, 1, -1);
                    g[y, x] = p;
                }

                for (int x = WIDTH - 1; x >= 0; x--)
                {
                    Point p = Get(g, x, y);
                    Compare(ref g, ref p, x, y, 1, 0);
                    g[y, x] = p;
                }
            }

            // Pass 1
            for (int y = HEIGHT - 1; y >= 0; y--)
            {
                for (int x = WIDTH - 1; x >= 0; x--)
                {
                    Point p = Get(g, x, y);
                    Compare(ref g, ref p, x, y, 1, 0);
                    Compare(ref g, ref p, x, y, 0, 1);
                    Compare(ref g, ref p, x, y, -1, 1);
                    Compare(ref g, ref p, x, y, 1, 1);
                    g[y, x] = p;
                }

                for (int x = 0; x < WIDTH; x++)
                {
                    Point p = Get(g, x, y);
                    Compare(ref g, ref p, x, y, -1, 0);
                    g[y, x] = p;
                    if (maxValue < p.DistSq)
                    {
                        maxValue = p.DistSq;
                    }
                }
            }

            return (float)Mathf.Sqrt(maxValue);
        }

    }
}