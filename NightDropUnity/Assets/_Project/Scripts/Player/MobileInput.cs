using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.InputSystem.EnhancedTouch;
using Touch = UnityEngine.InputSystem.EnhancedTouch.Touch;

namespace NightDrop.Player
{
    /// <summary>
    /// Mobile-first move/look/actions. Touch HUD writes here.
    /// Keyboard/mouse is editor-only so playmode works without a device.
    /// </summary>
    [DefaultExecutionOrder(-100)]
    public class MobileInput : MonoBehaviour
    {
        public static MobileInput Instance { get; private set; }

        [SerializeField] float lookSensitivity = 0.12f;
        [SerializeField] float editorLookSensitivity = 0.15f;

        InputAction _kbMove;
        InputAction _kbJump;
        InputAction _kbInteract;
        InputAction _kbFire;
        InputAction _kbSprint;

        Vector2 _hudMove;
        Vector2 _hudLookDelta;
        bool _hudJump;
        bool _hudJumpHeld;
        bool _hudInteract;
        bool _hudFire;
        bool _hudSprint;

        public Vector2 Move { get; private set; }
        public Vector2 LookDelta { get; private set; }
        public bool JumpPressed { get; private set; }
        public bool JumpHeld { get; private set; }
        public bool InteractPressed { get; private set; }
        public bool FireHeld { get; private set; }
        public bool SprintHeld { get; private set; }

        void Awake()
        {
            if (Instance != null && Instance != this)
            {
                Destroy(gameObject);
                return;
            }

            Instance = this;
            DontDestroyOnLoad(gameObject);
            EnhancedTouchSupport.Enable();
            BuildEditorActions();
        }

        void OnEnable()
        {
            _kbMove?.Enable();
            _kbJump?.Enable();
            _kbInteract?.Enable();
            _kbFire?.Enable();
            _kbSprint?.Enable();
        }

        void OnDisable()
        {
            _kbMove?.Disable();
            _kbJump?.Disable();
            _kbInteract?.Disable();
            _kbFire?.Disable();
            _kbSprint?.Disable();
        }

        void OnDestroy()
        {
            if (Instance == this)
                Instance = null;
            _kbMove?.Dispose();
            _kbJump?.Dispose();
            _kbInteract?.Dispose();
            _kbFire?.Dispose();
            _kbSprint?.Dispose();
        }

        void Update()
        {
            Vector2 move = _hudMove;
            Vector2 look = _hudLookDelta * lookSensitivity;
            bool jump = _hudJump;
            bool jumpHeld = _hudJumpHeld;
            bool interact = _hudInteract;
            bool fire = _hudFire;
            bool sprint = _hudSprint;

#if UNITY_EDITOR || UNITY_STANDALONE
            if (_kbMove != null)
            {
                Vector2 kb = _kbMove.ReadValue<Vector2>();
                if (kb.sqrMagnitude > 0.01f)
                    move = kb;
            }

            if (Mouse.current != null && Mouse.current.rightButton.isPressed)
                look += Mouse.current.delta.ReadValue() * editorLookSensitivity;

            jump |= WasPressed(_kbJump);
            jumpHeld |= _kbJump != null && _kbJump.IsPressed();
            interact |= WasPressed(_kbInteract);
            fire |= _kbFire != null && _kbFire.IsPressed();
            sprint |= _kbSprint != null && _kbSprint.IsPressed();
#endif

            Move = Vector2.ClampMagnitude(move, 1f);
            LookDelta = look;
            JumpPressed = jump;
            JumpHeld = jumpHeld;
            InteractPressed = interact;
            FireHeld = fire;
            SprintHeld = sprint;

            _hudLookDelta = Vector2.zero;
            _hudJump = false;
            _hudInteract = false;
        }

        public void SetHudMove(Vector2 value) => _hudMove = value;

        public void AddHudLook(Vector2 delta) => _hudLookDelta += delta;

        public void PressJump() => _hudJump = true;

        public void SetJump(bool held) => _hudJumpHeld = held;

        public void PressInteract() => _hudInteract = true;

        public void SetFire(bool held) => _hudFire = held;

        public void SetSprint(bool held) => _hudSprint = held;

        public static bool IsPointerOverLeftHalf(Vector2 screen)
        {
            return screen.x < Screen.width * 0.45f;
        }

        static bool WasPressed(InputAction action)
        {
            return action != null && action.WasPressedThisFrame();
        }

        void BuildEditorActions()
        {
            _kbMove = new InputAction("Move", InputActionType.Value);
            _kbMove.AddCompositeBinding("2DVector")
                .With("Up", "<Keyboard>/w")
                .With("Down", "<Keyboard>/s")
                .With("Left", "<Keyboard>/a")
                .With("Right", "<Keyboard>/d");

            _kbJump = new InputAction("Jump", InputActionType.Button, "<Keyboard>/space");
            _kbInteract = new InputAction("Interact", InputActionType.Button, "<Keyboard>/e");
            _kbFire = new InputAction("Fire", InputActionType.Button, "<Mouse>/leftButton");
            _kbSprint = new InputAction("Sprint", InputActionType.Button, "<Keyboard>/leftShift");
        }

        public static IReadOnlyList<Touch> ActiveTouches => Touch.activeTouches;
    }
}
