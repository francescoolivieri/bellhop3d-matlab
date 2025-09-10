% ssp_est_main  SSP field estimation demo using GP + MCMC.
clc
close all;

clean_files();

% Define estimate settings ------------------------------------------------

% Number of iterations
N = 2;

% Note: mu/Sigma for ssp_grid, taken from CTD data
data.th_names   = {'ssp_grid'};  % Parameters to estimate


% Setup the two environments ----------------------------------------------
% True world
sim_true = uw.Simulation();

% Estimation world
sim_est = uw.Simulation();
sim_est.params.setEstimationParameterNames(data.th_names); 


% Configure a simple default strategy for SSP example
sim_true.sensor.setStrategy("lawnmower");

% SSP Estimator setup -----------------------------------------------------
% Initialize GP model for estimation
config.ell_h = 400;    % horizontal correlation length (m)
config.ell_v = 20;     % vertical correlation length (m)
config.sigma_f = 1.0;   % Prior std dev of the SSP field (m/s)

% Likelihood Noise
config.tl_noise_std = 2.; % measurement noise

% MCMC Sample Parameters
% Should tune these
config.mcmc_iterations = 10; % Total steps in the MCMC chain (more the better)
config.mcmc_burn_in = 3;      % Steps to discard to let the chain converge
config.proposal_std = 0.05;   % Scales the size of MCMC proposal steps.


% SSP Esimator Initialization ---------------------------------------------
% Create an instance of the class.
ssp_estimator = SSPGaussianProcessMCMC(config);  
sim_est.params.set('ssp_grid', ssp_estimator.posterior_mean_ssp);


pos_check = [0.5 1 20];
before = sim_true.computeTL(pos_check);
fprintf("BEGINNING TL at (%.2f %.2f %.2f) difference: %f \n", pos_check, sum(abs(before - sim_est.computeTL(pos_check))));

data.start_ssp  = ssp_estimator.posterior_mean_ssp;

% Main estimation loop ----------------------------------------------------

for iter = 1:N
    % 1. Choose next measurement location using Sensor strategy
    sim_true.sensor.step();
    
    % 2. Take measurement (using true SSP)
    measurement = sim_true.computeTL();
    
    % 3. Update GP with inversion (updates also the simulation)
    ssp_estimator.update(sim_true.sensor.pos, measurement, sim_est);

    % Check status
    after = sim_est.computeTL(pos_check);
    fprintf("Difference at iteration %d at (%.2f %.2f %.2f) : %f \n", iter, pos_check, sum(abs(before - after), 'all'));

end

fprintf("Difference: %f \n", sum(abs(before - after), 'all'));


% Add path info
data.x = sim_true.sensor.path(:, 1);
data.y = sim_true.sensor.path(:, 2);
data.z = sim_true.sensor.path(:, 3);

data.sim_true = sim_true;
data.sim_est = sim_est;
data.ssp_estimator = ssp_estimator;

% Final plots
ssp_est_final_plots(data, sim_true.settings, 'results/plots');