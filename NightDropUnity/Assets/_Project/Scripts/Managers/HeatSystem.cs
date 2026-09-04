using System.Collections.Generic;
using NightDrop.Player;
using NightDrop.Vehicles;
using UnityEngine;

namespace NightDrop.Managers
{
    public class HeatSystem : MonoBehaviour
    {
        public static HeatSystem Instance { get; private set; }

        [SerializeField] float decayPerSecond = 3.4f;
        [SerializeField] float decayDelay = 7f;

        readonly List<VehicleController> _units = new List<VehicleController>();
        float _idle;

        public float Value { get; private set; }
        public int Level => Value < 10f ? 0 : Mathf.Clamp(Mathf.CeilToInt(Value / 20f), 1, 5);

        public static void Report(float amount)
        {
            if (Instance != null)
                Instance.Add(amount);
        }

        public void Add(float amount)
        {
            Value = Mathf.Clamp(Value + amount, 0f, 100f);
            _idle = 0f;
        }

        public void ResetHeat()
        {
            Value = 0f;
            _idle = 0f;
            ClearUnits();
        }

        void Awake()
        {
            if (Instance != null && Instance != this)
            {
                Destroy(this);
                return;
            }

            Instance = this;
        }

        void OnDestroy()
        {
            if (Instance == this)
                Instance = null;
        }

        void Update()
        {
            _idle += Time.deltaTime;
            if (_idle > decayDelay && Value > 0f)
                Value = Mathf.Max(0f, Value - decayPerSecond * Time.deltaTime);

            SyncUnits();
        }

        void SyncUnits()
        {
            int want = Level;
            _units.RemoveAll(v => v == null || v.PlayerDriven);
            while (_units.Count > want)
            {
                var extra = _units[_units.Count - 1];
                _units.RemoveAt(_units.Count - 1);
                if (extra != null && !extra.PlayerDriven)
                    Destroy(extra.gameObject);
            }

            var player = PlayerController.Instance;
            if (player == null)
                return;

            while (_units.Count < want)
            {
                Vector3 offset = Quaternion.Euler(0f, _units.Count * 90f, 0f) * new Vector3(18f, 0f, 22f);
                Vector3 pos = player.transform.position + offset;
                pos.y = 0.32f;
                var unit = VehicleFactory.SpawnPolice(pos, player.transform.eulerAngles.y, PatrolLoop());
                unit.SetChase(player.transform);
                _units.Add(unit);
            }

            for (int i = 0; i < _units.Count; i++)
            {
                if (_units[i] != null && !_units[i].PlayerDriven)
                    _units[i].SetChase(player.transform);
            }
        }

        void ClearUnits()
        {
            for (int i = 0; i < _units.Count; i++)
            {
                if (_units[i] != null && !_units[i].PlayerDriven)
                    Destroy(_units[i].gameObject);
            }

            _units.Clear();
        }

        static Vector3[] PatrolLoop()
        {
            return new[]
            {
                new Vector3(-36f, 0.32f, -36f),
                new Vector3(36f, 0.32f, -36f),
                new Vector3(36f, 0.32f, 36f),
                new Vector3(-36f, 0.32f, 36f)
            };
        }
    }
}
