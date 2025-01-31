using System.Linq;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace UnityEditor.Rendering.Universal
{
    [VolumeComponentEditor(typeof(Bloom))]
    sealed class BloomEditor : VolumeComponentEditor
    {
        // Marked By Bioum //
        SerializedDataParameter m_IterationCount;
        SerializedDataParameter m_HighQualityBlur;
        // Marked By Bioum //
        SerializedDataParameter m_Threshold;
        SerializedDataParameter m_Intensity;
        SerializedDataParameter m_Scatter;
        SerializedDataParameter m_Clamp;
        SerializedDataParameter m_Tint;
        SerializedDataParameter m_HighQualityFiltering;
        SerializedDataParameter m_DirtTexture;
        SerializedDataParameter m_DirtIntensity;

        public override void OnEnable()
        {
            var o = new PropertyFetcher<Bloom>(serializedObject);

            // Marked By Bioum //
            m_IterationCount = Unpack(o.Find(x => x.iterationCount));
            m_HighQualityBlur = Unpack(o.Find(x => x.highQualityBlur));
            // Marked By Bioum //
            m_Threshold = Unpack(o.Find(x => x.threshold));
            m_Intensity = Unpack(o.Find(x => x.intensity));
            m_Scatter = Unpack(o.Find(x => x.scatter));
            m_Clamp = Unpack(o.Find(x => x.clamp));
            m_Tint = Unpack(o.Find(x => x.tint));
            m_HighQualityFiltering = Unpack(o.Find(x => x.highQualityFiltering));
            m_DirtTexture = Unpack(o.Find(x => x.dirtTexture));
            m_DirtIntensity = Unpack(o.Find(x => x.dirtIntensity));
        }

        public override void OnInspectorGUI()
        {
            if (UniversalRenderPipeline.asset?.postProcessingFeatureSet == PostProcessingFeatureSet.PostProcessingV2)
            {
                EditorGUILayout.HelpBox(UniversalRenderPipelineAssetEditor.Styles.postProcessingGlobalWarning, MessageType.Warning);
                return;
            }

            EditorGUILayout.LabelField("Bloom", EditorStyles.miniLabel);

            // Marked by Bioum //
            //PropertyField(m_HighQualityBlur);
            PropertyField(m_IterationCount);
            // Marked by Bioum //
            PropertyField(m_Threshold);
            PropertyField(m_Intensity);
            PropertyField(m_Scatter);
            PropertyField(m_Tint);
            PropertyField(m_Clamp);
            //PropertyField(m_HighQualityFiltering);

            if (m_HighQualityFiltering.overrideState.boolValue && m_HighQualityFiltering.value.boolValue && CoreEditorUtils.buildTargets.Contains(GraphicsDeviceType.OpenGLES2))
                EditorGUILayout.HelpBox("High Quality Bloom isn't supported on GLES2 platforms.", MessageType.Warning);

            EditorGUILayout.LabelField("Lens Dirt", EditorStyles.miniLabel);

            PropertyField(m_DirtTexture);
            PropertyField(m_DirtIntensity);
        }
    }
}
