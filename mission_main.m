clc

% Get all items in the current directory
folder_contents = dir;

% Loop through each item
for item = folder_contents' % Transpose to loop through items correctly

    % Skip if the item is a directory
    if item.isdir
        continue;
    end

    % Get the filename without its extension
    [~, file_name_only, ~] = fileparts(item.name);

    % Check if the filename is exactly 7 digits using a regular expression
    if ~isempty(regexp(file_name_only, '^\d{7}$', 'once'))

        % If it matches, delete the file and notify the user
        fprintf('Deleting file: %s\n', item.name);
        delete(item.name);

    end
end


global units
units = 'km';

% Load the simulation settings
s = get_sim_settings();

% Draw random parameter according to prior distribution
data.th = s.mu_th+chol(s.Sigma_th,'lower')*randn(size(s.mu_th));

% Create chosen scenario for the simulation
[scene, sceneFigure] = scenarioBuilder(s);

% Generate a .ssp file if needed
if s.sim_use_ssp_file
    generateSSP3D(s, scene);
end

% Generate .env file (TRUE ENV)
writeENV3D(s.bellhop_file_name + ".env", s, data.th); 
fprintf('Wrote ENV file.\n');

% Generate .bty file 
writeBTY3D(s.bellhop_file_name + ".bty", scene, s);

% Run bellhop and draw environment
draw_true_env(s, scene);

%% Testing shd plot functions (not working)
% figure;
% plotshdpol( s.bellhop_file_name + ".shd",  0, 0, 10 )
%%

% Initialize filter 
data = init_filter(data,s);

% Initial Waypoints
%InitialWaypoints = [s.InitialPosition; data.x(1) data.y(1) -7];

for n=1:3
        
    % Print state
    fprintf('Iteration nr %d \n', n)

    % Get action
    data = pos_next_measurement(data, s);

    % Take measurement
    data = generate_data(data, s);

    % Update estimate
    data = ukf(data, s);

    % Display result
    plot_result(data, s);
end


% mission = uavMission(HomeLocation=[s.InitialPosition], Frame="LocalENU");
% addTakeoff(mission, 20);
% 
% for i=1:3    
%     addWaypoint(mission, [data.x(i) data.y(i) data.z(i)]);
% end
% 
% addWaypoint(mission, mission.HomeLocation);
% addLand(mission, mission.HomeLocation);
% 
% % show mission at the end, in the same figure as the scenario
% figure(sceneFigure)
% show(mission)
% hold on