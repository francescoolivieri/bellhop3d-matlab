% ssp_estimation_main.m
clc
close all;

clean_files();

% Define estimate settings ------------------------------------------------

% Number of iterations
N = 10;

% Note: mu/Sigma for ssp_grid, taken from CTD data
data.th_names   = {'ssp_grid'};  % Parameters to estimate
data.Sigma_rr   = 1^2;            % filter assumed noise var

% __ init the data structure __


% Setup the two environments ----------------------------------------------
% True world
data.sim_true = uw.Simulation();

% Estimation world
data.sim_est = uw.Simulation();
data.sim_est.params.setEstimationParameterNames(data.th_names); 
data.sim_est.params.update(data.th_est, data.th_names);

% SSP Estimator setup -----------------------------------------------------
% Initialize GP model for estimation
config.ell_h = 400;    % horizontal correlation length (m)
config.ell_v = 20;     % vertical correlation length (m)
config.sigma_f = 1.0;   % Prior std dev of the SSP field (m/s)

% Likelihood Noise
config.tl_noise_std = 2.; % measurement noise
config.filename = data.sim_est.settings.filename;

% MCMC Sample Parameters
% Should tune these
config.mcmc_iterations = 100; % Total steps in the MCMC chain (more the better)
config.mcmc_burn_in = 0;      % Steps to discard to let the chain converge
config.proposal_std = 0.05;   % Scales the size of MCMC proposal steps.


% SSP Esimator Initialization ---------------------------------------------
% Create an instance of the class.
data.ssp_estimator = SSPGaussianProcessMCMC(config);  
data.estimated_params.set('ssp_grid', data.ssp_estimator.posterior_mean_ssp);


pos_check = [0.5 1 20];
before = data.sim_true.computeTL(pos_check);
fprintf("BEGINNING TL at (%.2f %.2f %.2f) difference: %f \n", pos_check, sum(abs(before - data.sim_est.computeTL(pos_check)), 'all'));

% Main estimation loop
for iter = 1:s.N
    % 1. Choose next measurement location
    data = pos_next_measurement(data, s);
    
    % Get current position (fix for undefined pos variable)
    idx = find(isfinite(data.x), 1, 'last');
    current_pos = [data.x(idx), data.y(idx), data.z(idx)];
    
    % 2. Take measurement (simulate using true SSP)
    measurement = forward_model(data.true_params, current_pos, s);
    
    % 3. Update GP with sophisticated inversion
    data.ssp_estimator.update(current_pos, measurement, data.estimated_params);
    
    % 4. Generate SSP file for acoustic model (for future forward models)
    data.ssp_estimator.writeSSPFile();
                
    
    % 5. Update estimated parameters with current SSP grid
    data.estimated_params.set('ssp_grid', data.ssp_estimator.posterior_mean_ssp);
    
    after = forward_model(data.estimated_params, [0.5 1 20], s);

    fprintf("Difference at iteration %d at (%.2f %.2f %.2f) : %f \n", pos_check, sum(abs(before - data.sim_est.computeTL(pos_check)), 'all'));

end

fprintf("Difference: %f \n", sum(abs(before - after), 'all'));


% --- Get the Estimated SSP ---
% This is your best guess for the current sound speed profile
estimated_ssp = data.ssp_estimator.posterior_mean_ssp;

% --- Get the Uncertainty ---
% This is the standard deviation at each grid point, indicating where
% the model is most and least certain.
ssp_uncertainty = data.ssp_estimator.getUncertaintyGrid();

% --- Visualize the Results ---
% For example, plot a vertical slice at a specific x, y location
figure;
subplot(1, 2, 1);
z_coords = data.ssp_estimator.grid_z;
% Assuming you want to plot the slice at the first x and y grid points
ssp_slice = squeeze(estimated_ssp(1, 1, :));
plot(ssp_slice, z_coords);
set(gca, 'YDir','reverse');
xlabel('Sound Speed (m/s)');
ylabel('Depth (m)');
title('Posterior Mean SSP Slice');
grid on;

subplot(1, 2, 2);
uncertainty_slice = squeeze(ssp_uncertainty(1, 1, :));
plot(uncertainty_slice, z_coords);
set(gca, 'YDir','reverse');
xlabel('Uncertainty (std dev, m/s)');
ylabel('Depth (m)');
title('Posterior Uncertainty');
grid on;


% --- Save the Final SSP for Bellhop ---
% You can now write the final, estimated SSP to a file for other uses.
ssp_estimator.writeSSPFile('final_estimated_ssp.ssp');