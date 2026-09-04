using UnityEngine;
using UnityEngine.EventSystems;

namespace NightDrop.UI
{
    public class TouchHoldButton : MonoBehaviour, IPointerDownHandler, IPointerUpHandler
    {
        public enum ActionKind
        {
            Jump,
            Interact,
            Fire,
            Sprint
        }

        [SerializeField] ActionKind action;

        public void Bind(ActionKind kind) => action = kind;

        public void OnPointerDown(PointerEventData eventData)
        {
            var input = NightDrop.Player.MobileInput.Instance;
            if (input == null)
                return;

            switch (action)
            {
                case ActionKind.Jump:
                    input.PressJump();
                    input.SetJump(true);
                    break;
                case ActionKind.Interact:
                    input.PressInteract();
                    break;
                case ActionKind.Fire:
                    input.SetFire(true);
                    break;
                case ActionKind.Sprint:
                    input.SetSprint(true);
                    break;
            }
        }

        public void OnPointerUp(PointerEventData eventData)
        {
            var input = NightDrop.Player.MobileInput.Instance;
            if (input == null)
                return;

            if (action == ActionKind.Fire)
                input.SetFire(false);
            if (action == ActionKind.Sprint)
                input.SetSprint(false);
            if (action == ActionKind.Jump)
                input.SetJump(false);
        }
    }
}
