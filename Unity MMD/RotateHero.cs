using System;
using System.Collections;
using System.Collections.Generic;
using DG.Tweening;
using Unity.Mathematics;
using UnityEngine;

public class HeroRotate : MonoBehaviour
{
    public GameObject Target;
    public GameObject LightTarget;

    private bool isClick = false;
    private Vector3 LastMousePosition = Vector3.zero;

    private Quaternion LastQuaternion;
    private Quaternion LastLightQuaternion;
    private Quaternion LightRotateTargetQuaternion;

    public bool NeedRotateLight = false;

    public AnimationCurve RotateCurve ;

    private float NeedLightRotateTime = 0;

    public float RotateLightMaxTime = 0.75f;

    private GameObject LightRotateTarget;
    
    [Range(0f, 1f)] public float evalPercent = 0;

    public GameObject CameraTarget;

    private Vector3 CameraTargetPosition ;
    private Vector3 cameraOriginalPosition ;

    private Camera camera;
    public AnimationCurve CameraZoomCurve;

    
    private void Start()
    {
        LightRotateTarget = new GameObject("LightRotateTarget");
        LightRotateTarget.transform.position = transform.position;
        LightRotateTarget.transform.rotation = transform.rotation;
        LightRotateTarget.transform.SetParent(Target.transform);

        CameraTargetPosition = CameraTarget.transform.position;
        camera = GetComponent<Camera>();
        cameraOriginalPosition = camera.transform.position;
        if (CameraTarget.GetComponent<Camera>() != null)
        {
            DestroyImmediate(CameraTarget);
        }
    }
    
    public enum HeroCameraState
    {
        Normal,
        ZoomTo,
        ZoomBack,
        Zoomed,
    }

    public HeroCameraState heroCameraState = HeroCameraState.Normal;

    private Rect ButtonRect = new Rect(50, 250, 200, 40);
    
    string text = "放大";

    private void OnGUI()
    {
        // if(GUI.Button(new Rect(50,250,200,40),"放大"))
        // {
        //     if (heroCameraState == HeroCameraState.Normal)
        //         heroCameraState = HeroCameraState.ZoomTo;
        // }

        if (heroCameraState == HeroCameraState.Normal)
        {
            text = "放大";
        }
        else if (heroCameraState == HeroCameraState.Zoomed)
        {
            text = "缩小";
        }
    
        if(GUI.Button(ButtonRect,text))
        {
            if (heroCameraState == HeroCameraState.Normal)
                heroCameraState = HeroCameraState.ZoomTo;
            
            if (heroCameraState == HeroCameraState.Zoomed)
                heroCameraState = HeroCameraState.ZoomBack;
        }
    }
    
    float ZoomTime =0;
    public float MaxZoomTime = 0.25f;
    private void Update()
    {
        if (Input.GetMouseButtonDown(0))
        {
            LastMousePosition = Input.mousePosition;
            LastQuaternion = Target.transform.rotation;
            LastLightQuaternion = LightTarget.transform.rotation;
            isClick = true;
        }

        if (Input.GetMouseButtonUp(0))
        {
            isClick = false;
            LastMousePosition = Vector3.zero;
            LastQuaternion = Target.transform.rotation;
        }

        if (isClick)
        {
            Vector3 offset = Input.mousePosition - LastMousePosition;
            Target.transform.rotation = LastQuaternion * Quaternion.Euler(0,-offset.x,0);
            // LightTarget.transform.rotation = LastLightQuaternion * Quaternion.Lerp(Quaternion.identity , Quaternion.Euler(0,-offset.x,0),Time.deltaTime);
            // LightRotateTargetQuaternion = LastLightQuaternion * Quaternion.Euler(0,-offset.x,0);
        }

        if (Quaternion.Angle(LightTarget.transform.rotation, LightRotateTarget.transform.rotation) > 1f)
        {
            NeedLightRotateTime += Time.deltaTime;
            float evalPercent = Mathf.Clamp01( NeedLightRotateTime / RotateLightMaxTime);
            float RotatePercent = RotateCurve.Evaluate(evalPercent);
            LightTarget.transform.rotation = Quaternion.Lerp(LastLightQuaternion,LightRotateTarget.transform.rotation,RotatePercent);
            NeedRotateLight = true;
        }
        
        if( Quaternion.Angle(LightTarget.transform.rotation, LightRotateTarget.transform.rotation) < 1f)
        {
            LightTarget.transform.rotation = LightRotateTarget.transform.rotation;
            LastLightQuaternion = LightTarget.transform.rotation;
            NeedRotateLight = false;
            NeedLightRotateTime = 0;
        }

        if (heroCameraState == HeroCameraState.ZoomTo)
        {
            ZoomTime += Time.deltaTime;
            float zoomPercent = Mathf.Clamp01(ZoomTime / MaxZoomTime);
            float eval = CameraZoomCurve.Evaluate(zoomPercent);
            camera.transform.position = Vector3.Lerp(cameraOriginalPosition,CameraTargetPosition,eval);
            if (Vector3.Distance(camera.transform.position, CameraTargetPosition) < 0.02f)
            {
                ZoomTime = 0f;
                camera.transform.position = CameraTargetPosition;
                heroCameraState = HeroCameraState.Zoomed;
            }
        }
        else if (heroCameraState == HeroCameraState.ZoomBack)
        {
            ZoomTime += Time.deltaTime;
            float zoomPercent = Mathf.Clamp01(ZoomTime / MaxZoomTime);
            float eval = CameraZoomCurve.Evaluate(zoomPercent);
            camera.transform.position = Vector3.Lerp(CameraTargetPosition,cameraOriginalPosition,eval);
            if (Vector3.Distance(cameraOriginalPosition, camera.transform.position) <  0.02f)
            {
                ZoomTime = 0f;
                camera.transform.position = cameraOriginalPosition;
                heroCameraState = HeroCameraState.Normal;
            }
        }
        
    }
}
