using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.Rendering;

namespace TA
{
    public class SSAA : MonoBehaviour
    {

        public enum Level
        {
            x1 = 1,
            x2 = 2,
            x3 = 3,
            x4 = 4,
            x5 = 5,
            x6 = 6,
            x7 = 7,
            x8 = 8,
        };
        

        public Level level = Level.x3;

        // Start is called before the first frame update
        void Start()
        {
            // Init();
        }

        private Material mat = null;
        private RenderTexture SSAART = null;
        // private Camera camera = null;

        public void SetRT()
        {
            float scale = (int)level;
            var graphicsFormat = SystemInfo.GetCompatibleFormat(GraphicsFormatUtility.GetGraphicsFormat(RenderTextureFormat.Default, false), FormatUsage.MSAA8x);
            var depthRTDesc = new RenderTextureDescriptor((int)(Screen.width*3), (int)(Screen.height*3), graphicsFormat,32);
            depthRTDesc.sRGB = false;
            depthRTDesc.memoryless = RenderTextureMemoryless.None;
            depthRTDesc.msaaSamples = 8;
            depthRTDesc.autoGenerateMips = false;
            depthRTDesc.useMipMap = false;
            
            QualitySettings.antiAliasing = 8;
            QualitySettings.shadowResolution = ShadowResolution.VeryHigh;
            // SSAART =  new RenderTexture(Screen.width*scale, Screen.height*scale,-1);
            SSAART =  new RenderTexture(depthRTDesc);
            cam.targetTexture = SSAART;
            cam.allowMSAA = true;
        }

        private Camera cam = null;
        public void Init()
        {
            Camera HeroCam = GetComponent<Camera>();
            // GameObject newCam = new GameObject("newCam");
            GameObject newCam = Instantiate<GameObject>(gameObject);
            if (newCam.GetComponent<SSAA>())
            {
                Destroy(newCam.GetComponent<SSAA>());
            }
            newCam.transform.position = gameObject.transform.position;
            newCam.transform.rotation = gameObject.transform.rotation;
            newCam.transform.localScale = gameObject.transform.localScale;
            // Camera cam = newCam.AddComponent<Camera>();
            cam = newCam.GetComponent<Camera>();
            cam.CopyFrom(HeroCam);
            SetRT();
            Shader.SetGlobalTexture("SSAART",SSAART);
        }

        private void OnRenderImage(RenderTexture src, RenderTexture dest)
        {
            if (mat == null)
            {
                mat = new Material(Shader.Find("TA/SSAA"));
            }

            Graphics.Blit(src, dest, mat);
        }
    }
}