using System.Collections.Generic;
using UnityEngine;


public class PathTracingMaster : MonoBehaviour
{

    struct Sphere
    {
        public Vector3 position;
        public  float radius;
        public  Vector3 albedo;
        public float metallic;
        public float roughness;
        public float specular;
        public float specTrans;
        public Vector3 transColor;
        public Vector3 emission;
    };
    private RenderTexture _converged;
    public Vector2 SphereRadius = new Vector2(3.0f, 8.0f);
    public uint SpheresMax = 100;
    public float SpherePlacementRadius = 100.0f;
    private ComputeBuffer _sphereBuffer;

    public int SphereSeed;
    public ComputeShader RayTracingShader;

    private RenderTexture _target;

    private Camera _camera;
    public Texture SkyboxTexture;

    private uint _currentSample = 0;
    private Material _addMaterial;

    public Light DirectionalLight;


    private void OnEnable()
    {
        _currentSample = 0;
        SetUpScene();
    }
    private void OnDisable()
    {
        if (_sphereBuffer != null)
            _sphereBuffer.Release();
    }

    private void SetUpScene()
    {
        //Random.InitState(SphereSeed);

        Color color = Color.white;
        List<Sphere> spheres = new List<Sphere>();
        for (int i = 0; i < 55; i++)
        {
            Sphere sphere = new Sphere();

            sphere.radius = 10;
            float intervalX = 3 * sphere.radius;
            float intervalZ = 4 * sphere.radius;
            float startX = -4.5f * intervalX;
            float startZ = 2 * intervalZ;

            int row = i / 11;
            int col = i % 11;
            sphere.position = new Vector3(startX + col * intervalX, startZ - row * intervalZ,  0);

     

           
            sphere.emission = new Vector3(0, 0, 0);

         
            switch (row)
            {
                case 0://metallic row 
                    sphere.albedo = new Vector3(1, 0.71f, 0);
                    sphere.metallic = col * 0.1f;
                    sphere.transColor = sphere.albedo;
                    sphere.roughness = 0.1f;
                    sphere.specular = 0.5f;
                    sphere.specTrans = 0.0f;
                    break;
                case 1:
                    //specular row
                    sphere.albedo = new Vector3(1, 0, 0);
                    sphere.metallic = 0;
                    sphere.transColor = sphere.albedo;
                    sphere.roughness = 0.1f;
                    sphere.specular = col * 0.1f;
                    sphere.specTrans = 0.0f;

                    break;
                case 2:
                    //roughness row
                    sphere.albedo = new Vector3(0, 0.8f, 0.2f);
                    sphere.metallic = 0;
                    sphere.transColor = sphere.albedo;
                    sphere.roughness = col* 0.1f;
                    sphere.specular = 0.5f;
                    sphere.specTrans = 0.0f;
                    break;
                case 3:
                    //specTrans row
                    sphere.albedo = new Vector3(0.5f, 0.2f, 1);
                    sphere.metallic = 0;
                    sphere.transColor = sphere.albedo;
                    sphere.roughness = 0.1f;
                    sphere.specular = 0.5f;
                    sphere.specTrans = col * 0.1f;
                    break;
                case 4:
                    //roughness with specTrans = 1
                    sphere.albedo = new Vector3(0.03f, 0.03f, 0.03f);
                    sphere.metallic = 0;
                    sphere.transColor = new Vector3(1, 1, 1);
                    sphere.roughness = col * 0.1f;
                    sphere.specular = 0.5f;
                    sphere.specTrans = 1f;
                    break;
            }


 
            
           



            spheres.Add(sphere);
        }

        if (_sphereBuffer != null)
            _sphereBuffer.Release();
        if (spheres.Count > 0)
        {
            _sphereBuffer = new ComputeBuffer(spheres.Count, 68);
            _sphereBuffer.SetData(spheres);
        }
    }

    private void Awake()
    {
        _camera = GetComponent<Camera>();
    }
    private void SetShaderParameters()
    {
        RayTracingShader.SetVector("_PixelOffset", new Vector2(Random.value, Random.value));
        RayTracingShader.SetTexture(0, "_SkyboxTexture", SkyboxTexture);
        RayTracingShader.SetMatrix("_CameraToWorld", _camera.cameraToWorldMatrix);
        RayTracingShader.SetMatrix("_CameraInverseProjection", _camera.projectionMatrix.inverse);
        Vector3 l = DirectionalLight.transform.forward;
        RayTracingShader.SetVector("_DirectionalLight", new Vector4(l.x, l.y, l.z, DirectionalLight.intensity));
        RayTracingShader.SetBuffer(0, "_Spheres", _sphereBuffer);
        RayTracingShader.SetFloat("_Seed", Random.value);
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        SetShaderParameters();
        Render(destination);
    }

    private void Render(RenderTexture destination)
    {

        InitRenderTexture();
        RayTracingShader.SetTexture(0, "Result", _target);
        int threadGroupsX = Mathf.CeilToInt(Screen.width / 8.0f);
        int threadGroupsY = Mathf.CeilToInt(Screen.height / 8.0f);
        RayTracingShader.Dispatch(0, threadGroupsX, threadGroupsY, 1);


        if (_addMaterial == null)
            _addMaterial = new Material(Shader.Find("Hidden/AddShader"));
        _addMaterial.SetFloat("_Sample", _currentSample);
        Graphics.Blit(_target, _converged, _addMaterial);
        Graphics.Blit(_converged, destination);
        _currentSample++;
    }

    private void InitRenderTexture()
    {
        if (_target == null || _target.width != Screen.width || _target.height != Screen.height)
        {
            if (_target != null)
            { 
                _target.Release();
            }
            _target = new RenderTexture(Screen.width, Screen.height, 0,
                RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
            _target.enableRandomWrite = true;
            _target.Create();
        }

        if (_converged == null || _converged.width != Screen.width || _converged.height != Screen.height)
        {

            if (_converged != null)
            {
                _converged.Release();
            }

            _converged = new RenderTexture(Screen.width, Screen.height, 0,
                RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
            _converged.enableRandomWrite = true;
            _converged.Create();
        }
    }

    private void Update()
    {
        if (transform.hasChanged)
        {
            _currentSample = 0;
            transform.hasChanged = false;
        }

        if (DirectionalLight.transform.hasChanged)
        {
            _currentSample = 0;
            DirectionalLight.transform.hasChanged = false;
        }
    }
}

