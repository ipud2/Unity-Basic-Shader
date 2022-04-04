using System;
using System.Collections.Generic;
using UnityEngine;
using System.Linq;
using Random = UnityEngine.Random;

namespace Learn
{
    public class RayTracingMaster : MonoBehaviour
    {
        public ComputeShader RayTracingShader;
        public Texture SkyboxTexture;
        public Light DirectionalLight;

        [Header("Spheres")] public int SphereSeed;
        public Vector2 SphereRadius = new Vector2(3.0f, 8.0f);
        public uint SpheresMax = 100;
        public float SpherePlacementRadius = 100.0f;

        private Camera _camera;
        private float _lastFieldOfView;
        private RenderTexture _target;
        private RenderTexture _converged;
        private Material _addMaterial;
        private uint _currentSample = 0;
        private ComputeBuffer _sphereBuffer;
        private static List<Transform> _transformsToWatch = new List<Transform>();
        private static bool _meshObjectsNeedRebuilding = false;
        private static List<RayTracingObject> _rayTracingObjects = new List<RayTracingObject>();
        private static List<MeshObject> _meshObjects = new List<MeshObject>();
        private static List<Vector3> _vertices = new List<Vector3>();
        private static List<int> _indices = new List<int>();
        private ComputeBuffer _meshObjectBuffer;
        private ComputeBuffer _vertexBuffer;
        private ComputeBuffer _indexBuffer;
        
        
        public Color albedo;
        public Color specular;
        [Range(0,1)]
        public float smoothness;
        public Color emission;

        struct MeshObject
        {
            public Matrix4x4 localToWorldMatrix;
            public int indices_offset;
            public int indices_count;
            public Vector3 aabb_min;
            public Vector3 aabb_max;

            public static int GetCount()
            {
                return (16 + 1 + 1 + 3 + 3) * 4;
            }
        }

        struct Sphere
        {
            public Vector3 position;
            public float radius;
            public Vector3 albedo;
            public Vector3 specular;
            public float smoothness;
            public Vector3 emission;
        }

        private void Awake()
        {
            _camera = GetComponent<Camera>();

            _transformsToWatch.Add(transform);
            _transformsToWatch.Add(DirectionalLight.transform);
        }

        private void OnEnable()
        {
            _currentSample = 0;
            SetUpScene();
        }

        private void OnDisable()
        {
            _sphereBuffer?.Release();
            _meshObjectBuffer?.Release();
            _vertexBuffer?.Release();
            _indexBuffer?.Release();
        }

        private void Update()
        {
            if (Input.GetKeyDown(KeyCode.F12))
            {
                ScreenCapture.CaptureScreenshot(Time.time + "-" + _currentSample + ".png");
            }

            if (_camera.fieldOfView != _lastFieldOfView)
            {
                _currentSample = 0;
                _lastFieldOfView = _camera.fieldOfView;
            }

            foreach (Transform t in _transformsToWatch)
            {
                if (t.hasChanged)
                {
                    _currentSample = 0;
                    t.hasChanged = false;
                    _meshObjectsNeedRebuilding = true;
                }
            }
        }

        public static void RegisterObject(RayTracingObject obj)
        {
            _rayTracingObjects.Add(obj);
            _transformsToWatch.Add(obj.transform);
            _meshObjectsNeedRebuilding = true;
        }

        public static void UnregisterObject(RayTracingObject obj)
        {
            _rayTracingObjects.Remove(obj);
            _transformsToWatch.Remove(obj.transform);
            _meshObjectsNeedRebuilding = true;
        }

        private void SetUpScene()
        {
            Random.InitState(SphereSeed);
            List<Sphere> spheres = new List<Sphere>();

            // Add a number of random spheres
            for (int i = 0; i < SpheresMax; i++)
            {
                Sphere sphere = new Sphere();

                // Radius and radius
                sphere.radius = SphereRadius.x + Random.value * (SphereRadius.y - SphereRadius.x);
                Vector2 randomPos = Random.insideUnitCircle * SpherePlacementRadius;
                sphere.position = new Vector3(randomPos.x, sphere.radius, randomPos.y);

                // Reject spheres that are intersecting others
                foreach (Sphere other in spheres)
                {
                    float minDist = sphere.radius + other.radius;
                    if (Vector3.SqrMagnitude(sphere.position - other.position) < minDist * minDist)
                        goto SkipSphere;
                }

                // Albedo and specular color
                Color color = Random.ColorHSV();
                float chance = Random.value;
                if (chance < 0.9f)
                {
                    bool metal = chance < 0.4f;
                    sphere.albedo = metal ? Vector4.zero : new Vector4(color.r, color.g, color.b);
                    sphere.specular = metal ? new Vector4(color.r, color.g, color.b) : new Vector4(0.04f, 0.04f, 0.04f);
                    sphere.smoothness = Random.value;
                }
                else
                {
                    Color emission = Random.ColorHSV(0, 1f, 0, 1, 1f, 3.0f);
                    sphere.emission = new Vector3(emission.r, emission.g, emission.b);
                }

                // Add the sphere to the list
                spheres.Add(sphere);

                SkipSphere:
                continue;
            }

            // Assign to compute buffer
            if (_sphereBuffer != null)
                _sphereBuffer.Release();
            if (spheres.Count > 0)
            {
                _sphereBuffer = new ComputeBuffer(spheres.Count, 56);
                _sphereBuffer.SetData(spheres);
            }
        }

