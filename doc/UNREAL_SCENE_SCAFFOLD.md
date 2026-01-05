# Unreal Scene Scaffold & JSON Ingestion (POC)

Purpose: provide step-by-step guidance to build a minimal Unreal scene that plays back the exported MAT JSON (`data/processed/unreal_playback.json`) to drive visuals without live UDP.

Prerequisites
- Unreal Engine 5.x (5.4+ recommended)
- Visual Studio 2022 (C++) installed
- `data/processed/unreal_playback.json` produced by `scripts/matlab/export_simlog_for_unreal.m`

Quick Goals
- Create a simple level with 10 placeholder actors representing hydraulic components.
- Route 12 pipes using spline meshes (engine Starter Content or procedural splines).
- Create dynamic material(s) with a `Pressure` scalar parameter.
- Create a Niagara emitter for flow visualization with a `SpawnRate` parameter.
- Add a Cylinder actor whose local Z transform is driven by rod velocity.
- Implement an offline JSON loader (C++ or Blueprint) that steps frames and updates visuals.

Recent Progress (Dec 31, 2025 — Jan 1, 2026)
- Integrated flopperam/unreal-engine-mcp plugin into the project at `Plugins/UnrealMCP`.
- Removed a nested duplicate plugin copy that caused duplicate module definitions.
- Enabled the plugin in the project and rebuilt `SimpleHydraulicsEditor` (Win64, Development); the plugin editor module was produced.
- Installed Python MCP dependency (`mcp`) and started the advanced MCP server (`unreal_mcp_server_advanced.py`) using stdio transport; server writes `unreal_mcp_advanced.log`.
- Added and ran a stdio test client `Plugins/UnrealMCP/Python/test_client_stdio.py`; it initialized a session and listed available tools including `get_actors_in_level`, `find_actors_by_name`, `set_actor_transform`, and `apply_material_to_actor`.
- Confirmed playback input at `c:/0Work/Projects/LLM-MCP/SimscapeFluid/data/processed/unreal_playback.json` (~15.7 MB) produced by `scripts/matlab/export_simlog_for_unreal.m`.
- **Created `APlaybackManager` C++ actor** in `Source/SimpleHydraulics/PlaybackManager.h/.cpp`:
  - Loads `unreal_playback.json` using `FJsonSerializer` (parses frames with `t`, `pressure`, `flow`, `massFlow`, `rod` arrays).
  - Spawns placeholder actors (`Pump_01..06`, `Cylinder_01`, `PipeSpline_01..04`) on BeginPlay.
  - Provides `Play()`, `Pause()`, `Stop()`, `ApplyFrame(int32)` Blueprint-callable methods.
  - Tick-driven playback with adjustable `PlaybackSpeed` multiplier.
  - **Build succeeded** — Editor compiled with Json/JsonUtilities modules added to `SimpleHydraulics.Build.cs`.
- Copied `unreal_playback.json` to `C:\0Work\Projects\LLM-MCP\UnrealProject\SimpleHydraulics\Content\Data\unreal_playback.json` (ready for playback).

## How to Use APlaybackManager

1. **Open the Editor**:
   ```powershell
   & "C:\Program Files\Epic Games\UE_5.7\Engine\Binaries\Win64\UnrealEditor.exe" "C:\0Work\Projects\LLM-MCP\UnrealProject\SimpleHydraulics\SimpleHydraulics.uproject"
   ```

2. **Place `APlaybackManager` in your level**:
   - In the Place Actors panel, search for `PlaybackManager` (or open Content Browser → C++ Classes → SimpleHydraulics → `PlaybackManager`).
   - Drag `APlaybackManager` into the Viewport.

3. **Configure the actor** (Details panel):
   - **DataFilePath**: `Content/Data/unreal_playback.json` (or full path if needed).
   - **bAutoSpawnOnBeginPlay**: `true` (spawns placeholder actors automatically).
   - **bStartPaused**: `false` (starts playback immediately) or `true` (manual frame stepping).
   - **PlaybackSpeed**: `1.0` (real-time) or `2.0` (2x speed), etc.
   - **NumPumps**: `6`, **NumCylinders**: `1`, **NumPipes**: `4` (adjust as needed).
   - **ActorSpacing**: `200.0` cm (spacing between spawned actors).

