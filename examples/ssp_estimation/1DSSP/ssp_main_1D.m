% ssp_main_1D.m
clc
close all;

clean_files();

% Define estimate settings ------------------------------------------------

sim = uw.Simulation();
generateSSP1D(sim.settings);


% Number of iterations
N = 1;

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
config.ell_h = +inf;     % enforce horizontal constancy (1-D SSP)
config.ell_v = 50;      % vertical correlation length (m)
config.sigma_f = 1.;   % Prior std dev of the SSP field (m/s)

% Likelihood Noise
config.tl_noise_std = 0.5; % measurement noise (matches computeTL without added noise)

% MCMC Sample Parameters (pCN uses proposal_std as beta)
config.mcmc_iterations = 10;
config.mcmc_burn_in    = 5;
config.proposal_std    = 0.5;   % pCN beta (target ~25-35% acceptance)


% SSP Esimator Initialization ---------------------------------------------
% Create an instance of the class.
ssp_estimator = SSPGP_1D(config);  
sim_est.params.set('ssp_grid', ssp_estimator.posterior_mean_ssp);


pos_check = [0.5 1 20];
before = sim_true.computeTL(pos_check);
fprintf("BEGINNING TL at (%.2f %.2f %.2f) difference: %f \n", pos_check, sum(abs(before - sim_est.computeTL(pos_check)), 'all'));

data.start_ssp  = ssp_estimator.posterior_mean_ssp;

% Main estimation loop ----------------------------------------------------

for iter = 1:N
    % 1. Choose next measurement location using Sensor strategy
    sim_true.sensor.step();
    
    % 2. Take measurement (simulate using true SSP)
    tl_measurement = sim_true.computeTL();
    ssp_measurement = sim_true.sampleSoundSpeed();

    % 3. Update GP with inversion (updates also simulation)
    ssp_estimator.update(sim_true.sensor.pos, tl_measurement, sim_est, ssp_measurement);

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
ssp_est_final_plots(data, data.sim_true.settings, 'results/plots');
