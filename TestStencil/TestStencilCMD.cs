using System;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

public class TestStencilCMD : MonoBehaviour
{
    private CommandBuffer commandBuffer;
    private Material stencilTestMaterial;
    
    RenderTexture TempRT;

    private CameraEvent CamEvent = CameraEvent.AfterSkybox;
    private Camera camera;
    
    void OnEnable()
    {
        if (TempRT == null)
        {
            TempRT = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.DefaultHDR);
            TempRT.Create();
        }
        
        camera = GetComponent<Camera>();
        camera.clearStencilAfterLightingPass = true;

        // 初始化材质
        stencilTestMaterial = new Material(Shader.Find("Unlit/TestStencil"));

        // 创建命令缓冲区
        commandBuffer = new CommandBuffer {name = "Stencil Test"};
        
        // 清空命令缓冲区
        commandBuffer.Clear();
        // 设置渲染目标为当前渲染纹理
        //commandBuffer.SetRenderTarget(TempRT);
        //commandBuffer.ClearRenderTarget(true,true,Color.black);
        //stencilTestMaterial.SetTexture("_MainTex", BuiltinRenderTextureType.CameraTarget);
        // 执行Stencil测试并渲染全屏四边形
        commandBuffer.DrawMesh(CreateFullscreenTriangle(), Matrix4x4.identity, stencilTestMaterial, 0, 0);
        //commandBuffer.Blit(TempRT,BuiltinRenderTextureType.CameraTarget);
        
        // 设置命令缓冲区在摄像机渲染之后执行
        camera.AddCommandBuffer(CamEvent, commandBuffer);
    }
    

    private void OnDisable()
    {
        //释放RT内存
         if (TempRT != null)
         {
             TempRT.Release();
         }
         camera.RemoveCommandBuffer(CamEvent,commandBuffer);
    }

    private Mesh FullscreenTriangle = null;

    private Mesh CreateFullscreenTriangle()
    {
        // if (FullscreenTriangle == null)
        {
            Mesh mesh = new Mesh();

            mesh.vertices = new Vector3[]
            {
                new Vector3(-1, -1, 0),
                new Vector3(-1, 3, 0),
                new Vector3(3, -1, 0)
                
                // new Vector3(0, 0, 0),
                // new Vector3(0, 1, 0),
                // new Vector3(1, 1, 0)
            };

            mesh.triangles = new int[]
            {
                 0, 1,2
            };

            return mesh;
            // FullscreenTriangle = mesh;
        }

        // return FullscreenTriangle;
    }
}