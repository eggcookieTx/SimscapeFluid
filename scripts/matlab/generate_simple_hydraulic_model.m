%% Generate Simple Hydraulic System Simscape Model
% Created: 2025-12-30
% Purpose: Programmatically build Simscape Fluids model from P&ID schematic
% Based on: SimpleHydraulicSchematics.jpg
% 
% SCHEMATIC COMPONENTS (10):
%   1. Flow Rate Source (pump input)
%   2. Pressure Relief Valve (pressure protection - parallel path)
%   3. Vent Valve (tank return control - parallel path)
%   4. 4-Way 3-Position Directional Valve (cylinder direction control)
%   5. Check Valve (rod-end anti-backflow)
%   6. Flow Restriction (rod-end flow control)
%   7. Filter/Restriction (directional valve tank return)
%   8. Double-Acting Cylinder
%   9. Reservoir (Tank)
%  10. Fluid Properties (IL domain requirement)
%
% TOPOLOGY (P&ID flow path):
%   Pump --> 3 PARALLEL PATHS:
%            |--> Relief Valve --> Tank (pressure protection)
%            |--> Vent Valve (2-Way) --> Tank (tank return control)
%            |--> 4-Way Directional Valve (P) --> Control Cylinder
%                 |--> (A) --> Cylinder Cap-End (A) [direct]
%                 |--> (B) <-- Cylinder Rod-End (B) --> 2 PARALLEL PATHS:
%                                                    |--> Local Restriction --> (B)
%                                                    |--> Check Valve (reversed) --> (B)
%                 |--> (T) --> Filter --> Tank
%
% Block Connections:
%   FlowSource.B --> ReliefValve.A (parallel)
%   FlowSource.B --> VentValve.A (parallel, 2-Way)
%   FlowSource.B --> DirectionalValve.P (parallel)
%   ReliefValve.B --> Tank.A
%   VentValve.B --> Tank.A
%   DirectionalValve.A --> Cylinder.A (cap-end direct)
%   Cylinder.B (rod-end) SPLITS INTO 2 PARALLEL PATHS:
%     - Cylinder.B --> LocalRestriction --> DirectionalValve.B
%     - DirectionalValve.B --> CheckValve --> Cylinder.B (reversed direction)
%   DirectionalValve.T --> Filter --> Tank.A

%% Configuration
modelName = 'SimpleHydraulicSystem';
modelPath = '../../models/simscape/SimpleHydraulicSystem.slx';

%% Create new model
close_system(modelName, 0);
new_system(modelName);
open_system(modelName);

%% Block Positions (x1, y1, x2, y2) for organized layout
pos_source       = [50, 200, 120, 250];
pos_relief       = [200, 200, 270, 250];
pos_ventvalve    = [200, 350, 270, 400];
pos_dirvalve     = [350, 200, 420, 250];
pos_cylinder     = [550, 200, 620, 250];
pos_checkvalve   = [550, 350, 620, 400];
pos_flowrestr    = [620, 350, 690, 400];
pos_filter       = [420, 350, 490, 400];
pos_tank         = [750, 300, 820, 350];
pos_fluid_props  = [50, 50, 150, 100];

%% 1. FLOW RATE SOURCE (Pump equivalent)
add_block('fl_lib/Isothermal Liquid/Sources/Flow Rate Source (IL)', ...
    [modelName '/FlowSource'], ...
    'Position', pos_source);

%% 2. PRESSURE RELIEF VALVE (parallel path from pump)
add_block('SimscapeFluids_lib/Isothermal Liquid/Valves & Orifices/Pressure Control Valves/Pressure Relief Valve (IL)', ...
    [modelName '/ReliefValve'], ...
    'Position', pos_relief);

%% 3. VENT VALVE (parallel path from pump) - 2-Way Directional Valve
add_block('SimscapeFluids_lib/Isothermal Liquid/Valves & Orifices/Directional Control Valves/2-Way Directional Valve (IL)', ...
    [modelName '/VentValve'], ...
    'Position', pos_ventvalve);

%% 4. 4-WAY 3-POSITION DIRECTIONAL VALVE (parallel path from pump)
add_block('SimscapeFluids_lib/Isothermal Liquid/Valves & Orifices/Directional Control Valves/4-Way 3-Position Directional Valve (IL)', ...
    [modelName '/DirectionalValve'], ...
    'Position', pos_dirvalve);

%% 5. CHECK VALVE (rod-end return path)
add_block('SimscapeFluids_lib/Isothermal Liquid/Valves & Orifices/Directional Control Valves/Check Valve (IL)', ...
    [modelName '/CheckValve'], ...
    'Position', pos_checkvalve);