        private void RebuildMeshObjectBuffers()
        {
            if (!_meshObjectsNeedRebuilding)
            {
                return;
            }

            _meshObjectsNeedRebuilding = false;
            _currentSample = 0;

            // Clear all lists
            _meshObjects.Clear();
            _vertices.Clear();
            _indices.Clear();

            // Loop over all objects and gather their data
            foreach (RayTracingObject obj in _rayTracingObjects)
            {
                Mesh mesh = obj.GetComponent<MeshFilter>().sharedMesh;

                // Add vertex data
                int firstVertex = _vertices.Count;
                _vertices.AddRange(mesh.vertices);

                // Add index data - if the vertex buffer wasn't empty before, the
                // indices need to be offset
                int firstIndex = _indices.Count;
                var indices = mesh.GetIndices(0);
                _indices.AddRange(indices.Select(index => index + firstVertex));
                
                // Add the object itself
                _meshObjects.Add(new MeshObject()
                {
                    localToWorldMatrix = obj.transform.localToWorldMatrix,
                    indices_offset = firstIndex,
                    indices_count = indices.Length,
                    aabb_min = obj.GetComponent<MeshFilter>().mesh.bounds.min,
                    aabb_max = obj.GetComponent<MeshFilter>().mesh.bounds.max,
                });
            }
            
            CreateComputeBuffer(ref _meshObjectBuffer, _meshObjects, MeshObject.GetCount() );
            CreateComputeBuffer(ref _vertexBuffer, _vertices, 12);
            CreateComputeBuffer(ref _indexBuffer, _indices, 4);
        }

        private static void CreateComputeBuffer<T>(ref ComputeBuffer buffer, List<T> data, int stride)
            where T : struct
        {
            // Do we already have a compute buffer?
            if (buffer != null)
            {
                // If no data or buffer doesn't match the given criteria, release it
                if (data.Count == 0 || buffer.count != data.Count || buffer.stride != stride)
                {
                    buffer.Release();
                    buffer = null;
                }
            }

            if (data.Count != 0)
            {
                // If the buffer has been released or wasn't there to
                // begin with, create it
                if (buffer == null)
                {
                    buffer = new ComputeBuffer(data.Count, stride);
                }

                // Set data on the buffer
                buffer.SetData(data);
            }
        }

        private void SetComputeBuffer(string name, ComputeBuffer buffer)
        {
            if (buffer != null)
            {
                RayTracingShader.SetBuffer(0, name, buffer);
            }
        }

        Vector4 ColorTovVector4(in Color color)
        {
            return new Vector4(color.r, color.g, color.b, color.a);
        }

        private void SetShaderParameters()
        {
            RayTracingShader.SetTexture(0, "_SkyboxTexture", SkyboxTexture);
            RayTracingShader.SetMatrix("_CameraToWorld", _camera.cameraToWorldMatrix);
            RayTracingShader.SetMatrix("_CameraInverseProjection", _camera.projectionMatrix.inverse);
            RayTracingShader.SetVector("_PixelOffset", new Vector2(Random.value, Random.value));
            RayTracingShader.SetFloat("_Seed", Random.value);

            Vector3 l = DirectionalLight.transform.forward;
            RayTracingShader.SetVector("_DirectionalLight", new Vector4(l.x, l.y, l.z, DirectionalLight.intensity));

            SetComputeBuffer("_Spheres", _sphereBuffer);
            SetComputeBuffer("_MeshObjects", _meshObjectBuffer);
            SetComputeBuffer("_Vertices", _vertexBuffer);
            SetComputeBuffer("_Indices", _indexBuffer);
            
        
            RayTracingShader.SetVector("albedo", ColorTovVector4(albedo));
            RayTracingShader.SetVector("specular", ColorTovVector4(specular));
            RayTracingShader.SetVector("emission", ColorTovVector4(emission));
            RayTracingShader.SetFloat("smoothness",smoothness);
        }

        private void InitRenderTexture()
        {
            if (_target == null || _target.width != Screen.width || _target.height != Screen.height)
            {
                // Release render texture if we already have one
                if (_target != null)
                {
                    _target.Release();
                    _converged.Release();
                }

                // Get a render target for Ray Tracing
                _target = new RenderTexture(Screen.width, Screen.height, 0,
                    RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
                _target.enableRandomWrite = true;
                _target.Create();
                _converged = new RenderTexture(Screen.width, Screen.height, 0,
                    RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
                _converged.enableRandomWrite = true;
                _converged.Create();

                // Reset sampling
                _currentSample = 0;
            }
        }

        private void Render(RenderTexture destination)
        {
            // Make sure we have a current render target
            InitRenderTexture();

            // Set the target and dispatch the compute shader
            RayTracingShader.SetTexture(0, "Result", _target);
            int threadGroupsX = Mathf.CeilToInt(Screen.width / 8.0f);
            int threadGroupsY = Mathf.CeilToInt(Screen.height / 8.0f);
            RayTracingShader.Dispatch(0, threadGroupsX, threadGroupsY, 1);

            // Blit the result texture to the screen
            if (_addMaterial == null)
                _addMaterial = new Material(Shader.Find("Hidden/AddShader"));
            _addMaterial.SetFloat("_Sample", _currentSample);
            Graphics.Blit(_target, _converged, _addMaterial);
            Graphics.Blit(_converged, destination);
            _currentSample++;
        }

        private void OnRenderImage(RenderTexture source, RenderTexture destination)
        {
            RebuildMeshObjectBuffers();
            SetShaderParameters();
            Render(destination);
        }
    }
}
