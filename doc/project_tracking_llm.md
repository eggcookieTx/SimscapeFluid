# Project Tracking (LLM-Readable)

This document is designed for LLM context. It can be detailed and verbose to provide complete project state information.

## Session History

### Jan 6, 2026 - Niagara Flow Particles + Scene Lighting + Topology Complete

**Major Milestones Achieved:**
- ✅ Pipe-focused visualization architecture implemented (P&ID topology)
- ✅ Pressure visualization working on all 12 pipes (blue→red gradient)
- ✅ Automatic scene lighting (directional + sky light)
- ✅ Text labels for 9 components
- ⚠️ Niagara flow particles blocked (Fountain system missing)

**Actions Completed:**

1. **Topology System (Commits 6d44171, 3b2b0e8):**
   - Created `data/topology.json` with P&ID layout (9 components, 12 pipe connections)
   - Each pipe connection has: name, from/to components, waypoints, pressure_index, flow_index
   - Updated PlaybackManager to parse topology JSON instead of spawning grid
   - Implemented USplineComponent for pipe routing with 3D waypoints
   - Created USplineMeshComponent for visual pipe rendering (30cm diameter)
   - Applied M_Pressure material to all 12 pipe segments successfully
   - Added UTextRenderComponent labels for component names (positioned 150cm above)

2. **Niagara Integration (Commit 2c38792):**
   - Refactored flow visualization from sphere meshes to Niagara particle systems
   - Added Niagara module to Build.cs PublicDependencyModuleNames
   - Modified FFlowParticle struct: UNiagaraComponent* instead of AActor*
   - Initial system: `/Engine/VFX/Niagara/Systems/NS_GPUSprites`
   - SpawnFlowParticles(): One UNiagaraComponent per pipe attached to spline root
   - UpdateFlowParticles(): Sets SpawnRate (FlowMagnitude × 100000) and Velocity parameters
   - Removed sphere mesh approach (deprecated but working in commit 8b72ee5)

3. **Scene Lighting (Commit 824855a):**
   - Implemented SpawnSceneLighting() method in PlaybackManager
   - DirectionalLight: 5.0 intensity, warm white (1.0, 0.95, 0.9), 45° angle, casts shadows
   - SkyLight: 1.0 intensity, cool blue (0.5, 0.6, 0.8) ambient
   - Smart duplicate detection: checks for existing lights before spawning
   - Called automatically in BeginPlay()

4. **Visualization Fixes (Commit 93b7c7b - CURRENT):**
   - **Issue**: User reported "light source doesn't show labels, no niagara fall inside pipe"
   - **Research**: Fetched Epic's Niagara documentation
   - **Discovery**: NS_GPUSprites is generic template, lacks custom parameters (SpawnRate, Velocity)
   - **Text Label Fix**: Added BasicShapeMaterial as unlit base, increased size 50→80 units, added dynamic material with yellow color
   - **Niagara System Change**: Switched from NS_GPUSprites to `/Niagara/Systems/Fountain`
   - **Scale Fix**: Set RelativeScale3D to 0.1x to fit particles inside pipes
   - **Parameter Namespaces**: Tried User.SpawnRate, SpawnRate, Fountain.SpawnRate
   - **Debug Logging**: Added comprehensive per-pipe logging with spline info and SUCCESS/FAILED status

**Critical Blocker Found (Runtime Testing):**
```
LogTemp: Error: FlowParticleSystem not set - cannot spawn flow visualization. 
Make sure Niagara Fountain system is available.
```

**Root Cause:**
- `/Niagara/Systems/Fountain` does NOT exist in UE 5.7 installation
- FObjectFinder failed to load system
- FlowParticleSystem = nullptr
- No Niagara particles spawned

**What's Working:**
- ✅ Pressure visualization: All 12 pipes showing blue→red gradient based on data
- ✅ Scene lighting: Both DirectionalLight and SkyLight spawned successfully
- ✅ Text labels: Created for 9 components (yellow, positioned at 150cm)
- ✅ Playback: 31,671 frames running at ~100 FPS (Frame 11→6711 in ~6 seconds)
- ✅ Topology: All components and pipes in correct P&ID positions

**What's NOT Working:**
- ❌ Niagara flow particles: System failed to load, no particle spawning
- ⚠️ Text label visibility: Unclear if unlit material fix worked (needs user confirmation)

**Planned Resolution - Custom Niagara System:**

