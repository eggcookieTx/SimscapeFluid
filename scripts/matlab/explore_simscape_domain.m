%% SIMSCAPE DOMAIN LIBRARY EXPLORER
%  Generalized script to discover and display all available blocks in any Simscape domain or library
%
%  METHODOLOGY:
%  This script uses recursive find_system() calls to automatically explore the 
%  library structure of ALL available Simscape libraries, including:
%  - SimscapeFluids_lib (Isothermal Liquid, Thermal Liquid, Pneumatics, etc.)
%  - Foundation Library (fl_lib)
%  - Battery Library (batt_lib)
%  - Driveline Library (sdl_lib)
%  - Electrical Library (elec_lib)
%  - And any other installed Simscape libraries
%  
%  Rather than relying on static documentation paths that may be outdated, this
%  script discovers the actual library structure by querying MATLAB directly.
%  
%  USAGE:
%  explore_simscape_domain()                    % Interactive mode - prompts for domain/library
%  explore_simscape_domain('Isothermal Liquid') % Specific domain in SimscapeFluids_lib
%  explore_simscape_domain('batt_lib')          % Specific library
%  explore_simscape_domain('Libraries')         % List all available Simscape libraries
%  explore_simscape_domain('All')               % Discover and display all libraries
%  
%  INPUTS:
%  domain_name (optional, string): 
%    - Domain name: 'Isothermal Liquid', 'Thermal Liquid', 'Pneumatics', 'Mechanical', etc.
%    - Library name: 'batt_lib', 'sdl_lib', 'elec_lib', 'fl_lib', etc.
%    - Special: 'Libraries' to list all available, 'All' to explore all
%    - 'Foundation Library' for fl_lib
%
%  OUTPUT: 
%  Displays organized hierarchy with all block names and library paths.
%  No files created - results shown in command window for user reference.
%
%  AUTHOR: MATLAB Script (Automated)
%  MODIFIED: 2025-12-30
%  VERSION: 2.0 - Universal Simscape Library Explorer

function explore_simscape_domain(domain_name)
    
    % If no domain specified, prompt user
    if nargin < 1 || isempty(domain_name)
        domain_name = input_domain_selection();
    end
    
    % Ensure domain name is character vector or string
    if isstring(domain_name)
        domain_name = char(domain_name);
    end
    
    % Handle special commands
    if strcmpi(domain_name, 'Libraries')
        list_available_simscape_libraries();
        return
    elseif strcmpi(domain_name, 'All')
        explore_all_simscape_libraries();
        return
    end
    
    fprintf('\n%s\n', repmat('=', 1, 80));
    fprintf('SIMSCAPE DOMAIN EXPLORER\n');
    fprintf('Domain: %s\n', domain_name);
    fprintf('%s\n\n', repmat('=', 1, 80));
    
    % Map friendly domain names to libraries
    [lib_name, is_simscape_fluids] = map_domain_to_library(domain_name);
    
    if isempty(lib_name)
        fprintf('ERROR: Unknown domain ''%s''\n', domain_name);
        fprintf('Available domains: fluid, thermal, pneumatics, gas, mechanical, multibody, battery, driveline, electrical\n');
        return
    end
    
    % Explore the mapped library
    if is_simscape_fluids
        % For Simscape Fluids domains, use domain-specific exploration
        explore_simscape_fluids_domain(domain_name);
        
        % Also show Foundation Library blocks
        fprintf('\n%s\n', repmat('=', 1, 80));
        fprintf('FOUNDATION LIBRARY - Sensors & Physical Signal Components\n');
        fprintf('(Available for use with %s domain)\n', domain_name);
        fprintf('%s\n\n', repmat('=', 1, 80));
        explore_foundation_library();
    else
        % For other libraries, use generic exploration
        explore_simscape_library(lib_name);
    end
    
    fprintf('%s\n', repmat('=', 1, 80));
    fprintf('Discovery complete. Use block paths for add_block() in model generation scripts.\n');
    fprintf('%s\n\n', repmat('=', 1, 80));
    
end

