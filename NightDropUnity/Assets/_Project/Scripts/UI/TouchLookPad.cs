using UnityEngine;
using UnityEngine.EventSystems;

namespace NightDrop.UI
{
    public class TouchLookPad : MonoBehaviour, IPointerDownHandler, IPointerUpHandler, IDragHandler
    {
        int _pointerId = int.MinValue;
        Vector2 _last;

        public void OnPointerDown(PointerEventData eventData)
        {
            _pointerId = eventData.pointerId;
            _last = eventData.position;
        }

        public void OnDrag(PointerEventData eventData)
        {
            if (eventData.pointerId != _pointerId)
                return;

            Vector2 delta = eventData.position - _last;
            _last = eventData.position;
            if (NightDrop.Player.MobileInput.Instance != null)
                NightDrop.Player.MobileInput.Instance.AddHudLook(delta);
        }

        public void OnPointerUp(PointerEventData eventData)
        {
            if (eventData.pointerId != _pointerId)
                return;
            _pointerId = int.MinValue;
        }
    }
}
