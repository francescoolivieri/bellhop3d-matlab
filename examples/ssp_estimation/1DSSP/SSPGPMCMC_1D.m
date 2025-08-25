classdef SSPGP_1D < handle
    % SSPGaussianProcessMCMC - Gaussian Process for 3D Sound Speed Profile
    % estimation using Markov Chain Monte Carlo (MCMC) methods.
    %
    % This class models the 3D SSP field as a Gaussian Process and uses a
    % forward acoustic model (Bellhop) within an MCMC framework to
    % find the posterior distribution of the SSP, conditioned on observed
    % Transmission Loss (TL) measurements. This avoids the fragile step of
    % inverting TL to a single sound speed value.

    properties (Access = public)
        % GP hyperparameters
        ell_h           % Horizontal correlation length (m)
        ell_v           % Vertical correlation length (m)
        sigma_f         % Signal standard deviation (m/s)

        % Likelihood parameters
        tl_noise_std    % Measurement noise of the TL sensor (dB)

        % MCMC parameters
        mcmc_iterations % Total MCMC iterations per update
        mcmc_burn_in    % Number of initial samples to discard
        proposal_std    % Standard deviation for the MCMC proposal step

        % Data storage
        X_obs           % Observed measurement positions [N x 3] (x, y, z)
        tl_obs          % Observed TL measurements [N x 1] (dB)

        % Grid for prediction
        grid_x          % x coordinates (km)
        grid_y          % y coordinates (km)
        grid_z          % z coordinates (m)
        X_grid          % Grid positions [M x 3]
        
        % Mean function (from CTD data)
        mean_func       % Function handle for prior mean

        % MCMC results
        ssp_samples     % Cell array of SSP grid samples from the posterior
        posterior_mean_ssp % The mean of the posterior SSP samples
        posterior_var_ssp  % The variance of the posterior SSP samples
    end

    properties (Access = private)
        K_prior         % Prior covariance matrix for the grid
        K_prior_chol    % Cholesky decomposition of the prior covariance
        mu_prior_grid   % Prior mean on the grid
        % Conditioned (two-stage) prior quantities
        K_cond_chol     % Cholesky of conditioned covariance (after SSP obs)
        mu_cond_grid    % Conditioned mean on the grid (after SSP obs)
        use_conditioned_prior logical = false
        % Stored SSP observations (optional)
        ssp_obs_pos     % [Ns x 3] positions (x,y in km, z in m)
        ssp_obs_val     % [Ns x 1] sound speed measurements (m/s)
        ssp_obs_noise_std (1,1) double = 0.5
    end

    methods
        function obj = new_SSPGPMCMC_1D(config)
            % Constructor
            % Input: config struct with fields:
            %   - ell_h, ell_v, sigma_f: GP hyperparameters
            %   - tl_noise_std: TL measurement noise (dB)
            %   - mcmc_iterations, mcmc_burn_in, proposal_std: MCMC params

            % --- GP and Likelihood Hyperparameters ---
            obj.ell_h = config.ell_h;
            obj.ell_v = config.ell_v;
            obj.sigma_f = config.sigma_f;
            obj.tl_noise_std = config.tl_noise_std;

            % --- MCMC Parameters ---
            obj.mcmc_iterations = config.mcmc_iterations;
            obj.mcmc_burn_in = config.mcmc_burn_in;
            obj.proposal_std = config.proposal_std;

            % --- Initialize Data and Grid ---
            obj.X_obs = [];
            obj.tl_obs = [];
            obj.ssp_samples = {};

            fprintf('Setting up prediction grid and prior...\n');
            obj.setupMeanFunction();
            obj.setupPredictionGrid();
            obj.computePriorCovariance();
            
            % Initialize the posterior with the prior
            obj.posterior_mean_ssp = reshape(obj.mu_prior_grid, [length(obj.grid_x), length(obj.grid_y), length(obj.grid_z)]);
            obj.posterior_var_ssp = obj.sigma_f^2 * ones(size(obj.posterior_mean_ssp));

            fprintf('Initialization complete.\n');
        end

        function update(obj, new_pos, new_tl_measurement, sim, ssp_value, ssp_noise_std)
            % Update the SSP estimate with new TL and optional direct SSP measurement.
            % This is a computationally intensive operation.
            %
            % Inputs:
            %   new_pos: [1 x 3] receiver position for the new measurement
            %   new_tl_measurement: scalar TL value (dB)
            %   sim: The Simulation object we are performing the SSP update on
            %   ssp_value (optional): scalar SSP (m/s) measured at new_pos
            %   ssp_noise_std (optional): std dev (m/s) for SSP measurement noise

            fprintf('\n--- Starting MCMC Update ---\n');
            fprintf('New TL at [%.1f, %.1f, %.1f]: %.1f dB\n', new_pos, new_tl_measurement);

            % Add new data to the observation set
            obj.X_obs = [obj.X_obs; new_pos];
            obj.tl_obs = [obj.tl_obs; new_tl_measurement];

            % If an SSP point measurement is provided, condition the GP prior
            if nargin >= 5 && ~isempty(ssp_value)
                if nargin >= 6 && ~isempty(ssp_noise_std)
                    obj.ssp_obs_noise_std = ssp_noise_std;
                end
                % Initialize containers if empty
                if isempty(obj.ssp_obs_pos), obj.ssp_obs_pos = zeros(0,3); end
                if isempty(obj.ssp_obs_val), obj.ssp_obs_val = zeros(0,1); end
                obj.ssp_obs_pos = [obj.ssp_obs_pos; new_pos];
                obj.ssp_obs_val = [obj.ssp_obs_val; ssp_value];
                obj.conditionOnSSPObservations();
                fprintf('Conditioned GP on %d SSP obs (noise std = %.3f m/s).\n', size(obj.ssp_obs_pos,1), obj.ssp_obs_noise_std);
            end

            % --- MCMC Initialization ---
            % Start the chain from the current posterior mean
            if obj.use_conditioned_prior && ~isempty(obj.mu_cond_grid)
                current_ssp_flat = obj.mu_cond_grid(:);
            else
                current_ssp_flat = obj.posterior_mean_ssp(:);
            end
            
            % Calculate the log posterior for the starting point
            %log_post_current = obj.calculate_log_posterior(current_ssp_flat, sim);

            obj.ssp_samples = cell(1, obj.mcmc_iterations);
            accepted_count = 0;

            fprintf('Running pCN sampler for %d iterations...\n', obj.mcmc_iterations);
            
            % --- pCN Sampler Loop (dimension-robust) ---
            beta = min(0.5, max(0.01, obj.proposal_std));
            % Start with current likelihood value
            log_like_current = obj.calculate_log_likelihood(current_ssp_flat, sim);
            for i = 1:obj.mcmc_iterations
                % Draw from the (possibly conditioned) prior using the Cholesky factor
                if obj.use_conditioned_prior && ~isempty(obj.K_cond_chol)
                    L = obj.K_cond_chol;
                    mu0 = obj.mu_cond_grid(:);
                else
                    L = obj.K_prior_chol;
                    mu0 = obj.mu_prior_grid(:);
                end
                eta = L' * randn(size(current_ssp_flat));
                % Centered pCN around mu0: operate on u = x - mu0
                u = current_ssp_flat - mu0;
                u_prop = sqrt(1 - beta^2) * u + beta * eta;
                proposed_ssp_flat = mu0 + u_prop;

                % Likelihood-only acceptance ratio
                log_like_proposed = obj.calculate_log_likelihood(proposed_ssp_flat, sim);
                if isfinite(log_like_proposed)
                    if log(rand()) < (log_like_proposed - log_like_current)
                        current_ssp_flat = proposed_ssp_flat;
                        log_like_current = log_like_proposed;
                        accepted_count = accepted_count + 1;
                    end
                end

                % Store the current sample
                obj.ssp_samples{i} = current_ssp_flat;

                if mod(i, 100) == 0
                    fprintf('  Iteration %d/%d, Acceptance Rate: %.2f%%\n', i, obj.mcmc_iterations, 100*accepted_count/i);
                end
            end
            
            fprintf('MCMC complete. Final acceptance rate: %.2f%%\n', 100*accepted_count/obj.mcmc_iterations);

            % --- Update Posterior Statistics ---
            obj.updatePosteriorStats();
            fprintf('Posterior mean and variance have been updated.\n');

            sim.params.set('ssp_grid', obj.posterior_mean_ssp);
            fprintf('SSP estimation updated in the simulation. \n');

        end
        
        function updatePosteriorStats(obj)
            % Calculate the mean and variance from the collected MCMC samples
            % after discarding the burn-in period.
            
            if isempty(obj.ssp_samples) || length(obj.ssp_samples) <= obj.mcmc_burn_in
                warning('Not enough samples to update posterior. Using prior.');
                obj.posterior_mean_ssp = reshape(obj.mu_prior_grid, [length(obj.grid_x), length(obj.grid_y), length(obj.grid_z)]);
                return;
            end
            
            
            % Get samples after burn-in
            valid_samples_matrix = cell2mat(obj.ssp_samples(obj.mcmc_burn_in+1:end));
            
            % Calculate mean and variance
            mean_ssp_flat = mean(valid_samples_matrix, 2);
            var_ssp_flat = var(valid_samples_matrix, 0, 2);
            
            grid_dims = [length(obj.grid_x), length(obj.grid_y), length(obj.grid_z)];
            obj.posterior_mean_ssp = reshape(mean_ssp_flat, grid_dims);
            obj.posterior_var_ssp = reshape(var_ssp_flat, grid_dims);
        end

        function log_p = calculate_log_posterior(obj, ssp_flat, sim)
            % Calculates the log posterior probability of a given SSP field.
            % log P(ssp | tl) = log P(tl | ssp) + log P(ssp)
            
            % 1. Calculate log-likelihood: log P(tl | ssp)
            log_likelihood = obj.calculate_log_likelihood(ssp_flat, sim);
            
            % If the likelihood is impossible, the posterior is too.
            if isinf(log_likelihood)
                log_p = -inf;
                return;
            end
            
            % 2. Calculate log-prior: log P(ssp)
            log_prior = obj.calculate_log_prior(ssp_flat);
            
            % 3. Combine them
            log_p = log_likelihood + log_prior;

        end

        function log_likelihood = calculate_log_likelihood(obj, ssp_flat, sim)
            % Calculates log P(tl_obs | ssp) using the forward model.
            
            try
                % --- Run the Forward Acoustic Model ---
                ssp_grid = reshape(ssp_flat, [length(obj.grid_x), length(obj.grid_y), length(obj.grid_z)]);
                
                % Assign ssp field
                sim.params.set('ssp_grid', ssp_grid);
                
                % This function call should simulate TL for ALL observation points
                tl_predicted = sim.computeTL(obj.X_obs);

  
                % --- Calculate Likelihood ---
                % Assumes a Gaussian noise model for the TL measurements
                residual = obj.tl_obs - tl_predicted;
                log_likelihood = -0.5 * sum((residual / obj.tl_noise_std).^2);
                
            catch ME
                % If the forward model fails for a proposed SSP, that SSP is
                % considered impossible (zero probability).
                warning('Forward model failed: %s. Assigning -inf likelihood.', ME.message);
                log_likelihood = -inf;
            end
        end
        
        function log_prior = calculate_log_prior(obj, ssp_flat)
            % Calculates the log prior probability of an SSP field, log P(ssp).
            % This is given by the GP definition.
            delta = ssp_flat - obj.mu_prior_grid;
            
            % Using the Cholesky decomposition is more stable than inv(K_prior)
            v = obj.K_prior_chol' \ delta;
            log_prior = -0.5 * (v' * v);
        end
        
        function uncertainty_grid = getUncertaintyGrid(obj)
            % Returns the standard deviation of the posterior SSP.
            uncertainty_grid = sqrt(obj.posterior_var_ssp);
        end
    end
    
    methods (Access = private)
        function [K_xx, K_xs, K_ss] = kernelBlocks(obj, X_grid, X_obs)
            % Helper to compute kernel blocks for conditioning
            K_xx = obj.kernelMatrix(X_grid, X_grid);
            if nargin > 2 && ~isempty(X_obs)
                K_xs = obj.kernelMatrix(X_grid, X_obs);
                K_ss = obj.kernelMatrix(X_obs, X_obs);
            else
                K_xs = [];
                K_ss = [];
            end
        end
        function setupMeanFunction(obj)
            % Setup mean function from CTD data
            try
                S = load('data/CTD.mat');
                fn = fieldnames(S);
                raw = S.(fn{1});
                [z_tr, ~, grp] = unique(raw(:,1), 'stable');
                c_tr = accumarray(grp, raw(:,2), [], @mean);
                obj.mean_func = @(z) interp1(z_tr, c_tr, z, 'linear', 'extrap');
            catch
                warning('Could not load CTD.mat, using constant mean function');
                obj.mean_func = @(z) 1500 * ones(size(z));
            end
        end
 
        function setupPredictionGrid(obj)
            % Setup 3D prediction grid based on simulation settings
            s = uw.SimSettings.default();
            obj.grid_x = s.Ocean_x_min:s.OceanGridStep:s.Ocean_x_max;
            obj.grid_y = s.Ocean_y_min:s.OceanGridStep:s.Ocean_y_max;
            obj.grid_z = 0:s.Ocean_z_step:s.sim_max_depth;
            [X, Y, Z] = meshgrid(obj.grid_x, obj.grid_y, obj.grid_z);
            obj.X_grid = [X(:), Y(:), Z(:)];
        end

        function computePriorCovariance(obj)
            % Pre-computes the large prior covariance matrix K and its
            % Cholesky decomposition for the entire grid.
            % This can be memory-intensive for large grids.
            M = size(obj.X_grid, 1);
            fprintf('Computing %d x %d prior covariance matrix...\n', M, M);
            
            obj.mu_prior_grid = obj.mean_func(obj.X_grid(:,3));
            obj.K_prior = obj.kernelMatrix(obj.X_grid, obj.X_grid);
            
            % Add a small jitter for numerical stability before decomposition
            obj.K_prior = obj.K_prior + 1e-6 * eye(M);
            
            fprintf('Computing Cholesky decomposition...\n');
            obj.K_prior_chol = chol(obj.K_prior, 'lower');
            fprintf('Prior computation finished.\n');
        end

        function K = kernelMatrix(obj, X1, X2)
            % Compute kernel matrix using the anisotropic squared exponential kernel
            dx = pdist2(X1(:,1), X2(:,1)) * 1000; % km -> m
            dy = pdist2(X1(:,2), X2(:,2)) * 1000; % km -> m
            dz = pdist2(X1(:,3), X2(:,3));       % m
            
            r2_h = dx.^2 + dy.^2;
            r2_v = dz.^2;
            
            K = obj.sigma_f^2 * exp(-0.5 * r2_h / obj.ell_h^2 - 0.5 * r2_v / obj.ell_v^2);
        end
        
        function conditionOnSSPObservations(obj)
            % Apply GP conditioning on available SSP point observations.
            if isempty(obj.ssp_obs_pos) || isempty(obj.ssp_obs_val)
                obj.use_conditioned_prior = false;
                return;
            end

            Xs = obj.ssp_obs_pos;          % [Ns x 3]
            ys = obj.ssp_obs_val(:);       % [Ns x 1]

            % Kernel blocks
            [K_xx, K_xs, K_ss] = obj.kernelBlocks(obj.X_grid, Xs);

            % Observation noise
            R = (obj.ssp_obs_noise_std^2) * eye(size(K_ss,1));

            % Prior mean at obs
            mu_s = obj.mean_func(Xs(:,3));

            % Conditioned mean/covariance on grid
            % Use linear solver for stability: (K_ss + R) \ v
            A = K_ss + R;
            w = A \ (ys - mu_s);
            mu_cond = obj.mean_func(obj.X_grid(:,3)) + K_xs * w;

            V = A \ K_xs';
            K_cond = K_xx - K_xs * V;
            K_cond = (K_cond + K_cond') * 0.5;  % symmetrize
            K_cond = K_cond + 1e-6 * eye(size(K_cond,1));

            % Store
            obj.mu_cond_grid = mu_cond;
            obj.K_cond_chol  = chol(K_cond, 'lower');
            obj.use_conditioned_prior = true;
        end
    end
end
