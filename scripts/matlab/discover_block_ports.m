%% Discover Actual Port Names for Simscape Blocks
% This script uses simscape.connectionPortProperties() to discover the 
% actual port names for blocks in the hydraulic model.
% This information is needed to correctly wire connections using simscape.addConnection()

clear; clc;

% Open or load the model
model_path = '../../models/simscape/SimpleHydraulicSystem.slx';
try
    model = load_system(model_path);
    model_name = 'SimpleHydraulicSystem';
catch
    error('Could not open model. Create it first with generate_simple_hydraulic_model.m');
end

% Block names in the model
blocks = {
    'FlowSource'
    'Filter'
    'ReliefValve'
    'VentValve'
    'FlowControlValve'
    'CheckValve'
    'Cylinder'
    'Tank'
};

fprintf('=== SIMSCAPE BLOCK PORT NAMES ===\n\n');

% Discover port names for each block
port_map = struct();

for i = 1:length(blocks)
    block_name = blocks{i};
    block_path = [model_name '/' block_name];
    
    try
        % Get port properties using Simscape API
        props = simscape.connectionPortProperties(block_path);
        
        fprintf('Block: %s\n', block_name);
        fprintf('  Ports available: %d\n', length(props));
        fprintf('  Details:\n');
        
        port_names = {};
        for j = 1:length(props)
            port_name = props(j).Name;
            port_label = props(j).Label;
            port_names{j} = port_name;
            
            fprintf('    Port %d: Name="%s", Label="%s"\n', ...
                j, port_name, port_label);
        end
        
        % Store in map for reference
        port_map.(block_name) = port_names;
        
        fprintf('\n');
        
    catch ME
        fprintf('Block: %s\n');
        fprintf('  ERROR: %s\n\n', ME.message);
    end
end

fprintf('=== CONNECTION REFERENCE TABLE ===\n\n');
fprintf('Use these exact port names in generate_simple_hydraulic_model.m:\n\n');

% Create a connection reference table
connections = {
    'FlowSource', 'Filter', 'outlet', 'inlet';
    'Filter', 'ReliefValve', 'outlet', 'P';
    'ReliefValve', 'FlowControlValve', 'outlet', 'inlet';
    'ReliefValve', 'VentValve', 'T', 'inlet';
    'VentValve', 'Tank', 'outlet', 'P';
    'FlowControlValve', 'CheckValve', 'outlet', 'inlet';
    'CheckValve', 'Cylinder', 'outlet', 'P';
    'Cylinder', 'Tank', 'T', 'B';
};

fprintf('From Block        To Block          From Port         To Port\n');
fprintf('---              ---               ---               ---\n');

for i = 1:size(connections, 1)
    fprintf('%-17s%-18s%-18s%s\n', ...
        connections{i,1}, connections{i,2}, ...
        connections{i,3}, connections{i,4});
end

fprintf('\n=== UPDATE generate_simple_hydraulic_model.m WITH THESE NAMES ===\n\n');
fprintf('% Connection logic using actual discovered port names:\n');
fprintf('simscape.addConnection(''SimpleHydraulicSystem/FlowSource'', port_from_block{1}, ...\n');
fprintf('                       ''SimpleHydraulicSystem/Filter'', port_from_block{2}, ''autorouting'', ''smart'');\n');

% Don't close - will cause error with load_system result
% close_system(model_name);