**Approach**: Create purpose-built Niagara system via Python script
- **Script**: `scripts/python/create_niagara_flow_system.py`
- **Save Path**: `/Game/Niagara/NS_FlowParticles`
- **System Features**:
  * GPU sprite emitter for performance (handles 12 pipes × particles)
  * User.SpawnRate parameter (0-100 particles/sec, controlled by flow data)
  * User.Velocity parameter (cm/s, controlled by flow magnitude)
  * Small particle size (5-10cm) to fit inside 30cm pipes
  * Cyan color (water visualization)
  * Particle lifetime ~2 seconds
  * Velocity inheritance from spawn location
- **C++ Update**: Change FlowParticleSystem path from `/Niagara/Systems/Fountain` to `/Game/Niagara/NS_FlowParticles`

**Expected Outcome:**
- Particles spawn inside each pipe at rates matching flow data
- Particles move along pipe splines (visualizing fluid flow direction)
- Real-time updates during playback (spawn rate changes with flow)
- Visual feedback for hydraulic system operation

**Git Commits (Jan 6 Session):**
- `6d44171`: Topology JSON parsing with P&ID layout
- `3b2b0e8`: Pipe-focused visualization with spline meshes
- `8b72ee5`: Sphere mesh flow visualization (working, deprecated)
- `2c38792`: Niagara particle system refactor
- `824855a`: Automatic scene lighting
- `93b7c7b`: Text label + Niagara Fountain fix attempt (blocked by missing system)

**Testing Results:**
- Build: Clean success (13.21 seconds)
- Runtime: Pressure visualization perfect, Niagara blocked, lighting confirmed
- Output Log: Clear error message identifying missing Fountain system
- Frame rate: ~100 FPS during playback (excellent performance)

**Next Task:**
- Create custom Niagara system with User.SpawnRate and User.Velocity parameters
- Test particle spawning and movement inside pipes
- Verify flow visualization matches hydraulic data
- Consider fallback to sphere mesh system if Niagara proves problematic

---

### Jan 5, 2026 - Pressure Visualization Complete + Topology Planning

**Major Milestone Achieved: Playback with Dynamic Material Visualization Working**

**Actions Completed:**

1. **Material System Implementation:**
   - Created Python automation script `create_material_simple.py` (76 lines) using Unreal's MaterialEditingLibrary API
   - Material graph: ScalarParameter "Pressure" (0-1) → LinearInterpolate (blue to red) → BaseColor + EmissiveColor
   - Script executed successfully in Unreal Editor Python console, created `/Game/Materials/M_Pressure`
   - Material assigned to PlaybackManager's "Pressure Material" property

2. **C++ Visualization Enhancements:**
   - Updated PlaybackManager.h: Added UMaterialInterface* PressureMaterial, UStaticMesh* PumpMesh/CylinderMesh, TArray<UMaterialInstanceDynamic*> DynamicMaterials
   - Updated PlaybackManager.cpp constructor: Load Engine/BasicShapes meshes (Cube, Cylinder) via ConstructorHelpers
   - Enhanced SpawnPlaceholderActors(): Assign meshes, set scales (pumps 1x1x2, cylinders 1.5x1.5x3), create MaterialInstanceDynamic from PressureMaterial
   - Enhanced UpdateActorStates(): Set scalar parameter "Pressure" on dynamic materials each frame
   - Added detailed logging: Every 100 frames logs pressure, normalized value, Z position, material validity

3. **Critical Bug Fixes:**
   - **Crash on Second PIE Run**: Added cleanup logic in SpawnPlaceholderActors() to find and destroy existing actors by name before spawning (lines 210-220)
   - **Mobility Warnings**: Set EComponentMobility::Movable on spawned StaticMeshComponents to allow runtime animation
   - Both issues resolved, multiple PIE cycles tested successfully

4. **Data Analysis & Normalization Fix:**
   - Analyzed unreal_playback.json: Pressure range 0-224,082 Pa (0-0.224 MPa), not 0-10 MPa as initially assumed
   - Updated normalization in UpdateActorStates(): Changed divisor from 10,000,000 to 224,000 for correct 0-1 mapping
   - Result: Colors now properly animate blue (low pressure) → purple → red (high pressure) instead of staying all blue

