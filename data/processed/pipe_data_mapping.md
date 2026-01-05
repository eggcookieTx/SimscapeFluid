# Pipe-to-Data Index Mapping
## Simscape Port Data → Physical Pipe Connections

This document maps the 18 pressure and 11 flow values from `unreal_playback.json` to the 12 physical pipe connections in the hydraulic system.

---

## Data Arrays Reference

### Pressure Array (18 values, Pa)
```
Index  Port Name              Component.Port
-----  ---------------------  ---------------------------
0      pump_out               FlowSource.B
1      relief_in              ReliefValve.A
2      relief_out             ReliefValve.B
3      vent_in                VentValve.A
4      vent_out               VentValve.B
5      dir_P                  DirectionalValve.P
6      dir_T                  DirectionalValve.T
7      dir_A                  DirectionalValve.A
8      dir_B                  DirectionalValve.B
9      cyl_cap                Cylinder.A (cap end)
10     cyl_rod                Cylinder.B (rod end)
11     check_in               CheckValve.A
12     check_out              CheckValve.B
13     restrict_in            FlowRestriction.A
14     restrict_out           FlowRestriction.B
15     filter_in              Filter.A
16     filter_out             Filter.B
17     tank_in                Tank/Reservoir.A
```

### Flow Array (11 values, m³/s)
```
Index  Port Name              Component.Port
-----  ---------------------  ---------------------------
0      pump_out               FlowSource.B
1      relief_in              ReliefValve.A
2      vent_in                VentValve.A
3      dir_P                  DirectionalValve.P
4      dir_T                  DirectionalValve.T
5      dir_A                  DirectionalValve.A
6      dir_B                  DirectionalValve.B
7      check_in               CheckValve.A
8      restrict_in            FlowRestriction.A
9      filter_in              Filter.A
10     tank_in                Tank.A
```

---

## Physical Pipe Connections (12 pipes)

### Pipe 1: Main Pressure Line (FlowSource → DirectionalValve + branches)
**From:** FlowSource.B  
**To:** DirectionalValve.P (+ branches to ReliefValve.A, VentValve.A)  
**Pressure:** `pressure[0]` (pump_out) ≈ `pressure[5]` (dir_P) ≈ `pressure[1]` (relief_in) ≈ `pressure[3]` (vent_in)  
**Flow:** `flow[0]` (pump_out) = `flow[3]` (dir_P) + `flow[1]` (relief) + `flow[2]` (vent)  
**Visualization:** Use `pressure[0]` or `pressure[5]`, aggregate flow or use `flow[0]`  
**Notes:** This is a shared manifold - multiple components connected to same line

---

### Pipe 2: Relief Valve Return
**From:** ReliefValve.B  
**To:** Tank  
**Pressure:** `pressure[2]` (relief_out) → `pressure[17]` (tank_in)  
**Flow:** `flow[1]` (relief flow, measured at inlet)  
**Visualization:** Use `pressure[2]`, `flow[1]`  

---

### Pipe 3: Vent Valve Return
**From:** VentValve.B  
**To:** Tank  
**Pressure:** `pressure[4]` (vent_out) → `pressure[17]` (tank_in)  
**Flow:** `flow[2]` (vent flow, measured at inlet)  
**Visualization:** Use `pressure[4]`, `flow[2]`  

---

### Pipe 4: Directional Valve A → Cylinder Cap End
**From:** DirectionalValve.A  
**To:** Cylinder.A  
**Pressure:** `pressure[7]` (dir_A) ≈ `pressure[9]` (cyl_cap) - **should be equal**  
**Flow:** `flow[5]` (dir_A)  
**Visualization:** Use `pressure[7]` or `pressure[9]`, `flow[5]`  
**Notes:** High pressure during extension

---

### Pipe 5: Directional Valve B → Cylinder Rod End
**From:** DirectionalValve.B  
**To:** Cylinder.B  
**Pressure:** `pressure[8]` (dir_B) ≈ `pressure[10]` (cyl_rod) - **should be equal**  
**Flow:** `flow[6]` (dir_B)  
**Visualization:** Use `pressure[8]` or `pressure[10]`, `flow[6]`  
**Notes:** High pressure during retraction

---

### Pipe 6: Directional Valve T → Check Valve
**From:** DirectionalValve.T  
**To:** CheckValve.A  
**Pressure:** `pressure[6]` (dir_T) ≈ `pressure[11]` (check_in) - **should be equal**  
**Flow:** `flow[4]` (dir_T) ≈ `flow[7]` (check_in) - **should be equal**  
**Visualization:** Use `pressure[6]` or `pressure[11]`, `flow[4]` or `flow[7]`  

---

