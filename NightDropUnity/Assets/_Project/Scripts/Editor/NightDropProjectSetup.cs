using NightDrop.Managers;
using NightDrop.UI;
using NightDrop.World;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace NightDrop.Editor
{
    [InitializeOnLoad]
    public static class NightDropProjectSetup
    {
        const string PrefKey = "NightDrop.Phase0.Setup.v1";
        const string Scenes = "Assets/_Project/Scenes";
        const string Settings = "Assets/_Project/Settings";

        static NightDropProjectSetup()
        {
            EditorApplication.delayCall += RunIfNeeded;
        }

        [MenuItem("Night Drop/Run Phase 0 Setup")]
        static void ForceRun()
        {
            EditorPrefs.DeleteKey(PrefKey);
            RunIfNeeded();
        }

        static void RunIfNeeded()
        {
            if (EditorApplication.isPlayingOrWillChangePlaymode)
                return;
            if (EditorPrefs.GetBool(PrefKey, false))
                return;

            try
            {
                ConfigurePlayer();
                ConfigureUrp();
                ConfigureInput();
                EnsureScenes();
                EditorPrefs.SetBool(PrefKey, true);
                AssetDatabase.SaveAssets();
                Debug.Log("[Night Drop] Phase 0 setup complete. Play Bootstrap.");
            }
            catch (System.Exception e)
            {
                Debug.LogWarning("[Night Drop] Phase 0 setup waiting on packages: " + e.Message);
            }
        }

        static void ConfigurePlayer()
        {
            PlayerSettings.companyName = GameIds.CompanyName;
            PlayerSettings.productName = GameIds.ProductName;
            PlayerSettings.SetApplicationIdentifier(BuildTargetGroup.Android, "com.harborline.nightdrop");
            PlayerSettings.SetApplicationIdentifier(BuildTargetGroup.iOS, "com.harborline.nightdrop");
            PlayerSettings.defaultInterfaceOrientation = UIOrientation.LandscapeLeft;
            PlayerSettings.allowedAutorotateToPortrait = false;
            PlayerSettings.allowedAutorotateToPortraitUpsideDown = false;
            PlayerSettings.allowedAutorotateToLandscapeLeft = true;
            PlayerSettings.allowedAutorotateToLandscapeRight = true;
            PlayerSettings.colorSpace = ColorSpace.Linear;
            PlayerSettings.Android.minSdkVersion = AndroidSdkVersions.AndroidApiLevel24;
            EditorSettings.projectGenerationRootNamespace = "NightDrop";
        }

        static void ConfigureUrp()
        {
            if (!AssetDatabase.IsValidFolder(Settings))
                AssetDatabase.CreateFolder("Assets/_Project", "Settings");

            var rendererPath = Settings + "/URP-Mobile-Renderer.asset";
            var pipePath = Settings + "/URP-Mobile.asset";

            var renderer = AssetDatabase.LoadAssetAtPath<UniversalRendererData>(rendererPath);
            if (renderer == null)
            {
                renderer = ScriptableObject.CreateInstance<UniversalRendererData>();
                AssetDatabase.CreateAsset(renderer, rendererPath);
            }

            var pipe = AssetDatabase.LoadAssetAtPath<UniversalRenderPipelineAsset>(pipePath);
            if (pipe == null)
            {
                pipe = UniversalRenderPipelineAsset.Create(renderer);
                AssetDatabase.CreateAsset(pipe, pipePath);
            }

            GraphicsSettings.defaultRenderPipeline = pipe;
            QualitySettings.renderPipeline = pipe;
        }

        static void ConfigureInput()
        {
            var assets = AssetDatabase.LoadAllAssetsAtPath("ProjectSettings/ProjectSettings.asset");
            if (assets == null || assets.Length == 0)
                return;
            var so = new SerializedObject(assets[0]);
            var handler = so.FindProperty("activeInputHandler");
            if (handler != null)
            {
                handler.intValue = 1;
                so.ApplyModifiedPropertiesWithoutUndo();
            }
        }

        static void EnsureScenes()
        {
            if (!AssetDatabase.IsValidFolder(Scenes))
                AssetDatabase.CreateFolder("Assets/_Project", "Scenes");

            WriteScene(GameIds.BootstrapScene, go => go.AddComponent<GameBootstrap>());
            WriteScene(GameIds.MainMenuScene, go => go.AddComponent<MainMenuController>());
            WriteScene(GameIds.LoadingScene, go => go.AddComponent<LoadingOverlay>());
            WriteScene(GameIds.District01Scene, go => go.AddComponent<DistrictPlaceholder>());

            EditorBuildSettings.scenes = new[]
            {
                new EditorBuildSettingsScene($"{Scenes}/{GameIds.BootstrapScene}.unity", true),
                new EditorBuildSettingsScene($"{Scenes}/{GameIds.MainMenuScene}.unity", true),
                new EditorBuildSettingsScene($"{Scenes}/{GameIds.LoadingScene}.unity", true),
                new EditorBuildSettingsScene($"{Scenes}/{GameIds.District01Scene}.unity", true),
            };
        }

        static void WriteScene(string name, System.Action<GameObject> setup)
        {
            var path = $"{Scenes}/{name}.unity";
            if (System.IO.File.Exists(path))
            {
                var existing = EditorSceneManager.OpenScene(path, OpenSceneMode.Single);
                if (existing.rootCount > 0)
                    return;
            }

            var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
            var root = new GameObject(name);
            setup(root);
            EditorSceneManager.SaveScene(scene, path);
        }
    }
}
