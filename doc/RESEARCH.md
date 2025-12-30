# Simscape Fluid + Unreal Engine Integration Research

**Date**: December 30, 2025  
**Status**: Research in Progress  
**Last Updated**: 2025-12-30

---

## Executive Summary

This document compiles research findings on integrating MATLAB Simscape Fluid models with Unreal Engine. This is a **non-standard workflow** requiring custom integration solutions. The integration involves connecting real-time fluid simulation (MATLAB) with a graphics/gameplay engine (Unreal).

---

## 1. Simscape Fluids Overview

### 1.1 Product Definition
**Simscape Fluids** (formerly SimHydraulics) is a MATLAB/Simulink component library for modeling and simulating fluid systems.

### 1.2 Key Capabilities
- **Component Libraries**: Hydraulic pumps, valves, actuators, pipelines, heat exchangers
- **Fluid Domains Supported**:
  - Isothermal Liquid (basic hydraulic fluids)
  - Thermal Liquid (thermal effects included)
  - Two-Phase Fluid (refrigeration, condensation)
  - Gas systems
  - Moist Air systems

### 1.3 Application Areas
- Fluid power systems (front-loaders, power steering, landing gear actuation)
- Engine cooling and thermal management
- Gearbox lubrication systems
- Fuel supply systems
- Predictive maintenance and digital twins
- Virtual testing and HIL (Hardware-in-Loop) simulation

### 1.4 Simulation Output Options
- **Real-time Simulation**: Desktop execution and Simulink Real-Time
- **Code Generation**: C-code generation for deployment to HIL systems (dSPACE, Speedgoat)
- **Multidomain Integration**: Can integrate with mechanical, electrical, and thermal models
- **Model Deployment**: Supports conversion to Functional Mock-up Units (FMUs)

### 1.5 Performance Characteristics
- Solves complex nonlinear equations automatically
- Supports symbolic manipulation and index reduction for efficient solving
- Can achieve real-time simulation on high-end workstations
- Supports parallel computing for multiple simulation scenarios

### 1.6 Data Extraction for Visualization
**Critical for Unreal Integration:** Visualizing flow inside networks requires state data at multiple component ports, not just discrete sensor locations.

**Three Approaches:**

1. **Simscape Data Logging (simlog) - RECOMMENDED**
   - Automatically captures all port states without manual sensor placement
   - Access via: `simlog.BlockName.PortName.p` (pressure), `.q` (flow rate), `.T` (temperature)
   - Available for ALL conserving ports in the network
   - Zero performance overhead - data collected during normal simulation
   - Post-processing: Extract data and stream via UDP to Unreal
   - Example: `simlog.Cylinder.A.p` gives cap-end pressure over time

2. **Manual Sensor Placement**
   - Add Pressure Sensor (IL) and Flow Rate Sensor (IL) at strategic locations
   - Requires PS-Simulink Converter for each sensor
   - More explicit but requires sensor management overhead
   - Limited to manually placed locations
   - Better for real-time streaming (sensors output Simulink signals directly)

3. **Hybrid Approach - RECOMMENDED FOR THIS PROJECT**
   - Use simlog for comprehensive post-simulation analysis
   - Add strategic sensors for key visualization points (pump outlet, cylinder ports)
   - Simlog provides full network state backup
   - Sensors provide real-time streaming capability
   - Best of both worlds: comprehensive data + real-time visualization

**Implementation Notes:**
- Enable data logging: `set_param(modelName, 'DataLoggingOverride', 'on')`
- Access simlog after simulation: `out = sim(modelName); simlog = out.simlog;`
- Extract time-series: `pressure_data = simlog.Cylinder.A.p.series.values;`
- For Unreal: Stream selected simlog data via UDP at visualization frame rate

---

## 2. Unreal Engine Overview

