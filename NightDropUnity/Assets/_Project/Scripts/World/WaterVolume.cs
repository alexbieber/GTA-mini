using NightDrop.Player;
using UnityEngine;

namespace NightDrop.World
{
    public class WaterVolume : MonoBehaviour
    {
        void OnTriggerEnter(Collider other)
        {
            var player = other.GetComponentInParent<PlayerController>();
            if (player != null)
                player.SetInWater(true);
        }

        void OnTriggerExit(Collider other)
        {
            var player = other.GetComponentInParent<PlayerController>();
            if (player != null)
                player.SetInWater(false);
        }
    }
}
