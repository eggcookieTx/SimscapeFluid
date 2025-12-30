# Multi-Point Data Extraction Plan for Flow Visualization

**Date**: December 30, 2025  
**Status**: Planning  
**Phase**: Phase 2 Preparation

---

## Objective

Extract comprehensive port-level state data from Simscape hydraulic model to enable detailed flow visualization in Unreal Engine. Flow visualization requires knowing pressure, flow rate, and temperature at MULTIPLE points throughout the network, not just discrete sensor locations.

---

## Data Extraction Strategy: Hybrid Approach

### Approach 1: Simscape Data Logging (simlog) - Comprehensive Network State

**Purpose:** Capture ALL port states automatically without manual sensor placement

**Advantages:**
- ✅ Zero sensor management overhead
- ✅ Complete network state available
- ✅ No performance impact during simulation
- ✅ Perfect for post-processing and detailed analysis
- ✅ Every conserving port is automatically logged

**Access Pattern:**
```matlab
% Enable logging
set_param(modelName, 'DataLoggingOverride', 'on');

% Run simulation
out = sim(modelName);
simlog = out.simlog;

% Extract port data
pump_outlet_pressure = simlog.FlowSource.B.p.series.values;  % Pa
pump_outlet_flow = simlog.FlowSource.B.q.series.values;      % m³/s
cylinder_cap_pressure = simlog.Cylinder.A.p.series.values;   % Pa
cylinder_rod_pressure = simlog.Cylinder.B.p.series.values;   % Pa
```

**Data Points Available (20+ ports):**
1. **FlowSource**: A (inlet), B (outlet)
2. **ReliefValve**: A (inlet), B (tank return)
3. **VentValve**: A (inlet), B (outlet)
4. **DirectionalValve**: P (pump), T (tank), A (cap-end), B (rod-end)
5. **CheckValve**: A (inlet), B (outlet)
6. **FlowRestriction**: A (inlet), B (outlet)
7. **Filter**: A (inlet), B (outlet)
8. **Cylinder**: A (cap-end), B (rod-end)
9. **Tank**: A (inlet)

**Per Port Data:**
- `.p` - Pressure (Pa)
- `.q` - Volumetric flow rate (m³/s)
- `.T` - Temperature (K) [if thermal domain]
- `.series.time` - Time vector
- `.series.values` - Data values

---

### Approach 2: Strategic Real-Time Sensors

**Purpose:** Enable real-time data streaming during simulation for immediate visualization

**Advantages:**
- ✅ Direct Simulink signal output
- ✅ Real-time streaming capability
- ✅ Easy UDP integration
- ✅ Low latency for interactive visualization

**Sensor Placement (5 strategic points):**

1. **Pump Outlet Pressure** 
   - Location: FlowSource.B → DirectionalValve.P junction
   - Type: Pressure Sensor (IL)
   - Purpose: Main system pressure monitoring

2. **Pump Outlet Flow**
   - Location: FlowSource.B → DirectionalValve.P junction
   - Type: Flow Rate Sensor (IL)
   - Purpose: Total system flow rate

3. **Cylinder Cap-End Pressure**
   - Location: DirectionalValve.A → Cylinder.A
   - Type: Pressure Sensor (IL)
   - Purpose: Extend force monitoring

4. **Cylinder Rod-End Pressure**
   - Location: Cylinder.B (at parallel junction)
   - Type: Pressure Sensor (IL)
   - Purpose: Retract force monitoring

5. **Cylinder Position**
   - Location: Cylinder rod output
   - Type: Translational Position Sensor
   - Purpose: Motion tracking for visualization

**Signal Conversion:**
- All sensors output Physical Signals
- Require PS-Simulink Converter blocks
- Connect to UDP Send blocks or To Workspace

---

## Implementation Plan

### Task 1: Enable simlog Data Logging

**Script: `configure_simlog.m`**
```matlab
% Configure model for comprehensive data logging
modelName = 'SimpleHydraulicSystem';
load_system('../../models/simscape/SimpleHydraulicSystem.slx');

% Enable data logging
set_param(modelName, 'DataLoggingOverride', 'on');

% Configure logging settings
set_param(modelName, 'DataLoggingDecimation', '1');  % Log every step
set_param(modelName, 'DataLoggingMaxPoints', '10000');  % Max points per signal

% Save and run
save_system(modelName);
out = sim(modelName);

% Access logged data
simlog = out.simlog;
disp('Available blocks:');
disp(fieldnames(simlog));
```

---

### Task 2: Add Strategic Sensors to Model

**Script: `add_visualization_sensors.m`**
```matlab
% Add 5 strategic sensors for real-time visualization
modelName = 'SimpleHydraulicSystem';
load_system('../../models/simscape/SimpleHydraulicSystem.slx');

% 1. Pump outlet pressure sensor
add_block('fl_lib/Sensors & Transducers/Pressure Sensor', ...
    [modelName '/PumpPressureSensor']);
add_block('nesl_utility/Simulink-PS Converter', ...
    [modelName '/PumpPressureConverter']);

% 2. Pump outlet flow sensor
add_block('fl_lib/Sensors & Transducers/Flow Rate Sensor', ...
    [modelName '/PumpFlowSensor']);
add_block('nesl_utility/Simulink-PS Converter', ...
    [modelName '/PumpFlowConverter']);

% 3-5. Cylinder sensors (pressure A, pressure B, position)
% ... similar pattern ...

% Connect sensors to existing network
% (Manual in Simulink UI or programmatic via simscape.addConnection)

save_system(modelName);
```

