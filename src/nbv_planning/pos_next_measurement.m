function data = pos_next_measurement(data, s)
    % State-of-the-art NBV planning with multiple approaches
    
    % Get index of last state
    idx = find(isfinite(data.x), 1, 'last');
    
    % Check if sensor management or not 
    if s.sm
        
        % Select method based on settings
        switch s.nbv_method
            case 'tree_memoized'
                % Optimized tree-based approach with memoization
                data = tree_memoized_nbv(data, s, idx);
                
            case 'information_gain' % NOT TESTED
                % Information gain-based approach 
                data = information_gain_nbv(data, s, idx);
                
            case 'uncertainty_guided' % NOT TESTED
                % Uncertainty-guided approach inspired by NeU-NBV
                data = uncertainty_guided_nbv(data, s, idx);
                
            case 'multi_objective' % NOT TESTED
                % Multi-objective optimization approach
                data = multi_objective_nbv(data, s, idx);
                
            case 'rrt_star'
                % RRT* based NBV planning
                data = rrt_star_based_nbv(data, s, idx);
                
            case 'bayesian_opt'
                % Bayesian optimization approach
                data = bayesian_optimization_nbv(data, s, idx);
                
            otherwise
                % Move as lawn mower
                data = lawnmower_pattern(data, s, idx);
        end
        
    else
        % Move as lawn mower (original behavior)
        data = lawnmower_pattern(data, s, idx);
    end
end








function data = lawnmower_pattern(data, s, idx)
    % Original lawnmower pattern
    if (data.y(idx) + s.d_y) < s.y_max
        data.y(idx+1) = data.y(idx) + s.d_y;
        data.x(idx+1) = data.x(idx);
        data.z(idx+1) = data.z(idx);
    else
        data.y(idx+1) = s.y_min;
        if (data.x(idx) + s.d_x) < s.x_max
            data.x(idx+1) = data.x(idx) + s.d_x;
            data.z(idx+1) = data.z(idx);
        else
            data.x(idx+1) = s.x_min;
            if (data.z(idx) + s.d_z) < s.z_max
                data.z(idx+1) = data.z(idx) + s.d_z;
            else
                data.z(idx+1) = s.z_min;
            end
        end
    end
end