5. **File Organization:**
   - Copied unreal_playback.json (15.7 MB, 31,671 frames) to Unreal project: `Content/Data/unreal_playback.json`
   - Created MATERIAL_SETUP_GUIDE.md (150+ lines) with step-by-step manual material creation instructions
   - Created test_playback_mcp.py for MCP server connectivity testing (discovered MCP doesn't support material creation)

**Testing Results:**
- ✅ PlaybackManager loads 31,671 frames successfully
- ✅ Spawns 11 actors: 6 pumps (cubes), 1 cylinder, 4 pipe splines
- ✅ No crash on PIE → Stop → Play cycle
- ✅ No mobility warnings
- ✅ Actors visible with proper meshes
- ✅ Colors animate dynamically based on pressure data
- ✅ Z-position animation working (50 + normalized_pressure * 200)
- ✅ Materials update correctly (verified via log: "Material=Valid")
- ✅ Frame updates logged every 100 frames with detailed diagnostics

**Git Commits:**
- Commit `afc6079`: "Implement Unreal Engine PlaybackManager and MCP integration" (Jan 5, earlier)
- Commit `98dfbe9`: "Complete pressure visualization: dynamic materials, correct normalization, color animation working" (Jan 5, latest)

**Current State:**
- Basic POC fully functional: 31,671-frame playback with pressure-driven color visualization
- Actors spawning in simple grid layout (200 unit X spacing) - **NOT matching P&ID topology yet**
- Material system working perfectly with correct data range
- Ready for topology implementation

**Identified Gap:**
- **Missing**: Proper P&ID topology layout
- **Current**: Actors spawn in random grid positions
- **Needed**: Match 3D layout to SimpleHydraulicSchematics.jpg with proper pipe routing

**Next Task - Topology Implementation (Options 1 + 3):**

**Option 1: Manual Topology JSON**
- Create `topology.json` defining:
  - Component 3D positions matching P&ID layout
  - Pipe connection graph (from/to components)
  - Spline waypoints for pipe routing
- Extract connection data from Simscape model's 12 addConnection() calls
- Map 2D Simulink block positions to 3D Unreal coordinates

**Option 3: MCP Scene Builder**
- Create Python script using Unreal MCP server
- Read topology.json and programmatically build scene:
  - Spawn actors at correct positions via set_actor_transform
  - Create spline actors for pipe connections
  - Apply materials and meshes via apply_material_to_actor
- Advantage: Reproducible, version-controlled scene setup

**Integration Plan:**
1. Create topology.json with component positions and connections
2. Write MCP scene builder script to construct layout
3. Update PlaybackManager to read positions from JSON (instead of grid)
4. Implement spline mesh creation between connected components
5. Test playback with proper topology showing hydraulic flow paths

**Files Modified (Jan 5 session):**
- `UnrealProject/SimpleHydraulics/Source/SimpleHydraulics/PlaybackManager.h` - Added visualization properties
- `UnrealProject/SimpleHydraulics/Source/SimpleHydraulics/PlaybackManager.cpp` - Material support, mesh loading, normalization fix, logging
- `doc/project_tracking_human.md` - Progress updates, topology task added
- `doc/MATERIAL_SETUP_GUIDE.md` - New file, manual material creation guide
- `scripts/python/create_material_simple.py` - Automated material creation
- `scripts/python/test_playback_mcp.py` - MCP connectivity test

**Key Technical Learnings:**
- Unreal Python API required for material graph creation (MCP plugin doesn't support it)
- MaterialEditingLibrary can create complete material graphs programmatically
- Pressure normalization critical for visual feedback - must match actual data range
- Dynamic materials work well for real-time parameter updates
- Engine BasicShapes meshes sufficient for POC (no need for custom models yet)

**Performance Notes:**
- 31,671 frames load in ~1 second
- Playback runs smoothly (no FPS data yet, visual observation only)
- Material updates per frame: 7 actors × SetScalarParameterValue = minimal overhead
- No noticeable lag or frame drops during playback

---

### Current Focus (Unreal POC) — Research + Task Stack

**Note (Dec 31, 2025):** Unreal planning docs were removed at user request. Any new Unreal guidance will be recreated only after explicit approval.

**Research to confirm:**
- Target engine/toolchain (UE 5.x + VS2022) for a C++ project with UDP support
- Asset approach: placeholder meshes vs. sourced models
- UDP port/packet/update rate for POC (e.g., port 5004, JSON, ~10–30 Hz)
- Performance goals for POC: visual fidelity vs. ≥60 FPS, acceptable latency/loss thresholds
- MATLAB streaming script (udp_stream_simlog.m) to be created after POC validation (Phase 2C deferred)

**Immediate tasks to execute (Phases 3 & 4):**
1) Task 1: Create Unreal C++ project and plugin skeleton; ensure plugin appears in Editor
2) Task 2: Build component blueprints/materials; place 10 components per P&ID layout
3) Task 3: Route 12 pipes with spline meshes and pressure-driven materials
4) Task 4: Implement UDP plugin core (listener, JSON parsing, Blueprint accessors)
5) Task 5: Bind Blueprint controller to UDP events and log received data
6) Task 6: Wire visualization updates (pressure colors, flow particles, cylinder rod motion)
7) Task 7: Integration test with MAT-file playback via UDP; check FPS/latency/loss
8) Task 8: Polish (HUD, counters, packaged build) and capture learnings