%% MAP FRIENDLY DOMAIN NAMES TO LIBRARY NAMES
function [lib_name, is_simscape_fluids] = map_domain_to_library(domain_name)
    
    % Define mappings
    fluid_domains = {
        'isothermal liquid'
        'thermal liquid'
        'pneumatics'
        'two-phase fluid'
        'moist air'
        'gas'
    };
    
    domain_lower = lower(domain_name);
    
    % Check if it's a Simscape Fluids domain
    if any(strcmpi(domain_lower, fluid_domains))
        lib_name = 'SimscapeFluids_lib';
        is_simscape_fluids = true;
        return
    end
    
    % Check specific domain shortcuts
    switch domain_lower
        case 'fluid'
            lib_name = 'SimscapeFluids_lib';
            is_simscape_fluids = true;
        case 'mechanical'
            lib_name = 'fl_lib';  % Mechanical is in Foundation Library
            is_simscape_fluids = false;
        case 'multibody'
            lib_name = 'sm_lib';
            is_simscape_fluids = false;
        case 'battery'
            lib_name = 'batt_lib';
            is_simscape_fluids = false;
        case 'driveline'
            lib_name = 'sdl_lib';
            is_simscape_fluids = false;
        case 'electrical'
            lib_name = 'elec_lib';
            is_simscape_fluids = false;
        case 'foundation library'
            lib_name = 'fl_lib';
            is_simscape_fluids = false;
        otherwise
            % Try to use it as-is (might be a library name)
            lib_name = domain_name;
            is_simscape_fluids = strcmpi(domain_name, 'SimscapeFluids_lib');
    end
end

%% LIST ALL AVAILABLE SIMSCAPE LIBRARIES
function list_available_simscape_libraries()
    
    fprintf('\n%s\n', repmat('=', 1, 80));
    fprintf('AVAILABLE SIMSCAPE LIBRARIES\n');
    fprintf('%s\n\n', repmat('=', 1, 80));
    
    % Commonly available Simscape libraries
    potential_libs = {
        'SimscapeFluids_lib'        % Fluids (Isothermal Liquid, Thermal Liquid, etc.)
        'fl_lib'                    % Foundation Library (Sensors, converters, etc.)
        'batt_lib'                  % Battery Library
        'sdl_lib'                   % Driveline Library
        'elec_lib'                  % Electrical Library
        'sps_lib'                   % Power Systems (legacy)
        'sm_lib'                    % Multibody
        'driveline_lib'             % Alternative Driveline
        'electrical_lib'            % Alternative Electrical
        'battery_lib'               % Alternative Battery
    };
    
    available = {};
    
    for i = 1:length(potential_libs)
        lib = potential_libs{i};
        try
            items = find_system(lib, 'SearchDepth', 1);
            if ~isempty(items) && length(items) > 1
                available{end+1} = lib; %#ok<AGROW>
            end
        catch
            % Library not available
        end
    end
    
    if isempty(available)
        fprintf('No Simscape libraries found in current path.\n');
    else
        fprintf('Found %d Simscape libraries:\n\n', length(available));
        for i = 1:length(available)
            fprintf('  • %s\n', available{i});
        end
        fprintf('\nUsage: explore_simscape_domain(''%s'') to explore a library\n', available{1});
    end
    
    fprintf('\n%s\n\n', repmat('=', 1, 80));
end

%% EXPLORE ALL AVAILABLE SIMSCAPE LIBRARIES
function explore_all_simscape_libraries()
    
    fprintf('\n%s\n', repmat('=', 1, 80));
    fprintf('DISCOVERING ALL SIMSCAPE LIBRARIES\n');
    fprintf('%s\n\n', repmat('=', 1, 80));
    
    % Get list of available libraries
    potential_libs = {
        'SimscapeFluids_lib'
        'fl_lib'
        'batt_lib'
        'sdl_lib'
        'elec_lib'
        'sps_lib'
        'sm_lib'
    };
    
    for i = 1:length(potential_libs)
        lib = potential_libs{i};
        try
            items = find_system(lib, 'SearchDepth', 1);
            if ~isempty(items) && length(items) > 1
                fprintf('\n%s\n', repmat('=', 1, 80));
                fprintf('LIBRARY: %s\n', lib);
                fprintf('%s\n\n', repmat('=', 1, 80));
                
                % Explore this library
                if strcmpi(lib, 'SimscapeFluids_lib')
                    % For SimscapeFluids, explore domains
                    explore_all_fluids_domains();
                else
                    % Generic library exploration
                    explore_simscape_library(lib);
                end
            end
        catch
            % Library not available, skip
        end
    end
    
    fprintf('\n%s\n', repmat('=', 1, 80));
    fprintf('Discovery complete.\n');
    fprintf('%s\n\n', repmat('=', 1, 80));
end

