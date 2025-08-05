classdef SSPGaussianProcess < handle
    % SSPGaussianProcess - Gaussian Process for 3D Sound Speed Profile estimation
    %
    % This class manages GP-based estimation of sound speed profiles in 3D
    % underwater environments, with integration to Bellhop acoustic modeling.
    
    properties (Access = private)
        % GP hyperparameters
        ell_h           % Horizontal correlation length (m)
        ell_v           % Vertical correlation length (m)
        sigma_f         % Signal standard deviation (m/s)
        noise_std       % Measurement noise std (m/s)
        
        % Data storage
        X_obs           % Observed positions [N x 3] (x, y, z)
        y_obs           % Observed measurements [N x 1] (derived from TL)
        
        % Grid for prediction
        grid_x          % x coordinates (km)
        grid_y          % y coordinates (km) 
        grid_z          % z coordinates (m)
        X_grid          % Grid positions [M x 3]
        
        % Mean function (from CTD data)
        mean_func       % Function handle for prior mean
        
        % SSP file settings
        filename        % Output SSP filename
        
        % Cached computations
        K_inv           % Inverse of observation covariance matrix
        alpha           % K_inv * (y_obs - mean(X_obs))
    end
    
    methods
        function obj = SSPGaussianProcess(config)
            % Constructor
            % Input: config struct with fields:
            %   - ell_h: horizontal correlation length
            %   - ell_v: vertical correlation length  
            %   - sigma_f: signal standard deviation
            %   - noise_std: measurement noise standard deviation
            %   - filename: output SSP filename
            
            obj.ell_h = config.ell_h;
            obj.ell_v = config.ell_v;
            obj.sigma_f = config.sigma_f;
            obj.noise_std = config.noise_std;
            obj.filename = config.filename;
            
            % Initialize empty observation arrays
            obj.X_obs = [];
            obj.y_obs = [];
            
            % Load CTD data for mean function
            obj.setupMeanFunction();
            
            % Setup prediction grid based on simulation settings
            obj.setupPredictionGrid();
        end
        
        function setupMeanFunction(obj)
            % Setup mean function from CTD data
            try
                S = load('data/CTD.mat');
                fn = fieldnames(S);
                raw = S.(fn{1});
                z_raw = raw(:,1);
                c_raw = raw(:,2);
                
                % Remove duplicate depths and average
                [z_tr, ~, grp] = unique(z_raw, 'stable');
                c_tr = accumarray(grp, c_raw, [], @mean);
                
                % Create interpolation function
                obj.mean_func = @(z) interp1(z_tr, c_tr, z, 'linear', 'extrap');
                
            catch
                warning('Could not load CTD.mat, using constant mean function');
                obj.mean_func = @(z) 1500 * ones(size(z)); % Default ocean sound speed
            end
        end
        
        function setupPredictionGrid(obj)
            % Setup 3D prediction grid based on simulation settings
            s = get_sim_settings(); % Load simulation settings
            
            % Create coordinate vectors
            obj.grid_x = s.Ocean_x_min:s.Ocean_step:s.Ocean_x_max;  % km
            obj.grid_y = s.Ocean_y_min:s.Ocean_step:s.Ocean_y_max;  % km  
            obj.grid_z = 0:s.Ocean_z_step:s.sim_max_depth;          % m
            
            % Create full 3D meshgrid
            [X, Y, Z] = meshgrid(obj.grid_x, obj.grid_y, obj.grid_z);
            obj.X_grid = [X(:), Y(:), Z(:)]; % [M x 3] matrix
        end
        
        function update(obj, pos, measurement)
            % Update GP with new observation
            % Inputs:
            %   pos: [1 x 3] position vector [x_km, y_km, z_m]
            %   measurement: scalar transmission loss measurement [dB]
            
            % Convert TL measurement to sound speed estimate
            % This is a simplified conversion - in practice you'd want a more
            % sophisticated inversion method
            c_estimate = obj.tlToSoundSpeed(measurement, pos);
            
            % Add to observation data
            obj.X_obs = [obj.X_obs; pos];
            obj.y_obs = [obj.y_obs; c_estimate];
            
            % Update cached computations
            obj.updateCachedValues();
        end
        
        function c_est = tlToSoundSpeed(obj, tl, pos)
            % Convert transmission loss to sound speed estimate
            % This is a simplified placeholder - replace with proper inversion
            
            % For now, use prior mean plus small perturbation based on TL
            prior_mean = obj.mean_func(pos(3));
            
            % Simple heuristic: higher TL suggests different sound speed
            % This needs to be replaced with proper acoustic inversion
            perturbation = (tl - 80) * 0.1; % Rough scaling
            c_est = prior_mean + perturbation;
            
            % Clamp to reasonable range
            c_est = max(1400, min(1600, c_est));
        end
        
        function updateCachedValues(obj)
            % Update cached covariance matrix inverse and alpha values
            if isempty(obj.X_obs)
                return;
            end
            
            N = size(obj.X_obs, 1);
            
            % Compute observation covariance matrix
            K_obs = obj.kernelMatrix(obj.X_obs, obj.X_obs);
            K_obs = K_obs + obj.noise_std^2 * eye(N); % Add noise
            
            % Compute mean at observation points
            mu_obs = obj.mean_func(obj.X_obs(:,3));
            
            % Cache inverse and alpha
            obj.K_inv = inv(K_obs + 1e-6*eye(N)); % Add jitter for stability
            obj.alpha = obj.K_inv * (obj.y_obs - mu_obs);
        end
        
        function K = kernelMatrix(obj, X1, X2)
            % Compute kernel matrix between two sets of points
            % Inputs:
            %   X1: [N1 x 3] positions
            %   X2: [N2 x 3] positions
            % Output:
            %   K: [N1 x N2] kernel matrix
            
            N1 = size(X1, 1);
            N2 = size(X2, 1);
            K = zeros(N1, N2);
            
            for i = 1:N1
                % Compute squared distances
                dx = X1(i,1) - X2(:,1); % x difference (km)
                dy = X1(i,2) - X2(:,2); % y difference (km)  
                dz = X1(i,3) - X2(:,3); % z difference (m)
                
                % Convert x,y to meters for consistent units
                dx_m = dx * 1000;
                dy_m = dy * 1000;
                
                % Anisotropic squared exponential kernel
                r2_h = dx_m.^2 + dy_m.^2;
                r2_v = dz.^2;
                
                K(i,:) = obj.sigma_f^2 * exp(-0.5 * r2_h / obj.ell_h^2 - 0.5 * r2_v / obj.ell_v^2);
            end
        end
        
        function [mu_pred, var_pred] = predict(obj, X_test)
            % Predict mean and variance at test points
            % Input:
            %   X_test: [N_test x 3] test positions
            % Outputs:
            %   mu_pred: [N_test x 1] predicted means
            %   var_pred: [N_test x 1] predicted variances
            
            if isempty(obj.X_obs)
                % No observations yet, return prior
                mu_pred = obj.mean_func(X_test(:,3));
                var_pred = obj.sigma_f^2 * ones(size(mu_pred));
                return;
            end
            
            % Cross-covariance between test and observation points
            K_cross = obj.kernelMatrix(X_test, obj.X_obs);
            
            % Prior mean at test points
            mu_prior = obj.mean_func(X_test(:,3));
            
            % Posterior mean
            mu_pred = mu_prior + K_cross * obj.alpha;
            
            % Posterior variance (if requested)
            if nargout > 1
                K_test = obj.kernelMatrix(X_test, X_test);
                var_pred = diag(K_test) - diag(K_cross * obj.K_inv * K_cross');
                var_pred = max(var_pred, 1e-8); % Ensure non-negative
            end
        end
        
        function ssp_grid = getCurrentSSPGrid(obj)
            % Get current SSP estimate on the full 3D grid
            [mu_pred, ~] = obj.predict(obj.X_grid);
            
            % Reshape to grid format [Ny x Nx x Nz]
            Ny = length(obj.grid_y);
            Nx = length(obj.grid_x);
            Nz = length(obj.grid_z);
            
            ssp_grid = reshape(mu_pred, [Ny, Nx, Nz]);
        end
        
        function writeSSPFile(obj)
            % Write current SSP estimate to file for Bellhop
            ssp_grid = obj.getCurrentSSPGrid();
            writeSSP3D(obj.filename, obj.grid_x, obj.grid_y, obj.grid_z, ssp_grid);
        end
        
        function uncertainty = getUncertainty(obj, positions)
            % Get prediction uncertainty at specified positions
            % Input:
            %   positions: [N x 3] query positions (optional, default: grid)
            
            if nargin < 2
                positions = obj.X_grid;
            end
            
            [~, var_pred] = obj.predict(positions);
            uncertainty = sqrt(var_pred); % Standard deviation
        end
        
        function n_obs = getNumObservations(obj)
            % Get number of observations
            n_obs = size(obj.X_obs, 1);
        end
        
        function [pos, measurements] = getObservations(obj)
            % Get all observations
            pos = obj.X_obs;
            measurements = obj.y_obs;
        end
    end
end