### Jan 1, 2026 - Unreal POC Integration Progress

**Actions Completed:**
- Integrated the flopperam/unreal-engine-mcp plugin into `Plugins/UnrealMCP` and removed a nested duplicate copy that caused duplicate module definitions.
- Updated `SimpleHydraulics.uproject` to enable the plugin and rebuilt `SimpleHydraulicsEditor` (Win64, Development); editor plugin module produced.
- Installed Python dependency `mcp` for the plugin Python server and started `unreal_mcp_server_advanced.py` (stdio transport). Server writes `unreal_mcp_advanced.log`.
- Created and executed `Plugins/UnrealMCP/Python/test_client_stdio.py`. The test client initialized a stdio session and listed available tools (including `get_actors_in_level`, `find_actors_by_name`, `set_actor_transform`, `apply_material_to_actor`).
- Confirmed offline playback JSON at `c:/0Work/Projects/LLM-MCP/SimscapeFluid/data/processed/unreal_playback.json` (~15.7 MB) produced by the MATLAB exporter.

**Notes / Observations:**
- The server exposes many control tools — use `find_actors_by_name` / `set_actor_transform` and material tools for initial tests.
- Avoid streaming the full JSON until mapping from JSON fields → UE actor properties is validated with a small-frame test.

**Next Immediate Tasks (short-term):**
1. Define JSON→UE mapping (pressure indices → material parameters; flow → Niagara spawn rate; rod.vel → cylinder transform).
2. Confirm target actor names in the Unreal level (or add an `APlaybackManager`) so the playback client can target them.
3. Implement a minimal playback client `Plugins/UnrealMCP/Python/playback_client.py` that reads one frame and issues a single safe `set_actor_transform` test call; include a unit test to mock MCP session.
4. Validate update in Editor (PIE) on a small subset, then extend to batched/frame streaming with timing control.

### December 31, 2025 - Phase Priority Reordering

**Decision Made:**
- ✅ **Reorder Phase Execution**
  - Previous: Phase 2C (UDP) → Phase 3 (Layout) → Phase 4 (Visualization)
  - New: Phase 3 & 4 (Unreal POC) → Phase 2C (UDP finalization)
  - Rationale: Build visualization first to verify POC works, then finalize UDP
  
**New Priority:**
1. **Phase 3 & 4 (IMMEDIATE)**: Unreal side development
   - Design 3D layout matching SimpleHydraulicSchematics.jpg
   - Build basic Unreal level with component placeholders
   - Create C++ UDP receiver plugin
   - Implement pressure/flow visualization
   - **Goal**: Proof of concept showing complete hydraulic network state visualization

2. **Phase 2C (DEFERRED)**: UDP streaming finalization
   - Will implement after Unreal visualization is working
   - Define final packet format based on Unreal requirements
   - Optimize data transmission

### December 31, 2025 - Phase 2C Planning

**Decisions Made:**
- ✅ **Phase 2B SKIPPED**: Real-time sensor addition
  - Rationale: simlog captures all 20+ port states automatically
  - Physical sensor placement would be redundant
  - simlog data is more comprehensive than discrete sensors
  - Cost-benefit: Skip sensor modeling, focus on visualization

**Previous Planning:**
- Phase 2C: UDP streaming of simlog data to Unreal
- Next Tasks:
  1. Create `udp_stream_simlog.m` - load MAT file and stream data via UDP
  2. JSON packet format for 20+ port states
  3. UDP transmission at 10-30 Hz (streaming historical data playback)
  4. Prepare for Unreal UDP receiver plugin
  5. Start Phase 3: Unreal receiver and visualization

### December 31, 2025 - Phase 2 Part A Complete

**Completed:**
- ✅ **PHASE 2A COMPLETE**: Simscape Data Logging
  - Created `run_and_log_simulation.m` script for comprehensive simlog data extraction
  - Implemented critical fix: Use `Simulink.SimulationInput` object for proper SimulationOutput return
  - Discovered and resolved simlog data access issues:
    * Used `.series.values('unit')` method for accessing pressure/flow data
    * Used try-catch instead of isfield() for simscape.logging.Node objects
    * Properly handled component-specific structures (e.g., Cylinder uses chamber_A.mdot_A instead of q_A)
  - Script now successfully extracts 20+ port states:
    * FlowSource: pressure, flow (B port)
    * ReliefValve: pressures (A, B ports), flow
    * VentValve: pressures, flow
    * DirectionalValve: all 4 ports (P, T, A, B) with pressure and flow
    * CheckValve: pressures, flow
    * FlowRestriction: pressures, flow
    * Filter: pressures, flow
    * Cylinder: cap-end/rod-end pressures, mass flows, rod velocity
    * Tanks: inlet pressure, flow
  - Data files: 2-3 MB per run (31,671 time points over 30 seconds)
  - Updated ERROR_LOG.md with comprehensive resolution details