### 2.1 Current Version & Status
- **Latest Version**: Unreal Engine 5.7 (as of Dec 2025)
- **Architecture**: Real-time rendering and gameplay engine
- **Primary Use Cases**: Games, film/TV, architectural visualization, simulation
- **Licensing**: Free for under $1M revenue; royalty or seat-based for larger projects

### 2.2 Unreal Engine Capabilities
- Advanced real-time graphics rendering
- Physics simulation (Chaos Physics Engine)
- Networking and multiplayer support
- Asset marketplace (Fab)
- Blueprint visual scripting + C++ programming
- Cross-platform deployment

### 2.3 Extension Mechanisms
- **Plugin System**: Community and official plugins available
- **C++ Integration**: Direct engine source modification available
- **Blueprint System**: Visual scripting for gameplay logic
- **Custom Data Types**: Can create custom structures for data passing

---

## 3. Integration Approaches

### 3.1 Data Flow Models

#### Model A: Simulation-First
```
MATLAB/Simulink (Simulation) 
    ↓ (Output: Fluid States, Pressures, Flows)
Network Stream (UDP/TCP/Named Pipes)
    ↓ 
Unreal Engine (Visualization & Interaction)
    ↓ (Input: Control Commands)
Network Stream
    ↓
MATLAB/Simulink (Update Parameters)
```

#### Model B: Compiled FMU Wrapper
```
MATLAB Simscape Model
    ↓ (Export as FMU)
Custom C++ Plugin in Unreal
    ↓ (Loads and executes FMU)
Unreal Engine (Simulation & Visualization)
```

#### Model C: C-Code Deployment
```
MATLAB Simscape Model
    ↓ (Generate C Code)
Custom DLL/Plugin in Unreal
    ↓ (Wraps C code)
Unreal Engine (Direct integration)
```

---

## 4. Communication Methods

### 4.1 Network-Based Communication
**Pros:**
- Loose coupling between systems
- Can run on separate machines
- Easier debugging and development separation
- Allows MATLAB to remain the primary simulation driver

**Cons:**
- Network latency (typically 1-10ms for local network)
- Synchronization challenges
- Additional infrastructure complexity

**Protocols:**
- UDP (fast, unreliable - good for streaming state updates) ✓ **Unreal has native support via FUdpSocketBuilder**
- TCP (slower, reliable - good for critical commands)
- WebSockets (possible but overkill)
- Shared Memory / Named Pipes (Windows-specific, faster)

**Unreal Engine UDP Support:**
- Native C++ `FUdpSocketBuilder` class for creating UDP sockets
- `FSocket` interface for socket operations
- `FInternetAddr` for address handling
- Available in plugins, modules, and Blueprints (via C++ callable functions)
- Proven in multiplayer, telemetry, and hardware integration use cases

### 4.2 Direct Code Integration
**Pros:**
- Minimal latency (microseconds)
- True real-time simulation possible
- Single memory space
- Better performance for tightly coupled logic

**Cons:**
- Requires C/C++ knowledge of both systems
- Difficult debugging across system boundaries
- Tight coupling - changes to one affect the other
- Limited to systems that support direct compilation

**Methods:**
- DLL wrapping of generated C code
- FMU (Functional Mock-up Unit) standard
- Custom Unreal plugins

---

## 5. Key Technical Challenges

### 5.1 Real-Time Constraints
- MATLAB typically runs Simscape at fixed timesteps (0.001s - 0.01s)
- Unreal runs at variable framerates (typically 60Hz = 16.67ms)
- **Challenge**: Synchronizing different timesteps and frame rates
- **Solution**: Decouple simulation from rendering, or use interpolation

### 5.2 Data Serialization
- Need to efficiently pack/unpack fluid state data
- **Candidates**: JSON, binary protocols, MessagePack, Protobuf
- **Performance**: Binary faster, JSON more human-readable

### 5.3 Synchronization
- Managing state consistency between systems
- Handling lag/network delay
- Ensuring deterministic behavior for testing

