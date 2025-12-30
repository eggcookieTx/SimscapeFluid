%% Discover Port Names for New Blocks
clear; clc;

% Open model
model_name = 'SimpleHydraulicSystem';
load_system('../../models/simscape/SimpleHydraulicSystem.slx');

fprintf('=== NEW BLOCK PORT NAMES ===\n\n');

% Check DirectionalValve
try
    props = simscape.connectionPortProperties([model_name '/DirectionalValve']);
    fprintf('DirectionalValve ports:\n');
    for i = 1:length(props)
        fprintf('  Port %d: Name="%s", Label="%s"\n', i, props(i).Name, props(i).Label);
    end
    fprintf('\n');
catch ME
    fprintf('DirectionalValve ERROR: %s\n\n', ME.message);
end

% Check VentValve (POCV)
try
    props = simscape.connectionPortProperties([model_name '/VentValve']);
    fprintf('VentValve (POCV) ports:\n');
    for i = 1:length(props)
        fprintf('  Port %d: Name="%s", Label="%s"\n', i, props(i).Name, props(i).Label);
    end
    fprintf('\n');
catch ME
    fprintf('VentValve ERROR: %s\n\n', ME.message);
end