%% 6. FLOW RESTRICTION (rod-end return path, in series with check valve)
add_block('SimscapeFluids_lib/Isothermal Liquid/Pipes & Fittings/Local Restriction (IL)', ...
    [modelName '/FlowRestriction'], ...
    'Position', pos_flowrestr);

%% 7. FILTER (directional valve tank return path)
add_block('SimscapeFluids_lib/Isothermal Liquid/Pipes & Fittings/Local Resistance (IL)', ...
    [modelName '/Filter'], ...
    'Position', pos_filter);

%% 8. CYLINDER (Double-Acting Actuator)
add_block('SimscapeFluids_lib/Isothermal Liquid/Actuators/Double-Acting Actuator (IL)', ...
    [modelName '/Cylinder'], ...
    'Position', pos_cylinder);

%% 9. TANK/RESERVOIR
add_block('SimscapeFluids_lib/Isothermal Liquid/Tanks & Accumulators/Tank (IL)', ...
    [modelName '/Tank'], ...
    'Position', pos_tank);

%% 10. ISOTHERMAL LIQUID PROPERTIES (Required for IL networks)
add_block('SimscapeFluids_lib/Isothermal Liquid/Utilities/Isothermal Liquid Predefined Properties (IL)', ...
    [modelName '/FluidProperties'], ...
    'Position', pos_fluid_props);

%% CONNECT BLOCKS - Main flow path
% Using actual port names discovered via simscape.connectionPortProperties()
% Port mapping:
%   FlowSource: A=inlet, B=outlet, M=manual
%   ReliefValve: A=inlet, B=return
%   VentValve (2-Way): A=inlet, B=outlet
%   DirectionalValve: P=pump inlet, T=tank return, A=cap-end port, B=rod-end port, S=solenoid
%   CheckValve: A=inlet, B=outlet
%   FlowRestriction: A=inlet, B=outlet
%   Filter: A=inlet, B=outlet
%   Cylinder: A=cap-end, B=rod-end
%   Tank: A=inlet

try
    % THREE PARALLEL PATHS FROM PUMP OUTLET:
    
    % Path 1: Flow Source B -> Relief Valve A -> Tank
    simscape.addConnection([modelName '/FlowSource'], 'B', ...
                           [modelName '/ReliefValve'], 'A', 'autorouting', 'smart');
    simscape.addConnection([modelName '/ReliefValve'], 'B', ...
                           [modelName '/Tank'], 'A', 'autorouting', 'smart');
    
    % Path 2: Flow Source B -> Vent Valve (2-Way) A -> Tank
    simscape.addConnection([modelName '/FlowSource'], 'B', ...
                           [modelName '/VentValve'], 'A', 'autorouting', 'smart');
    simscape.addConnection([modelName '/VentValve'], 'B', ...
                           [modelName '/Tank'], 'A', 'autorouting', 'smart');
    
    % Path 3: Flow Source B -> Directional Valve P
    simscape.addConnection([modelName '/FlowSource'], 'B', ...
                           [modelName '/DirectionalValve'], 'P', 'autorouting', 'smart');
    
    % Directional Valve A -> Cylinder cap-end (A) [DIRECT]
    simscape.addConnection([modelName '/DirectionalValve'], 'A', ...
                           [modelName '/Cylinder'], 'A', 'autorouting', 'smart');
    
    % CYLINDER ROD-END (B) HAS 2 PARALLEL RETURN PATHS:
    % Path 1: Cylinder Rod (B) -> Flow Restriction -> Directional Valve B
    simscape.addConnection([modelName '/Cylinder'], 'B', ...
                           [modelName '/FlowRestriction'], 'A', 'autorouting', 'smart');
    simscape.addConnection([modelName '/FlowRestriction'], 'B', ...
                           [modelName '/DirectionalValve'], 'B', 'autorouting', 'smart');
    
    % Path 2: Directional Valve B -> Check Valve -> Cylinder Rod (B) (PARALLEL, opposite direction)
    simscape.addConnection([modelName '/DirectionalValve'], 'B', ...
                           [modelName '/CheckValve'], 'A', 'autorouting', 'smart');
    simscape.addConnection([modelName '/CheckValve'], 'B', ...
                           [modelName '/Cylinder'], 'B', 'autorouting', 'smart');
    
    % Directional Valve T -> Filter -> Tank
    simscape.addConnection([modelName '/DirectionalValve'], 'T', ...
                           [modelName '/Filter'], 'A', 'autorouting', 'smart');
    simscape.addConnection([modelName '/Filter'], 'B', ...
                           [modelName '/Tank'], 'A', 'autorouting', 'smart');
    
    fprintf('\n✓ SUCCESS: All 12 connections made successfully!\n');
    connections_made = true;
    
