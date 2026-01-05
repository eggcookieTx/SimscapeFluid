%% Export simlog data to Unreal playback JSON
% Purpose: Load the most recent simlog MAT produced by run_and_log_simulation.m and
% export a JSON time series for Unreal offline playback (no UDP). Keeps all
% available pressures/flows plus cylinder mass flows and rod velocity.
%
% Output: data/processed/unreal_playback.json
% Schema per sample:
% {
%   "t": <seconds>,
%   "pressure": [pump_out, relief_in, relief_out, vent_in, vent_out, dir_P, dir_T, dir_A, dir_B, cyl_cap, cyl_rod, check_in, check_out, restrict_in, restrict_out, filter_in, filter_out, tank_in],
%   "flow": [pump_out, relief_in, vent_in, dir_P, dir_T, dir_A, dir_B, check_in, restrict_in, filter_in, tank_in],
%   "massFlow": [cyl_cap_mdot, cyl_rod_mdot],
%   "rod": {"vel": <m/s>}
% }
% Units: Pa, m^3/s, kg/s, m/s

clear; clc;

%% Paths
processedDir = fullfile('..', '..', 'data', 'processed');
if ~exist(processedDir, 'dir')
    error('Processed data folder not found: %s', processedDir);
end

%% Locate latest simlog MAT
files = dir(fullfile(processedDir, 'simlog_data_*.mat'));
if isempty(files)
    error('No simlog_data_*.mat found in %s. Run run_and_log_simulation.m first.', processedDir);
end
[~, idx] = max([files.datenum]);
matFile = fullfile(processedDir, files(idx).name);
fprintf('Loading %s\n', matFile);

loaded = load(matFile, 'data');
if ~isfield(loaded, 'data')
    error('Expected variable "data" not found in %s', matFile);
end
d = loaded.data;

%% Helper for safe extraction
getOrEmpty = @(s, path, n) trygetfill(s, path, n);

% Time
if ~isfield(d, 'time')
    error('data.time missing');
end
t = d.time(:);
num = numel(t);

%% Build arrays (use empty if missing)
pressure = zeros(num, 18);
flow = zeros(num, 11);
massFlow = zeros(num, 2);
rodVel = zeros(num, 1);


pressure(:, 1)  = getOrEmpty(d, {'pump','outlet','pressure'}, num);       % pump_out
pressure(:, 2)  = getOrEmpty(d, {'relief','inlet','pressure'}, num);      % relief_in
pressure(:, 3)  = getOrEmpty(d, {'relief','outlet','pressure'}, num);     % relief_out
pressure(:, 4)  = getOrEmpty(d, {'vent','inlet','pressure'}, num);        % vent_in
pressure(:, 5)  = getOrEmpty(d, {'vent','outlet','pressure'}, num);       % vent_out
pressure(:, 6)  = getOrEmpty(d, {'directional','pump','pressure'}, num);  % dir_P
pressure(:, 7)  = getOrEmpty(d, {'directional','tank','pressure'}, num);  % dir_T
pressure(:, 8)  = getOrEmpty(d, {'directional','capEnd','pressure'}, num);% dir_A
pressure(:, 9)  = getOrEmpty(d, {'directional','rodEnd','pressure'}, num);% dir_B
pressure(:, 10) = getOrEmpty(d, {'cylinder','capEnd','pressure'}, num);   % cyl_cap
pressure(:, 11) = getOrEmpty(d, {'cylinder','rodEnd','pressure'}, num);   % cyl_rod
pressure(:, 12) = getOrEmpty(d, {'checkValve','inlet','pressure'}, num);  % check_in
pressure(:, 13) = getOrEmpty(d, {'checkValve','outlet','pressure'}, num); % check_out
pressure(:, 14) = getOrEmpty(d, {'flowRestriction','inlet','pressure'}, num);  % restrict_in
pressure(:, 15) = getOrEmpty(d, {'flowRestriction','outlet','pressure'}, num); % restrict_out
pressure(:, 16) = getOrEmpty(d, {'filter','inlet','pressure'}, num);      % filter_in
pressure(:, 17) = getOrEmpty(d, {'filter','outlet','pressure'}, num);     % filter_out
pressure(:, 18) = getOrEmpty(d, {'tank','inlet','pressure'}, num);        % tank_in

flow(:, 1)  = getOrEmpty(d, {'pump','outlet','flow'}, num);
flow(:, 2)  = getOrEmpty(d, {'relief','inlet','flow'}, num);
flow(:, 3)  = getOrEmpty(d, {'vent','inlet','flow'}, num);
flow(:, 4)  = getOrEmpty(d, {'directional','pump','flow'}, num);
flow(:, 5)  = getOrEmpty(d, {'directional','tank','flow'}, num);
flow(:, 6)  = getOrEmpty(d, {'directional','capEnd','flow'}, num);
flow(:, 7)  = getOrEmpty(d, {'directional','rodEnd','flow'}, num);
flow(:, 8)  = getOrEmpty(d, {'checkValve','inlet','flow'}, num);
flow(:, 9)  = getOrEmpty(d, {'flowRestriction','inlet','flow'}, num);
flow(:, 10) = getOrEmpty(d, {'filter','inlet','flow'}, num);
flow(:, 11) = getOrEmpty(d, {'tank','inlet','flow'}, num);

massFlow(:, 1) = getOrEmpty(d, {'cylinder','capEnd','massFlow'}, num);
massFlow(:, 2) = getOrEmpty(d, {'cylinder','rodEnd','massFlow'}, num);

rodVel = getOrEmpty(d, {'cylinder','rod','velocity'}, num);

% Validate lengths
validateVector = @(v, name) assert(numel(v)==num, 'Length mismatch for %s', name);
validateVector(t, 'time');
validateVector(pressure(:,1), 'pressure');

%% Build struct array for JSON
frames(num,1) = struct('t', 0, 'pressure', [], 'flow', [], 'massFlow', [], 'rod', struct());
for i = 1:num
    frames(i).t = t(i);
    frames(i).pressure = pressure(i, :);
    frames(i).flow = flow(i, :);
    frames(i).massFlow = massFlow(i, :);
    frames(i).rod = struct('vel', rodVel(i));
end

jsonText = jsonencode(frames);

%% Save JSON
outputFile = fullfile(processedDir, 'unreal_playback.json');
fid = fopen(outputFile, 'w');
if fid == -1
    error('Cannot open %s for writing', outputFile);
end
fwrite(fid, jsonText, 'char');
fclose(fid);

info = dir(outputFile);
fprintf('✓ Wrote %s (%.2f MB)\n', outputFile, info.bytes/1e6);

%% Helper function

function v = trygetfill(s, path, n)
    v = [];
    try
        for k = 1:numel(path)
            s = s.(path{k});
        end
        v = s;
    catch
        v = zeros(n,1);
    end
    if isempty(v)
        v = zeros(n,1);
    end
    if isrow(v)
        v = v(:);
    end
    if numel(v) ~= n
        v = zeros(n,1);
    end
end
