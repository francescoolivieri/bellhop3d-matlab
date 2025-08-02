function value = getParameterValue(data, param_name, use_estimated)
    % Get parameter value from either true or estimated parameter map
    %
    % Inputs:
    %   data - Data structure containing parameter maps
    %   param_name - String name of the parameter
    %   use_estimated - Boolean, if true use estimated params, else use true params
    %
    % Output:
    %   value - Parameter value
    
    if nargin < 3
        use_estimated = false; % Default to true parameters
    end
    
    if use_estimated
        if isfield(data, 'estimated_params') && isKey(data.estimated_params, param_name)
            value = data.estimated_params(param_name);
        else
            error('Estimated parameter "%s" not found', param_name);
        end
    else
        if isfield(data, 'true_params') && isKey(data.true_params, param_name)
            value = data.true_params(param_name);
        else
            error('True parameter "%s" not found', param_name);
        end
    end
end 