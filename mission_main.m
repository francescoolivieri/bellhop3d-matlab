clc
clf

% Define parameters to estimate
params.names = {'sound_speed_sediment', 'sound_speed_sediment'};  % Parameters to estimate
params.mu = [1600; 1700];                                 % Prior means
params.Sigma = diag([20 20].^2);                        % Prior covariances

% Setup the simulation environment with custom parameters
[data, s, sceneFigure] = setupUnderwaterSimulation(...
    'Parameters', params, ...
    'Units', 'km', ...
    'ExtraOutput', false);

% % Display parameter information
% fprintf('\n=== Parameter Configuration ===\n');
% fprintf('Parameters being estimated: %s\n', strjoin(s.estimation_param_names, ', '));
% fprintf('\nTrue parameter values:\n');
% for i = 1:length(s.estimation_param_names)
%     param_name = s.estimation_param_names{i};
%     true_val = getParameterValue(data, param_name, false);
%     est_val = getParameterValue(data, param_name, true);
%     fprintf('  %s: true=%.4f, initial_estimate=%.4f\n', param_name, true_val, est_val);
% end
% 
% fprintf('\nAll available parameters in the model:\n');
% param_keys = keys(data.true_params);
% for i = 1:length(param_keys)
%     param_name = param_keys{i};
%     value = data.true_params(param_name);
%     fprintf('  %s: %.4f\n', param_name, value);
% end

% Main simulation loop
for n=2:s.N
    % Print state
    fprintf('\n=== Iteration nr %d ===\n', n)

    % Get action
    tic
    data = pos_next_measurement(data, s);
    toc

    % Take measurement
    data = generate_data(data, s);

    % Update estimate
    data = ukf(data, s);
    
    % % Update parameter estimates in the map (this would be done in ukf function)
    % % For demonstration, showing how to update estimates:
    % if isfield(data, 'th_est')
    %     data = updateParameterEstimates(data, s, data.th_est);
    % end

    % Display result
    plot_result(data, s);
    
    % Display current parameter estimates
    fprintf('Current parameter estimates:\n');
    for i = 1:length(s.estimation_param_names)
        param_name = s.estimation_param_names{i};
        true_val = getParameterValue(data, param_name, false);
        est_val = getParameterValue(data, param_name, true);
        error_val = abs(true_val - est_val);
        fprintf('  %s: estimate=%.4f, true=%.4f, error=%.4f\n', ...
            param_name, est_val, true_val, error_val);
    end
end

% Commented out UAV mission code preserved for future use
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