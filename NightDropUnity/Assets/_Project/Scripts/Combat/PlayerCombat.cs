using NightDrop.AI;
using NightDrop.Player;
using NightDrop.Vehicles;
using UnityEngine;

namespace NightDrop.Combat
{
    /// <summary>
    /// On-foot punch and pistol. Touch Fire / left mouse shoots. Punch / F swings.
    /// </summary>
    [DefaultExecutionOrder(15)]
    public class PlayerCombat : MonoBehaviour
    {
        [SerializeField] float punchReach = 1.35f;
        [SerializeField] float punchDamage = 40f;
        [SerializeField] float punchCooldown = 0.55f;
        [SerializeField] float shotRange = 42f;
        [SerializeField] float shotDamage = 34f;
        [SerializeField] float shotCooldown = 0.28f;

        Health _health;
        float _punchReady;
        float _shotReady;
        bool _fireWasHeld;

        void Awake()
        {
            _health = GetComponent<Health>();
        }

        void Update()
        {
            if (_health != null && _health.Dead)
                return;
            var player = GetComponent<PlayerController>();
            if (player != null && player.InVehicle)
                return;

            var input = MobileInput.Instance;
            if (input == null)
                return;

            if (input.PunchPressed)
                TryPunch();

            bool fire = input.FireHeld;
            if (fire && !_fireWasHeld)
                TryShoot();
            _fireWasHeld = fire;
        }

        void TryPunch()
        {
            if (Time.time < _punchReady)
                return;
            _punchReady = Time.time + punchCooldown;
            Vector3 center = transform.position + transform.forward * 0.85f + Vector3.up * 1.0f;
            var hits = Physics.OverlapSphere(center, punchReach);
            for (int i = 0; i < hits.Length; i++)
            {
                var ped = hits[i].GetComponentInParent<Pedestrian>();
                if (ped != null && !ped.Downed)
                    ped.Hurt(punchDamage, transform.position, 10f);
            }
        }

        void TryShoot()
        {
            if (Time.time < _shotReady)
                return;
            _shotReady = Time.time + shotCooldown;

            Vector3 origin = transform.position + Vector3.up * 1.35f;
            Vector3 dir = transform.forward;
            if (Camera.main != null)
            {
                Ray aim = Camera.main.ViewportPointToRay(new Vector3(0.5f, 0.5f, 0f));
                origin = aim.origin;
                dir = aim.direction;
            }

            Vector3 end = origin + dir * shotRange;
            var self = GetComponent<PlayerController>();
            if (FirstHit(origin, dir, shotRange, self, null, out RaycastHit hit))
            {
                end = hit.point;
                var ped = hit.collider.GetComponentInParent<Pedestrian>();
                if (ped != null)
                    ped.Hurt(shotDamage, transform.position, 18f);
            }

            Tracer(origin, end);
        }

        public static bool FirstHit(Vector3 origin, Vector3 dir, float range, PlayerController ignorePlayer, VehicleController ignoreCar, out RaycastHit hit)
        {
            hit = default;
            var hits = Physics.RaycastAll(origin, dir, range, ~0, QueryTriggerInteraction.Ignore);
            float best = float.MaxValue;
            bool found = false;
            for (int i = 0; i < hits.Length; i++)
            {
                var col = hits[i].collider;
                if (col == null || hits[i].distance >= best)
                    continue;
                if (ignorePlayer != null && col.GetComponentInParent<PlayerController>() == ignorePlayer)
                    continue;
                if (ignoreCar != null && col.GetComponentInParent<VehicleController>() == ignoreCar)
                    continue;
                best = hits[i].distance;
                hit = hits[i];
                found = true;
            }

            return found;
        }

        static void Tracer(Vector3 from, Vector3 to)
        {
            var go = GameObject.CreatePrimitive(PrimitiveType.Cube);
            go.name = "Tracer";
            var col = go.GetComponent<Collider>();
            if (col != null)
                Destroy(col);
            go.transform.position = (from + to) * 0.5f;
            Vector3 span = to - from;
            if (span.sqrMagnitude > 0.0001f)
                go.transform.rotation = Quaternion.LookRotation(span);
            go.transform.localScale = new Vector3(0.035f, 0.035f, Mathf.Max(0.2f, span.magnitude));
            var renderer = go.GetComponent<Renderer>();
            if (renderer != null)
                renderer.material.color = new Color(1f, 0.9f, 0.45f);
            Destroy(go, 0.06f);
        }
    }
}
