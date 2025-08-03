function param_map = getDefaultParameterMap(s)
    % Define all possible parameters and their default values
    param_map = containers.Map();
    
    % Acoustic parameters
    param_map('sound_speed_water') = s.sim_param_sp_water;        % m/s
    param_map('sound_speed_sediment') = s.sim_param_sp_sediment;     % m/s
    param_map('density_sediment') = s.sim_param_density_sediment;          % g/cm³
    param_map('attenuation_sediment') = s.sim_param_attenuation_sediment;      % dB/λ
    
    % Geometric parameters
    param_map('water_depth') = s.sim_max_depth;               % m
    param_map('source_depth') = s.sim_sender_depth;               % m
    param_map('range') = s.sim_range;                    % m
end 