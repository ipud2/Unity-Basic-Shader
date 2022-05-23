using System;
using UnityEngine;
using System.Collections;
#if UNITY_EDITOR
using UnityEditor;
#endif
using UnityEngine.InputSystem;


public class OrbitCamera : MonoBehaviour
{
    public float zoomSpeed = 1;

    public Transform transformCache;
    public float radius = 1.5f;
    public bool isAnimating;

    public GameObject dummyForRotation;
    public Transform dummyTransform;

    private Vector3 _focusPoint;
    private float _radiusCurrent = 15f;
    private bool _isTrackingMouse0;
    private Vector2 _mouse0StartPosition;

    private bool _isTrackingMouse1;
    private Vector2 _mouse1StartPosition;

    private Vector3 positionOffset = Vector3.zero;
    private Vector3 _positionOffsetCurrent = Vector3.zero;

    private Quaternion _rot2 = Quaternion.identity;

    private const float RadiusMin = 0.5f;

    private void Awake()
    {
        positionOffset =dummyForRotation.transform.position -  transformCache.transform.position;
    }

    private void Start()
    {
        transformCache = transform;
        _focusPoint = transformCache.forward * -1f * radius;
        _positionOffsetCurrent = positionOffset;
        _radiusCurrent = radius;
        dummyForRotation = new GameObject();
        dummyTransform = dummyForRotation.transform;

        dummyTransform.rotation = transformCache.rotation;
        dummyTransform.position = transformCache.position;
        _rot2 = transformCache.rotation;
    }


    private void OrbitAroundObject(Vector3 newOffset, float radiusRef)
    {
        positionOffset = newOffset;
        _positionOffsetCurrent = positionOffset;
        radius = radiusRef;
        _radiusCurrent = radius;
    }


    // Update is called once per frame
    private void Update()
    {
        transformCache.position = dummyTransform.position = Vector3.zero;

        var hasHitRestrictedHitArea = false;


        if (Mouse.current.leftButton.wasPressedThisFrame)
        {
            _mouse0StartPosition = Mouse.current.position.ReadValue();
            _isTrackingMouse0 = true;
        }

        if (_mouse0StartPosition.x < 200f && _mouse0StartPosition.y > Screen.height - 200f)
        {
            hasHitRestrictedHitArea = true;
        }

        if (!hasHitRestrictedHitArea)
        {
            if (_isTrackingMouse0)
            {
                Vector3 mousePositionDifference = Mouse.current.position.ReadValue() - _mouse0StartPosition;
                dummyTransform.Rotate(Vector3.up, mousePositionDifference.x * 0.4f, Space.World);

                dummyTransform.Rotate(dummyTransform.right.normalized, mousePositionDifference.y * -0.4f,
                    Space.World);
                _rot2 = dummyTransform.rotation;
                _mouse0StartPosition = Mouse.current.position.ReadValue();
            }

            transformCache.rotation = Quaternion.Lerp(transformCache.rotation, _rot2, Time.deltaTime * 4f);
        }


        if (Mouse.current.leftButton.wasReleasedThisFrame)
        {
            _isTrackingMouse0 = false;
        }


        if (Mouse.current.rightButton.wasPressedThisFrame)
        {
            _mouse1StartPosition = Mouse.current.position.ReadValue();
            _isTrackingMouse1 = true;
        }

        if (Mouse.current.middleButton.wasPressedThisFrame)
        {
            _mouse1StartPosition = Mouse.current.position.ReadValue();
            _isTrackingMouse1 = true;
        }

        if (!hasHitRestrictedHitArea)
        {
            if (_isTrackingMouse1)
            {
                var mousePositionDifference = Mouse.current.position.ReadValue() - _mouse1StartPosition;
                //Vector3 XZPlanerDirection = transformCache.forward.normalized;
                //XZPlanerDirection.y = 0;

                positionOffset += transformCache.up.normalized * (mousePositionDifference.y * -(radius / 2f / 100f));

                positionOffset += transformCache.right.normalized *
                                  (mousePositionDifference.x * -(radius / 2f / 100f));
                /*
                if(positionOffset.y < 0){
                    positionOffset.y = 0;
                }*/

                _mouse1StartPosition = Mouse.current.position.ReadValue();
            }
        }

        if (Mouse.current.rightButton.wasReleasedThisFrame)
        {
            _isTrackingMouse1 = false;
        }

        if (Mouse.current.middleButton.wasReleasedThisFrame)
        {
            _isTrackingMouse1 = false;
        }

        if (!hasHitRestrictedHitArea)
        {
            if (!isAnimating)
            {
                var delta = Mouse.current.scroll.y.ReadValue() / 1000f * zoomSpeed * -radius;
                radius += delta;
                if (radius < RadiusMin)
                {
                    var radDiff = RadiusMin - radius;
                    positionOffset += transformCache.forward * (radDiff * 4f);
                    radius = RadiusMin;
                }
            }
        }

        _positionOffsetCurrent = Vector3.Lerp(_positionOffsetCurrent, positionOffset, Time.deltaTime * 4f);
        _radiusCurrent = Mathf.Lerp(_radiusCurrent, radius, Time.deltaTime * 4f);
        _focusPoint = transformCache.forward * -1f * _radiusCurrent;
        transformCache.position = _focusPoint + _positionOffsetCurrent;
        dummyTransform.position = transformCache.position;
    }
}