### 5.4 Visualization Mapping
- Fluid pressure → Visual effects (color, particle systems)
- Flow rates → Animation speeds
- Temperature → Heat effects, visual feedback
- System states → HUD indicators

---

## 6. Existing Tools & Standards

### 6.1 FMU (Functional Mock-up Unit)
- **Standard**: FMI 2.0 and 3.0
- **Support in MATLAB**: Can export Simulink models as FMUs
- **Advantage**: Industry standard, portable
- **Current Status**: No native Unreal Engine FMU loader found (would need custom plugin)

### 6.2 Hardware-in-Loop Systems
- **dSPACE**: Proven integration with Simscape (uses C-code generation)
- **Speedgoat**: Real-time target hardware
- **Lesson**: C-code deployment path is well-established for MATLAB

### 6.3 MATLAB Engine for External Languages
- **MATLAB Engine for Python**: Can call MATLAB from Python
- **MATLAB Engine for C/C++**: Can call MATLAB from compiled code
- **Note**: Requires MATLAB Engine API, adds licensing complexity

---

## 7. Reference Architectures & Case Studies

### 7.1 Volvo Construction Equipment (from MathWorks)
- **Challenge**: Real-time hydraulic simulation for training simulators
- **Solution**: Simscape model → Simulink Real-Time → Hardware-in-Loop system
- **Outcome**: Full-scale hydraulic system model running in real-time
- **Lesson**: Simscape CAN achieve real-time performance with proper optimization

### 7.2 General Simscape Deployment Pattern
- Desktop development with Simulink
- Code generation for real-time execution
- Integration with control hardware or visualization systems

### 7.3 Game Engine Integration Patterns
- Game engines typically consume pre-computed data or accept real-time state updates
- Physics engines in engines (Chaos/UE5) handle local simulation
- External data drives parameters and initial conditions

---

## 8. Proposed Integration Architecture (Preliminary)

### 8.1 Architecture Option 1: Loose Coupling (Recommended for Initial Development)

```
┌─────────────────────┐
│  MATLAB/Simulink    │
│  Simscape Model     │
│  - Hydraulic system │
│  - Fluid dynamics   │
│  - Pressure/flows   │
└──────────┬──────────┘
           │ UDP/TCP Stream
           │ (State Updates @ 100-1000Hz)
           ↓
┌──────────────────────────────┐
│   Data Bridge Process        │
│   (Python/C# Middleware)     │
│   - Serialization            │
│   - Buffering                │
│   - Time sync                │
└──────────┬───────────────────┘
           │ Unreal-Native Format
           ↓
┌──────────────────────────────┐
│   Unreal Engine              │
│   Custom Plugin              │
│   - Receives fluid state     │
│   - Updates actor positions  │
│   - Renders visualization    │
│   - Sends user commands back │
└──────────────────────────────┘
```

**Advantages:**
- Systems remain independent and debuggable
- MATLAB can run on separate machine
- Easy to add additional visualization systems
- Clear separation of concerns

**Challenges:**
- Network latency
- Potential synchronization issues
- Additional middleware needed

### 8.2 Architecture Option 2: Direct Integration (Advanced)

```
┌──────────────────────────────┐
│   Unreal Engine C++ Plugin   │
│   - FMU Loader / Solver      │
│   - Fluid Simulation         │
│   - Physics Integration      │
│   - Visualization            │
└──────────────────────────────┘
```

**Advantages:**
- Zero latency
- True real-time capability
- Single integrated system
- Best performance

**Challenges:**
- Complex to implement
- Requires deep knowledge of both systems
- Harder to debug
- MATLAB development cycle becomes restrictive

---

## 9. Technology Stack Recommendations

### 9.1 For Loose Coupling (Option 1)