%% EXPLORE ALL DOMAINS IN SIMSCAPE FLUIDS
function explore_all_fluids_domains()
    domains = {
        'Isothermal Liquid'
        'Thermal Liquid'
        'Pneumatics'
        'Two-Phase Fluid'
        'Moist Air'
        'Gas'
    };
    
    for d = 1:length(domains)
        domain = domains{d};
        fprintf('\n[DOMAIN] %s\n', domain);
        fprintf('%s\n\n', repmat('-', 1, 60));
        try
            explore_simscape_fluids_domain(domain);
        catch err
            fprintf('Error exploring %s: %s\n', domain, err.message);
        end
        fprintf('\n');
    end
end

%% EXPLORE A GENERIC SIMSCAPE LIBRARY
function explore_simscape_library(lib_name)
    
    % Try to load the library
    try
        load_system(lib_name);
    catch
        % May already be loaded
    end
    
    % Get top-level categories
    try
        categories = find_system(lib_name, 'SearchDepth', 1);
        categories(strcmpi(categories, lib_name)) = [];  % Remove root
    catch
        fprintf('Could not find library: %s\n', lib_name);
        return
    end
    
    if isempty(categories)
        fprintf('Library found but contains no categories.\n');
        return
    end
    
    % Sort categories
    [~, idx] = sort(categories);
    categories = categories(idx);
    
    % Display each category and its contents
    for c = 1:length(categories)
        cat_path = categories{c};
        [~, cat_name] = fileparts(cat_path);
        
        fprintf('[CATEGORY] %s\n', cat_name);
        fprintf('%s\n', repmat('-', 1, 60));
        
        % Get items in this category (2 levels deep to catch subcategories)
        try
            all_items = find_system(cat_path, 'SearchDepth', 2);
            all_items(strcmpi(all_items, cat_path)) = [];
            
            if isempty(all_items)
                fprintf('  (empty)\n\n');
                continue
            end
            
            % Get direct children (subcategories or blocks)
            direct_items = find_system(cat_path, 'SearchDepth', 1);
            direct_items(strcmpi(direct_items, cat_path)) = [];
            
            % Separate subcategories and blocks
            if ~isempty(direct_items)
                [~, idx2] = sort(direct_items);
                direct_items = direct_items(idx2);
                
                for d = 1:length(direct_items)
                    item_path = direct_items{d};
                    [~, item_name] = fileparts(item_path);
                    
                    % Get blocks in this subcategory
                    try
                        sub_items = find_system(item_path, 'SearchDepth', 1);
                        sub_items(strcmpi(sub_items, item_path)) = [];
                    catch
                        sub_items = {};
                    end
                    
                    if ~isempty(sub_items)
                        fprintf('  └─ %s\n', item_name);
                        [~, idx3] = sort(sub_items);
                        sub_items = sub_items(idx3);
                        
                        for b = 1:length(sub_items)
                            [~, block_name] = fileparts(sub_items{b});
                            full_path = strrep(sub_items{b}, filesep, '/');
                            fprintf('       • %s\n', block_name);
                            fprintf('         Path: %s\n', full_path);
                        end
                    else
                        % It's a block, not a subcategory
                        full_path = strrep(item_path, filesep, '/');
                        fprintf('  • %s\n', item_name);
                        fprintf('    Path: %s\n', full_path);
                    end
                end
            end
        catch
            fprintf('  (could not read contents)\n');
        end
        
        fprintf('\n');
    end
end