catch err
    fprintf('\n✗ Connection failed: %s\n', err.message);
    fprintf('To diagnose port names, run: test_new_blocks.m\n');
    connections_made = false;
end

%% Configure Solver
set_param(modelName, 'Solver', 'ode15s');
set_param(modelName, 'StopTime', '10');
set_param(modelName, 'SolverType', 'Variable-step');
set_param(modelName, 'MaxStep', '0.001');

%% Save model
save_system(modelName, modelPath);

fprintf('\n');
fprintf('════════════════════════════════════════════════════════\n');
fprintf('✓ Hydraulic Model Created Successfully\n');
fprintf('════════════════════════════════════════════════════════\n');
fprintf('Model: %s\n', modelPath);
fprintf('\nBLOCKS ADDED (%d total):\n', 10);
fprintf('  1. Flow Rate Source                (pump input)\n');
fprintf('  2. Pressure Relief Valve          (pressure protection, 210 bar) - PARALLEL\n');
fprintf('  3. Vent Valve (2-Way Directional) (tank return control) - PARALLEL\n');
fprintf('  4. 4-Way 3-Position Directional   (cylinder direction control) - PARALLEL\n');
fprintf('  5. Check Valve                    (rod-end reverse flow)\n');
fprintf('  6. Local Restriction              (rod-end flow control)\n');
fprintf('  7. Filter                         (directional tank return)\n');
fprintf('  8. Double-Acting Cylinder         (20cm² piston, 10cm² rod)\n');
fprintf('  9. Reservoir/Tank                 (fluid storage)\n');
fprintf(' 10. Fluid Properties               (IL domain)\n');
fprintf('\nCONNECTIONS STATUS:\n');
if connections_made
    fprintf('  ✓ All 12 block connections made programmatically\n');
    fprintf('\n  TOPOLOGY (3 parallel paths from pump):\n');
    fprintf('    Path 1: Pump → Relief Valve → Tank\n');
    fprintf('    Path 2: Pump → Vent Valve (2-Way) → Tank\n');
    fprintf('    Path 3: Pump → 4-Way Directional Valve\n');
    fprintf('              ├→ (A) → Cylinder Cap (A)\n');
    fprintf('              ├← Cylinder Rod (B) ← (2 PARALLEL PATHS):\n');
    fprintf('              │         ├ CheckValve\n');
    fprintf('              │         └ FlowRestriction\n');
    fprintf('              │         ← (B)\n');
    fprintf('              └→ (T) → Filter → Tank\n');
else
    fprintf('  ⚠ Auto-connection failed. MANUALLY connect blocks in Simulink UI:\n');
    fprintf('     Path 1 (Relief): FlowSource.B → ReliefValve.A → Tank.A\n');
    fprintf('     Path 2 (Vent): FlowSource.B → VentValve.A → Tank.A\n');
    fprintf('     Path 3 (Directional):\n');
    fprintf('       - FlowSource.B → DirectionalValve.P\n');
    fprintf('       - DirectionalValve.A → Cylinder.A\n');
    fprintf('       - Cylinder.B splits to 2 parallel paths:\n');
    fprintf('         1) → CheckValve.A → CheckValve.B → DirectionalValve.B\n');
    fprintf('         2) → FlowRestriction.A → FlowRestriction.B → DirectionalValve.B\n');
    fprintf('       - DirectionalValve.T → Filter.A → Tank.A\n');
end
fprintf('\nNEXT STEPS:\n');
fprintf('  1. Open model in Simulink: open(''%s'')\n', modelPath);
fprintf('  2. Configure parameters:\n');
fprintf('     - FlowSource: Set flow rate to 0.003 m³/min (3 GPM)\n');
fprintf('     - ReliefValve: Set cracking pressure to 210 bar (2.1e7 Pa)\n');
fprintf('     - Cylinder: Set piston area ~20cm², rod area ~10cm²\n');
fprintf('     - DirectionalValve: Add solenoid actuators for control\n');
fprintf('  3. Add sensors from Foundation Library:\n');
fprintf('     - Pressure Sensor (IL) at pump outlet\n');
fprintf('     - Flow Rate Sensor (IL) at pump outlet\n');
fprintf('  4. Run simulation and verify pressures/flows match expectations\n');
fprintf('════════════════════════════════════════════════════════\n\n');
