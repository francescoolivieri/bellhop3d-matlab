function [data, s, sceneFigure] = setupUnderwaterSimulation(varargin)
    % Setup underwater simulation with configurable parameters
    %
    % Optional Name-Value Parameters:
    %   'Parameters' - Struct with fields:
    %       - names: cell array of parameter names to estimate
    %       - mu: prior mean values
    %       - Sigma: prior covariance matrix
    %   'Units' - String specifying units (default: 'km')
    %   'ExtraOutput' - Boolean for additional output (default: false)
    
    % Parse input parameters
    p = inputParser;
    addParameter(p, 'Parameters', [], @(x) isempty(x) || isstruct(x));
    addParameter(p, 'Units', 'km', @ischar);
    addParameter(p, 'ExtraOutput', false, @islogical);
    parse(p, varargin{:});
    
    % Initialize global variables
    global extra_output
    extra_output = p.Results.ExtraOutput;
    
    global units
    units = p.Results.Units;
    
    % Clean any existing files
    clean_files();
    
    % Load the simulation settings
    s = get_sim_settings();

    % Initialize parameter mapping system
    [data, s] = initializeParameterMaps( s, p.Results.Parameters);
   
    % Create chosen scenario for the simulation
    [scene, sceneFigure] = scenarioBuilder(s);
    s.scene = scene;
    
    % Generate a .ssp file if needed
    if s.sim_use_ssp_file
        generateSSP3D(s, scene);
    end
    
    % Generate .env file using true parameter values
    writeENV3D(s.bellhop_file_name + ".env", s, data.true_params); 
    fprintf('Wrote true ENV file.\n');
    
    % Generate .bty file using true parameter values
    if s.sim_use_bty_file
        writeBTY3D(s.bellhop_file_name + ".bty", scene, data.true_params);
        figure
    end
    
    % Run bellhop and draw environment
    draw_true_env(s, scene);

    % Print polar shd
    figure;
    plotshdpol(s.bellhop_file_name + ".shd");
    
    % Initialize filter
    data = init_filter(data, s);
end

function [data, s] = initializeParameterMaps(s, param_config)
    % Initialize parameter mapping system
    
    % Define all possible parameters and their default values
    default_params = getDefaultParameterMap(s);
    
    % Initialize true parameter map with defaults
    data.true_params = default_params;
    
    % Handle custom parameter configuration
    if ~isempty(param_config)
        % Validate parameter structure
        assert(all(isfield(param_config, {'names', 'mu', 'Sigma'})), ...
            'Parameters struct must contain fields: names, mu, Sigma');
        assert(length(param_config.mu) == size(param_config.Sigma, 1), ...
            'Parameter mean and covariance dimensions must match');
        
        % Store estimation configuration
        s.estimation_param_names = param_config.names;
        s.mu_th = param_config.mu;
        s.Sigma_th = param_config.Sigma;
        
        % Sample true values for parameters being estimated
        true_values = param_config.mu + chol(param_config.Sigma,'lower')*randn(size(param_config.mu));
        
        for i = 1:length(param_config.names)
            param_name = param_config.names{i};
            if isKey(data.true_params, param_name)
                data.true_params(param_name) = [];
            else
                warning('Parameter "%s" not recognized in parameter map', param_name);
            end
        end

        % Update true parameter map with sampled values
        for i = 1:length(param_config.names)
            param_name = param_config.names{i};
            if isKey(data.true_params, param_name)
                data.true_params(param_name) = [data.true_params(param_name) true_values(i)];
            else
                warning('Parameter "%s" not recognized in parameter map', param_name);
            end
        end
    else
        disp("ERROR BUT GOING ON - Loading thetas from settings (not yet implemented)");

        % Use default estimation parameters from settings
        s.estimation_param_names = s.parameter_names;
        
        % Sample true values using default priors
        true_values = s.mu_th + chol(s.Sigma_th,'lower')*randn(size(s.mu_th));
        
        % Update true parameter map
        for i = 1:length(s.estimation_param_names)
            param_name = s.estimation_param_names{i};
            if isKey(data.true_params, param_name)
                data.true_params(param_name) = true_values(i);
            end
        end
    end
    
    % Initialize estimated parameter map (model's current belief)
    data.estimated_params = containers.Map();
    
    for key = data.true_params.keys()
        k = key{1};
        data.estimated_params(k) = data.true_params(k);
    
    end


    % Set initial estimates for parameters being estimated to prior means
    for i = 1:length(s.estimation_param_names)
        
        data.estimated_params(s.estimation_param_names{i}) = [];
    end
    
    for i = 1:length(s.estimation_param_names)
        param_name = s.estimation_param_names{i};
        data.estimated_params(param_name) = [data.estimated_params(param_name) s.mu_th(i)];
    end

    % Store parameter arrays for backward compatibility
    data.th = getParameterArray(data.true_params, s.estimation_param_names);
    data.th_est = getParameterArray(data.estimated_params, s.estimation_param_names);

    % TODO: Control on bty parameters
    data.true_params = paddingSedimentParams(data.true_params, default_params);
    data.estimated_params = paddingSedimentParams(data.estimated_params, default_params);
    % printMap(data.true_params)
    % printMap(data.estimated_params)

end


function param_array = getParameterArray(param_map, param_names)

    % Convert parameter map to array based on specified parameter names
    param_array = zeros(length(param_names), 1);
    cont = 1;
    for i = 1:length(unique(param_names))
        if isKey(param_map, param_names{i})
            values = param_map(param_names{i});

            for j = 1:length(values)
                param_array(cont) = values(j);
                cont = cont+1;
            end
        else
            error('Parameter "%s" not found in parameter map', param_names{i});
        end
    end
end

function updateParameterMap(param_map, param_names, param_values)
    % Update parameter map with new values
    for i = 1:length(param_names)
        param_map(param_names{i}) = param_values(i);
    end
end