%% EXPLORE SIMSCAPE FLUIDS DOMAIN (Isothermal Liquid, Thermal Liquid, etc.)
function explore_simscape_fluids_domain(domain_name)
    
    % Build library root path: SimscapeFluids_lib/DomainName
    library_root = sprintf('SimscapeFluids_lib/%s', domain_name);
    
    % Load the Simscape Fluids library to ensure it's in the path
    try
        load_system('SimscapeFluids_lib');
    catch
        % Library may already be loaded, continue anyway
    end
    
    % Define categories for this domain
    categories = {
        'Pumps & Motors'
        'Valves & Orifices'
        'Actuators'
        'Pipes & Fittings'
        'Tanks & Accumulators'
        'Utilities'
    };
    
    % Explore each category
    for c = 1:length(categories)
        cat_name = categories{c};
        cat_path = sprintf('%s/%s', library_root, cat_name);
        
        fprintf('\n[CATEGORY] %s\n', cat_name);
        fprintf('%s\n', repmat('-', 1, 60));
        
        % Use recursive find_system to get all items in this category at all depths
        try
            all_items = find_system(cat_path, 'SearchDepth', 1);
        catch
            fprintf('  (category not found)\n');
            continue
        end
        
        % Filter to get only direct children (SearchDepth=1 results, excluding root)
        blocks = {};
        subcats = {};
        
        for i = 1:length(all_items)
            item = all_items{i};
            if ~strcmpi(item, cat_path)  % Exclude the category itself
                % Check if it's a subsystem (subcategory) or block
                try
                    type = get_param(item, 'BlockType');
                    if strcmpi(type, 'SubSystem')
                        subcats{end+1} = item; %#ok<AGROW>
                    else
                        blocks{end+1} = item; %#ok<AGROW>
                    end
                catch
                    % Couldn't determine type, might be a folder
                    subcats{end+1} = item; %#ok<AGROW>
                end
            end
        end
        
        % Display subcategories with their blocks
        if ~isempty(subcats)
            [~, idx] = sort(subcats);
            subcats = subcats(idx);
            
            for s = 1:length(subcats)
                subcat_path = subcats{s};
                [~, subcat_name] = fileparts(subcat_path);
                
                fprintf('  └─ %s\n', subcat_name);
                
                try
                    subcat_items = find_system(subcat_path, 'SearchDepth', 1);
                    subcat_blocks = {};
                    
                    for j = 1:length(subcat_items)
                        item = subcat_items{j};
                        if ~strcmpi(item, subcat_path)
                            subcat_blocks{end+1} = item; %#ok<AGROW>
                        end
                    end
                    
                    if ~isempty(subcat_blocks)
                        [~, idx2] = sort(subcat_blocks);
                        subcat_blocks = subcat_blocks(idx2);
                        
                        for b = 1:length(subcat_blocks)
                            [~, block_name] = fileparts(subcat_blocks{b});
                            full_lib_path = sprintf('SimscapeFluids_lib/%s', ...
                                strrep(subcat_blocks{b}, 'SimscapeFluids_lib/', ''));
                            fprintf('       • %s\n', block_name);
                            fprintf('         Path: %s\n', full_lib_path);
                        end
                    end
                catch
                    % Subcategory has no blocks
                end
            end
        end
        
        % Display any blocks at top level of category
        if ~isempty(blocks)
            if ~isempty(subcats)
                fprintf('\n');  % Add spacing if we already printed subcats
            end
            [~, idx] = sort(blocks);
            blocks = blocks(idx);
            
            for b = 1:length(blocks)
                [~, block_name] = fileparts(blocks{b});
                full_lib_path = sprintf('SimscapeFluids_lib/%s', ...
                    strrep(blocks{b}, 'SimscapeFluids_lib/', ''));
                fprintf('  • %s\n', block_name);
                fprintf('    Path: %s\n', full_lib_path);
            end
        end
        
        if isempty(blocks) && isempty(subcats)
            fprintf('  (no items found)\n');
        end
    end
    
end

