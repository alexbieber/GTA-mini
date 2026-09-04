using NightDrop.AI;
using NightDrop.Managers;
using NightDrop.Vehicles;
using UnityEngine;

namespace NightDrop.Player
{
    [DefaultExecutionOrder(10)]
    [RequireComponent(typeof(CharacterController))]
    public class PlayerController : MonoBehaviour
    {
        public static PlayerController Instance { get; private set; }

        [SerializeField] float walkSpeed = 4.4f;
        [SerializeField] float runSpeed = 7.2f;
        [SerializeField] float swimSpeed = 3.6f;
        [SerializeField] float jumpSpeed = 8.4f;
        [SerializeField] float gravity = 24f;
        [SerializeField] float swimGravity = 2.4f;
        [SerializeField] float rotateSharpness = 14f;
        [SerializeField] float coyoteTime = 0.12f;

        CharacterController _cc;
        float _vertical;
        float _coyote;
        bool _inWater;
        VehicleController _vehicle;
        Transform _lookAt;
        Renderer[] _renderers;

        public bool InWater => _inWater;
        public bool IsGrounded => _cc != null && _cc.isGrounded;
        public bool InVehicle => _vehicle != null;

        public void SetInWater(bool on) => _inWater = on;

        void Awake()
        {
            Instance = this;
            _cc = GetComponent<CharacterController>();
            _lookAt = transform.Find("LookAt");
            _renderers = GetComponentsInChildren<Renderer>(true);
        }

        void OnDestroy()
        {
            if (Instance == this)
                Instance = null;
        }

        void Update()
        {
            var input = MobileInput.Instance;
            if (input != null && input.InteractPressed)
                TryInteract();

            if (_vehicle != null)
                return;

            Vector2 stick = input != null ? input.Move : Vector2.zero;
            bool sprint = input != null && input.SprintHeld;
            bool jump = input != null && input.JumpPressed;
            bool jumpHeld = input != null && input.JumpHeld;

            Transform cam = Camera.main != null ? Camera.main.transform : transform;
            Vector3 planar = Vector3.zero;
            Vector3 fwd = cam.forward;
            Vector3 right = cam.right;
            fwd.y = 0f;
            right.y = 0f;
            if (fwd.sqrMagnitude > 0.001f)
                fwd.Normalize();
            if (right.sqrMagnitude > 0.001f)
                right.Normalize();
            planar = fwd * stick.y + right * stick.x;
            if (planar.sqrMagnitude > 1f)
                planar.Normalize();

            if (_inWater)
                Swim(planar, sprint, jumpHeld);
            else
                Walk(planar, sprint, jump);
        }

        void Walk(Vector3 planar, bool sprint, bool jump)
        {
            if (_cc.isGrounded)
            {
                _coyote = coyoteTime;
                if (_vertical < 0f)
                    _vertical = -2f;
            }
            else
            {
                _coyote -= Time.deltaTime;
                _vertical -= gravity * Time.deltaTime;
            }

            if (jump && _coyote > 0f)
            {
                _vertical = jumpSpeed;
                _coyote = 0f;
            }

            float speed = sprint ? runSpeed : walkSpeed;
            Vector3 motion = planar * speed;
            motion.y = _vertical;
            _cc.Move(motion * Time.deltaTime);
            Face(planar);
        }

        void Swim(Vector3 planar, bool sprint, bool jumpHeld)
        {
            _coyote = 0f;
            float up = 0f;
            if (jumpHeld)
                up += 1f;
            if (sprint)
                up -= 1f;
            _vertical = Mathf.MoveTowards(_vertical, up * swimSpeed, 12f * Time.deltaTime);
            _vertical -= swimGravity * Time.deltaTime;

            Vector3 motion = planar * swimSpeed;
            motion.y = _vertical;
            _cc.Move(motion * Time.deltaTime);
            Face(planar);
        }

        void Face(Vector3 planar)
        {
            if (planar.sqrMagnitude < 0.04f)
                return;
            var want = Quaternion.LookRotation(planar, Vector3.up);
            transform.rotation = Quaternion.Slerp(transform.rotation, want, 1f - Mathf.Exp(-rotateSharpness * Time.deltaTime));
        }

        public void ForceExitVehicle()
        {
            if (_vehicle != null)
                ExitVehicle();
        }

        void TryInteract()
        {
            if (_vehicle != null)
            {
                ExitVehicle();
                return;
            }

            var near = VehicleController.FindNearest(transform.position, 3.6f);
            if (near != null)
                EnterVehicle(near);
        }

        void EnterVehicle(VehicleController vehicle)
        {
            _vehicle = vehicle;
            vehicle.SetPlayerDriven(true);
            if (vehicle.IsPolice)
                HeatSystem.Report(28f);
            SetVisible(false);
            if (_cc != null)
                _cc.enabled = false;
            ThirdPersonCamera.Instance?.Retarget(vehicle.transform, vehicle.LookAt, true);
        }

        void ExitVehicle()
        {
            if (_vehicle == null)
                return;

            Vector3 exit = _vehicle.ExitPosition();
            _vehicle.SetPlayerDriven(false);
            _vehicle = null;
            transform.SetPositionAndRotation(exit, transform.rotation);
            if (_cc != null)
                _cc.enabled = true;
            SetVisible(true);
            Transform look = _lookAt != null ? _lookAt : transform;
            ThirdPersonCamera.Instance?.Retarget(transform, look, false);
        }

        void SetVisible(bool on)
        {
            if (_renderers == null)
                return;
            for (int i = 0; i < _renderers.Length; i++)
            {
                if (_renderers[i] != null)
                    _renderers[i].enabled = on;
            }
        }

        void OnControllerColliderHit(ControllerColliderHit hit)
        {
            var ped = hit.collider.GetComponentInParent<Pedestrian>();
            if (ped == null || ped.Downed)
                return;
            if (_cc.velocity.magnitude < 5.4f)
                return;
            ped.KnockDown(transform.position);
        }
    }
}
