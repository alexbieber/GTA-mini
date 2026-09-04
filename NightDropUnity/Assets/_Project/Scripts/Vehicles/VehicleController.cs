using System.Collections.Generic;
using NightDrop.Managers;
using NightDrop.Player;
using UnityEngine;

namespace NightDrop.Vehicles
{
    [DefaultExecutionOrder(20)]
    public class VehicleController : MonoBehaviour
    {
        static readonly List<VehicleController> All = new List<VehicleController>();

        [SerializeField] float maxSteer = 28f;
        [SerializeField] float motorForce = 2200f;
        [SerializeField] float brakeForce = 2800f;
        [SerializeField] float handbrakeForce = 4200f;
        [SerializeField] float aiSpeed = 9.5f;
        [SerializeField] float downforce = 90f;

        WheelCollider[] _drive;
        WheelCollider[] _steer;
        WheelCollider[] _all;
        Transform[] _visuals;
        Rigidbody _rb;
        float _steerAngle;
        int _wp;
        Vector3[] _path;
        bool _ai;
        float _upsideDown;
        float _aiCap;
        Transform _chase;
        float _ramCool;

        public Transform LookAt { get; set; }
        public bool PlayerDriven { get; private set; }
        public bool IsPolice { get; set; }

        public static VehicleController FindNearest(Vector3 pos, float range)
        {
            VehicleController best = null;
            float bestSqr = range * range;
            for (int i = 0; i < All.Count; i++)
            {
                var v = All[i];
                if (v == null || v.PlayerDriven)
                    continue;
                float sqr = (v.transform.position - pos).sqrMagnitude;
                if (sqr < bestSqr)
                {
                    bestSqr = sqr;
                    best = v;
                }
            }

            return best;
        }

        public void Configure(WheelCollider[] all, WheelCollider[] steer, WheelCollider[] drive, Transform[] visuals, Transform lookAt, Vector3[] path)
        {
            _all = all;
            _steer = steer;
            _drive = drive;
            _visuals = visuals;
            LookAt = lookAt;
            _path = path;
            _ai = path != null && path.Length >= 2;
            _rb = GetComponent<Rigidbody>();
            _aiCap = aiSpeed;
        }

        public void SetChase(Transform target)
        {
            _chase = target;
            _ai = true;
            _aiCap = IsPolice ? 14.5f : 11f;
        }

        public void SetPlayerDriven(bool on)
        {
            PlayerDriven = on;
            _ai = !on && (_chase != null || (_path != null && _path.Length >= 2));
            if (on)
                _rb.velocity = Vector3.ClampMagnitude(_rb.velocity, 16f);
        }

        public Vector3 ExitPosition()
        {
            return transform.position + transform.right * 2.4f + Vector3.up * 0.4f;
        }

        void OnEnable() => All.Add(this);

        void OnDisable() => All.Remove(this);

        void FixedUpdate()
        {
            if (_all == null || _rb == null)
                return;

            float throttle = 0f;
            float steerInput = 0f;
            float brake = 0f;
            bool handbrake = false;

            if (PlayerDriven)
            {
                var input = MobileInput.Instance;
                Vector2 stick = input != null ? input.Move : Vector2.zero;
                throttle = stick.y;
                steerInput = stick.x;
                handbrake = input != null && input.JumpHeld;
                if (Mathf.Abs(throttle) < 0.08f)
                    brake = 0.35f;
            }
            else if (_ai)
            {
                AiDrive(out throttle, out steerInput, out brake);
            }
            else
            {
                brake = 1f;
                throttle = 0f;
            }

            _steerAngle = Mathf.Lerp(_steerAngle, steerInput * maxSteer, 8f * Time.fixedDeltaTime);
            float motor = (handbrake ? 0f : throttle * motorForce) / Mathf.Max(1, _drive.Length);
            float brakeTorque = handbrake ? handbrakeForce : brake * brakeForce;

            for (int i = 0; i < _steer.Length; i++)
                _steer[i].steerAngle = _steerAngle;

            for (int i = 0; i < _drive.Length; i++)
                _drive[i].motorTorque = motor;

            for (int i = 0; i < _all.Length; i++)
            {
                bool rear = _all[i].transform.localPosition.z < 0f;
                _all[i].brakeTorque = handbrake && !rear ? brakeTorque * 0.25f : brakeTorque;
            }

            float speed = _rb.velocity.magnitude;
            _rb.AddForce(-transform.up * speed * downforce);

            if (transform.up.y < 0.25f)
            {
                _upsideDown += Time.fixedDeltaTime;
                if (_upsideDown > 2.2f)
                {
                    transform.position += Vector3.up * 1.4f;
                    transform.rotation = Quaternion.LookRotation(transform.forward, Vector3.up);
                    _rb.velocity = Vector3.zero;
                    _rb.angularVelocity = Vector3.zero;
                    _upsideDown = 0f;
                }
            }
            else
            {
                _upsideDown = 0f;
            }

            SyncVisuals();
        }

        void AiDrive(out float throttle, out float steerInput, out float brake)
        {
            Vector3 aim;
            if (_chase != null)
                aim = _chase.position;
            else
                aim = _path[_wp];

            Vector3 flat = aim - transform.position;
            flat.y = 0f;
            if (_chase == null && flat.magnitude < 5.5f)
                _wp = (_wp + 1) % _path.Length;

            Vector3 local = transform.InverseTransformPoint(_chase != null ? _chase.position : _path[_wp]);
            steerInput = Mathf.Clamp(local.x / 8f, -1f, 1f);
            float speed = Vector3.Dot(_rb.velocity, transform.forward);
            throttle = speed < _aiCap ? 0.62f : 0.05f;
            if (_chase != null)
                throttle = speed < _aiCap ? 0.85f : 0.2f;
            brake = Mathf.Abs(steerInput) > 0.75f && speed > 8f ? 0.2f : 0f;
        }

        void OnCollisionEnter(Collision collision)
        {
            if (!PlayerDriven || Time.time < _ramCool)
                return;
            if (_rb.velocity.magnitude < 5.5f)
                return;

            var ped = collision.collider.GetComponentInParent<NightDrop.AI.Pedestrian>();
            if (ped != null && !ped.Downed)
            {
                ped.KnockDown(transform.position);
                _ramCool = Time.time + 0.4f;
                return;
            }

            var other = collision.collider.GetComponentInParent<VehicleController>();
            if (other != null && other != this)
            {
                HeatSystem.Report(other.IsPolice ? 22f : 7f);
                _ramCool = Time.time + 0.6f;
            }
        }

        void SyncVisuals()
        {
            for (int i = 0; i < _all.Length; i++)
            {
                _all[i].GetWorldPose(out Vector3 pos, out Quaternion rot);
                if (_visuals != null && i < _visuals.Length && _visuals[i] != null)
                {
                    _visuals[i].position = pos;
                    _visuals[i].rotation = rot * Quaternion.Euler(0f, 0f, 90f);
                }
            }
        }
    }
}