### Pipe 7: Check Valve → Flow Restriction
**From:** CheckValve.B  
**To:** FlowRestriction.A  
**Pressure:** `pressure[12]` (check_out) ≈ `pressure[13]` (restrict_in) - **should be equal**  
**Flow:** `flow[7]` (check inlet flow) ≈ `flow[8]` (restrict_in) - **should be equal**  
**Visualization:** Use `pressure[12]` or `pressure[13]`, `flow[8]`  

---

### Pipe 8: Flow Restriction → Filter
**From:** FlowRestriction.B  
**To:** Filter.A  
**Pressure:** `pressure[14]` (restrict_out) ≈ `pressure[15]` (filter_in) - **should be equal**  
**Flow:** `flow[8]` (restrict inlet) ≈ `flow[9]` (filter_in) - **should be equal**  
**Visualization:** Use `pressure[14]` or `pressure[15]`, `flow[9]`  

---

### Pipe 9: Filter → Tank
**From:** Filter.B  
**To:** Tank  
**Pressure:** `pressure[16]` (filter_out) ≈ `pressure[17]` (tank_in) - **should be equal**  
**Flow:** `flow[9]` (filter inlet) ≈ `flow[10]` (tank_in) - **should be equal**  
**Visualization:** Use `pressure[16]` or `pressure[17]`, `flow[10]`  

---

### Pipe 10: Tank → FlowSource Inlet (not logged)
**From:** Tank  
**To:** FlowSource.A (inlet, not logged)  
**Pressure:** Assumed atmospheric (~0 Pa gauge)  
**Flow:** Not directly measured (equal to pump outlet flow in steady state)  
**Visualization:** Use constant low pressure, no flow visualization needed  
**Notes:** Suction line, typically low pressure

---

### Pipe 11: Cylinder Cap End Port C (vent/bleed - if exists)
**Status:** Not present in current schematic  
**Notes:** Reserved for future expansion

---

### Pipe 12: Cylinder Rod End Port C (vent/bleed - if exists)
**Status:** Not present in current schematic  
**Notes:** Reserved for future expansion

---

## Recommended Visualization Strategy

### For Each Pipe:
1. **Color (Pressure):** Map pressure value to blue→red gradient
   - Use the "from" component port pressure as primary
   - Validate equality with "to" port in debug mode
   
2. **Thickness/Opacity (Flow):** Map |flow| to line thickness
   - Higher flow = thicker pipe visualization
   - Use absolute value (flow can be negative for reverse direction)
   
3. **Particles (Flow Direction):** Spawn particles along spline
   - Positive flow: particles move from→to
   - Negative flow: particles move to→from
   - Particle speed proportional to |flow|

4. **Labels (Optional):** Show pressure and flow values as text
   - Position at pipe midpoint
   - Format: "P: 2.5 bar, Q: 1.2 L/min"

---

## Data Validation Checks

### Expected Equalities (pressure values should match):
```
pressure[0] ≈ pressure[5] ≈ pressure[1] ≈ pressure[3]  // Main manifold
pressure[7] ≈ pressure[9]                               // Cylinder cap line
pressure[8] ≈ pressure[10]                              // Cylinder rod line
pressure[6] ≈ pressure[11]                              // Dir.T → Check
pressure[12] ≈ pressure[13]                             // Check → Restrict
pressure[14] ≈ pressure[15]                             // Restrict → Filter
pressure[16] ≈ pressure[17]                             // Filter → Tank
```

### Expected Equalities (flow values should match):
```
flow[0] ≈ flow[3] + flow[1] + flow[2]  // Pump splits to Dir.P + Relief + Vent
flow[4] ≈ flow[7]                       // Dir.T → Check
flow[7] ≈ flow[8]                       // Check → Restrict
flow[8] ≈ flow[9]                       // Restrict → Filter
flow[9] ≈ flow[10]                      // Filter → Tank
```

---

## Updated topology.json Structure

Components should have **minimal or no data_index** (just labels).  
Connections should have **pressure_index** and **flow_index** for pipe visualization.

Example:
```json
{
  "id": "pipe_01",
  "name": "Main Pressure Line",
  "from": {"component": "FlowSource", "port": "B"},
  "to": {"component": "DirectionalValve", "port": "P"},
  "pressure_index": 0,
  "flow_index": 0,
  "waypoints": [...]
}
```

---

## Next Steps

1. **Update topology.json:** Move data_index from components to connections
2. **Modify PlaybackManager.cpp:** 
   - Spawn simple labeled component nodes
   - Create spline meshes for each pipe connection
   - Apply dynamic materials to **pipes** (not components)
   - Map pressure→color, flow→thickness/particles
3. **Test:** Verify pressure equality between connected ports
4. **Enhance:** Add text labels, particle systems, UI overlay

---

**Generated:** 2026-01-05  
**Purpose:** Data mapping for Unreal Engine hydraulic visualization