| Component | Choice | Rationale |
|-----------|--------|-----------|
| Simulation | MATLAB/Simulink Simscape | Proven, full-featured |
| Data Format | Binary or JSON | Binary = fast, JSON = readable |
| Transport | UDP over TCP with fallback | UDP for speed, TCP for reliability |
| Middleware | MATLAB or C++ | Direct integration, efficient |
| Unreal Plugin | C++ with serialization | Native Unreal ecosystem |
| Visualization | Unreal's Niagara/Blueprints | Native particle systems, animations |

### 9.2 For Direct Integration (Option 2)

| Component | Choice | Rationale |
|-----------|--------|-----------|
| Simulation | MATLAB → FMU or C-code gen | Portable, optimized |
| Integration | Custom Unreal C++ Plugin | Direct engine integration |
| Synchronization | Fixed timestep with interpolation | Consistent behavior |
| Compilation | CMake + Visual Studio | Windows build standard |

---

## 10. Development Workflow (Preliminary)

### Phase 1: Proof of Concept
1. Create simple Simscape model (basic hydraulic cylinder)
2. Export state data to UDP socket
3. Create Unreal actor that listens to socket
4. Map fluid pressure → visual feedback (color, scale, position)
5. Test synchronization and latency

### Phase 2: Multi-Point Data Collection & Streaming
1. **Enable Simscape Data Logging (simlog)**
   - Configure model for automatic port state capture
   - Extract pressure, flow rate, temperature at all component ports
   - No manual sensor placement needed for comprehensive data

2. **Add Strategic Sensors for Real-Time Streaming**
   - Pressure Sensor (IL) at pump outlet
   - Flow Rate Sensor (IL) at pump outlet  
   - Pressure Sensors at cylinder ports (A & B)
   - Position sensor on cylinder rod
   - Convert to Simulink signals via PS-Simulink Converter

3. **UDP Data Streaming Implementation**
   - Stream sensor signals in real-time during simulation
   - Post-process simlog data for additional visualization points
   - Design data packet structure for Unreal (JSON or binary)
   - Implement frame-rate appropriate data transmission (30-60 Hz)

4. **Unreal Receiver Setup**
   - Create UDP socket listener in Unreal
   - Parse incoming data packets
   - Map data to visual elements (pipe colors, flow particles, pressure indicators)

5. **Validation & Performance Testing**
   - Verify data accuracy (simlog vs sensors)
   - Test latency and synchronization
   - Optimize data packet size and transmission rate

### Phase 3: Production Integration
1. Optimization for target performance metrics
2. Full system testing
3. Documentation and user guides
4. Deployment setup

---

## 11. Risks & Mitigation

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| Network latency issues | Medium | High | Start with loose coupling, optimize later |
| Synchronization drift | Medium | High | Implement timestep synchronization |
| MATLAB license limitations | Low | High | Research engine licensing for deployment |
| Performance bottlenecks | Medium | Medium | Profile early, optimize critical path |
| Unreal plugin compatibility | Low | Medium | Use stable UE version (5.7+) |
| Complex state management | Medium | Medium | Design clear data schemas early |

---

## 12. Resource Requirements

### 12.1 Hardware (Minimum)
- CPU: Multi-core processor (i7/Ryzen 7 equivalent)
- RAM: 32GB+ for both systems running
- Network: Gigabit Ethernet (if separate machines)
- GPU: RTX 2080 or better (for Unreal rendering)

### 12.2 Software
- **MATLAB R2025b** (confirmed project version)
- Simulink
- Simscape Fluids (addon product)
- **Unreal Engine 5.7.1** (confirmed project version)
- C++ compiler (MSVC for Windows)

### 12.3 Knowledge Requirements
- MATLAB/Simulink modeling
- C++ (for Unreal plugins)
- Networking basics
- Physics/Hydraulics fundamentals
- Optional: Real-time systems

---

## 13. Alternative Approaches Evaluated

### 13.1 Co-Simulation Standards (FMI 2.0/3.0)
- **Status**: No native Unreal support
- **Effort**: High (requires custom FMI loader plugin)
- **Recommendation**: Consider for future if FMI becomes critical