- ✅ Documented critical API discoveries in ERROR_LOG.md for future reference

**Next Phase:**
- Phase 2B: Add 5 strategic real-time sensors to model for UDP streaming
- Phase 2C: Implement UDP data transmission

### December 30, 2025 - Extended Session

**Completed:**
- ✅ Created base folder structure: data/, doc/, scripts/, models/
- ✅ Initialized documentation framework with 10 key documents
- ✅ Created PROJECT_STRUCTURE.md with complete directory organization
- ✅ Conducted comprehensive research on Simscape Fluids + Unreal integration
- ✅ Identified two viable integration architectures
- ✅ Confirmed Unreal Engine has native UDP support (FUdpSocketBuilder)
- ✅ Created RESEARCH.md with 16 sections covering all integration aspects
- ✅ Task 1: All schematic components mapped to Simscape blocks
- ✅ Created generate_simple_hydraulic_model.m script
- ✅ Created explore_simscape_domain.m - Generalized, domain-aware library explorer
  - Consolidated 3 ad-hoc discovery scripts into 1 reusable tool
  - Supports any Simscape domain (Isothermal Liquid, Thermal Liquid, Pneumatics, etc.)
  - Supports Foundation Library (fl_lib) blocks (Sensors, Converters, Physical Signals)
  - Displays organized category listing with full block paths
  - No file output - results printed to command window
- ✅ Updated doc/improvements.md with "Library Block Discovery Automation Process" section
  - Documents find_system() methodology
  - Explains domain-driven library search
  - Records critical discoveries (ampersand in paths, domain suffixes, subcategory nesting)
  - Provides usage examples and future improvements
- ✅ **PHASE 1 COMPLETE**: Working Simscape hydraulic model
  - 10 blocks: FlowSource, ReliefValve, VentValve, DirectionalValve (4-Way), CheckValve, FlowRestriction, Filter, Cylinder, Tank, FluidProperties
  - 12 programmatic connections via simscape.addConnection()
  - 3 parallel pump paths (Relief, Vent, Directional Control)
  - Rod-end control: 2 parallel paths (check valve for return actuation + flow restriction for metering)
  - Manual signal connections added by user
  - Model runs successfully
- ✅ Updated ERROR_LOG.md with general LLM knowledge gap errors (API misuse, port discovery)

**In Progress:**
- Phase 2: Adding sensors and UDP data transmission setup

**Blockers/Issues:**
- Foundation Library blocks in explore script needed updates (completed fl_lib support)
- None currently blocking progress

## Implementation Plan

### Phase 1: P&ID Schematics → Running Simscape Model
**Objective:** Generate working Simscape model from hydraulic schematic image

**Reference Schematic:** SimpleHydraulicSchematics.jpg

**Identified Components:**
- Electric motor (M)
- Fixed displacement pump (max 3 GPM)
- Pressure relief valve
- Vent valve
- Pressure gauge/sensor
- Flow control valve
- Flow meter
- Filter
- Hydraulic cylinder (velocity input v(in/sec), force output F(lb))

**Tasks:**

**Task 1: Research and confirm Simscape Fluids blocks availability** [✅ COMPLETE]
- ✅ Search MATLAB R2025b documentation for each component
- ✅ Map P&ID symbols to Simscape library blocks
- ✅ Document block names and library paths
- ✅ Created generate_simple_hydraulic_model.m script
- ✅ Script successfully generates .slx file with 10 hydraulic blocks:
  - FlowSource (Flow Rate Source IL)
  - ReliefValve (Pressure Relief Valve IL)
  - VentValve (2-Way Directional Valve IL)
  - DirectionalValve (4-Way 3-Position Directional Valve IL)
  - CheckValve (Check Valve IL - reversed for return actuation)
  - FlowRestriction (Local Restriction IL - rod-end metering)
  - Filter (Local Resistance IL)
  - Cylinder (Double-Acting Actuator IL)
  - Tank (Tank IL)
  - FluidProperties (Isothermal Liquid Predefined Properties IL)
