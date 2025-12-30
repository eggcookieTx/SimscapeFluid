%% SIMSCAPE DOMAIN LIBRARY EXPLORER
%  Generalized script to discover and display all available blocks in any Simscape domain
%
%  METHODOLOGY:
%  This script uses recursive find_system() calls to automatically explore the 
%  library structure of Simscape Foundation Library and domain-specific libraries
%  (Isothermal Liquid, Thermal Liquid, Electrical, Mechanical, Pneumatics, etc.)
%  
%  Rather than relying on static documentation paths that may be outdated, this
%  script discovers the actual library structure by querying MATLAB directly.
%  
%  USAGE:
%  explore_simscape_domain()           % Interactive mode - prompts for domain
%  explore_simscape_domain('Isothermal Liquid')  % Direct domain input
%  
%  INPUTS:
%  domain_name (optional, string): Name of Simscape domain or 'Foundation Library'
%                                   Examples: 'Isothermal Liquid', 'Thermal Liquid',
%                                   'Electrical', 'Mechanical', 'Pneumatics'
%
%  OUTPUT: 
%  Displays organized category listing with all block names and library paths.
%  No files created - results shown in command window for user reference.
%
%  AUTHOR: MATLAB Script (Automated)
%  MODIFIED: 2025-12-30
%  VERSION: 1.0

function explore_simscape_domain(domain_name)
    
    % If no domain specified, prompt user
    if nargin < 1 || isempty(domain_name)
        domain_name = input_domain_selection();
    end
    
    % Ensure domain name is character vector or string
    if isstring(domain_name)
        domain_name = char(domain_name);
    end
    
    fprintf('\n%s\n', repmat('=', 1, 80));
    fprintf('SIMSCAPE DOMAIN LIBRARY EXPLORER\n');
    fprintf('Domain: %s\n', domain_name);
    fprintf('%s\n\n', repmat('=', 1, 80));
    
    % Determine which library root to use and validate domain
    if strcmpi(domain_name, 'Foundation Library')
        explore_foundation_library();
    else
        % Explore domain-specific library
        explore_simscape_fluids_domain(domain_name);
        
        % Also show relevant Foundation Library blocks (sensors, converters)
        fprintf('\n%s\n', repmat('=', 1, 80));
        fprintf('FOUNDATION LIBRARY - Sensors & Physical Signal Components\n');
        fprintf('(Available for use with %s domain)\n', domain_name);
        fprintf('%s\n\n', repmat('=', 1, 80));
        explore_foundation_library();
    end
    
    fprintf('%s\n', repmat('=', 1, 80));
    fprintf('Discovery complete. Use block paths for add_block() in model generation scripts.\n');
    fprintf('%s\n\n', repmat('=', 1, 80));
    
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
                [~, name] = fileparts(item);
                
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
    fprintf('SIMSCAPE DOMAIN LIBRARY EXPLORER - Domain Selection\n');
    fprintf('%s\n\n', repmat('=', 1, 80));
    
    available_domains = {
        'Isothermal Liquid'
        'Thermal Liquid'
        'Pneumatics'
        'Two-Phase Fluid'
        'Moist Air'
        'Gas'
        'Foundation Library'
    };
    
    fprintf('Available Simscape domains:\n\n');
    for i = 1:length(available_domains)
        fprintf('  %d. %s\n', i, available_domains{i});
    end
    
    fprintf('\nEnter domain number (1-%d) or domain name: ', length(available_domains));
    user_input = input('', 's');
    
    % Try to parse as number first
    choice_num = str2double(user_input);
    
    if ~isnan(choice_num) && choice_num >= 1 && choice_num <= length(available_domains)
        domain_name = available_domains{choice_num};
    elseif any(strcmpi(user_input, available_domains))
        domain_name = user_input;
    else
        fprintf('ERROR: Invalid selection. Using Isothermal Liquid.\n');
        domain_name = 'Isothermal Liquid';
    end
    
    fprintf('\nSelected: %s\n', domain_name);
    
end
