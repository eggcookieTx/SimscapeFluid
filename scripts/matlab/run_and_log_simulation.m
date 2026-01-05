%% Run Simulation with Comprehensive Data Logging
% Executes SimpleHydraulicSystem model for 30 seconds with simlog enabled
% Logs all port states (pressure, flow) for 20+ connection points
% Saves data for UDP streaming to Unreal Engine
%
% Output: MAT file with simlog data structure

clear; clc;

%% Configuration
modelName = 'SimpleHydraulicSystem';
modelPath = '../../models/simscape/SimpleHydraulicSystem.slx';
simTime = 30;  % seconds
outputFolder = '../../data/processed';

fprintf('\n%s\n', repmat('=', 1, 80));
fprintf('SIMSCAPE HYDRAULIC SIMULATION WITH DATA LOGGING\n');
fprintf('%s\n\n', repmat('=', 1, 80));

%% Load Model
fprintf('Loading model: %s\n', modelPath);
try
    load_system(modelPath);
catch ME
    error('Failed to load model: %s', ME.message);
end

%% Configure Solver and Data Logging
fprintf('Configuring solver and data logging...\n');
% Set daessc solver (better for Simscape DAE systems)
set_param(modelName, 'SolverType', 'Variable-step');
set_param(modelName, 'Solver', 'daessc');
fprintf('  Solver: daessc (variable-step)\n');

% Ensure Simscape logging is enabled (should already be in model)
set_param(modelName, 'SimscapeLogType', 'all');
set_param(modelName, 'DSMLogging', 'on');
set_param(modelName, 'ReturnWorkspaceOutputs', 'on');
set_param(modelName, 'ReturnWorkspaceOutputsName', 'out');
fprintf('  Simscape logging: Enabled\n');

fprintf('  Simulation time: %d seconds\n', simTime);
fprintf('\n');

%% Run Simulation
fprintf('Running simulation...\n');
tic;

% Use SimulationInput object to ensure SimulationOutput is returned
simIn = Simulink.SimulationInput(modelName);
simOut = sim(simIn);

% Get simlog data
simlog = simOut.simlog;
fprintf('✓ Simlog data found: %s\n', class(simlog));
fprintf('✓ Simulation time data: %d points\n', length(simOut.tout));
    
elapsed = toc;
fprintf('✓ Simulation completed in %.2f seconds\n\n', elapsed);


%% Verify Logged Data
fprintf('Verifying logged data...\n');
fprintf('  Available blocks in simlog:\n');

blocks = fieldnames(simlog);
for i = 1:length(blocks)
    blockName = blocks{i};
    fprintf('    %d. %s\n', i, blockName);
    
    % Check available ports
    if isstruct(simlog.(blockName))
        ports = fieldnames(simlog.(blockName));
        for j = 1:length(ports)
            portName = ports{j};
            if isstruct(simlog.(blockName).(portName))
                % Check for pressure and flow data
                hasP = isfield(simlog.(blockName).(portName), 'p');
                hasQ = isfield(simlog.(blockName).(portName), 'q');
                if hasP || hasQ
                    dataTypes = {};
                    if hasP, dataTypes{end+1} = 'p'; end
                    if hasQ, dataTypes{end+1} = 'q'; end
                    fprintf('       Port %s: [%s]\n', portName, strjoin(dataTypes, ', '));
                end
            end
        end
    end
end
fprintf('\n');

%% Extract Key Data Points
fprintf('Extracting key data points...\n');

data = struct();
data.time = simlog.FlowSource.B.p.series.time;  % Time vector
data.simTime = simTime;
data.numPoints = length(data.time);

% Pump outlet (FlowSource)
try
    data.pump.outlet.pressure = simlog.FlowSource.B.p.series.values('Pa');
    data.pump.outlet.flow = simlog.FlowSource.q_B.series.values('m^3/s');
catch
    fprintf('  Warning: Could not extract pump data\n');
end

% Relief Valve
try
    data.relief.inlet.pressure = simlog.ReliefValve.A.p.series.values('Pa');
    data.relief.inlet.flow = simlog.ReliefValve.q_A.series.values('m^3/s');
    data.relief.outlet.pressure = simlog.ReliefValve.B.p.series.values('Pa');
catch
    fprintf('  Warning: Could not extract relief valve data\n');
end

% Vent Valve
try
    data.vent.inlet.pressure = simlog.VentValve.A.p.series.values('Pa');
    data.vent.inlet.flow = simlog.VentValve.q_A.series.values('m^3/s');
    data.vent.outlet.pressure = simlog.VentValve.B.p.series.values('Pa');
catch
    fprintf('  Warning: Could not extract vent valve data\n');
end

% Directional Valve (4 ports)
try
    data.directional.pump.pressure = simlog.DirectionalValve.P.p.series.values('Pa');
    data.directional.pump.flow = simlog.DirectionalValve.q_P.series.values('m^3/s');
    data.directional.tank.pressure = simlog.DirectionalValve.T.p.series.values('Pa');
    data.directional.tank.flow = simlog.DirectionalValve.q_T.series.values('m^3/s');
    data.directional.capEnd.pressure = simlog.DirectionalValve.A.p.series.values('Pa');
    data.directional.capEnd.flow = simlog.DirectionalValve.q_A.series.values('m^3/s');
    data.directional.rodEnd.pressure = simlog.DirectionalValve.B.p.series.values('Pa');
    data.directional.rodEnd.flow = simlog.DirectionalValve.q_B.series.values('m^3/s');
