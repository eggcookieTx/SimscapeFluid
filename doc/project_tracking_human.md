# Project Tracking (Human Summary)

Quick reference for project status. For detailed context, see project_tracking_llm.md.

## Current Status

- **Date**: January 6, 2026
- **Overall Progress**: Phase 1 Complete - Phase 2A Complete - Phase 3 Nearly Complete
- **Current Phase**: Phase 3 & 4 - Flow Visualization (Niagara System Creation)

## Completed
- ✓ Folder structure created (data, doc, scripts, models)
- ✓ Documentation framework initialized (10 docs)
- ✓ Comprehensive research on Simscape + Unreal integration
- ✓ Identified feasible architecture: UDP-based loose coupling
- ✓ Confirmed Unreal has native UDP support
- ✓ **Phase 1 Complete**: Generated working Simscape hydraulic model
  - 10 hydraulic blocks with proper topology
  - 3 parallel pump paths (Relief, Vent, Directional Control)
  - Rod-end control with parallel check valve + flow restriction
  - Manual signal connections added
  - Model runs successfully
- ✓ **Phase 2A Complete**: Simscape Data Logging
  - Created `run_and_log_simulation.m` script
  - Successfully implemented `Simulink.SimulationInput` for simlog access
  - Extracting 20+ port states (pressure, flow, velocity) from all 10 blocks
  - Script generates 2-3 MB MAT files with complete port-level data
  - 31,671 time points over 30-second simulation
  - Data saved with proper units (Pa, m³/s, m/s)
- ✓ **Phase 2B Skipped**: Real-Time Sensors
  - Rationale: simlog captures all component port states (20+ points) automatically
- ⏭️ **Phase 2C Deferred**: UDP Streaming
  - Will implement after Unreal visualization POC is working

## Recent Progress (Jan 1, 2026)

- Integrated the flopperam/unreal-engine-mcp plugin into `Plugins/UnrealMCP` and removed a duplicate nested copy that caused module conflicts.
- Enabled the plugin in `SimpleHydraulics.uproject` and rebuilt the editor; plugin editor module is present in the built Editor.
- Installed Python dependency `mcp` and started the plugin's advanced MCP server using stdio transport; server runtime log at `Plugins/UnrealMCP/Python/unreal_mcp_advanced.log`.
- Created and ran `Plugins/UnrealMCP/Python/test_client_stdio.py` to validate stdio client↔server connectivity; the server returned a tools list including `get_actors_in_level`, `find_actors_by_name`, `set_actor_transform`, and `apply_material_to_actor`.
- Verified `data/processed/unreal_playback.json` exists (15.7 MB) and is ready for safe-test playback.
- **✓ Implemented C++ `APlaybackManager` actor**:
  - Created `Source/SimpleHydraulics/PlaybackManager.h/.cpp` with JSON loader, actor spawning, and frame-by-frame playback.
  - Added Json/JsonUtilities module dependencies to `SimpleHydraulics.Build.cs` and rebuilt successfully.
  - Copied playback JSON to `Content/Data/unreal_playback.json` in the Unreal project.
  - Exposed Blueprint-callable methods: `LoadData()`, `SpawnPlaceholderActors()`, `Play()`, `Pause()`, `Stop()`, `ApplyFrame(int32)`.
  - Manager spawns placeholder actors (`Pump_01..06`, `Cylinder_01`, `PipeSpline_01..04`) and updates their Z positions based on normalized pressure (simple POC visualization).
- Updated `doc/UNREAL_SCENE_SCAFFOLD.md` with step-by-step usage instructions for `APlaybackManager`.

## Recent Progress (Jan 6, 2026)

**✓ Topology & Pipe Visualization Complete:**
- Created topology.json with P&ID layout (9 components, 12 pipe connections)
- Implemented spline mesh rendering for all pipes (30cm diameter)
- Pressure visualization working on all 12 pipes (blue→red gradient)
- Component text labels added (yellow, 80 units, positioned above components)
- Scene lighting implemented (directional + sky light, auto-spawn)
- All builds successful, git commits: 6d44171, 3b2b0e8, 8b72ee5, 2c38792, 824855a, 93b7c7b

**⚠️ Current Blocker - Niagara Flow Particles:**
- Attempted to use `/Niagara/Systems/Fountain` - system does NOT exist in UE 5.7
- FlowParticleSystem failed to load at runtime
- No flow particles spawning (error: "FlowParticleSystem not set")
- Text label visibility unclear (needs testing with improved unlit material)

**✓ What's Working:**
- Pressure visualization: Perfect, all pipes showing data-driven colors
- Scene lighting: Both lights spawned successfully
- Playback: 31,671 frames at ~100 FPS
- Topology: Components and pipes in correct P&ID positions

**❌ What's Blocked:**
- Niagara particles: Missing Fountain system
- Flow visualization: No particles appearing in pipes

**📋 Next Task - Create Custom Niagara System:**
- Write Python script to generate `/Game/Niagara/NS_FlowParticles`
- Features: User.SpawnRate + User.Velocity parameters, 5-10cm particles, cyan color
- Update PlaybackManager to load custom system instead of Fountain
- Test particle spawning inside pipes with flow data driving spawn rate

---

## Recent Progress (Jan 5, 2026)

