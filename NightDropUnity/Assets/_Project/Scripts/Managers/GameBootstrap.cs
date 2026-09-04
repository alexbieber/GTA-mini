using NightDrop.Managers;
using NightDrop.Player;
using NightDrop.UI;
using NightDrop.World;
using UnityEngine;

namespace NightDrop.Managers
{
    public class GameBootstrap : MonoBehaviour
    {
        public static GameBootstrap Instance { get; private set; }

        Canvas _hud;

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        static void AutoBoot()
        {
            if (FindObjectOfType<GameBootstrap>() != null)
                return;
            var go = new GameObject("GameBootstrap");
            go.AddComponent<GameBootstrap>();
        }

        void Awake()
        {
            if (Instance != null && Instance != this)
            {
                Destroy(gameObject);
                return;
            }

            Instance = this;
            DontDestroyOnLoad(gameObject);
            Application.targetFrameRate = 30;
            Screen.sleepTimeout = SleepTimeout.NeverSleep;

            if (FindObjectOfType<MobileInput>() == null)
                gameObject.AddComponent<MobileInput>();

            if (FindObjectOfType<SceneStreamingManager>() == null)
                gameObject.AddComponent<SceneStreamingManager>();

            _hud = TouchHudFactory.Build(transform);
            HeatHud.Bind(_hud.transform);
            _hud.enabled = false;

            if (GetComponent<HeatSystem>() == null)
                gameObject.AddComponent<HeatSystem>();
        }

        void Start()
        {
            var streaming = SceneStreamingManager.Instance;
            if (streaming == null)
                return;

            streaming.DistrictLoaded += OnDistrictLoaded;
            var active = UnityEngine.SceneManagement.SceneManager.GetActiveScene().name;
            if (active == GameIds.BootstrapScene || string.IsNullOrEmpty(active) || active == "Untitled")
                streaming.LoadDistrict(GameIds.MainMenuScene);
            else
                OnDistrictLoaded(active);
        }

        void OnDestroy()
        {
            if (SceneStreamingManager.Instance != null)
                SceneStreamingManager.Instance.DistrictLoaded -= OnDistrictLoaded;
            if (Instance == this)
                Instance = null;
        }

        void OnDistrictLoaded(string sceneName)
        {
            bool inDistrict = sceneName == GameIds.District01Scene;
            if (_hud != null)
                _hud.enabled = inDistrict;

            if (inDistrict)
            {
                PlayerRig.Ensure();
            }
            else
            {
                PlayerRig.Hide();
                HeatSystem.Instance?.ResetHeat();
            }
        }
    }
}
