using UnityEngine;
using UnityEngine.UI;

namespace NightDrop.UI
{
    public static class TouchHudFactory
    {
        public static Canvas Build(Transform parent)
        {
            var canvasGo = new GameObject("TouchHUD", typeof(RectTransform), typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
            canvasGo.transform.SetParent(parent, false);
            var canvas = canvasGo.GetComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            canvas.sortingOrder = 100;

            var scaler = canvasGo.GetComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1920, 1080);
            scaler.matchWidthOrHeight = 0.5f;

            EnsureEventSystem();

            BuildJoystick(canvas.transform);
            BuildLookPad(canvas.transform);
            BuildButton(canvas.transform, "Jump", new Vector2(-220, 160), TouchHoldButton.ActionKind.Jump);
            BuildButton(canvas.transform, "Fire", new Vector2(-90, 280), TouchHoldButton.ActionKind.Fire);
            BuildButton(canvas.transform, "Use", new Vector2(-90, 120), TouchHoldButton.ActionKind.Interact);
            BuildButton(canvas.transform, "Run", new Vector2(-350, 160), TouchHoldButton.ActionKind.Sprint);
            return canvas;
        }

        static void EnsureEventSystem()
        {
            if (Object.FindObjectOfType<UnityEngine.EventSystems.EventSystem>() != null)
                return;

            var es = new GameObject("EventSystem");
            es.AddComponent<UnityEngine.EventSystems.EventSystem>();
            es.AddComponent<UnityEngine.InputSystem.UI.InputSystemUIInputModule>();
            Object.DontDestroyOnLoad(es);
        }

        static void BuildJoystick(Transform parent)
        {
            var root = Panel("Joystick", parent, new Vector2(220, 220), new Vector2(0f, 0f), new Vector2(180, 180));
            var bg = root.GetComponent<Image>();
            bg.color = new Color(1f, 1f, 1f, 0.12f);

            var handleGo = Panel("Handle", root.transform, new Vector2(90, 90), new Vector2(0.5f, 0.5f), Vector2.zero);
            handleGo.GetComponent<Image>().color = new Color(1f, 1f, 1f, 0.35f);
            handleGo.GetComponent<RectTransform>().anchorMin = new Vector2(0.5f, 0.5f);
            handleGo.GetComponent<RectTransform>().anchorMax = new Vector2(0.5f, 0.5f);

            root.AddComponent<VirtualJoystick>();
        }

        static void BuildLookPad(Transform parent)
        {
            var pad = Panel("LookPad", parent, Vector2.zero, new Vector2(1f, 0.5f), Vector2.zero);
            var rt = pad.GetComponent<RectTransform>();
            rt.anchorMin = new Vector2(0.45f, 0f);
            rt.anchorMax = new Vector2(1f, 1f);
            rt.offsetMin = Vector2.zero;
            rt.offsetMax = Vector2.zero;
            pad.GetComponent<Image>().color = new Color(0f, 0f, 0f, 0.02f);
            pad.AddComponent<TouchLookPad>();
        }

        static void BuildButton(Transform parent, string label, Vector2 anchored, TouchHoldButton.ActionKind kind)
        {
            var go = Panel(label, parent, new Vector2(140, 140), new Vector2(1f, 0f), anchored);
            go.GetComponent<Image>().color = new Color(1f, 1f, 1f, 0.16f);
            var btn = go.AddComponent<TouchHoldButton>();
            btn.Bind(kind);

            var textGo = new GameObject("Label", typeof(RectTransform), typeof(Text));
            textGo.transform.SetParent(go.transform, false);
            var trt = textGo.GetComponent<RectTransform>();
            trt.anchorMin = Vector2.zero;
            trt.anchorMax = Vector2.one;
            trt.offsetMin = Vector2.zero;
            trt.offsetMax = Vector2.zero;
            var text = textGo.GetComponent<Text>();
            text.text = label;
            text.alignment = TextAnchor.MiddleCenter;
            text.color = Color.white;
            text.fontSize = 28;
            text.font = Resources.GetBuiltinResource<Font>("Arial.ttf")
                        ?? Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
        }

        static GameObject Panel(string name, Transform parent, Vector2 size, Vector2 anchor, Vector2 anchoredPos)
        {
            var go = new GameObject(name, typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            go.transform.SetParent(parent, false);
            var rt = go.GetComponent<RectTransform>();
            rt.anchorMin = anchor;
            rt.anchorMax = anchor;
            rt.pivot = anchor;
            rt.sizeDelta = size;
            rt.anchoredPosition = anchoredPos;
            return go;
        }
    }
}