4. **Play In Editor (PIE)**:
   - Press `Alt+P` or click Play in the toolbar.
   - The manager loads JSON, spawns actors, and begins playback.
   - Check the Output Log (`Window → Developer Tools → Output Log`) for:
     ```
     LogTemp: Warning: PlaybackManager: Loaded 31671 frames from ...
     LogTemp: Warning: PlaybackManager: Spawned 11 placeholder actors
     LogTemp: Log: PlaybackManager: Playback started
     ```

5. **Manual control** (Blueprint or C++):
   - Get reference to `APlaybackManager` and call:
     - `LoadData()` — reload JSON.
     - `SpawnPlaceholderActors()` — re-create scene actors.
     - `Play()`, `Pause()`, `Stop()` — playback controls.
     - `ApplyFrame(int32 FrameIndex)` — apply a specific frame (manual stepping).
     - `GetFrameCount()`, `GetCurrentFrameIndex()`, `IsPlaying()` — query state.

6. **Inspect spawned actors**:
   - Open `Window → World Outliner` and search for `Pump_`, `Cylinder_`, `PipeSpline_`.
   - Select an actor and press `F` in the Viewport to frame it.
   - Actors update their Z position based on normalized pressure (simple placeholder visualization).

7. **Next steps**:
   - Assign static meshes to spawned actors (e.g., cubes/cylinders from Starter Content).
   - Create and assign dynamic material instances (`M_Pressure`) with scalar parameter `Pressure`.
   - Map specific pressure/flow indices to specific actors (edit `UpdateActorStates()` in `PlaybackManager.cpp`).
   - Add Niagara emitters for flow visualization (set `SpawnRate` per frame).
   - Integrate cylinder rod position (integrate `RodVelocity` to compute displacement).

Asset & Naming Conventions (suggested)
- Placeholders:
  - `Pump_01` .. `Pump_10` (StaticMeshActor using Engine cube/sphere)
  - `Cylinder_01` (contains rod sub-actor `CylinderRod`)
  - `PipeSpline_01` .. `PipeSpline_12` (SplineActors with SplineMeshComponents)
- Materials:
  - `M_Pressure` (Material with scalar parameter `Pressure` used by components)
- Niagara:
  - `NS_FlowEmitter` (Module exposes `SpawnRate` float parameter)

JSON Schema (from exporter)
- Root: array of frames. Each frame:
  - `t` (seconds)
  - `pressure`: array[18] — indices map to:
    0 pump_out, 1 relief_in, 2 relief_out, 3 vent_in, 4 vent_out,
    5 dir_P, 6 dir_T, 7 dir_A, 8 dir_B, 9 cyl_cap, 10 cyl_rod,
    11 check_in, 12 check_out, 13 restrict_in, 14 restrict_out,
    15 filter_in, 16 filter_out, 17 tank_in
  - `flow`: array[11] — pump_out, relief_in, vent_in, dir_P, dir_T, dir_A, dir_B, check_in, restrict_in, filter_in, tank_in
  - `massFlow`: array[2] — [cyl_cap_mdot, cyl_rod_mdot]
  - `rod`: object { `vel`: m/s }

Recommended UE ingestion approach (C++ core, Blueprint API)

1) File placement
- Put `unreal_playback.json` in the project `Content/` or a known absolute path. Example runtime path: `FPaths::ProjectContentDir() / "Data/unreal_playback.json"` (create `Content/Data` and copy file).

2) C++ Loader (high-level)
- Use `FFileHelper::LoadFileToString` to read JSON string.
- Parse with `TSharedPtr<FJsonValue>` and `FJsonSerializer` into `TArray<TSharedPtr<FJsonValue>>` frames.
- Convert each frame into a lightweight struct:
  - `float Time; TArray<float> Pressures; TArray<float> Flows; float RodVel;`