---

### Task 3: Extract simlog Data for UDP Streaming

**Script: `extract_simlog_data.m`**
```matlab
% Extract all port states from simlog for UDP transmission
function data_struct = extract_simlog_data(simlog, time_index)
    % Extract data at specific time index for UDP packet
    
    data_struct = struct();
    
    % Pump
    data_struct.pump.outlet.pressure = simlog.FlowSource.B.p.series.values(time_index);
    data_struct.pump.outlet.flow = simlog.FlowSource.B.q.series.values(time_index);
    
    % Relief Valve
    data_struct.relief.inlet.pressure = simlog.ReliefValve.A.p.series.values(time_index);
    data_struct.relief.outlet.pressure = simlog.ReliefValve.B.p.series.values(time_index);
    data_struct.relief.inlet.flow = simlog.ReliefValve.A.q.series.values(time_index);
    
    % Vent Valve
    data_struct.vent.inlet.pressure = simlog.VentValve.A.p.series.values(time_index);
    data_struct.vent.outlet.pressure = simlog.VentValve.B.p.series.values(time_index);
    
    % Directional Valve (4 ports)
    data_struct.directional.pump.pressure = simlog.DirectionalValve.P.p.series.values(time_index);
    data_struct.directional.tank.pressure = simlog.DirectionalValve.T.p.series.values(time_index);
    data_struct.directional.capEnd.pressure = simlog.DirectionalValve.A.p.series.values(time_index);
    data_struct.directional.rodEnd.pressure = simlog.DirectionalValve.B.p.series.values(time_index);
    
    % Cylinder
    data_struct.cylinder.capEnd.pressure = simlog.Cylinder.A.p.series.values(time_index);
    data_struct.cylinder.rodEnd.pressure = simlog.Cylinder.B.p.series.values(time_index);
    
    % Check Valve
    data_struct.checkValve.inlet.pressure = simlog.CheckValve.A.p.series.values(time_index);
    data_struct.checkValve.outlet.pressure = simlog.CheckValve.B.p.series.values(time_index);
    
    % Flow Restriction
    data_struct.flowRestriction.inlet.pressure = simlog.FlowRestriction.A.p.series.values(time_index);
    data_struct.flowRestriction.outlet.pressure = simlog.FlowRestriction.B.p.series.values(time_index);
    data_struct.flowRestriction.flow = simlog.FlowRestriction.A.q.series.values(time_index);
    
    % Filter
    data_struct.filter.inlet.pressure = simlog.Filter.A.p.series.values(time_index);
    data_struct.filter.outlet.pressure = simlog.Filter.B.p.series.values(time_index);
    
    % Tank
    data_struct.tank.inlet.pressure = simlog.Tank.A.p.series.values(time_index);
    
    % Add timestamp
    data_struct.time = simlog.FlowSource.B.p.series.time(time_index);
end
```

---

### Task 4: UDP Streaming Implementation

**Two Streaming Modes:**

1. **Real-Time Mode** (during simulation)
   - Stream sensor data only (5 points)
   - 30-60 Hz update rate
   - Low latency for interactive visualization
   - Uses UDP Send blocks in Simulink

2. **Batch Mode** (post-simulation)
   - Stream complete simlog data (20+ points)
   - 10-30 Hz playback rate
   - Full network visualization
   - Uses MATLAB UDP socket programming

**Data Packet Format (JSON):**
```json
{
  "timestamp": 1.234,
  "mode": "realtime" | "batch",
  "data": {
    "pump": {"outlet": {"pressure": 21000000, "flow": 0.00005}},
    "cylinder": {"capEnd": {"pressure": 18000000}, "rodEnd": {"pressure": 2000000}},
    "directional": {"pump": {"pressure": 20500000}, "capEnd": {"pressure": 18000000}, "rodEnd": {"pressure": 2000000}},
    "tank": {"inlet": {"pressure": 101325}}
  }
}
```

---

## Validation Checklist

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

---

## Next Steps (Phase 3)

1. Create Unreal UDP receiver plugin
2. Map incoming data to visual elements:
   - Pipe colors (pressure gradient)
   - Flow particles (flow direction and rate)
   - Component states (valve positions, cylinder extension)
3. Implement real-time visualization pipeline
4. Performance optimization

---

## References

- [Simscape Data Logging Documentation](https://www.mathworks.com/help/simscape/ug/about-simulation-data-logging.html)
- [Accessing Logged Simulation Data](https://www.mathworks.com/help/simscape/ug/accessing-logged-simulation-data.html)
- [Foundation Library Sensors](https://www.mathworks.com/help/physmod/simscape/ref/sensors.html)