- ✅ All 12 connections made programmatically via simscape.addConnection()
- ✅ Manual signal connections added
- ✅ Model runs successfully
- 📂 Output: models/simscape/SimpleHydraulicSystem.slx (working model)
- 📖 See doc/improvements.md for library discovery methodology
   
**Task 2: MATLAB MCP server iterative clarification process** [DEFERRED TO PHASE 2]
- Will configure component parameters in next phase
- Required inputs: Pump displacement for 3 GPM, pressure ratings, cylinder specs
   
**Task 3: Generate MATLAB script for model creation** [✅ COMPLETE]
- ✅ MCP generated programmatic model building script: generate_simple_hydraulic_model.m
- ✅ Script creates .slx file with 10 hydraulic components + 12 connections
- ✅ Configures solver: ode15s, 10-second stop time, variable-step
- ✅ Successfully executed - output: models/simscape/SimpleHydraulicSystem.slx
- ✅ Model topology matches P&ID schematic
   
**Task 4: Validate and run Simscape model** [✅ COMPLETE]
- ✅ Model runs successfully with manual signal connections
- ✅ All 3 parallel pump paths functioning
- ✅ Rod-end control with check valve + flow restriction operational
- ✅ Ready for parameter tuning and sensor addition

**Deliverables:**
- Component-to-block mapping document
- MATLAB script for model generation
- Working .slx Simscape model file
- Simulation results validation report

**Success Criteria:**
- All schematic components mapped to existing Simscape blocks
- Generated model loads in Simulink without errors
- Simulation runs to completion
- Results match expected hydraulic behavior

### Phase 2: Multi-Point Data Collection & UDP Streaming
**Objective:** Extract comprehensive port-level state data and stream to Unreal for flow visualization

**Critical Requirement:** Flow visualization requires state data at MULTIPLE component ports, not just discrete sensor locations.

**Data Extraction Strategy - Hybrid Approach:**

**Part A: Simscape Data Logging (simlog) - Comprehensive Network State**
- Enable automatic logging of ALL port states (pressure, flow, temperature)
- Access via: `simlog.BlockName.PortName.p`, `.q`, `.T`
- Zero manual sensor placement needed
- Provides complete network state for post-processing
- Extract data for: FlowSource, ReliefValve, VentValve, DirectionalValve (all ports), CheckValve, FlowRestriction, Filter, Cylinder, Tank

**Part B: Strategic Real-Time Sensors - Key Visualization Points**
- Add Pressure Sensor (IL) at pump outlet (main line pressure)
- Add Flow Rate Sensor (IL) at pump outlet (system flow)
- Add Pressure Sensors at cylinder ports A & B (actuation monitoring)
- Add Position Sensor on cylinder rod (motion tracking)
- Convert all to Simulink signals via PS-Simulink Converter blocks

**Tasks:**

1. **Configure Simscape Data Logging**
   - Enable simlog in model settings
   - Test data extraction post-simulation
   - Document port naming structure for all 10 blocks
   - Create extraction script for simlog → structured data
   
2. **Add Real-Time Sensors to Model**
   - Place 4-5 strategic sensors at key points
   - Add PS-Simulink converters
   - Wire to UDP send blocks
   - Validate sensor outputs match expected values
   
3. **Implement UDP Data Streaming**
   - Design data packet structure (JSON or binary)
     * Real-time: Sensor values (4-5 points)
     * Batch: simlog port states (20+ points)
   - Add UDP Send blocks to model
   - Configure transmission rate (30-60 Hz for real-time, 10 Hz for batch)
   - Test data transmission to localhost
   
4. **Data Validation & Verification**
   - Compare simlog vs sensor values (cross-validation)
   - Measure UDP transmission latency
   - Verify no packet loss over extended runs
   - Document data format and port mapping

**Deliverables:**
- Modified .slx model with simlog enabled + strategic sensors
- simlog extraction script (MATLAB)
- UDP data packet format specification
- Port-to-visualization mapping document
- UDP transmission test results

**Success Criteria:**
- simlog captures all 20+ port states successfully
- Real-time sensors transmit at 30+ Hz
- Latency < 20ms for real-time data
- No data loss over 5+ minute runs
- Complete network state available for visualization

**Detailed Implementation Guide:**

**A. Simlog Data Logging Setup**

Enable automatic logging in model:
```matlab
% Configure model for comprehensive data logging
modelName = 'SimpleHydraulicSystem';
load_system('../../models/simscape/SimpleHydraulicSystem.slx');

% Enable data logging
set_param(modelName, 'DataLoggingOverride', 'on');
set_param(modelName, 'DataLoggingDecimation', '1');  % Log every step
set_param(modelName, 'DataLoggingMaxPoints', '10000');  % Max points

% Run and access data
out = sim(modelName);
simlog = out.simlog;
```