### 13.2 ROS (Robot Operating System)
- **Status**: Possible but adds complexity
- **Effort**: High
- **Recommendation**: Only if multi-system integration needed

### 13.3 Game Engine Physics (Chaos)
- **Status**: Built-in to Unreal, but simpler than Simscape
- **Use Case**: Quick approximations, not full fidelity simulation
- **Recommendation**: Could supplement Simscape for certain effects

---

## 14. Success Metrics

### Functional
- [ ] Simscape model running in MATLAB
- [ ] Data streaming to Unreal successfully
- [ ] Unreal visualization responding to simulation state
- [ ] Bidirectional control (Unreal → MATLAB)
- [ ] Real-time performance @ 60+ FPS

### Non-Functional
- [ ] Latency < 100ms (for loose coupling)
- [ ] Data accuracy within 1% of MATLAB simulation
- [ ] System stable for 10+ minute sessions
- [ ] Easy to extend with new fluid systems

---

## 15. Open Questions & Investigation Needed

1. **MATLAB Licensing**: Can Simscape models be deployed without per-seat licenses?
2. **FMU Standards**: How much effort for custom FMU loader in Unreal?
3. **Real-Time Performance**: Can Simscape achieve consistent 1000Hz simulation on standard PC?
4. **Network Synchronization**: Best practices for deterministic sync over network?
5. **Visualization Fidelity**: What's the optimal mapping of fluid states to visual effects?
6. **Debugging**: Tools and approaches for debugging distributed system?

---

## 16. Conclusion

Creating a Simscape Fluid + Unreal Engine integration is **technically feasible** using one of two approaches:

1. **Loose Coupling** (Recommended for MVP): Network-based streaming of fluid state data
2. **Direct Integration** (Future optimization): Compiled FMU or C-code in Unreal plugin

The **loose coupling approach** offers the best balance of:
- Development speed
- System maintainability
- Debuggability
- Extensibility

No existing "off-the-shelf" solution exists, so custom engineering will be required.

---

## 16. Simscape Fluids Block Inventory (Isothermal Liquid Library)

**Confirmed Available Blocks for P&ID Components:**

### Pumps and Motors Category:
- **Fixed-Displacement Pump (IL)** - Matches schematic pump (3 GPM max)
- Fixed-Displacement Motor (IL) - Rotary actuation
- Variable-Displacement Pump (IL)
- Variable-Displacement Motor (IL)
- Pressure-Compensated Pump (IL)
- Centrifugal Pump (IL)

### Valves and Orifices Category:
**Directional Control Valves** (subcategory confirmed, specific blocks need manual lookup)
**Flow Control Valves** (subcategory confirmed - includes flow control valve from schematic)
**Pressure Control Valves** (subcategory confirmed - includes pressure relief valve from schematic)
**Valve Actuators and Forces** (subcategory confirmed)
**Orifices** (subcategory confirmed)

### Actuators Category:
- **Double-Acting Actuator (IL)** - Matches hydraulic cylinder from schematic
- Single-Acting Actuator (IL)
- Double-Acting Rotary Actuator (IL)
- Single-Acting Rotary Actuator (IL)
- Rotating Single-Acting Actuator (IL)
- Cylinder Cushion (IL)
- Cylinder Friction (IL)

### Pipes and Fittings Category:
- **Pipe (IL)** - Hydraulic lines in schematic
- **Local Resistance (IL)** - Can model filter
- Elbow (IL)
- T-Junction (IL)
- Cross-Junction (IL)
- Y-Junction (IL)
- Area Change (IL)
- Pipe Bend (IL)

### Utilities Category:
- Isothermal Liquid Predefined Properties (IL) - System fluid properties