catch
    fprintf('  Warning: Could not extract directional valve data\n');
end

% Cylinder
try
    data.cylinder.capEnd.pressure = simlog.Cylinder.A.p.series.values('Pa');
    data.cylinder.capEnd.massFlow = simlog.Cylinder.chamber_A.mdot_A.series.values('kg/s');
    data.cylinder.rodEnd.pressure = simlog.Cylinder.B.p.series.values('Pa');
    data.cylinder.rodEnd.massFlow = simlog.Cylinder.chamber_B.mdot_A.series.values('kg/s');
    data.cylinder.rod.velocity = simlog.Cylinder.R.v.series.values('m/s');
catch ME
    fprintf('  Warning: Could not extract cylinder data: %s\n', ME.message);
end

% Check Valve
try
    data.checkValve.inlet.pressure = simlog.CheckValve.A.p.series.values('Pa');
    data.checkValve.inlet.flow = simlog.CheckValve.q_A.series.values('m^3/s');
    data.checkValve.outlet.pressure = simlog.CheckValve.B.p.series.values('Pa');
catch
    fprintf('  Warning: Could not extract check valve data\n');
end

% Flow Restriction
try
    data.flowRestriction.inlet.pressure = simlog.FlowRestriction.A.p.series.values('Pa');
    data.flowRestriction.inlet.flow = simlog.FlowRestriction.q_A.series.values('m^3/s');
    data.flowRestriction.outlet.pressure = simlog.FlowRestriction.B.p.series.values('Pa');
catch
    fprintf('  Warning: Could not extract flow restriction data\n');
end

% Filter
try
    data.filter.inlet.pressure = simlog.Filter.A.p.series.values('Pa');
    data.filter.inlet.flow = simlog.Filter.q_A.series.values('m^3/s');
    data.filter.outlet.pressure = simlog.Filter.B.p.series.values('Pa');
catch
    fprintf('  Warning: Could not extract filter data\n');
end

% Tank (Reservoir_IL or Reservoir_IL1)
try
    data.tank.inlet.pressure = simlog.Reservoir_IL.A.p.series.values('Pa');
    data.tank.inlet.flow = simlog.Reservoir_IL.q_A.series.values('m^3/s');
catch
    try
        data.tank.inlet.pressure = simlog.Reservoir_IL1.A.p.series.values('Pa');
        data.tank.inlet.flow = simlog.Reservoir_IL1.q_A.series.values('m^3/s');
    catch
        fprintf('  Warning: Could not extract tank data\n');
    end
end

fprintf('✓ Extracted data for %d time points\n', data.numPoints);
fprintf('  Time range: %.2f to %.2f seconds\n', data.time(1), data.time(end));
fprintf('\n');

%% Display Summary Statistics
fprintf('DATA SUMMARY:\n');
if isfield(data, 'pump') && isfield(data.pump, 'outlet')
    fprintf('  Pump outlet pressure: %.2e to %.2e Pa (%.1f to %.1f bar)\n', ...
        min(data.pump.outlet.pressure), max(data.pump.outlet.pressure), ...
        min(data.pump.outlet.pressure)/1e5, max(data.pump.outlet.pressure)/1e5);
    fprintf('  Pump outlet flow: %.2e to %.2e m³/s\n', ...
        min(data.pump.outlet.flow), max(data.pump.outlet.flow));
end
if isfield(data, 'cylinder') && isfield(data.cylinder, 'capEnd')
    fprintf('  Cylinder cap-end pressure: %.2e to %.2e Pa (%.1f to %.1f bar)\n', ...
        min(data.cylinder.capEnd.pressure), max(data.cylinder.capEnd.pressure), ...
        min(data.cylinder.capEnd.pressure)/1e5, max(data.cylinder.capEnd.pressure)/1e5);
end
if isfield(data, 'cylinder') && isfield(data.cylinder, 'rodEnd')
    fprintf('  Cylinder rod-end pressure: %.2e to %.2e Pa (%.1f to %.1f bar)\n', ...
        min(data.cylinder.rodEnd.pressure), max(data.cylinder.rodEnd.pressure), ...
        min(data.cylinder.rodEnd.pressure)/1e5, max(data.cylinder.rodEnd.pressure)/1e5);
end
fprintf('\n');

%% Save Data
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
outputFile = fullfile(outputFolder, sprintf('simlog_data_%s.mat', timestamp));

save(outputFile, 'data', 'simlog');
fprintf('✓ Data saved to: %s\n', outputFile);
fprintf('  File size: %.2f MB\n', dir(outputFile).bytes / 1e6);
fprintf('\n');

%% Close Model
close_system(modelName, 0);

fprintf('%s\n', repmat('=', 1, 80));
fprintf('SIMULATION COMPLETE\n');
fprintf('%s\n', repmat('=', 1, 80));
fprintf('\nNext steps:\n');
fprintf('  1. Load data: load(''%s'')\n', outputFile);
fprintf('  2. Plot results: plot(data.time, data.pump.outlet.pressure)\n');
fprintf('  3. Stream to UDP: Use extract_simlog_data.m function\n');
fprintf('\n');
