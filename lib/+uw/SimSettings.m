classdef SimSettings
    % SIMSETTINGS  Static container for default simulation settings.
    %   Replaces the old get_sim_settings() function.

    methods (Static)
        function s = default()
            %% Ocean Settings
            s.OceanDepth = 50.;
            s.OceanFloorType = 'flat';    % flat, smooth_waves, gaussian_features, fractal_noise (go to uw/internal/scenario/scenarioBuilder.m to tune scenario parameters)
            s.Ocean_x_min = -2; s.Ocean_x_max = 2;
            s.Ocean_y_min = -2; s.Ocean_y_max = 2;
            s.Ocean_step   = 0.2;
            s.Ocean_z_step = s.OceanDepth * 0.25;

            %% Bellhop simulation settings
            s.sim_max_depth      = 80.0;
            s.sim_range          = 1.5;
            s.sim_num_bearings   = 6;   % optimal is 361 (but heavy computationally)

            % Extensions
            s.sim_use_ssp_file   = true;
            s.sim_use_bty_file   = true;
            s.sim_accurate_3d    = false;   % increases runtime ~3×
            s.sim_bty_splitted   = false;

            % Default acoustic parameters & settings (!!! copied into SimulationParameters !!!)
            % Easier to have all settings in one place
            s.sim_source_frequency      = 1000.;
            s.sim_source_x       = -0.2;
            s.sim_source_y       = 0.0;
            s.sim_source_depth   = 10.0;
            s.sim_param_sp_water            = 1500;
            s.sim_param_sp_sediment         = 1450;
            s.sim_param_density_sediment    = 1.5;
            s.sim_param_attenuation_sediment= 0.5;

            %% External file references
            s.sim_id = sprintf('%07d', randi([0,9999999]));
            s.filename  = ['sim_env' '_' s.sim_id];

            %% Measurements Settings
            s.z_min = 0;              s.z_max = s.sim_max_depth;
            s.x_min = -1.5;           s.x_max = 1.5;
            s.y_min = -1.5;           s.y_max = 1.5;

            % Sensor management
            s.sm         = false;            % sensor management on/off
            s.nbv_method = 'rrt_star';

            %% Measurement grid
            s.d_z = 15;    s.d_x = 0.5;  s.d_y = 0.5;  % step sizes
            s.z_start = 20; s.x_start = 0.5; s.y_start = 0.5;
            s.depth  = 1;                                 % planning tree depth
            s.N      = 10;                                % total number of measurements
            s.sigma_tl_noise = 1;                         % measurement noise (dB)

        end
    end
end
