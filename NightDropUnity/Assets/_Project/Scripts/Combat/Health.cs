using System;
using UnityEngine;

namespace NightDrop.Combat
{
    public class Health : MonoBehaviour
    {
        [SerializeField] float max = 100f;

        public float Max => max;
        public float Current { get; private set; }
        public bool Dead => Current <= 0f;
        public event Action Died;

        void Awake()
        {
            Current = max;
        }

        public void Apply(float amount)
        {
            if (Dead || amount <= 0f)
                return;
            Current = Mathf.Max(0f, Current - amount);
            if (Dead)
                Died?.Invoke();
        }

        public void Revive()
        {
            Current = max;
        }
    }
}
