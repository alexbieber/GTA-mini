using Cinemachine;
using UnityEngine;

namespace NightDrop.Player
{
    [DefaultExecutionOrder(50)]
    public class ThirdPersonCamera : MonoBehaviour
    {
        [SerializeField] float yawScale = 0.18f;
        [SerializeField] float pitchScale = 0.0018f;

        CinemachineFreeLook _freeLook;

        public static ThirdPersonCamera Create(Transform follow, Transform lookAt)
        {
            var existing = Camera.main;
            if (existing != null && existing.GetComponent<CinemachineBrain>() == null)
            {
                existing.gameObject.SetActive(false);
                existing.tag = "Untagged";
            }

            var rigRoot = new GameObject("CameraRig");
            Object.DontDestroyOnLoad(rigRoot);

            var camGo = new GameObject("PlayerCamera");
            camGo.transform.SetParent(rigRoot.transform, false);
            var cam = camGo.AddComponent<Camera>();
            cam.tag = "MainCamera";
            cam.nearClipPlane = 0.12f;
            cam.farClipPlane = 400f;
            camGo.AddComponent<AudioListener>();
            var brain = camGo.AddComponent<CinemachineBrain>();
            brain.m_UpdateMethod = CinemachineBrain.UpdateMethod.LateUpdate;

            var vcamGo = new GameObject("FreeLook");
            vcamGo.transform.SetParent(rigRoot.transform, false);
            var freeLook = vcamGo.AddComponent<CinemachineFreeLook>();
            freeLook.Follow = follow;
            freeLook.LookAt = lookAt;
            freeLook.m_BindingMode = CinemachineTransposer.BindingMode.WorldSpace;
            freeLook.m_Orbits = new[]
            {
                new CinemachineFreeLook.Orbit(4.4f, 2.4f),
                new CinemachineFreeLook.Orbit(1.65f, 5.2f),
                new CinemachineFreeLook.Orbit(0.35f, 2.6f)
            };
            freeLook.m_Lens.FieldOfView = 58f;
            freeLook.m_XAxis.m_InputAxisName = string.Empty;
            freeLook.m_YAxis.m_InputAxisName = string.Empty;
            freeLook.m_XAxis.m_MaxSpeed = 0f;
            freeLook.m_YAxis.m_MaxSpeed = 0f;
            freeLook.m_YAxis.Value = 0.38f;
            freeLook.Priority = 20;

            var driver = camGo.AddComponent<ThirdPersonCamera>();
            driver._freeLook = freeLook;
            Instance = driver;
            CameraRoot = rigRoot;
            return driver;
        }

        public static ThirdPersonCamera Instance { get; private set; }
        public static GameObject CameraRoot { get; private set; }

        public void Retarget(Transform follow, Transform lookAt, bool driving)
        {
            if (_freeLook == null)
                return;
            _freeLook.Follow = follow;
            _freeLook.LookAt = lookAt;
            if (driving)
            {
                _freeLook.m_Orbits = new[]
                {
                    new CinemachineFreeLook.Orbit(7.2f, 5.4f),
                    new CinemachineFreeLook.Orbit(3.1f, 9.4f),
                    new CinemachineFreeLook.Orbit(0.8f, 6.2f)
                };
                _freeLook.m_Lens.FieldOfView = 62f;
                _freeLook.m_YAxis.Value = 0.42f;
            }
            else
            {
                _freeLook.m_Orbits = new[]
                {
                    new CinemachineFreeLook.Orbit(4.4f, 2.4f),
                    new CinemachineFreeLook.Orbit(1.65f, 5.2f),
                    new CinemachineFreeLook.Orbit(0.35f, 2.6f)
                };
                _freeLook.m_Lens.FieldOfView = 58f;
            }
        }

        void LateUpdate()
        {
            if (_freeLook == null)
                return;
            var input = MobileInput.Instance;
            if (input == null)
                return;

            Vector2 look = input.LookDelta;
            _freeLook.m_XAxis.Value += look.x * yawScale;
            _freeLook.m_YAxis.Value = Mathf.Clamp01(_freeLook.m_YAxis.Value - look.y * pitchScale);
        }
    }
}
