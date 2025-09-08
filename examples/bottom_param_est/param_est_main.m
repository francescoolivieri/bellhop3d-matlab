clc
close all;

clean_files();

% Define estimate settings ------------------------------------------------

% Number of iterations
N = 8;

% Note: names and according values must be in the SAME order
data.th_names   = {'sound_speed_sediment'};  % Parameters to estimate
data.th_est = [1650];              % Prior means
data.Sigma_est = diag([20].^2);     % Prior covariances
data.Sigma_rr       = 1^2;              % Filter assumed noise var

% Pick ground truth from the prob. distribution
data.th = data.th_est + chol(data.Sigma_est,'lower')*randn(size(data.th_est));

% Setup the two environments ----------------------------------------------
% True world
sim_true = uw.Simulation();
sim_true.params.update(data.th , data.th_names);

% Estimation world
sim_est = uw.Simulation();
sim_est.params.setEstimationParameterNames(data.th_names); 
sim_est.params.update(data.th_est, data.th_names);

% Main simulation loop ----------------------------------------------------
% Initialize data structure
data = init_filter(data, sim_true.settings, N);

% Configure sensor moving strategy 
sim_true.sensor.setStrategy("lawnmower");

for n=2:N
    % Print state
    fprintf('\n=== Iteration nr %d ===\n', n)

    % Build estimation state for IPP (used by some strategies)
    estimation_state = struct( ...
        'sim_est', sim_est, ...
        'th_est', data.th_est(:, n-1), ...
        'Sigma_est', data.Sigma_est(:, :, n-1), ...
        'Sigma_rr', data.Sigma_rr);

    % Execute configured strategy
    sim_true.sensor.step(estimation_state);

    % Take measurement from real world
    data.m(n-1) = sim_true.computeTLWithNoise();

    % Take measurement from real world
    % data = generate_data(data);

    % Update estimate
    data = ukf(data, sim_est, data.m(n-1), sim_true.sensor.pos);

    % Display result
    plot_results(data, sim_true, sim_est);
    
end

% Add path info
data.x = sim_true.sensor.path(:, 1);
data.y = sim_true.sensor.path(:, 2);
data.z = sim_true.sensor.path(:, 3);

bottom_est_final_plots(data, sim_est.settings, "results/param_est_main")