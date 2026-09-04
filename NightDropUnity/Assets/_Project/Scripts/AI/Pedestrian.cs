using NightDrop.Managers;
using NightDrop.Player;
using UnityEngine;
using UnityEngine.AI;

namespace NightDrop.AI
{
    public class Pedestrian : MonoBehaviour
    {
        public enum Mood
        {
            Wander,
            Idle,
            Flee,
            Down
        }

        [SerializeField] float walkSpeed = 1.55f;
        [SerializeField] float fleeSpeed = 5.4f;

        CharacterController _cc;
        Vector3 _goal;
        float _wait;
        float _down;
        Mood _mood = Mood.Wander;

        public bool Downed => _mood == Mood.Down;

        public void KnockDown(Vector3 from)
        {
            if (_mood == Mood.Down)
                return;
            _mood = Mood.Down;
            _down = 6f;
            if (_cc != null)
                _cc.enabled = false;
            transform.rotation = Quaternion.LookRotation(transform.right, Vector3.up);
            HeatSystem.Report(16f);
            ScareNearby(from);
        }

        public void Scare(Vector3 from)
        {
            if (_mood == Mood.Down)
                return;
            _mood = Mood.Flee;
            Vector3 away = transform.position + (transform.position - from).normalized * 14f;
            away.y = 0.15f;
            _goal = away;
        }

        public static void ScareNearby(Vector3 from)
        {
            var peds = FindObjectsOfType<Pedestrian>();
            for (int i = 0; i < peds.Length; i++)
            {
                if (peds[i] != null && (peds[i].transform.position - from).sqrMagnitude < 140f)
                    peds[i].Scare(from);
            }
        }

        void Awake()
        {
            _cc = GetComponent<CharacterController>();
            PickGoal();
        }

        void Update()
        {
            if (_mood == Mood.Down)
            {
                _down -= Time.deltaTime;
                if (_down <= 0f)
                {
                    transform.rotation = Quaternion.identity;
                    _mood = Mood.Wander;
                    if (_cc != null)
                        _cc.enabled = true;
                    PickGoal();
                }

                return;
            }

            var player = PlayerController.Instance;
            if (player != null && HeatSystem.Instance != null && HeatSystem.Instance.Level > 0)
            {
                if ((player.transform.position - transform.position).sqrMagnitude < 220f)
                    Scare(player.transform.position);
            }

            if (_mood == Mood.Idle)
            {
                _wait -= Time.deltaTime;
                if (_wait <= 0f)
                {
                    _mood = Mood.Wander;
                    PickGoal();
                }

                return;
            }

            float speed = _mood == Mood.Flee ? fleeSpeed : walkSpeed;
            Vector3 to = _goal - transform.position;
            to.y = 0f;
            if (to.sqrMagnitude < 1.2f)
            {
                if (_mood == Mood.Flee)
                    PickGoal();
                else
                {
                    _mood = Mood.Idle;
                    _wait = Random.Range(1.2f, 3.4f);
                }

                return;
            }

            Vector3 dir = to.normalized;
            if (_cc != null && _cc.enabled)
            {
                Vector3 motion = dir * speed;
                motion.y = -8f;
                _cc.Move(motion * Time.deltaTime);
            }

            if (dir.sqrMagnitude > 0.05f)
                transform.rotation = Quaternion.Slerp(transform.rotation, Quaternion.LookRotation(dir), 8f * Time.deltaTime);
        }

        void PickGoal()
        {
            Vector2 ring = Random.insideUnitCircle * 42f;
            _goal = new Vector3(ring.x, 0.15f, ring.y);
            if (NavMesh.SamplePosition(_goal, out NavMeshHit hit, 8f, NavMesh.AllAreas))
                _goal = hit.position;
        }
    }
}
