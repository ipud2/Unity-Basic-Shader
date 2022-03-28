using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class SSPRRenderFeature : ScriptableRendererFeature
{
    public ComputeShader ssprCumpute;

   class CustomRenderPass : ScriptableRenderPass
   {
       private int width;
       private int height;
       
       public CustomRenderPass(ComputeShader ssprCumpute)
       {
           this.ssprCumpute = ssprCumpute;
       }
       ComputeShader ssprCumpute;

       private int kernel;
       private int kernelClear;
       
        // private RenderTargetIdentifier ssprRT;
        private RenderTargetHandle ssprRTHandle;
        private Material ssprMat;

        private static int id_ssprRT= Shader.PropertyToID("ssprRT");
        private static int id_IVP= Shader.PropertyToID("IVP");
        
        // This method is called before executing the render pass.
        // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
        // When empty this render pass will render to the active camera render target.
        // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
        // The render pipeline will ensure target setup and clearing happens in a performant manner.
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            if(!ssprCumpute)
                return;
            
            // ssprRTHandle = new RenderTargetHandle("sspr");
            ssprRTHandle.Init("ssprRT");
            ssprMat = new Material(Shader.Find(@"Unlit/SSPR"));
            
            RenderTextureDescriptor opaqueDesc = renderingData.cameraData.cameraTargetDescriptor;
            opaqueDesc.depthBufferBits = 0;
            opaqueDesc.enableRandomWrite = true;
            cmd.GetTemporaryRT(ssprRTHandle.id,opaqueDesc);
            cmd.SetGlobalTexture(id_ssprRT,ssprRTHandle.Identifier());

            width = renderingData.cameraData.cameraTargetDescriptor.width;
            height = renderingData.cameraData.cameraTargetDescriptor.height;
            
            kernel = ssprCumpute.FindKernel("CSMain");
            kernelClear = ssprCumpute.FindKernel("CSMainClear");
            cmd.SetComputeVectorParam(ssprCumpute,"Size",new Vector4(width,height,0,0));
            
        }

        // Here you can implement the rendering logic.
        // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
        // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
        // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if(!ssprCumpute)
                return;
            CommandBuffer cmd = CommandBufferPool.Get("SSPR CMD");
            
            
            //获取 VP矩阵 并传入 Compute Shader
            var V = renderingData.cameraData.GetViewMatrix();
            var P = renderingData.cameraData.GetGPUProjectionMatrix();
            var VP = P*V;
            cmd.SetComputeMatrixParam(ssprCumpute,id_IVP,Matrix4x4.Inverse(VP));
            // cmd.GetTemporaryRT(ssprRTHandle.id,renderingData.cameraData.cameraTargetDescriptor);
            // Blit(cmd,renderingData.cameraData.targetTexture,ssprRTHandle.Identifier(),ssprMat);
            // cmd.Blit(null,ssprRTHandle.Identifier(),ssprMat);
            // Debug.Log("cmd  sspr");
            cmd.SetComputeTextureParam(ssprCumpute,kernel,id_ssprRT,ssprRTHandle.Identifier());
            cmd.DispatchCompute(ssprCumpute,kernelClear,(int)(width/8),(int)(height/8),1);
            cmd.DispatchCompute(ssprCumpute,kernel,(int)(width/8),(int)(height/8),1);
            
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        // Cleanup any allocated resources that were created during the execution of this render pass.
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            if(!ssprCumpute)
                return;
            cmd.ReleaseTemporaryRT(ssprRTHandle.id);
        }
    }

    CustomRenderPass m_ScriptablePass;

    /// <inheritdoc/>
    public override void Create()
    {
        m_ScriptablePass = new CustomRenderPass(ssprCumpute);

        // Configures where the render pass should be injected.
        m_ScriptablePass.renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
        // m_ScriptablePass.renderPassEvent = RenderPassEvent.BeforeRenderingTransparents;
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(m_ScriptablePass);
    }
}


