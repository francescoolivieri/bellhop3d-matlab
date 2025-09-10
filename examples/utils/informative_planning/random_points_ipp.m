function next_pos = random_points_ipp(current_pos, bounds, estimation_state, n_candidates, search_radius)
    % Information gain-based approach (efficient sampling)
    % CURRENT_POS: [x y z] current position
    % BOUNDS: struct with movement constraints
    % ESTIMATION_STATE: struct with sim_est, th_est, Sigma_est, Sigma_rr
    % N_CANDIDATES: number of candidate positions (default: 10)
    % SEARCH_RADIUS: search radius in steps (default: 3)
    
    if nargin < 4, n_candidates = 10; end
    if nargin < 5, search_radius = 3; end
    
    candidate_positions = generate_candidate_positions_with_opts(current_pos(1), current_pos(2), current_pos(3), bounds, n_candidates, search_radius);
    
    best_info_gain = -inf;
    best_pos = current_pos;
    
    for i = 1:size(candidate_positions, 1)
        pos = candidate_positions(i, :);
        if is_valid_position(pos, bounds)
            info_gain = calculate_information_gain(estimation_state.sim_est, pos, ...
                estimation_state.th_est, estimation_state.Sigma_est, estimation_state.Sigma_rr);
            if info_gain > best_info_gain
                best_info_gain = info_gain;
                best_pos = pos;
            end
        end
    end
    
    next_pos = best_pos;
end

function positions = generate_candidate_positions_with_opts(x, y, z, s, n_candidates, search_radius)
    % Generate candidate positions in a sphere around current position
    positions = [];
    
    for i = 1:n_candidates
        % Random position within movement constraints
        dx = (rand - 0.5) * 2 * s.d_x * search_radius;
        dy = (rand - 0.5) * 2 * s.d_y * search_radius;
        dz = (rand - 0.5) * 2 * s.d_z * search_radius;
        
        new_pos = [x + dx, y + dy, z + dz];
        positions = [positions; new_pos];
    end
end