**✓ Fixed Critical Bugs:**
- Fixed crash on second PIE run: Added cleanup logic to destroy existing actors by name before spawning new ones
- Fixed mobility warnings: Set `EComponentMobility::Movable` on spawned StaticMeshComponents
- Rebuilt successfully, tested PIE → Stop → Play cycle with no crashes
- Committed and pushed all changes to dev repo

**✓ Testing Confirmed:**
- PlaybackManager loads 31,671 frames successfully
- Spawns 11 placeholder actors without errors
- Basic Z-position animation working (no meshes yet, actors are invisible)
- No crash on multiple PIE runs

## Current Task (Jan 5, 2026)

**✓ Pressure Visualization Complete - Working!**

Goal: Make the invisible actors visible and show pressure changes with color

Steps:
1. ✓ Created M_Pressure material via Python automation (blue=low, red=high gradient)
2. ✓ Assigned cube meshes to pumps, cylinder mesh to cylinder actors
3. ✓ Created Material Instance Dynamic (MID) in C++ for each actor
4. ✓ Updated `UpdateActorStates()` to set scalar parameter "Pressure" (normalized to 0-224kPa range)
5. ✓ Tested playback - color changes visible, actors animating vertically
6. ✓ Fixed normalization: Changed from 10 MPa to 0.224 MPa to match actual data range

**Result:** 6 cubes (pumps) + 1 cylinder now visible, colors animate blue→purple→red based on pressure data

---

**✓ COMPLETE: P&ID Topology Layout**
- topology.json created with all 9 components and 12 pipe connections
- PlaybackManager reads topology and spawns splines with waypoints
- Pressure visualization working on all pipes
- Text labels for all components

**[IN PROGRESS] Create Custom Niagara Flow Particle System**

Goal: Enable flow visualization inside pipes with data-driven particle spawning

Current Blocker:
- `/Niagara/Systems/Fountain` does not exist in UE 5.7
- FlowParticleSystem = nullptr at runtime
- No particles spawning

Plan:
1. **Create Python Script** (`scripts/python/create_niagara_flow_system.py`):
   - Generate custom Niagara system with GPU sprite emitter
   - Add User.SpawnRate parameter (0-100 particles/sec)
   - Add User.Velocity parameter (flow speed in cm/s)
   - Set particle size 5-10cm (fits inside 30cm pipes)
   - Use cyan color for water visualization
   - Save as `/Game/Niagara/NS_FlowParticles`
2. **Update PlaybackManager.cpp**:
   - Change system path from `/Niagara/Systems/Fountain` to `/Game/Niagara/NS_FlowParticles`
   - Rebuild and test particle spawning
3. **Runtime Testing**:
   - Verify particles spawn inside pipes
   - Check spawn rate changes with flow data
   - Validate particle movement along splines
   - Confirm performance (12 pipes × particles)

Fallback Option:
- Revert to sphere mesh flow visualization (commit 8b72ee5) if Niagara proves problematic

## Immediate Next Steps

1. ✓ Open the Editor, place `APlaybackManager` in the level, configure `DataFilePath`, and test playback
2. ✓ Assign static meshes (cubes/cylinders from Engine BasicShapes) to spawned actors for visual feedback
3. ✓ Create dynamic material `M_Pressure` with scalar parameter and assign to actors; map pressure to color
4. **[NEXT]** Implement proper P&ID topology layout (currently actors spawn in simple grid):
   - **Approach 1**: Create `topology.json` with actual component positions and pipe connections from P&ID
   - **Approach 3**: Use MCP Python script to programmatically build scene with proper layout
   - Update PlaybackManager to read topology and spawn splines between connected components
   - Match 3D layout to P&ID schematic (see `SimpleHydraulicSchematics.jpg`)
5. **[FUTURE]** Add flow visualization using Niagara particle systems (map flow data to spawn rate)
6. **[FUTURE]** Implement cylinder rod extension/retraction based on `rod.vel` integration
7. **[FUTURE]** Add UI overlay (UMG widget) displaying real-time pressure/flow values
8. Validate full playback at 30 Hz with all 31,671 frames and confirm stable frame rate

## Implementation Plan

**Phase 1: P&ID → Simscape Model** [✅ COMPLETE]

**Phase 2A: Simscape Data Logging** [✅ COMPLETE]

**Phase 2B: Real-Time Sensors** [⏭️ SKIPPED]

**Phase 2C: UDP Streaming** [⏭️ DEFERRED - After Unreal POC]
- Will implement after Phase 3 & 4 POC is working

**Phase 3: Unreal Layout & Receiver** [🟨 CURRENT - PRIORITY]

**Phase 4: Connect to Unreal & Visualization** [🟨 CURRENT - PRIORITY]

**Phase 2C: UDP Streaming** [⏭️ AFTER POC]

## In Progress

## Next Steps
1. Create Unreal C++ project and plugin scaffold (UE Plugin Wizard) and confirm it loads. Ref: see links in doc/RESEARCH.md Unreal POC section.
2. Build a minimal scene: place 10 placeholder components and route 12 pipes using spline meshes; use engine starter assets only.
3. Implement offline MAT playback: export simulation data to JSON (see export_simlog_for_unreal.m), ingest in Unreal, and drive material color (pressure), Niagara particle rate (flow), and cylinder rod transform (velocity).
4. Validate visuals and frame rate using offline playback before adding UDP or custom assets.

## Blockers
None currently

---
