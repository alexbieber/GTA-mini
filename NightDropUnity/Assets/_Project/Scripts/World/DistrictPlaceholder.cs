using NightDrop.AI;
using NightDrop.Vehicles;
using UnityEngine;

namespace NightDrop.World
{
    /// <summary>
    /// Placeholder district root until art and streaming chunks exist.
    /// </summary>
    public class DistrictPlaceholder : MonoBehaviour
    {
        [SerializeField] Vector2 size = new Vector2(120f, 120f);

        void Start()
        {
            if (GetComponentInChildren<MeshRenderer>() != null)
                return;

            var ground = GameObject.CreatePrimitive(PrimitiveType.Plane);
            ground.name = "BlockGround";
            ground.transform.SetParent(transform, false);
            ground.transform.localScale = new Vector3(size.x / 10f, 1f, size.y / 10f);
            var renderer = ground.GetComponent<Renderer>();
            renderer.material.color = new Color(0.18f, 0.2f, 0.22f);

            var lightGo = new GameObject("Sun");
            lightGo.transform.SetParent(transform, false);
            lightGo.transform.rotation = Quaternion.Euler(50f, 40f, 0f);
            var light = lightGo.AddComponent<Light>();
            light.type = LightType.Directional;
            light.intensity = 1.05f;
            light.shadows = LightShadows.Soft;

            SpawnCurb(new Vector3(8f, 0.45f, 6f), new Vector3(3.2f, 0.9f, 1.2f));
            SpawnCurb(new Vector3(-6f, 0.7f, 10f), new Vector3(2.4f, 1.4f, 2.4f));
            SpawnWater(new Vector3(22f, -0.2f, 18f), new Vector3(16f, 2.2f, 14f));
            SpawnRoads();
            SpawnVehicles();
            DistrictNavMesh.Bake(Vector3.zero, new Vector3(size.x + 20f, 16f, size.y + 20f));
            SpawnPeds();
        }

        void SpawnCurb(Vector3 pos, Vector3 scale)
        {
            var box = GameObject.CreatePrimitive(PrimitiveType.Cube);
            box.name = "Block";
            box.transform.SetParent(transform, false);
            box.transform.position = pos;
            box.transform.localScale = scale;
            box.GetComponent<Renderer>().material.color = new Color(0.32f, 0.3f, 0.28f);
        }

        void SpawnWater(Vector3 pos, Vector3 scale)
        {
            var water = GameObject.CreatePrimitive(PrimitiveType.Cube);
            water.name = "Canal";
            water.transform.SetParent(transform, false);
            water.transform.position = pos;
            water.transform.localScale = scale;
            var col = water.GetComponent<Collider>();
            col.isTrigger = true;
            var rb = water.AddComponent<Rigidbody>();
            rb.isKinematic = true;
            rb.useGravity = false;
            water.AddComponent<WaterVolume>();
            var mat = water.GetComponent<Renderer>().material;
            mat.color = new Color(0.12f, 0.38f, 0.55f, 0.45f);
            mat.SetFloat("_Mode", 3f);
        }

        void SpawnRoads()
        {
            SpawnAsphalt(new Vector3(0f, 0.03f, 36f), new Vector3(80f, 0.04f, 9f));
            SpawnAsphalt(new Vector3(0f, 0.03f, -36f), new Vector3(80f, 0.04f, 9f));
            SpawnAsphalt(new Vector3(36f, 0.03f, 0f), new Vector3(9f, 0.04f, 80f));
            SpawnAsphalt(new Vector3(-36f, 0.03f, 0f), new Vector3(9f, 0.04f, 80f));
        }

        void SpawnAsphalt(Vector3 pos, Vector3 scale)
        {
            var road = GameObject.CreatePrimitive(PrimitiveType.Cube);
            road.name = "Asphalt";
            road.transform.SetParent(transform, false);
            road.transform.position = pos;
            road.transform.localScale = scale;
            Object.Destroy(road.GetComponent<Collider>());
            road.GetComponent<Renderer>().material.color = new Color(0.11f, 0.12f, 0.13f);
        }

        void SpawnVehicles()
        {
            var loop = new[]
            {
                new Vector3(-36f, 0.32f, -36f),
                new Vector3(36f, 0.32f, -36f),
                new Vector3(36f, 0.32f, 36f),
                new Vector3(-36f, 0.32f, 36f)
            };
            VehicleFactory.Spawn(new Vector3(5.4f, 0.32f, -7.2f), 0f, new Color(0.92f, 0.55f, 0.12f), null);

            var colors = new[]
            {
                new Color(0.82f, 0.82f, 0.84f),
                new Color(0.18f, 0.2f, 0.28f),
                new Color(0.55f, 0.12f, 0.12f),
                new Color(0.12f, 0.32f, 0.48f),
                new Color(0.22f, 0.42f, 0.24f)
            };
            float[] yaws = { 90f, 0f, -90f, 180f };
            for (int i = 0; i < 4; i++)
                VehicleFactory.Spawn(loop[i], yaws[i], colors[i], loop);
            VehicleFactory.Spawn(Vector3.Lerp(loop[0], loop[1], 0.5f), 90f, colors[4], loop);
        }

        void SpawnPeds()
        {
            for (int i = 0; i < 18; i++)
            {
                Vector2 ring = Random.insideUnitCircle * 38f;
                var pos = new Vector3(ring.x, 0.15f, ring.y);
                if (pos.magnitude < 4f)
                    pos += Vector3.right * 6f;
                PedestrianFactory.Spawn(pos);
            }
        }
    }
}
