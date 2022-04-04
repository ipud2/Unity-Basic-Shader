using UnityEngine;



namespace Learn
{
    [RequireComponent(typeof(MeshRenderer))]
    [RequireComponent(typeof(MeshFilter))]
    public class RayTracingObject : MonoBehaviour
    {
        private void OnEnable()
        {
            RayTracingMaster.RegisterObject(this);
        }

        private void OnDisable()
        {
            RayTracingMaster.UnregisterObject(this);
        }

        void Start()
        {
            var bounds = GetComponent<MeshFilter>().mesh.bounds;
            Debug.Log(  bounds +" = " + bounds.min +" " + bounds.max );
        }
    }
}