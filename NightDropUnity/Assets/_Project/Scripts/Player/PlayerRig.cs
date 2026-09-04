using UnityEngine;

namespace NightDrop.Player
{
    public static class PlayerRig
    {
        const string RootName = "PlayerRig";

        public static PlayerController Ensure()
        {
            if (PlayerController.Instance != null)
            {
                PlayerController.Instance.gameObject.SetActive(true);
                if (ThirdPersonCamera.CameraRoot != null)
                    ThirdPersonCamera.CameraRoot.SetActive(true);
                return PlayerController.Instance;
            }

            var root = new GameObject(RootName);
            Object.DontDestroyOnLoad(root);
            root.transform.position = new Vector3(0f, 1.0f, 0f);

            var cc = root.AddComponent<CharacterController>();
            cc.height = 1.8f;
            cc.radius = 0.32f;
            cc.center = new Vector3(0f, 0.9f, 0f);
            cc.slopeLimit = 45f;
            cc.stepOffset = 0.3f;
            cc.minMoveDistance = 0f;

            var player = root.AddComponent<PlayerController>();
            BuildBody(root.transform);

            var lookAt = new GameObject("LookAt");
            lookAt.transform.SetParent(root.transform, false);
            lookAt.transform.localPosition = new Vector3(0f, 1.45f, 0f);
            ThirdPersonCamera.Create(root.transform, lookAt.transform);
            return player;
        }

        public static void Hide()
        {
            if (PlayerController.Instance != null)
            {
                PlayerController.Instance.ForceExitVehicle();
                PlayerController.Instance.gameObject.SetActive(false);
            }
            if (ThirdPersonCamera.CameraRoot != null)
                ThirdPersonCamera.CameraRoot.SetActive(false);
        }

        static void BuildBody(Transform parent)
        {
            var body = GameObject.CreatePrimitive(PrimitiveType.Capsule);
            body.name = "Body";
            body.transform.SetParent(parent, false);
            body.transform.localPosition = new Vector3(0f, 0.9f, 0f);
            Object.Destroy(body.GetComponent<Collider>());
            body.GetComponent<Renderer>().material.color = new Color(0.18f, 0.22f, 0.28f);

            var head = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            head.name = "Head";
            head.transform.SetParent(parent, false);
            head.transform.localPosition = new Vector3(0f, 1.58f, 0.04f);
            head.transform.localScale = Vector3.one * 0.38f;
            Object.Destroy(head.GetComponent<Collider>());
            head.GetComponent<Renderer>().material.color = new Color(0.72f, 0.58f, 0.46f);
        }
    }
}
