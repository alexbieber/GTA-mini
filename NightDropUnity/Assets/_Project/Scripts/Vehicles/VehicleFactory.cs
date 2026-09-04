using UnityEngine;

namespace NightDrop.Vehicles
{
    public static class VehicleFactory
    {
        public static VehicleController Spawn(Vector3 position, float yaw, Color color, Vector3[] path)
        {
            var root = new GameObject(path != null ? "TrafficCar" : "ParkedCar");
            root.transform.SetPositionAndRotation(position, Quaternion.Euler(0f, yaw, 0f));

            var rb = root.AddComponent<Rigidbody>();
            rb.mass = 1180f;
            rb.drag = 0.12f;
            rb.angularDrag = 1.1f;
            rb.interpolation = RigidbodyInterpolation.Interpolate;
            rb.collisionDetectionMode = CollisionDetectionMode.Continuous;
            rb.centerOfMass = new Vector3(0f, -0.45f, 0.12f);

            var hull = root.AddComponent<BoxCollider>();
            hull.center = new Vector3(0f, 0.38f, 0f);
            hull.size = new Vector3(1.85f, 0.7f, 4.15f);

            BuildBody(root.transform, color);

            var lookAt = new GameObject("LookAt");
            lookAt.transform.SetParent(root.transform, false);
            lookAt.transform.localPosition = new Vector3(0f, 1.15f, 0.2f);

            var wcFl = MakeWheel(root.transform, "FL", new Vector3(-0.78f, 0.08f, 1.32f));
            var wcFr = MakeWheel(root.transform, "FR", new Vector3(0.78f, 0.08f, 1.32f));
            var wcRl = MakeWheel(root.transform, "RL", new Vector3(-0.78f, 0.08f, -1.28f));
            var wcRr = MakeWheel(root.transform, "RR", new Vector3(0.78f, 0.08f, -1.28f));

            var visFl = MakeWheelVisual(root.transform, new Vector3(-0.78f, 0.34f, 1.32f));
            var visFr = MakeWheelVisual(root.transform, new Vector3(0.78f, 0.34f, 1.32f));
            var visRl = MakeWheelVisual(root.transform, new Vector3(-0.78f, 0.34f, -1.28f));
            var visRr = MakeWheelVisual(root.transform, new Vector3(0.78f, 0.34f, -1.28f));

            var vehicle = root.AddComponent<VehicleController>();
            vehicle.Configure(
                new[] { wcFl, wcFr, wcRl, wcRr },
                new[] { wcFl, wcFr },
                new[] { wcFl, wcFr, wcRl, wcRr },
                new[] { visFl, visFr, visRl, visRr },
                lookAt.transform,
                path
            );
            return vehicle;
        }

        public static VehicleController SpawnPolice(Vector3 position, float yaw, Vector3[] path)
        {
            var unit = Spawn(position, yaw, new Color(0.07f, 0.12f, 0.22f), path);
            unit.gameObject.name = "PatrolUnit";
            unit.IsPolice = true;
            var bar = GameObject.CreatePrimitive(PrimitiveType.Cube);
            bar.name = "LightBar";
            bar.transform.SetParent(unit.transform, false);
            bar.transform.localPosition = new Vector3(0f, 1.08f, 0.1f);
            bar.transform.localScale = new Vector3(0.9f, 0.12f, 0.35f);
            Object.Destroy(bar.GetComponent<Collider>());
            bar.GetComponent<Renderer>().material.color = new Color(0.15f, 0.25f, 0.95f);
            var lamp = new GameObject("Lamp");
            lamp.transform.SetParent(bar.transform, false);
            var light = lamp.AddComponent<Light>();
            light.type = LightType.Point;
            light.color = new Color(0.3f, 0.45f, 1f);
            light.range = 8f;
            light.intensity = 2.2f;
            return unit;
        }

        static void BuildBody(Transform parent, Color color)
        {
            var body = GameObject.CreatePrimitive(PrimitiveType.Cube);
            body.name = "Hull";
            body.transform.SetParent(parent, false);
            body.transform.localPosition = new Vector3(0f, 0.42f, 0f);
            body.transform.localScale = new Vector3(1.85f, 0.55f, 4.2f);
            Object.Destroy(body.GetComponent<Collider>());
            body.GetComponent<Renderer>().material.color = color;

            var cabin = GameObject.CreatePrimitive(PrimitiveType.Cube);
            cabin.name = "Cabin";
            cabin.transform.SetParent(parent, false);
            cabin.transform.localPosition = new Vector3(0f, 0.82f, -0.15f);
            cabin.transform.localScale = new Vector3(1.55f, 0.42f, 1.7f);
            Object.Destroy(cabin.GetComponent<Collider>());
            cabin.GetComponent<Renderer>().material.color = new Color(0.12f, 0.16f, 0.2f);

            var glass = GameObject.CreatePrimitive(PrimitiveType.Cube);
            glass.name = "Glass";
            glass.transform.SetParent(parent, false);
            glass.transform.localPosition = new Vector3(0f, 0.84f, 0.62f);
            glass.transform.localScale = new Vector3(1.4f, 0.28f, 0.08f);
            Object.Destroy(glass.GetComponent<Collider>());
            glass.GetComponent<Renderer>().material.color = new Color(0.45f, 0.62f, 0.72f);
        }

        static WheelCollider MakeWheel(Transform parent, string name, Vector3 local)
        {
            var go = new GameObject(name);
            go.transform.SetParent(parent, false);
            go.transform.localPosition = local;
            var wc = go.AddComponent<WheelCollider>();
            wc.radius = 0.34f;
            wc.suspensionDistance = 0.16f;
            wc.mass = 22f;
            wc.forceAppPointDistance = 0.1f;
            var spring = wc.suspensionSpring;
            spring.spring = 28000f;
            spring.damper = 2800f;
            spring.targetPosition = 0.5f;
            wc.suspensionSpring = spring;
            wc.forwardFriction = Grip(0.4f, 1f, 0.8f, 0.7f, 1.6f);
            wc.sidewaysFriction = Grip(0.2f, 1f, 0.5f, 0.75f, 1.8f);
            return wc;
        }

        static Transform MakeWheelVisual(Transform parent, Vector3 local)
        {
            var wheel = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            wheel.name = "WheelVis";
            wheel.transform.SetParent(parent, false);
            wheel.transform.localPosition = local;
            wheel.transform.localRotation = Quaternion.Euler(0f, 0f, 90f);
            wheel.transform.localScale = new Vector3(0.68f, 0.16f, 0.68f);
            Object.Destroy(wheel.GetComponent<Collider>());
            wheel.GetComponent<Renderer>().material.color = new Color(0.08f, 0.08f, 0.08f);
            return wheel.transform;
        }

        static WheelFrictionCurve Grip(float exSlip, float exVal, float asSlip, float asVal, float stiff)
        {
            return new WheelFrictionCurve
            {
                extremumSlip = exSlip,
                extremumValue = exVal,
                asymptoteSlip = asSlip,
                asymptoteValue = asVal,
                stiffness = stiff
            };
        }
    }
}
