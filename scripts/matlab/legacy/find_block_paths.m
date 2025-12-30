%% Find exact block paths in Simscape libraries
% Purpose: Locate all components for the hydraulic model in both fl_lib and SimscapeFluids_lib

clear all; close all; clc;

%% Components to find
components = {
    'Isothermal Liquid Predefined Properties'
    'Flow Rate Source'
    'Fixed-Displacement Pump'
    'Pressure Relief Valve'
    'Local Resistance'
    'Pressure Sensor'
    'Check Valve'
    'Flow Rate Sensor'
    'Double-Acting Actuator'
    'Constant Volume Reservoir'
    'Pipe'
};

fprintf('=== Searching for Simscape Fluids and Foundation Library blocks ===\n\n');

%% Search in SimscapeFluids_lib
fprintf('Searching SimscapeFluids_lib...\n');
try
    load_system('SimscapeFluids_lib');
    fprintf('✓ SimscapeFluids_lib loaded\n');
    
    % List all subsystems - these are the actual blocks we can add
    subsys_fluids = find_system('SimscapeFluids_lib/Isothermal Liquid', 'SearchDepth', 3);
    fprintf('\nFound paths in SimscapeFluids_lib/Isothermal Liquid:\n');
    disp(subsys_fluids);
    
catch ME
    fprintf('✗ Error: %s\n', ME.message);
end

%% List Isothermal Liquid subcategories
fprintf('\n\nListing SimscapeFluids_lib/Isothermal Liquid structure:\n');
try
    il_path = 'SimscapeFluids_lib/Isothermal Liquid';
    
    % Get all subsystems under Isothermal Liquid
    items = find_system(il_path, 'SearchDepth', 1, 'BlockType', 'SubSystem');
    fprintf('Subcategories:\n');
    for i = 1:length(items)
        fprintf('  %s\n', items{i});
    end
    
catch ME
    fprintf('✗ Error: %s\n', ME.message);
end

fprintf('\n=== Search Complete ===\n');
fprintf('Use the paths above in add_block() calls in the model generation script.\n');