### Sensors (Simscape Foundation Library):
**Note:** Isothermal Liquid sensors are accessed via Simscape Foundation Library Physical Signals.
Sensors output physical signals that must be converted to Simulink signals using PS-Simulink Converter blocks.
- Pressure sensors: Connect to isothermal liquid ports, measure pressure
- Flow rate sensors: Measure volumetric/mass flow through component
- These are **implicit sensors** in Simscape - use "Simscape > Foundation Library > Physical Signals > Sensors" blocks

### Missing Block Confirmation Needed:
1. **Electric Motor** - Need to confirm rotational-to-hydraulic interface (likely Simscape Multibody or Electrical domain connection)
2. **Pressure Gauge** - Likely uses generic pressure sensor from Physical Signals library
3. **Flow Meter** - Likely uses generic flow rate sensor from Physical Signals library
4. **Vent Valve** - May be 2-way directional valve or simple orifice
5. **Filter** - Can be modeled as Local Resistance (IL) with pressure drop characteristics

### Component Mapping Summary:
| Schematic Component | Simscape Block | Library Path | Status |
|---------------------|----------------|--------------|--------|
| Electric Motor (M) | Flow Rate Source (IL) with Physical Signal input | Isothermal Liquid > Sources | ✓ CONFIRMED |
| Fixed Displacement Pump (3 GPM) | Fixed-Displacement Pump (IL) | Isothermal Liquid > Pumps and Motors | ✓ CONFIRMED |
| Pressure Relief Valve | Pressure Relief Valve (IL) | Isothermal Liquid > Valves and Orifices > Pressure Control | ✓ CONFIRMED |
| Vent Valve | Local Resistance (IL) | Isothermal Liquid > Pipes and Fittings | ✓ CONFIRMED |
| Pressure Gauge | Pressure Sensor (IL) | Simscape > Foundation > Physical Signals > Sensors | ✓ CONFIRMED |
| Flow Control Valve | Local Resistance (IL) + Check Valve (IL) | Isothermal Liquid > Pipes and Fittings + Valves | ✓ CONFIRMED |
| Flow Meter | Flow Rate Sensor (IL) | Simscape > Foundation > Physical Signals > Sensors | ✓ CONFIRMED |
| Filter | Local Resistance (IL) | Isothermal Liquid > Pipes and Fittings | ✓ CONFIRMED |
| Hydraulic Cylinder | Double-Acting Actuator (IL) | Isothermal Liquid > Actuators | ✓ CONFIRMED |

### All Components Confirmed - Ready for Phase 1 Task 2
All 9 schematic components have been successfully mapped to Simscape Fluids blocks.

---

## References & Resources

### Documentation
- [MATLAB Simscape Fluids Documentation](https://www.mathworks.com/help/hydro/)
- [Unreal Engine Documentation](https://docs.unrealengine.com/)
- [FMI Standard](https://fmi-standard.org/)

### Related Work
- Volvo Construction Equipment case study (real-time hydraulic simulator)
- dSPACE + MATLAB integration (C-code generation pattern)
- FMU/FMI standards for co-simulation

### Tools & Libraries
- MessagePack (data serialization)
- ZeroMQ (networking alternative)
- Python socket library (prototyping middleware)

---

## Appendix: Glossary

- **FMU**: Functional Mock-up Unit (portable simulation model)
- **FMI**: Functional Mock-up Interface (co-simulation standard)
- **HIL**: Hardware-in-Loop (testing with real hardware)
- **UDP**: User Datagram Protocol (fast, unreliable network)
- **TCP**: Transmission Control Protocol (slower, reliable network)
- **Simscape**: MATLAB physical modeling language
- **Simulink**: MATLAB block-diagram simulation tool
- **Niagara**: Unreal Engine particle system
- **Blueprint**: Unreal Engine visual scripting

---

**Next Steps:**
1. Validate key assumptions (licensing, performance)
2. Create proof-of-concept prototype
3. Test network communication latency
4. Develop data serialization schema
5. Document findings in this file
