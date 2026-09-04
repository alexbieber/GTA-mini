using UnityEngine;
using UnityEngine.EventSystems;

namespace NightDrop.UI
{
    public class VirtualJoystick : MonoBehaviour, IPointerDownHandler, IPointerUpHandler, IDragHandler
    {
        [SerializeField] RectTransform handle;
        [SerializeField] float range = 70f;

        RectTransform _root;
        int _pointerId = int.MinValue;

        void Awake()
        {
            _root = transform as RectTransform;
            if (handle == null)
            {
                var child = transform.Find("Handle") as RectTransform;
                handle = child;
            }
        }

        public void OnPointerDown(PointerEventData eventData)
        {
            _pointerId = eventData.pointerId;
            OnDrag(eventData);
        }

        public void OnDrag(PointerEventData eventData)
        {
            if (eventData.pointerId != _pointerId)
                return;

            RectTransformUtility.ScreenPointToLocalPointInRectangle(
                _root, eventData.position, eventData.pressEventCamera, out Vector2 local);

            Vector2 clamped = Vector2.ClampMagnitude(local, range);
            if (handle != null)
                handle.anchoredPosition = clamped;

            Vector2 value = clamped / range;
            if (NightDrop.Player.MobileInput.Instance != null)
                NightDrop.Player.MobileInput.Instance.SetHudMove(value);
        }

        public void OnPointerUp(PointerEventData eventData)
        {
            if (eventData.pointerId != _pointerId)
                return;

            _pointerId = int.MinValue;
            if (handle != null)
                handle.anchoredPosition = Vector2.zero;
            if (NightDrop.Player.MobileInput.Instance != null)
                NightDrop.Player.MobileInput.Instance.SetHudMove(Vector2.zero);
        }
    }
}
