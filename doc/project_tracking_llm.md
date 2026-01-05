# Project Tracking (LLM-Readable)

This document is designed for LLM context. It can be detailed and verbose to provide complete project state information.

## Session History

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
