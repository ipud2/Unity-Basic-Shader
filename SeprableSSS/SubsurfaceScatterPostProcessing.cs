using System;
using System.Collections;
using System.Collections.Generic;
using UnityEditor.SearchService;
using UnityEngine;
using UnityEngine.Rendering;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class SubsurfaceScatterPostProcessing : MonoBehaviour
{
    [Range(2, 50)] public int nSamples = 25;
    [Range(0, 3)] public float scaler = 0.1f;
    public Color strength;
    public Color falloff;
    Camera mCam;
    CommandBuffer buffer;
    Material mMat;

    private static int BlurRTID = Shader.PropertyToID("_BlurRTID"); //用一个数代表现当前RT,_SceneID没有用在任何地方，这样返回的数不会和其他冲突
    private static int SSSScaler = Shader.PropertyToID("_SSSScaler");
    private static int SSSKernel = Shader.PropertyToID("_Kernel");
    private static int SSSSamples = Shader.PropertyToID("_Samples");
    
    private void OnEnable()
    {
        mCam = GetComponent<Camera>();
        mCam.depthTextureMode |= DepthTextureMode.Depth;
        mMat = new Material(Shader.Find("Unlit/SSS"));

        buffer = new CommandBuffer();
        buffer.name = "Separable Subsurface Scatter";
        mCam.clearStencilAfterLightingPass = true;
        mCam.AddCommandBuffer(CameraEvent.AfterForwardOpaque, buffer);
    }

    private RenderTexture BlurRT = null;
    private static Mesh mMesh;

    private static Mesh mesh
    {
        get
        {
            if (mMesh != null)
            {
                return mMesh;
            }

            mMesh = new Mesh();
            mMesh.vertices = new Vector3[]
            {
                new Vector3(-1, -1, 0),
                new Vector3(-1, 1, 0),
                new Vector3(1, 1, 0),
                new Vector3(1, -1, 0)
            };
            mMesh.uv = new Vector2[]
            {
                new Vector2(0, 1),
                new Vector2(0, 0),
                new Vector2(1, 0),
                new Vector2(1, 1)
            };
            mMesh.SetIndices(new int[] {0, 1, 2, 3}, MeshTopology.Quads, 0);
            return mMesh;
        }
    }
    
    private void Update()
    {
        if (Input.GetKeyDown(KeyCode.Space))
        {
            Debug.ClearDeveloperConsole();
            Vector3 normalizedStrength = Vector3.Normalize(new Vector3(strength.r, strength.g, strength.b));
            Vector3 normalizedFallOff = Vector3.Normalize(new Vector3(falloff.r, falloff.g, falloff.b));
            List<Vector4> kernel = KernelCalculator.CalculateKernel(nSamples, normalizedStrength, normalizedFallOff);
            for (int i = 0; i < kernel.Count; i++)
            {
                Debug.Log(kernel[i] * 1000f);
            }

            Debug.Log("2222223333333333333");
        }
    }

    private void OnPreRender()
    {
        Vector3 normalizedStrength = Vector3.Normalize(new Vector3(strength.r, strength.g, strength.b));
        Vector3 normalizedFallOff = Vector3.Normalize(new Vector3(falloff.r, falloff.g, falloff.b));
        List<Vector4> kernel = KernelCalculator.CalculateKernel(nSamples, normalizedStrength, normalizedFallOff);
             
        mMat.SetInt(SSSSamples, nSamples);
        mMat.SetVectorArray(SSSKernel, kernel);
        mMat.SetFloat(SSSScaler, scaler);
        
        // BlurRT = RenderTexture.GetTemporary(mCam.pixelWidth, mCam.pixelHeight, 0, RenderTextureFormat.DefaultHDR);
        
        buffer.Clear();
        // buffer.GetTemporaryRT(SceneID, mCam.pixelWidth, mCam.pixelHeight, 0, FilterMode.Trilinear, RenderTextureFormat.DefaultHDR);
        // buffer.BlitStencil(BuiltinRenderTextureType.CameraTarget, BlurRT, BuiltinRenderTextureType.CameraTarget, mMat, 0);
        buffer.GetTemporaryRT(BlurRTID,mCam.pixelWidth,mCam.pixelHeight,0,FilterMode.Trilinear,RenderTextureFormat.DefaultHDR);
        
        buffer.SetGlobalTexture(ShaderID._SourceTex, BuiltinRenderTextureType.CameraTarget);
        buffer.SetRenderTarget(BlurRTID);
        buffer.DrawMesh(mesh, Matrix4x4.identity, mMat, 0, 0);
        
        buffer.SetGlobalTexture(ShaderID._SourceTex, BlurRTID);
        buffer.SetRenderTarget(BuiltinRenderTextureType.CameraTarget);
        buffer.DrawMesh(mesh, Matrix4x4.identity, mMat, 0, 1);
        
        // buffer.BlitSRT(BlurRT, BuiltinRenderTextureType.CameraTarget, mMat, 1);
    }


    private void OnDisable()
    {
        // BlurRT.Release();
        buffer.ReleaseTemporaryRT(BlurRTID);
        mCam.RemoveCommandBuffer(CameraEvent.AfterForwardOpaque, buffer);
        buffer.Release();
    }
}