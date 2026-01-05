# Error Log

Track general errors encountered due to LLM knowledge limitations from training data.

**Purpose**: Document API misuse, outdated methods, and knowledge gaps that caused errors across projects. This helps identify patterns where the LLM's training data is incomplete or outdated.

**Scope**: General technical errors applicable to multiple projects (wrong API usage, missing documentation, etc.)

**Not Included**: Project-specific design decisions, topology corrections, or requirements clarifications - these belong in project tracking documents.

## Error Format
- **Date**: YYYY-MM-DD
- **Error Type**: [Error classification]
- **Context**: Where/when it occurred
- **Message**: Full error message
- **Resolution**: How it was fixed
- **Reference**: Documentation links
- **Status**: Resolved / Recurring / Monitoring

## Logged Errors

### 2024-12-30: Wrong Connection Method for Simscape Blocks
- **Date**: 2024-12-30
- **Error Type**: API Misuse
- **Context**: Attempting to connect Simscape Isothermal Liquid blocks programmatically
- **Message**: Used `add_line()` which is for Simulink signal lines, not physical conserving connections
- **Root Cause**: AI attempted to use standard Simulink connection API instead of Simscape-specific API
- **Resolution**: Use `simscape.addConnection(block1, port1, block2, port2, 'autorouting', 'smart')` for Simscape conserving ports
- **Reference**: https://www.mathworks.com/help/simscape/ref/simscape.addconnection.html
- **Status**: ✅ Resolved
- **Prevention**: Always use Simscape API for physical network connections

### 2024-12-30: Unknown Port Names for Simscape Blocks
- **Date**: 2024-12-30
- **Error Type**: Missing Documentation/Discovery
- **Context**: Connecting blocks without knowing actual port names (A, B, P, T, etc.)
- **Message**: Connection failed because port names were assumed incorrectly
- **Root Cause**: Simscape blocks use specific port naming (e.g., DirectionalValve has P/T/A/B/S ports)
- **Resolution**: Use `simscape.connectionPortProperties(blockPath)` to discover actual port names
- **Script Created**: `discover_block_ports.m` - diagnostic tool to query port properties
- **Status**: ✅ Resolved
- **Prevention**: Always discover port names before connecting new block types

### 2025-12-31: sim() Returns Empty SimulationOutput - Missing simlog Data
- **Date**: 2025-12-31
- **Error Type**: API Misuse / Incorrect Configuration
- **Context**: Programmatic simulation using `sim(modelName)` for Simscape data logging
- **Message**: `sim()` returned only `SimulationMetadata` and `ErrorMessage` fields, no `simlog` field containing Simscape logging data
- **Symptoms**:
  - `simOut = sim(modelName)` completed successfully
  - `fieldnames(simOut)` showed only: `SimulationMetadata`, `ErrorMessage`
  - Expected fields missing: `simlog`, `yout`, `tout`, `xout`
  - Model runs successfully manually in Simulink GUI
  - Model already configured with `SimscapeLogType='all'` and `ReturnWorkspaceOutputs='on'`
- **Root Cause**: Using basic `sim(modelName)` syntax does not guarantee `Simulink.SimulationOutput` object return format. The model may have been created before R2019a or had legacy configuration
- **Resolution**: 
  1. **Primary Fix**: Use `Simulink.SimulationInput` object to force proper output format:
     ```matlab
     simIn = Simulink.SimulationInput(modelName);
     simOut = sim(simIn);
     ```
     This guarantees `sim()` returns `Simulink.SimulationOutput` object with all data fields
  2. **Data Access Fix**: Simscape logging data requires proper access methods:
     - Pressure: `simlog.BlockName.Port.p.series.values('Pa')` (must specify units)
     - Flow: `simlog.BlockName.q_Port.series.values('m^3/s')` (not `Port.q`)
  3. **Object Handling Fix**: `simscape.logging.Node` objects don't work with `isfield()`
     - Use `try-catch` blocks instead of `isfield()` checks
     - Or use `isprop()` instead of `isfield()`
- **Failed Attempts**:
  - Passing `'ReturnWorkspaceOutputs', 'on'` to `sim()` - insufficient
  - Using `set_param()` before simulation - doesn't affect sim() return type
  - Checking model parameters (they were already correct)
- **Reference**: 
  - https://www.mathworks.com/help/simulink/slref/sim.html
  - https://www.mathworks.com/help/simulink/gui/singlesimulationoutput.html
  - https://www.mathworks.com/help/simulink/slref/simulink.simulationoutput.html
- **Additional Discovery**: 
  - Cylinder blocks have different structure than valves:
    - Valves: `ValveName.Port.p` and `ValveName.q_Port`
    - Cylinder: `Cylinder.Port.p` but mass flow in `Cylinder.chamber_A.mdot_A` 
    - Cylinder velocity: `Cylinder.R.v` (rod port)
- **Status**: ✅ Resolved
- **Prevention**: 
  - Always use `Simulink.SimulationInput` for programmatic simulations
  - Always call `.values('unit')` with explicit units when extracting simlog data
  - Use try-catch for simscape.logging.Node property access
  - Test data extraction immediately after simulation, not after saving/loading MAT file

## Recurring Issues
[Issues that need investigation or systematic fix]