**Data Points Available (20+ ports):**
1. FlowSource: A (inlet), B (outlet)
2. ReliefValve: A (inlet), B (tank return)
3. VentValve: A (inlet), B (outlet)
4. DirectionalValve: P (pump), T (tank), A (cap-end), B (rod-end)
5. CheckValve: A (inlet), B (outlet)
6. FlowRestriction: A (inlet), B (outlet)
7. Filter: A (inlet), B (outlet)
8. Cylinder: A (cap-end), B (rod-end)
9. Tank: A (inlet)

Per port data: `.p` (pressure), `.q` (flow rate), `.T` (temperature), `.series.time`, `.series.values`

**B. Strategic Sensor Placement (5 sensors)**

1. **Pump Outlet Pressure** - FlowSource.B → DirectionalValve.P junction
2. **Pump Outlet Flow** - Same location
3. **Cylinder Cap-End Pressure** - DirectionalValve.A → Cylinder.A
4. **Cylinder Rod-End Pressure** - Cylinder.B at parallel junction
5. **Cylinder Position** - Cylinder rod output

All sensors require PS-Simulink Converter blocks for signal conversion.

**C. simlog Extraction Script**

Create `extract_simlog_data.m`:
```matlab
function data_struct = extract_simlog_data(simlog, time_index)
    data_struct = struct();
    
    % Pump
    data_struct.pump.outlet.pressure = simlog.FlowSource.B.p.series.values(time_index);
    data_struct.pump.outlet.flow = simlog.FlowSource.B.q.series.values(time_index);
    
    % Directional Valve (4 ports)
    data_struct.directional.pump.pressure = simlog.DirectionalValve.P.p.series.values(time_index);
    data_struct.directional.tank.pressure = simlog.DirectionalValve.T.p.series.values(time_index);
    data_struct.directional.capEnd.pressure = simlog.DirectionalValve.A.p.series.values(time_index);
    data_struct.directional.rodEnd.pressure = simlog.DirectionalValve.B.p.series.values(time_index);
    
    % Cylinder
    data_struct.cylinder.capEnd.pressure = simlog.Cylinder.A.p.series.values(time_index);
    data_struct.cylinder.rodEnd.pressure = simlog.Cylinder.B.p.series.values(time_index);
    
    % Relief, Vent, Check, Restriction, Filter, Tank...
    % (similar pattern for all 20+ ports)
    
    data_struct.time = simlog.FlowSource.B.p.series.time(time_index);
end
```

**D. UDP Streaming Modes**

1. **Real-Time Mode** (during simulation)
   - Stream sensor data only (5 points)
   - 30-60 Hz update rate
   - Uses UDP Send blocks in Simulink

2. **Batch Mode** (post-simulation)
   - Stream complete simlog data (20+ points)
   - 10-30 Hz playback rate
   - Uses MATLAB UDP socket programming

**Data Packet Format (JSON):**
```json
{
  "timestamp": 1.234,
  "mode": "realtime" | "batch",
  "data": {
    "pump": {"outlet": {"pressure": 21000000, "flow": 0.00005}},
    "cylinder": {"capEnd": {"pressure": 18000000}, "rodEnd": {"pressure": 2000000}},
    "directional": {"pump": {"pressure": 20500000}, "capEnd": {"pressure": 18000000}}
  }
}
```

**E. Validation Checklist**
- [ ] simlog captures all 20+ port states
- [ ] simlog data extraction script works
- [ ] 5 strategic sensors added to model
- [ ] PS-Simulink converters configured
- [ ] UDP Send blocks added and tested
- [ ] Real-time streaming achieves 30+ Hz
- [ ] Batch streaming tested with simlog data
- [ ] Data format documented
- [ ] Port-to-visualization mapping created
- [ ] Cross-validation: simlog vs sensor values match
- [ ] Latency measured < 20ms
- [ ] No packet loss over 5+ minute test runs

