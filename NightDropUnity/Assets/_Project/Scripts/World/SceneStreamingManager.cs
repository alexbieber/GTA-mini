using System;
using System.Collections;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace NightDrop.World
{
    /// <summary>
    /// Additive district loading so a full city never sits in RAM at once.
    /// </summary>
    public class SceneStreamingManager : MonoBehaviour
    {
        public static SceneStreamingManager Instance { get; private set; }

        public string ActiveDistrict { get; private set; }
        public bool IsBusy { get; private set; }

        public event Action<string> DistrictLoaded;

        void Awake()
        {
            if (Instance != null && Instance != this)
            {
                Destroy(gameObject);
                return;
            }

            Instance = this;
            DontDestroyOnLoad(gameObject);
        }

        void OnDestroy()
        {
            if (Instance == this)
                Instance = null;
        }

        public void LoadDistrict(string sceneName, Action onDone = null)
        {
            if (IsBusy)
                return;
            StartCoroutine(LoadRoutine(sceneName, onDone));
        }

        public void ShowMainMenu()
        {
            LoadDistrict(GameIds.MainMenuScene);
        }

        IEnumerator LoadRoutine(string sceneName, Action onDone)
        {
            IsBusy = true;
            yield return EnsureLoaded(GameIds.LoadingScene, LoadSceneMode.Additive);

            if (!string.IsNullOrEmpty(ActiveDistrict) && ActiveDistrict != sceneName)
                yield return SceneManager.UnloadSceneAsync(ActiveDistrict);

            if (!IsLoaded(sceneName))
            {
                var load = SceneManager.LoadSceneAsync(sceneName, LoadSceneMode.Additive);
                while (load != null && !load.isDone)
                    yield return null;
            }

            ActiveDistrict = sceneName;
            var scene = SceneManager.GetSceneByName(sceneName);
            if (scene.IsValid())
                SceneManager.SetActiveScene(scene);

            if (IsLoaded(GameIds.LoadingScene) && sceneName != GameIds.LoadingScene)
                yield return SceneManager.UnloadSceneAsync(GameIds.LoadingScene);

            IsBusy = false;
            DistrictLoaded?.Invoke(sceneName);
            onDone?.Invoke();
        }

        static bool IsLoaded(string sceneName)
        {
            var scene = SceneManager.GetSceneByName(sceneName);
            return scene.IsValid() && scene.isLoaded;
        }

        static IEnumerator EnsureLoaded(string sceneName, LoadSceneMode mode)
        {
            if (IsLoaded(sceneName))
                yield break;
            var load = SceneManager.LoadSceneAsync(sceneName, mode);
            while (load != null && !load.isDone)
                yield return null;
        }
    }
}
