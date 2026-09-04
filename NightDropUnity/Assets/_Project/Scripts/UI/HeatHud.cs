using NightDrop.Managers;
using UnityEngine;
using UnityEngine.UI;

namespace NightDrop.UI
{
    public class HeatHud : MonoBehaviour
    {
        Image[] _pips;

        public static HeatHud Bind(Transform hudRoot)
        {
            var existing = hudRoot.GetComponent<HeatHud>();
            if (existing != null)
                return existing;
            return hudRoot.gameObject.AddComponent<HeatHud>();
        }

        void Start()
        {
            var row = new GameObject("Heat", typeof(RectTransform));
            row.transform.SetParent(transform, false);
            var rt = row.GetComponent<RectTransform>();
            rt.anchorMin = new Vector2(0.5f, 1f);
            rt.anchorMax = new Vector2(0.5f, 1f);
            rt.pivot = new Vector2(0.5f, 1f);
            rt.anchoredPosition = new Vector2(0f, -24f);
            rt.sizeDelta = new Vector2(280f, 36f);

            _pips = new Image[5];
            for (int i = 0; i < 5; i++)
            {
                var pip = new GameObject("Pip" + i, typeof(RectTransform), typeof(Image));
                pip.transform.SetParent(row.transform, false);
                var prt = pip.GetComponent<RectTransform>();
                prt.anchorMin = prt.anchorMax = new Vector2(0f, 0.5f);
                prt.pivot = new Vector2(0f, 0.5f);
                prt.sizeDelta = new Vector2(44f, 22f);
                prt.anchoredPosition = new Vector2(i * 54f, 0f);
                var img = pip.GetComponent<Image>();
                img.color = new Color(1f, 1f, 1f, 0.18f);
                _pips[i] = img;
            }
        }

        void Update()
        {
            int level = HeatSystem.Instance != null ? HeatSystem.Instance.Level : 0;
            if (_pips == null)
                return;
            for (int i = 0; i < _pips.Length; i++)
            {
                bool on = i < level;
                _pips[i].color = on
                    ? Color.Lerp(new Color(1f, 0.72f, 0.15f), new Color(0.95f, 0.2f, 0.12f), i / 4f)
                    : new Color(1f, 1f, 1f, 0.16f);
            }
        }
    }
}
