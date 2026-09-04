using NightDrop.World;
using UnityEngine;
using UnityEngine.UI;

namespace NightDrop.UI
{
    public class MainMenuController : MonoBehaviour
    {
        void Start()
        {
            if (GetComponentInChildren<Button>() != null)
                return;
            Build();
        }

        void Build()
        {
            var canvasGo = new GameObject("MenuCanvas", typeof(RectTransform), typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
            canvasGo.transform.SetParent(transform, false);
            var canvas = canvasGo.GetComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            canvas.sortingOrder = 50;
            var scaler = canvasGo.GetComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1920, 1080);

            var titleGo = new GameObject("Title", typeof(RectTransform), typeof(Text));
            titleGo.transform.SetParent(canvasGo.transform, false);
            var titleRt = titleGo.GetComponent<RectTransform>();
            titleRt.anchorMin = new Vector2(0.5f, 0.62f);
            titleRt.anchorMax = new Vector2(0.5f, 0.62f);
            titleRt.sizeDelta = new Vector2(900, 140);
            var title = titleGo.GetComponent<Text>();
            title.text = GameIds.ProductName;
            title.alignment = TextAnchor.MiddleCenter;
            title.fontSize = 72;
            title.color = Color.white;
            title.font = Resources.GetBuiltinResource<Font>("Arial.ttf")
                         ?? Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");

            var subGo = new GameObject("Tag", typeof(RectTransform), typeof(Text));
            subGo.transform.SetParent(canvasGo.transform, false);
            var subRt = subGo.GetComponent<RectTransform>();
            subRt.anchorMin = new Vector2(0.5f, 0.52f);
            subRt.anchorMax = new Vector2(0.5f, 0.52f);
            subRt.sizeDelta = new Vector2(1100, 80);
            var sub = subGo.GetComponent<Text>();
            sub.text = "Vesper District  ·  original city, original story";
            sub.alignment = TextAnchor.MiddleCenter;
            sub.fontSize = 28;
            sub.color = new Color(1f, 1f, 1f, 0.7f);
            sub.font = title.font;

            CreateButton(canvasGo.transform, "Play", new Vector2(0f, -40f), () =>
            {
                SceneStreamingManager.Instance?.LoadDistrict(GameIds.District01Scene);
            });
        }

        static void CreateButton(Transform parent, string label, Vector2 pos, UnityEngine.Events.UnityAction onClick)
        {
            var go = new GameObject(label, typeof(RectTransform), typeof(Image), typeof(Button));
            go.transform.SetParent(parent, false);
            var rt = go.GetComponent<RectTransform>();
            rt.anchorMin = rt.anchorMax = new Vector2(0.5f, 0.5f);
            rt.sizeDelta = new Vector2(360, 90);
            rt.anchoredPosition = pos;
            go.GetComponent<Image>().color = new Color(0.85f, 0.45f, 0.12f, 0.95f);
            go.GetComponent<Button>().onClick.AddListener(onClick);

            var textGo = new GameObject("Label", typeof(RectTransform), typeof(Text));
            textGo.transform.SetParent(go.transform, false);
            var trt = textGo.GetComponent<RectTransform>();
            trt.anchorMin = Vector2.zero;
            trt.anchorMax = Vector2.one;
            trt.offsetMin = trt.offsetMax = Vector2.zero;
            var text = textGo.GetComponent<Text>();
            text.text = label;
            text.alignment = TextAnchor.MiddleCenter;
            text.fontSize = 36;
            text.color = Color.white;
            text.font = Resources.GetBuiltinResource<Font>("Arial.ttf")
                        ?? Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
        }
    }
}
