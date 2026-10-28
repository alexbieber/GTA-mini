using NightDrop.Player;
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.UI;

namespace NightDrop.Combat
{
    public class CombatHud : MonoBehaviour
    {
        Text _hp;
        GameObject _wasted;
        Button _retry;

        public static CombatHud Bind(Transform hudRoot)
        {
            var existing = hudRoot.GetComponent<CombatHud>();
            if (existing != null)
                return existing;
            return hudRoot.gameObject.AddComponent<CombatHud>();
        }

        void Start()
        {
            var hpGo = new GameObject("Health", typeof(RectTransform), typeof(Text));
            hpGo.transform.SetParent(transform, false);
            var hpRt = hpGo.GetComponent<RectTransform>();
            hpRt.anchorMin = hpRt.anchorMax = new Vector2(0f, 1f);
            hpRt.pivot = new Vector2(0f, 1f);
            hpRt.anchoredPosition = new Vector2(28f, -24f);
            hpRt.sizeDelta = new Vector2(280f, 48f);
            _hp = hpGo.GetComponent<Text>();
            _hp.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            _hp.fontSize = 32;
            _hp.alignment = TextAnchor.MiddleLeft;
            _hp.color = Color.white;
            _hp.text = "HP 100";

            _wasted = new GameObject("Wasted", typeof(RectTransform), typeof(Image));
            _wasted.transform.SetParent(transform, false);
            var panel = _wasted.GetComponent<RectTransform>();
            panel.anchorMin = Vector2.zero;
            panel.anchorMax = Vector2.one;
            panel.offsetMin = Vector2.zero;
            panel.offsetMax = Vector2.zero;
            _wasted.GetComponent<Image>().color = new Color(0.05f, 0.02f, 0.02f, 0.72f);

            var labelGo = new GameObject("Label", typeof(RectTransform), typeof(Text));
            labelGo.transform.SetParent(_wasted.transform, false);
            var labelRt = labelGo.GetComponent<RectTransform>();
            labelRt.anchorMin = labelRt.anchorMax = new Vector2(0.5f, 0.5f);
            labelRt.sizeDelta = new Vector2(640f, 120f);
            labelRt.anchoredPosition = new Vector2(0f, 80f);
            var label = labelGo.GetComponent<Text>();
            label.font = _hp.font;
            label.fontSize = 72;
            label.alignment = TextAnchor.MiddleCenter;
            label.color = new Color(0.95f, 0.28f, 0.22f);
            label.text = "WASTED";

            var buttonGo = new GameObject("Retry", typeof(RectTransform), typeof(Image), typeof(Button));
            buttonGo.transform.SetParent(_wasted.transform, false);
            var buttonRt = buttonGo.GetComponent<RectTransform>();
            buttonRt.anchorMin = buttonRt.anchorMax = new Vector2(0.5f, 0.5f);
            buttonRt.sizeDelta = new Vector2(280f, 88f);
            buttonRt.anchoredPosition = new Vector2(0f, -40f);
            buttonGo.GetComponent<Image>().color = new Color(1f, 1f, 1f, 0.16f);
            _retry = buttonGo.GetComponent<Button>();
            _retry.onClick.AddListener(Retry);

            var retryLabelGo = new GameObject("Label", typeof(RectTransform), typeof(Text));
            retryLabelGo.transform.SetParent(buttonGo.transform, false);
            var retryRt = retryLabelGo.GetComponent<RectTransform>();
            retryRt.anchorMin = Vector2.zero;
            retryRt.anchorMax = Vector2.one;
            retryRt.offsetMin = Vector2.zero;
            retryRt.offsetMax = Vector2.zero;
            var retryLabel = retryLabelGo.GetComponent<Text>();
            retryLabel.font = _hp.font;
            retryLabel.fontSize = 32;
            retryLabel.alignment = TextAnchor.MiddleCenter;
            retryLabel.color = Color.white;
            retryLabel.text = "Retry";

            _wasted.SetActive(false);
        }

        void Update()
        {
            var player = PlayerController.Instance;
            bool live = player != null && player.isActiveAndEnabled && player.Health != null;
            if (_hp != null)
                _hp.text = live ? "HP " + Mathf.CeilToInt(player.Health.Current) : "";

            bool dead = live && player.Health.Dead;
            if (_wasted != null && _wasted.activeSelf != dead)
                _wasted.SetActive(dead);

            if (!dead || player == null)
                return;

#if UNITY_EDITOR || UNITY_STANDALONE
            if (Keyboard.current != null && Keyboard.current.rKey.wasPressedThisFrame)
                player.Respawn();
#endif
        }

        void Retry()
        {
            PlayerController.Instance?.Respawn();
        }
    }
}
