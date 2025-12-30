%% Get correct component names from MATLAB documentation
% Purpose: Navigate SimscapeFluids_lib/Isothermal Liquid and list all components

clear all; close all; clc;

fprintf('=== Exploring SimscapeFluids_lib/Isothermal Liquid ===\n\n');

%% Load SimscapeFluids library
fprintf('Loading SimscapeFluids_lib...\n');
load_system('SimscapeFluids_lib');
fprintf('✓ Loaded\n\n');

%% List what's directly under Isothermal Liquid
fprintf('Subsystems under SimscapeFluids_lib/Isothermal Liquid:\n');
fprintf('----------------------------------------\n');
il_path = 'SimscapeFluids_lib/Isothermal Liquid';
il_subsys = find_system(il_path, 'SearchDepth', 1, 'BlockType', 'SubSystem');

for i = 1:length(il_subsys)
    [~, name] = fileparts(il_subsys{i});
    if ~strcmp(name, 'Isothermal Liquid')  % Skip the parent itself
        fprintf('  %s\n', name);
    end
end

%% List components in key categories
categories_to_explore = {
    'Pumps & Motors'
    'Valves & Orifices'
    'Actuators'
    'Pipes & Fittings'
    'Tanks & Accumulators'
    'Utilities'
};

for cat_idx = 1:length(categories_to_explore)
    cat_name = categories_to_explore{cat_idx};
    cat_path = [il_path '/' cat_name];
    
    fprintf('\n\nComponents in %s:\n', cat_name);
    fprintf('----------------------------------------\n');
    
    try
        cat_subsys = find_system(cat_path, 'SearchDepth', 1, 'BlockType', 'SubSystem');
        
        if length(cat_subsys) > 1
            for i = 2:length(cat_subsys)  % Skip first (parent)
                [~, name] = fileparts(cat_subsys{i});
                fprintf('  %s\n', name);
            end
        else
            fprintf('  (No direct components - may have subcategories)\n');
            
            % Check for subcategories
            subcat_subsys = find_system(cat_path, 'SearchDepth', 1);
            fprintf('  Subcategories found:\n');
            for i = 1:length(subcat_subsys)
                [~, name] = fileparts(subcat_subsys{i});
                if ~strcmp(name, cat_name)
                    fprintf('    - %s\n', name);
                end
            end
        end
    catch ME
        fprintf('  ✗ Error: %s\n', ME.message);
    end
end

fprintf('\n\n=== Usage ===\n');
fprintf('Use these paths in add_block():\n');
fprintf('add_block(''SimscapeFluids_lib/Isothermal Liquid/CATEGORY/BlockName'', ...)\n');

