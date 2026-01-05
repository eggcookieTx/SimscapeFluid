# Project Tracking (Human Summary)

Quick reference for project status. For detailed context, see project_tracking_llm.md.

## Current Status

- **Date**: December 31, 2025
 - **Date**: January 1, 2026
- **Overall Progress**: Phase 1 Complete - Phase 2A Complete
- **Current Phase**: Phase 3 & 4 - Unreal Layout & UDP Receiver (POC)

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

**[IN PROGRESS] Implement Proper P&ID Topology Layout**

Goal: Replace random grid layout with actual hydraulic schematic topology

Current State:
- Actors spawn in simple grid (200 unit X spacing)
- No visual representation of pipe connections
- Layout doesn't match P&ID schematic

Plan (Options 1 + 3):
1. **Create topology.json**: Define component 3D positions and connections matching P&ID
   - Extract connection graph from Simscape model (12 pipe connections)
   - Map to 3D coordinates matching hydraulic flow paths
   - Include spline waypoints for pipe routing
2. **MCP Scene Builder Script**: Programmatically build scene via Unreal MCP
   - Read topology.json and spawn actors at correct positions
   - Create spline actors for pipe connections with proper routing
   - Apply materials and meshes matching component types
3. **Update PlaybackManager**: Read topology data for spawning
   - Load positions from JSON instead of grid calculation
   - Spawn spline meshes between connected components
   - Maintain data-driven animation (pressure, flow, rod velocity)

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
