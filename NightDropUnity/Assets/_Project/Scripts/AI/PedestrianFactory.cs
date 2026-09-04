using UnityEngine;

namespace NightDrop.AI
{
    public static class PedestrianFactory
    {
        public static Pedestrian Spawn(Vector3 position)
        {
            var root = new GameObject("Pedestrian");
            root.transform.position = position;
            var cc = root.AddComponent<CharacterController>();
            cc.height = 1.6f;
            cc.radius = 0.28f;
            cc.center = new Vector3(0f, 0.8f, 0f);
            var ped = root.AddComponent<Pedestrian>();
            BuildBody(root.transform);
            return ped;
        }

        static void BuildBody(Transform parent)
        {
            var skin = Color.Lerp(new Color(0.45f, 0.32f, 0.22f), new Color(0.78f, 0.62f, 0.48f), Random.value);
            var clothes = Color.HSVToRGB(Random.value, 0.35f, 0.45f);

            var body = GameObject.CreatePrimitive(PrimitiveType.Capsule);
            body.name = "Body";
            body.transform.SetParent(parent, false);
            body.transform.localPosition = new Vector3(0f, 0.8f, 0f);
            Object.Destroy(body.GetComponent<Collider>());
            body.GetComponent<Renderer>().material.color = clothes;

            var head = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            head.name = "Head";
            head.transform.SetParent(parent, false);
            head.transform.localPosition = new Vector3(0f, 1.48f, 0.04f);
            head.transform.localScale = Vector3.one * 0.34f;
            Object.Destroy(head.GetComponent<Collider>());
            head.GetComponent<Renderer>().material.color = skin;
        }
    }
}
