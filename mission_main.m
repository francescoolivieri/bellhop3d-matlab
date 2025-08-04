clc
close all;

% Define parameters to estimate
params.names = {'sound_speed_sediment', 'sound_speed_sediment'};  % Parameters to estimate
params.mu = [1600; 1700];                                 % Prior means
params.Sigma = diag([20 40].^2);                        % Prior covariances

% Setup the simulation environment with custom parameters
[data, s, sceneFigure] = setupUnderwaterSimulation(...
    'Parameters', params, ...
    'Units', 'km', ...
    'ExtraOutput', false);


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

    % Display result
    plot_result(data, s);
    
end
