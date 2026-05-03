-- ServerScriptService/MazePathCache (ModuleScript)
-- v2 fix-up — caches PathfindingService waypoints per maze spawn marker.
-- Computed once per MazeGenerator.Apply() run; all enemies from the same
-- spawn share the same cached waypoint list. Per-enemy variance happens at
-- the move step (small random perpendicular offset per enemy) so they don't
-- look like a marching column.
--
-- Why per-spawn caching instead of per-enemy compute:
-- - PathfindingService:ComputeAsync yields. 10-15 waves of enemies × N path
--   computes per spawn = noticeable hitches. Caching costs 4 computes total
--   (one per spawn marker) at maze generation time.
-- - Maze geometry is static during a run. Same spawn → same destination →
--   same valid path. No per-enemy variation needed at the topology level.

local PathfindingService = game:GetService("PathfindingService")

local MazePathCache = {}

local cache = {}  -- [markerName] = { waypoints = { Waypoint, Waypoint, ... } }

-- Path agent params tuned for our enemies. AgentRadius covers the largest
-- non-boss enemy (Splitter is 3.2 wide; ServerCrasher is 4.5 but it's
-- lane-only). AgentHeight covers any vertical clearance. CanJump=false
-- because enemies walk via BodyVelocity, not Humanoid.
local AGENT_PARAMS = {
	AgentRadius      = 2.5,   -- bumped from 2.2 — covers Splitter (3.2 wide → radius 1.6 + margin)
	AgentHeight      = 5,
	AgentCanJump     = false,
	WaypointSpacing  = 4,     -- bumped down from 6 — tighter path-following at corners
}

function MazePathCache.Compute()
	cache = {}

	local map = workspace:FindFirstChild("Map")
	if not map then
		warn("[MazePathCache] No workspace.Map — skipping path compute")
		return
	end
	local base = map:FindFirstChild("MazeGen_CenterBase")
	if not base then
		warn("[MazePathCache] No MazeGen_CenterBase — skipping path compute (run MazeGenerator.Apply() first)")
		return
	end

	local spawnCount = 0
	local successCount = 0

	for _, child in ipairs(map:GetChildren()) do
		if child:GetAttribute("MazeSpawn") then
			spawnCount = spawnCount + 1
			local path = PathfindingService:CreatePath(AGENT_PARAMS)
			local ok, err = pcall(function()
				path:ComputeAsync(child.Position, base.Position)
			end)
			if ok and path.Status == Enum.PathStatus.Success then
				cache[child.Name] = { waypoints = path:GetWaypoints() }
				successCount = successCount + 1
				print(string.format("[MazePathCache] %s → CenterBase: %d waypoints",
					child.Name, #path:GetWaypoints()))
			else
				warn(string.format("[MazePathCache] Path compute FAILED for %s — status: %s, err: %s",
					child.Name, tostring(path.Status), tostring(err)))
			end
		end
	end

	print(string.format("[MazePathCache] %d/%d paths cached", successCount, spawnCount))
end

-- Find the closest spawn marker to a given position. EnemySpawner uses this
-- to figure out which path applies to a freshly-spawned enemy (since
-- spawnPosition() picks a random marker and the spawn position has small
-- random jitter, we re-derive which marker by proximity).
function MazePathCache.FindClosestSpawnMarker(position)
	local map = workspace:FindFirstChild("Map")
	if not map then return nil end
	local closest, closestDist = nil, math.huge
	for _, child in ipairs(map:GetChildren()) do
		if child:GetAttribute("MazeSpawn") then
			local d = (child.Position - position).Magnitude
			if d < closestDist then
				closestDist = d
				closest = child
			end
		end
	end
	return closest
end

function MazePathCache.GetWaypoints(markerName)
	local entry = cache[markerName]
	if not entry then return nil end
	return entry.waypoints
end

function MazePathCache.HasPaths()
	return next(cache) ~= nil
end

return MazePathCache
