%% Diagnose Block Port Indices
% Simpler approach: use port indices instead of names

modelName = 'SimpleHydraulicSystem';
modelPath = '../../models/simscape/SimpleHydraulicSystem.slx';

open_system(modelPath);

fprintf('\n%s\n', repmat('=', 1, 80));
fprintf('SIMSCAPE BLOCK PORT INDICES\n');
fprintf('%s\n\n', repmat('=', 1, 80));

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

for b = 1:length(blocks)
    block_name = blocks{b};
    block_path = [modelName '/' block_name];
    
    fprintf('[%s]\n', block_name);
    
    try
        % Get port handles
        handles = get_param(block_path, 'PortHandles');
        
        if isstruct(handles) && isfield(handles, 'Inport')
            fprintf('  Inports: %d\n', length(handles.Inport));
        end
        if isstruct(handles) && isfield(handles, 'Outport')
            fprintf('  Outports: %d\n', length(handles.Outport));
        end
        
        % For Simscape blocks, list in/out ports
        inports = find_system(block_path, 'SearchDepth', 1, 'BlockType', 'Inport');
        outports = find_system(block_path, 'SearchDepth', 1, 'BlockType', 'Outport');
        
        if ~isempty(inports)
            fprintf('  Input port labels:\n');
            for i = 1:length(inports)
                port_label = get_param(inports{i}, 'Name');
                fprintf('    Port %d: %s\n', i, port_label);
            end
        end
        
        if ~isempty(outports)
            fprintf('  Output port labels:\n');
            for i = 1:length(outports)
                port_label = get_param(outports{i}, 'Name');
                fprintf('    Port %d: %s\n', i, port_label);
            end
        end
        
    catch err
        fprintf('  Error: %s\n', err.message);
    end
    
    fprintf('\n');
end

fprintf('%s\n\n', repmat('=', 1, 80));

close_system(modelPath, 0);
