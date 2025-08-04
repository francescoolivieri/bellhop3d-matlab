function param_map = createParameterMapFromArray(th_array, s, reference_map)
    % Create parameter map from array using estimation parameter names
    %
    % Inputs:
    %   th_array - Array of parameter values
    %   s - Settings structure containing estimation_param_names
    %   reference_map - (Optional) Reference parameter map to copy from
    %
    % Output:
    %   param_map - Parameter map with updated values
    
    if nargin < 3 || isempty(reference_map)
        % Create default parameter map if no reference provided
        param_map = getDefaultParameterMap(s);
    else
        % Copy from reference map
        param_map = containers.Map(reference_map.keys, reference_map.values);
    end
    
    % Validate input dimensions
    if length(th_array) ~= length(s.estimation_param_names)
        error('Array length must match number of estimation parameters');
    end
    
    % Update with estimated parameters
    params_added = zeros(size(s.estimation_param_names));
    for i = 1:length(s.estimation_param_names)
        
        % Check if already added
        if params_added(i) ~= 0 
            continue
        end

        param_name = s.estimation_param_names{i};      
        
        if isKey(param_map, param_name)
            param_map(param_name) = th_array(i);
            params_added(i) = 1;
            
            for j = i+1:length(s.estimation_param_names)
                param_name_iter = s.estimation_param_names{j};      
                if strcmp( param_name_iter, param_name )
                    param_map(param_name) = [param_map(param_name) th_array(j)];
                    params_added(j) = 1;
                end
            end

        else
            warning('Parameter "%s" not found in parameter map', param_name);
            param_map(param_name) = th_array(i); % Add it anyway
        end
    end
end