%% EXPLORE FOUNDATION LIBRARY (Sensors, Converters, Physical Signals)
function explore_foundation_library()
    
    % Try both possible Foundation Library roots
    library_roots = {
        'fl_lib'  % Direct Foundation Library
        'nesl_utility/Simscape/Foundation Library'  % Via nesl_utility
    };
    
    found_lib = false;
    
    for lib_idx = 1:length(library_roots)
        library_root = library_roots{lib_idx};
        
        % Try to find categories in this library root
        try
            items = find_system(library_root, 'SearchDepth', 1);
            if ~isempty(items) && length(items) > 1  % More than just root
                found_lib = true;
                break
            end
        catch
            % Try next library root
        end
    end
    
    if ~found_lib
        % Load foundation library if not already loaded
        try
            load_system('fl_lib');
            library_root = 'fl_lib';
        catch
            try
                load_system('nesl_utility/Simscape/Foundation Library');
                library_root = 'nesl_utility/Simscape/Foundation Library';
            catch
                fprintf('  ERROR: Foundation Library not found\n');
                return
            end
        end
    end
    
    % Explore categories in Foundation Library
    try
        categories = find_system(library_root, 'SearchDepth', 1);
        categories(strcmpi(categories, library_root)) = [];  % Remove root
    catch
        fprintf('  (no categories found)\n');
        return
    end
    
    if isempty(categories)
        fprintf('  (no items found)\n');
        return
    end
    
    % Sort and display categories
    [~, idx] = sort(categories);
    categories = categories(idx);
    
    for c = 1:length(categories)
        cat_path = categories{c};
        [~, cat_name] = fileparts(cat_path);
        
        fprintf('[CATEGORY] %s\n', cat_name);
        fprintf('%s\n', repmat('-', 1, 60));
        
        % Find ALL blocks under this category (including subcategories)
        try
            all_blocks = find_system(cat_path, 'SearchDepth', 2);
            all_blocks(strcmpi(all_blocks, cat_path)) = [];  % Remove root
        catch
            all_blocks = {};
        end
        
        if isempty(all_blocks)
            fprintf('  (no blocks found)\n\n');
            continue
        end
        
        % Separate by depth/category for organized display
        direct_items = find_system(cat_path, 'SearchDepth', 1);
        direct_items(strcmpi(direct_items, cat_path)) = [];
        
        % If we have direct subcategories, show blocks organized by subcategory
        if ~isempty(direct_items)
            [~, idx2] = sort(direct_items);
            direct_items = direct_items(idx2);
            
            for d = 1:length(direct_items)
                subcat_path = direct_items{d};
                [~, subcat_name] = fileparts(subcat_path);
                
                % Get blocks in this subcategory
                try
                    subcat_blocks = find_system(subcat_path, 'SearchDepth', 1);
                    subcat_blocks(strcmpi(subcat_blocks, subcat_path)) = [];
                catch
                    subcat_blocks = {};
                end
                
                if ~isempty(subcat_blocks)
                    fprintf('  └─ %s\n', subcat_name);
                    [~, idx3] = sort(subcat_blocks);
                    subcat_blocks = subcat_blocks(idx3);
                    
                    for b = 1:length(subcat_blocks)
                        [~, block_name] = fileparts(subcat_blocks{b});
                        
                        % Build appropriate path
                        if strncmp(library_root, 'fl_lib', 6)
                            full_path = sprintf('fl_lib/%s', strrep(subcat_blocks{b}, 'fl_lib/', ''));
                        else
                            full_path = sprintf('nesl_utility/Simscape/Foundation Library/%s', ...
                                strrep(subcat_blocks{b}, 'nesl_utility/Simscape/Foundation Library/', ''));
                        end
                        
                        fprintf('       • %s\n', block_name);
                        fprintf('         Path: %s\n', full_path);
                    end
                end
            end
        else
            % No subcategories, show blocks at top level
            [~, idx2] = sort(all_blocks);
            all_blocks = all_blocks(idx2);
            
            for b = 1:length(all_blocks)
                [~, block_name] = fileparts(all_blocks{b});
                
                % Build appropriate path
                if strncmp(library_root, 'fl_lib', 6)
                    full_path = sprintf('fl_lib/%s', strrep(all_blocks{b}, 'fl_lib/', ''));
                else
                    full_path = sprintf('nesl_utility/Simscape/Foundation Library/%s', ...
                        strrep(all_blocks{b}, 'nesl_utility/Simscape/Foundation Library/', ''));
                end
                
                fprintf('  • %s\n', block_name);
                fprintf('    Path: %s\n', full_path);
            end
        end
        
        fprintf('\n');
    end
    
end

%% INTERACTIVE DOMAIN SELECTION
function domain_name = input_domain_selection()
    
    fprintf('\n%s\n', repmat('=', 1, 80));
    fprintf('SIMSCAPE DOMAIN EXPLORER - Domain Selection\n');
    fprintf('%s\n\n', repmat('=', 1, 80));
    
    available_domains = {
        'fluid'           % SimscapeFluids_lib
        'multibody'       % sm_lib
        'mechanical'      % fl_lib mechanical components
        'battery'         % batt_lib
        'driveline'       % sdl_lib
        'electrical'      % elec_lib
        'Libraries'       % List all available
        'All'             % Explore all
    };
    
    fprintf('Available domains:\n\n');
    for i = 1:length(available_domains)
        fprintf('  %d. %s\n', i, available_domains{i});
    end
    
    fprintf('\nAdditional options: You can also specify specific domains like:\n');
    fprintf('  - ''Isothermal Liquid'', ''Thermal Liquid'', ''Pneumatics'', ''Gas''\n');
    fprintf('  - ''Two-Phase Fluid'', ''Moist Air''\n\n');
    
    fprintf('Enter domain number (1-%d) or domain name: ', length(available_domains));
    user_input = input('', 's');
    
    % Try to parse as number first
    choice_num = str2double(user_input);
    
    if ~isnan(choice_num) && choice_num >= 1 && choice_num <= length(available_domains)
        domain_name = available_domains{choice_num};
    else
        domain_name = user_input;
    end
    
    fprintf('\nSelected: %s\n', domain_name);
    
end
