using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class CSRenderFeature : ScriptableRendererFeature
{
    public ComputeShader computeShader;
    
    class CustomRenderPass : ScriptableRenderPass
    {
        public ComputeShader computeShader;
        
        private int width, height;

        private int kernel;

        private static int ID_Result = Shader.PropertyToID("Result");

        private RenderTexture resultRT;

        private Material CopyMat;

        
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            RenderTextureDescriptor desc = renderingData.cameraData.cameraTargetDescriptor;
            desc.enableRandomWrite = true;
            desc.msaaSamples = 1;
            desc.dimension = TextureDimension.Tex2D;
            desc.graphicsFormat = GraphicsFormat.R32G32B32A32_SFloat;
            desc.depthBufferBits = 0;
            
            resultRT = RenderTexture.GetTemporary(desc);
            width = resultRT.width;
            height = resultRT.height;
            
            //获取ComputeShader 入口函数的 id
            kernel = computeShader.FindKernel("CSMain");

            CopyMat = new Material(Shader.Find(@"Unlit/BlitCopy"));
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get("CS CMD");
            
            //设置ComputeShader中的RT
            computeShader.SetTexture(kernel,ID_Result,resultRT);
            //Compute Shader开启工作
            cmd.DispatchCompute(computeShader,kernel,width/8,height/8,1);
            
            cmd.Blit(resultRT,renderingData.cameraData.renderer.cameraColorTarget,CopyMat,0);
            // Debug.Log("dsadsadasdsa");
            //执行 cmd
            context.ExecuteCommandBuffer(cmd);
            //释放cmd
            CommandBufferPool.Release(cmd);
        }

        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            if (resultRT)
            {
                RenderTexture.ReleaseTemporary(resultRT);
            }
        }
    }

    CustomRenderPass m_ScriptablePass;

    public override void Create()
    {
        m_ScriptablePass = new CustomRenderPass();
        m_ScriptablePass.computeShader = computeShader;

        m_ScriptablePass.renderPassEvent = RenderPassEvent.AfterRenderingPostProcessing;
    }
    
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(m_ScriptablePass);
    }
}


