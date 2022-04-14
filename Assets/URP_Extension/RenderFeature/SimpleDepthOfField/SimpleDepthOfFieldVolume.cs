using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[System.Serializable, VolumeComponentMenu("Bioum/SimpleDepthOfField")]
public class SimpleDepthOfFieldVolume : VolumeComponent, IPostProcessComponent
{
    public BoolParameter toggle = new BoolParameter(false, true);
    public MinFloatParameter start = new MinFloatParameter(10, 0,true);
    public FloatParameter end = new MinFloatParameter(50, 0,true);
    public ClampedFloatParameter blur = new ClampedFloatParameter(1, 0, 2, true);
    public BoolParameter debug = new BoolParameter(false, true);

    public bool IsActive() => toggle.value;
    public bool IsTileCompatible() => false;
}