- Store frames in a `TArray` in a manager `AActor` or `UObject` and expose playback controls to Blueprint.

Pseudo C++ outline
```
// Read file
FString JsonStr;
FFileHelper::LoadFileToString(JsonStr, *FilePath);

TSharedPtr<FJsonValue> Root;
TSharedRef<TJsonReader<>> Reader = TJsonReaderFactory<>::Create(JsonStr);
FJsonSerializer::Deserialize(Reader, Root);

TArray<TSharedPtr<FJsonValue>> Frames = Root->AsArray();
for (auto &Fv : Frames) { /* extract arrays into structs */ }

// Playback timer
GetWorld()->GetTimerManager().SetTimer(PlayHandle, this, &UPlaybackMgr::StepFrame, FrameDt, true);

void StepFrame() {
  const Frame& f = Frames[FrameIndex++];
  // Update dynamic materials: MaterialInstance->SetScalarParameterValue("Pressure", mappedValue);
  // Update Niagara emitter: SetFloatParameter("SpawnRate", mappedFlow);
  // Update Cylinder rod: CylinderRod->SetRelativeLocation(Z = scale * integratedRodPosition);
}
```

3) Blueprint exposure
- Expose `UFUNCTION(BlueprintCallable)` methods: `LoadPlayback(FString Path)`, `Play()`, `Pause()`, `Stop()`, `SetPlaybackRate(float)`.
- Expose `FOnPlaybackFrame` `DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam` to broadcast per-frame data to Blueprint actors.

4) Material & Niagara updates
- For each component actor, cache a `UMaterialInstanceDynamic` for `M_Pressure`.
- Map a chosen pressure index (per actor) to the material parameter; use a linear mapping function to convert Pa → 0..1 for color lerp.
- For flow visualization, set Niagara `SpawnRate` via `UNiagaraComponent::SetVariableFloat` or via parameter binding.

5) Cylinder rod mapping
- Exported data contains rod velocity only; integrate velocity to estimate displacement or use a normalized mapping:
  - `pos += vel * dt` per step; clamp to expected stroke range.

Performance notes
- Use a fixed playback rate (e.g., 30 Hz) for in-editor testing (sample stepping). If using full 31k frames, downsample or step by `stride` to match target playback length.
- Avoid per-frame JSON parsing; parse once at load-time into native structures.
- Use `MaterialInstanceDynamic` and cached Niagara components to avoid allocations during playback.

Checklist (in-editor)
1. Create C++ project and plugin skeleton (Plugin Wizard) or add an Actor `APlaybackManager` in C++.
2. Place placeholder actors and spline pipes in level.
3. Create `M_Pressure` material and `NS_FlowEmitter` Niagara asset.
4. Copy `unreal_playback.json` to `Content/Data/`.
5. Implement loader and test `LoadPlayback` + `Play` in PIE.

Files added/edited by this guide
- `scripts/matlab/export_simlog_for_unreal.m` — exporter (already added)
- `data/processed/unreal_playback.json` — generated playback file
- `doc/UNREAL_SCENE_SCAFFOLD.md` — (this file)

Next steps I can take for you
- Generate a minimal C++ `APlaybackManager` source file + header (ready-to-drop into a plugin) and a small `README.md` with UE editor steps.
- Or produce a Blueprint-only loader using `VaRest` (plugin) or built-in JSON parsing via Blueprints (less recommended).

Immediate recommended safe-test
- Implement a minimal Python playback client that reads one frame from `data/processed/unreal_playback.json`, connects to the MCP server (stdio), calls `find_actors_by_name` (or `get_actors_in_level`) and issues one `set_actor_transform` (identity or small offset) to validate end-to-end updates in the Editor. Do not stream the full file until mapping is validated.

---
Place this file in `doc/` and follow the checklist to scaffold the scene in the Unreal Editor.
