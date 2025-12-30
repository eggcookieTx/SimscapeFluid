%% List all actual component blocks for the model

clear all; close all; clc;

fprintf('=== All Available Components for Hydraulic Model ===\n\n');

load_system('SimscapeFluids_lib');

%% Helper function to list all blocks under a path
function list_blocks(path, indent)
    try
        items = find_system(path, 'SearchDepth', 1);
        for i = 1:length(items)
            [~, name] = fileparts(items{i});
            if ~strcmp(name, extractAfter(path, '/'))
                fprintf('%s✓ %s\n', indent, name);
            end
        end
    catch
        % Path doesn't exist or has no items
    end
end

%% List components we need
fprintf('1. PUMPS & MOTORS\n');
fprintf('----------------------------------------\n');
list_blocks('SimscapeFluids_lib/Isothermal Liquid/Pumps & Motors', '  ');

fprintf('\n2. VALVES & ORIFICES - Pressure Control\n');
fprintf('----------------------------------------\n');
list_blocks('SimscapeFluids_lib/Isothermal Liquid/Valves & Orifices/Pressure Control Valves', '  ');

fprintf('\n3. VALVES & ORIFICES - Flow Control\n');
fprintf('----------------------------------------\n');
list_blocks('SimscapeFluids_lib/Isothermal Liquid/Valves & Orifices/Flow Control Valves', '  ');

fprintf('\n4. VALVES & ORIFICES - Directional Control\n');
fprintf('----------------------------------------\n');
list_blocks('SimscapeFluids_lib/Isothermal Liquid/Valves & Orifices/Directional Control Valves', '  ');

fprintf('\n5. PIPES & FITTINGS\n');
fprintf('----------------------------------------\n');
list_blocks('SimscapeFluids_lib/Isothermal Liquid/Pipes & Fittings', '  ');

fprintf('\n6. ACTUATORS\n');
fprintf('----------------------------------------\n');
list_blocks('SimscapeFluids_lib/Isothermal Liquid/Actuators', '  ');

fprintf('\n7. TANKS & ACCUMULATORS\n');
fprintf('----------------------------------------\n');
list_blocks('SimscapeFluids_lib/Isothermal Liquid/Tanks & Accumulators', '  ');

fprintf('\n8. UTILITIES\n');
fprintf('----------------------------------------\n');
list_blocks('SimscapeFluids_lib/Isothermal Liquid/Utilities', '  ');

fprintf('\n\n=== SENSORS (Foundation Library) ===\n');
fprintf('----------------------------------------\n');
fprintf('✓ Pressure Sensor (PS) - from nesl_utility/Simscape/Foundation Library/Physical Signals/Sensors\n');
fprintf('✓ Flow Rate Sensor (PS) - from nesl_utility/Simscape/Foundation Library/Physical Signals/Sensors\n');

fprintf('\n\n=== Copy exact paths for use in add_block() ===\n');
