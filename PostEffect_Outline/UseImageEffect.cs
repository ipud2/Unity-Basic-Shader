using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class UseImageEffect : MonoBehaviour
{
    public Material Mat;
    public DepthTextureMode mode = DepthTextureMode.DepthNormals;
    private Camera cam;
    private void Start()
    {
        cam = GetComponent<Camera>();
    }

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        cam.depthTextureMode = mode;
        if(Mat) Graphics.Blit(src,dest,Mat);
    }
}
