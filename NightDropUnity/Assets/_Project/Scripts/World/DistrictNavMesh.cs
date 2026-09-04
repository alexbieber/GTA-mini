using System.Collections.Generic;
using UnityEngine;
using UnityEngine.AI;

namespace NightDrop.World
{
    public static class DistrictNavMesh
    {
        public static void Bake(Vector3 center, Vector3 size)
        {
            var bounds = new Bounds(center, size);
            var sources = new List<NavMeshBuildSource>();
            var markups = new List<NavMeshBuildMarkup>();
            NavMeshBuilder.CollectSources(bounds, ~0, NavMeshCollectGeometry.PhysicsColliders, 0, markups, sources);
            if (sources.Count == 0)
                return;

            var settings = NavMesh.GetSettingsByIndex(0);
            settings.agentRadius = 0.32f;
            settings.agentHeight = 1.7f;
            settings.agentSlope = 35f;
            var data = NavMeshBuilder.BuildNavMeshData(settings, sources, bounds, Vector3.zero, Quaternion.identity);
            if (data != null)
                NavMesh.AddNavMeshData(data);
        }
    }
}