**References:**
- [Simscape Data Logging](https://www.mathworks.com/help/simscape/ug/about-simulation-data-logging.html)
- [Accessing Logged Data](https://www.mathworks.com/help/simscape/ug/accessing-logged-simulation-data.html)
- [Foundation Library Sensors](https://www.mathworks.com/help/physmod/simscape/ref/sensors.html)

### Phase 3: Unreal Layout Modeling
**Objective:** Create 3D representation of hydraulic system in Unreal

**Tasks:**
1. Design 3D layout matching P&ID topology
   - Map 2D schematic to 3D space
   - Decide component placement and routing
   
2. Create or source 3D assets
   - Pump, motor, valves, cylinder models
   - Pipes and connections
   - Instrumentation (gauges, sensors)
   
3. Build Unreal level
   - Place components in scene
   - Connect with pipe meshes
   - Add lighting and camera views
   
4. Prepare for data integration
   - Tag components for data binding
   - Set up particle systems for fluid flow
   - Create material instances for pressure visualization

**Deliverables:**
- 3D layout design document
- Unreal level with hydraulic system layout
- Component tagging scheme

**Success Criteria:**
- Layout recognizable from original P&ID
- All major components represented
- Ready for data connection

### Phase 4: Connect Simscape Results to Unreal
**Objective:** Real-time visualization of Simscape simulation in Unreal

**Tasks:**
1. Create Unreal UDP receiver plugin
   - C++ plugin using FUdpSocketBuilder
   - Deserialize incoming data
   - Map data to component IDs
   
2. Implement visualization logic
   - Pressure → component color/material
   - Flow rate → particle system intensity
   - Cylinder position → actor transform
   - Motor speed → rotation animation
   
3. Synchronization and performance
   - Match Unreal update rate to MATLAB send rate
   - Handle network jitter
   - Optimize for 60+ FPS
   
4. User interface and controls
   - HUD showing key parameters
   - Graphs for time-series data
   - Optional: Send control commands back to MATLAB

**Deliverables:**
- Unreal C++ UDP plugin
- Complete visualization system
- Performance benchmark results
- User guide

**Success Criteria:**
- Real-time visualization matches MATLAB simulation
- Stable performance (60+ FPS, <50ms latency)
- System runs reliably for extended periods
- Data accuracy within 2% of MATLAB values

### Status Tracking
Track task completion and actual duration in project_tracking_llm.md as work progresses.
**Objective:** Validate feasibility of UDP-based loose coupling approach

**Tasks:**
1. Create simple Simscape hydraulic cylinder model (MATLAB)
   - Single hydraulic actuator with pressure input
   - Output: Pressure, flow rate, rod position
   - UDP sender in MATLAB (via Java or MEX)
   
2. Create Unreal C++ plugin for UDP reception
   - Implement FUdpSocketBuilder listener
   - Deserialize incoming fluid state data
   - Store in custom data structures
   - Trigger events for Blueprint consumption
   
4. Build Unreal visualization actor
   - Blueprint actor that subscribes to fluid state events
   - Map pressure → color gradient (low=blue, high=red)
   - Map flow rate → particle system intensity
   - Map rod position → actor Z-position
   
5. Bidirectional control test
   - Unreal sends pressure command via UDP
   - MATLAB/Simscape receives and applies
   - Verify state feedback loop works

**Deliverables:**
- Basic Simscape model (.slx file) with UDP sender
- Unreal plugin (C++)
- Test visualization level
- Performance measurements (latency, FPS impact)

**Success Criteria:**
- System runs for 5+ minutes without errors
- Latency < 50ms
- Unreal maintains 60+ FPS
- Data accuracy within 2% of MATLAB

### Phase 2: Advanced Features
**Objective:** Enhance simulation complexity and visualization fidelity

**Tasks:**
1. Multi-component Simscape model
   - Pump, accumulator, valves, cylinders
   - Thermal effects
   - More complex fluid network
   
2. Improved data synchronization
   - Implement timestep sync between systems
   - Handle network jitter and packet loss
   - Logging and verification
   
3. Enhanced visualization
   - Real-time data plotting (pressure, flow graphs)
   - 3D representations of hydraulic components
   - HUD status displays
   - Heat visualization
   
4. Control interface
   - Unreal UI for parameter adjustment
   - Real-time control of pump speed, valve position
   - Scenario/test case switching

**Estimated Effort:** 2-3 weeks


**Tasks:**
1. Performance optimization
   - Profile bottlenecks
   - Optimize UDP message format
   - Implement frame skipping/interpolation if needed
   
2. Stability testing
   - Long-duration stability tests (hours)
   - Error handling and recovery
   - Network resilience
   
3. Documentation
   - User guides and setup instructions
   - Architecture documentation
   - API reference for extending with new systems
   
4. Deployment setup
   - Configuration files
   - Launch scripts
   - Troubleshooting guide

**Estimated Effort:** 2-3 weeks

### Status Tracking
Track task completion and actual duration in project_tracking_llm.md as work progresses.Detailed Context

[Project progress details, decisions, context for LLM understanding]
