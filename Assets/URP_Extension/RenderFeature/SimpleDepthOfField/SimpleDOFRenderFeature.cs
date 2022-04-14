using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class SimpleDOFRenderFeature : ScriptableRendererFeature
{
    private SimpleDOFRenderPass renderPass;
    private Material m_Material;
    [SerializeField, HideInInspector] private Shader m_Shader = null;
    const string m_ShaderName = "Bioum/RenderFeature/SimpleDOF";

    public override void Create()
    {
        renderPass = new SimpleDOFRenderPass("Simple Depth Of Field");
        renderPass.renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;

        RenderTextureFormat format = SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.R8)
            ? RenderTextureFormat.R8
            : RenderTextureFormat.ARGB32;
        renderPass.format = format;

        if (!m_Shader)
            m_Shader = Shader.Find(m_ShaderName);
        if (!m_Material)
            m_Material = CoreUtils.CreateEngineMaterial(m_Shader);

        renderPass.material = m_Material;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        var src = renderer.cameraColorTarget;
        renderPass.Setup(src);
        renderer.EnqueuePass(renderPass);
    }


    class SimpleDOFRenderPass : ScriptableRenderPass
    {
        private string profilerTag;
        private RenderTargetIdentifier source;
        private SimpleDepthOfFieldVolume volume;
        public Material material;
        private const int downsample = 2;
        private Color fogColor;
        public RenderTextureFormat format;

        private static readonly int m_SimpleDOFBlurTargetID = Shader.PropertyToID("_SimpleDOFBlurTarget");
        private static readonly int m_SimpleDOFFinalTargetID = Shader.PropertyToID("_SimpleDOFFinalTarget");
        private RenderTargetIdentifier m_SimpleDOFBlurTarget = new RenderTargetIdentifier(m_SimpleDOFBlurTargetID);
        private RenderTargetIdentifier m_SimpleDOFFinalTarget = new RenderTargetIdentifier(m_SimpleDOFFinalTargetID);
        private RenderTextureDescriptor m_Descriptor;
        
        private static readonly int _SimpleDOFParam = Shader.PropertyToID("_SimpleDOFParam");

        public SimpleDOFRenderPass(string profilerTag) => this.profilerTag = profilerTag;
        public void Setup(RenderTargetIdentifier source) => this.source = source;

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            var stack = VolumeManager.instance.stack;
            volume = stack.GetComponent<SimpleDepthOfFieldVolume>();
            if (!volume.IsActive()) return;

            if (renderingData.cameraData.cameraType != CameraType.Game)
                return;


            CommandBuffer cmd = CommandBufferPool.Get(profilerTag);

            m_Descriptor = renderingData.cameraData.cameraTargetDescriptor;
            cmd.GetTemporaryRT(m_SimpleDOFFinalTargetID, m_Descriptor, FilterMode.Bilinear);

            m_Descriptor.msaaSamples = 1;
            m_Descriptor.width /= downsample;
            m_Descriptor.height /= downsample;
            cmd.GetTemporaryRT(m_SimpleDOFBlurTargetID, m_Descriptor, FilterMode.Bilinear);

            //模糊
            material.SetVector(_SimpleDOFParam, new Vector4(
                volume.start.value,
                Mathf.Max(volume.start.value, volume.end.value),
                volume.blur.value,
                volume.debug.value ? 1 : 0));
            Render(cmd, m_SimpleDOFBlurTarget, material, 0, true);

            //混合
            Render(cmd, m_SimpleDOFFinalTarget, material, 1, true);
            cmd.EnableShaderKeyword("_SIMPLE_DOF");

            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }

        private void Render(CommandBuffer cmd, RenderTargetIdentifier target, Material material, int pass,
            bool clear = true)
        {
            cmd.SetRenderTarget(
                target,
                RenderBufferLoadAction.DontCare,
                RenderBufferStoreAction.Store,
                target,
                RenderBufferLoadAction.DontCare,
                RenderBufferStoreAction.DontCare
            );

            if (clear)
                cmd.ClearRenderTarget(true, true, Color.clear);

            cmd.DrawMesh(RenderingUtils.fullscreenMesh, Matrix4x4.identity, material, 0, pass);
        }

        public override void FrameCleanup(CommandBuffer cmd)
        {
            cmd.DisableShaderKeyword("_SIMPLE_DOF");
        }
    }
}