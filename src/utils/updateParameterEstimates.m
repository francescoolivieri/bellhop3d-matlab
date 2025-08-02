function data = updateParameterEstimates(data, s, new_estimates)
    % Update estimated parameter map with new parameter estimates
    %
    % Inputs:
    %   data - Data structure containing parameter maps
    %   s - Settings structure containing estimation parameter names
    %   new_estimates - Array of new parameter estimates
    %
    % Output:
    %   data - Updated data structure
    
    % Validate inputs
    if length(new_estimates) ~= length(s.estimation_param_names)
        error('Number of estimates must match number of estimation parameters');
    end
    
    % Update estimated parameter map
    for i = 1:length(s.estimation_param_names)
        param_name = s.estimation_param_names{i};
        data.estimated_params(param_name) = new_estimates(i);
    end
    
    % Update backward compatibility array
    data.th_est = new_estimates;
    
    % Optional: Log parameter updates
    if isfield(s, 'verbose') && s.verbose
        fprintf('Updated parameter estimates:\n');
        for i = 1:length(s.estimation_param_names)
            fprintf('  %s: %.4f -> %.4f (true: %.4f)\n', ...
                s.estimation_param_names{i}, ...
                data.th_est(i), ...
                new_estimates(i), ...
                data.true_params(s.estimation_param_names{i}));
        end
    end
end 