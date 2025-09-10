function data = pos_next_measurement(data, s)
    % State-of-the-art IPP planning with multiple approaches
    
    % Get index of last state
    idx = find(isfinite(data.x), 1, 'last');
    
    % Check if sensor management or not 
    if s.sm
        
        % Select method based on settings
        switch s.ipp_method
            case 'tree_search'
                % Tree-based IPP planning (updated to use new signature)
                current_pos = [data.x(idx), data.y(idx), data.z(idx)];
                estimation_state = struct();
                if isfield(data, 'sim_est'), estimation_state.sim_est = data.sim_est; end
                if isfield(data, 'th_est'), estimation_state.th_est = data.th_est(:, idx); end
                if isfield(data, 'Sigma_est'), estimation_state.Sigma_est = data.Sigma_est(:, :, idx); end
                if isfield(data, 'Sigma_rr'), estimation_state.Sigma_rr = data.Sigma_rr; end
                
                depth = 1; if isfield(s, 'tree_depth'), depth = s.tree_depth; end
                next_pos = tree_search_ipp(current_pos, s, estimation_state, depth);
                data.x(idx+1) = next_pos(1);
                data.y(idx+1) = next_pos(2);
                data.z(idx+1) = next_pos(3);

            case 'rrt_star'
                % RRT* based IPP planning (updated to use new signature)
                current_pos = [data.x(idx), data.y(idx), data.z(idx)];
                estimation_state = struct();
                if isfield(data, 'sim_est'), estimation_state.sim_est = data.sim_est; end
                if isfield(data, 'th_est'), estimation_state.th_est = data.th_est(:, idx); end
                if isfield(data, 'Sigma_est'), estimation_state.Sigma_est = data.Sigma_est(:, :, idx); end
                if isfield(data, 'Sigma_rr'), estimation_state.Sigma_rr = data.Sigma_rr; end
                
                next_pos = rrt_star_based_ipp(current_pos, s, estimation_state, 15, 1.0, 0.05, 8.0);
                data.x(idx+1) = next_pos(1);
                data.y(idx+1) = next_pos(2);
                data.z(idx+1) = next_pos(3);
                
            case 'information_gain'
                % Information gain-based approach (updated to use new signature)
                current_pos = [data.x(idx), data.y(idx), data.z(idx)];
                estimation_state = struct();
                if isfield(data, 'sim_est'), estimation_state.sim_est = data.sim_est; end
                if isfield(data, 'th_est'), estimation_state.th_est = data.th_est(:, idx); end
                if isfield(data, 'Sigma_est'), estimation_state.Sigma_est = data.Sigma_est(:, :, idx); end
                if isfield(data, 'Sigma_rr'), estimation_state.Sigma_rr = data.Sigma_rr; end
                
                next_pos = random_points_ipp(current_pos, s, estimation_state, 10, 3);
                data.x(idx+1) = next_pos(1);
                data.y(idx+1) = next_pos(2);
                data.z(idx+1) = next_pos(3);

            case 'multi_objective' % NOT TESTED
                % Multi-objective optimization approach
                disp("Multi-Objective NOT complete. Check the code and uncomment the call before running.");
                disp("Starting lawnmower...");
                lawnmower_pattern(data, s, idx);
                
                %data = multi_objective_ipp(data, s, idx);
                
            otherwise
                % Move as lawn mower
                data = lawnmower_pattern(data, s, idx);
        end
        
    else

        % data.x(idx+1) = data.x(idx);
        % data.y(idx+1) = data.y(idx);
        % data.z(idx+1) = data.z(idx) + s.Ocean_z_step;

        % Move as lawn mower (original behavior)
        data = lawnmower_pattern(data, s, idx);
    end
end








function data = lawnmower_pattern(data, s, idx)
    % Circular lawnmower pattern: sqrt(x^2 + y^2) < s.x_max

    temp_x = data.x(idx);
    temp_y = data.y(idx);
    temp_z = data.z(idx);
    
    % Loop indefinitely until a valid point within the circle is found.
    while true
        % Propose the next point using the original rectangular lawnmower logic.
        if (temp_y + s.d_y) < s.y_max
            % Move along the y-axis (primary scan direction).
            temp_y = temp_y + s.d_y;
        else
            % Reached the end of a y-scan. Reset y and move along the x-axis.
            temp_y = s.y_min;
            if (temp_x + s.d_x) < s.x_max
                % Move along the x-axis (secondary scan direction).
                temp_x = temp_x + s.d_x;
            else
                % Reached the end of an x-scan. Reset x and move along the z-axis.
                temp_x = s.x_min;
                if (temp_z + s.d_z) < s.z_max
                    % Move along the z-axis (tertiary scan direction).
                    temp_z = temp_z + s.d_z;
                else
                    % Reached the end of the z-scan, so reset z. This causes
                    % the pattern to wrap around.
                    temp_z = s.z_min;
                end
            end
        end
    
        % Check if the newly proposed point (temp_x, temp_y) is inside the circle.
        if sqrt(temp_x^2 + temp_y^2) < s.x_max
            % The point is valid. Assign it to the output structure.
            data.x(idx+1) = temp_x;
            data.y(idx+1) = temp_y;
            data.z(idx+1) = temp_z;
            
            % Exit the function since we have found the next valid point.
            return;
        end
        
        % If the point is outside the circle, the loop continues. The updated
        % temporary coordinates will be used to calculate the next point in the
        % sequence, effectively skipping the invalid ones.
    end
end