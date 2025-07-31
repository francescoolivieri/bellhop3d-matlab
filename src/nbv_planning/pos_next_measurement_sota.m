function data = pos_next_measurement_sota(data, s)
    % State-of-the-art NBV planning with multiple approaches
    
    % Get index of last state
    idx = find(isfinite(data.x), 1, 'last');
    
    % Check if sensor management or not 
    if s.sm
        
        % Select method based on settings
        switch s.nbv_method
            case 'tree_memoized'
                % Optimized tree-based approach with memoization
                data = tree_based_nbv_memoized(data, s, idx);
                
            case 'tree_27'
                % Tree-based approach with 27 actions
                data = tree_based_nbv_27(data, s, idx);
                
            case 'information_gain'
                % Information gain-based approach (SOTA)
                data = information_gain_nbv(data, s, idx);
                
            case 'uncertainty_guided'
                % Uncertainty-guided approach inspired by NeU-NBV
                data = uncertainty_guided_nbv(data, s, idx);
                
            case 'multi_objective'
                % Multi-objective optimization approach
                data = multi_objective_nbv(data, s, idx);
                
            case 'rrt_nbv'
                % RRT-based NBV planning
                data = rrt_based_nbv(data, s, idx);
                
            case 'rrt_star_nbv'
                % RRT* (optimal) based NBV planning
                data = rrt_star_based_nbv(data, s, idx);
                
            case 'bayesian_opt'
                % Bayesian optimization approach
                data = bayesian_optimization_nbv(data, s, idx);
                
            otherwise
                % Default to original tree method
                data = tree_based_nbv_original(data, s, idx);
        end
        
    else
        % Move as lawn mower (original behavior)
        data = lawnmower_pattern(data, s, idx);
    end
end

function data = tree_based_nbv_memoized(data, s, idx)
    % Original tree approach with memoization
    tree = generateTree(s.depth);
    position_cache = containers.Map('KeyType', 'char', 'ValueType', 'any');
    
    tic
    tree = traverseTreeMemoized(tree, data.th_est(:, idx), data.Sigma_est(:, :, idx), ...
        data.x(idx), data.y(idx), data.z(idx), s, position_cache);
    toc
    
    best_action = getBestActionSequence(tree);
    [data.x(idx+1), data.y(idx+1), data.z(idx+1)] = update_pos(data.x(idx), data.y(idx), data.z(idx), s, best_action(1));
end

function data = tree_based_nbv_27(data, s, idx)
    % Tree approach with 27 actions
    tree = generateTree27(s.depth);
    position_cache = containers.Map('KeyType', 'char', 'ValueType', 'any');
    
    tic
    tree = traverseTreeMemoized27(tree, data.th_est(:, idx), data.Sigma_est(:, :, idx), ...
        data.x(idx), data.y(idx), data.z(idx), s, position_cache);
    toc
    
    best_action = getBestActionSequence(tree);
    [data.x(idx+1), data.y(idx+1), data.z(idx+1)] = update_pos_27(data.x(idx), data.y(idx), data.z(idx), s, best_action(1));
end

function data = information_gain_nbv(data, s, idx)
    % Information gain-based approach (efficient sampling)
    candidate_positions = generate_candidate_positions(data.x(idx), data.y(idx), data.z(idx), s);
    
    best_info_gain = -inf;
    best_pos = [data.x(idx), data.y(idx), data.z(idx)];
    
    for i = 1:size(candidate_positions, 1)
        pos = candidate_positions(i, :);
        if is_valid_position(pos, s)
            info_gain = calculate_information_gain(pos, data.th_est(:, idx), data.Sigma_est(:, :, idx), s);
            if info_gain > best_info_gain
                best_info_gain = info_gain;
                best_pos = pos;
            end
        end
    end
    
    data.x(idx+1) = best_pos(1);
    data.y(idx+1) = best_pos(2);
    data.z(idx+1) = best_pos(3);
end

function data = uncertainty_guided_nbv(data, s, idx)
    % Uncertainty-guided approach inspired by neural rendering methods
    candidate_positions = generate_candidate_positions(data.x(idx), data.y(idx), data.z(idx), s);
    
    best_uncertainty_reduction = -inf;
    best_pos = [data.x(idx), data.y(idx), data.z(idx)];
    
    for i = 1:size(candidate_positions, 1)
        pos = candidate_positions(i, :);
        if is_valid_position(pos, s)
            uncertainty_reduction = calculate_uncertainty_reduction(pos, data.th_est(:, idx), data.Sigma_est(:, :, idx), s);
            if uncertainty_reduction > best_uncertainty_reduction
                best_uncertainty_reduction = uncertainty_reduction;
                best_pos = pos;
            end
        end
    end
    
    data.x(idx+1) = best_pos(1);
    data.y(idx+1) = best_pos(2);
    data.z(idx+1) = best_pos(3);
end

function data = multi_objective_nbv(data, s, idx)
    % Multi-objective optimization considering exploration vs exploitation
    candidate_positions = generate_candidate_positions(data.x(idx), data.y(idx), data.z(idx), s);
    
    best_score = -inf;
    best_pos = [data.x(idx), data.y(idx), data.z(idx)];
    
    for i = 1:size(candidate_positions, 1)
        pos = candidate_positions(i, :);
        if is_valid_position(pos, s)
            % Combine multiple objectives
            info_gain = calculate_information_gain(pos, data.th_est(:, idx), data.Sigma_est(:, :, idx), s);
            coverage = calculate_coverage_score(pos, s);
            efficiency = calculate_efficiency_score(pos, [data.x(idx), data.y(idx), data.z(idx)], s);
            
            % Weighted combination
            score = s.w_info * info_gain + s.w_coverage * coverage + s.w_efficiency * efficiency;
            
            if score > best_score
                best_score = score;
                best_pos = pos;
            end
        end
    end
    
    data.x(idx+1) = best_pos(1);
    data.y(idx+1) = best_pos(2);
    data.z(idx+1) = best_pos(3);
end

function data = bayesian_optimization_nbv(data, s, idx)
    % Enhanced Bayesian optimization approach
    pos_x = optimizableVariable('x', [s.x_min, s.x_max], 'Type', 'real');
    pos_y = optimizableVariable('y', [s.y_min, s.y_max], 'Type', 'real');
    pos_z = optimizableVariable('z', [s.z_min, s.z_max], 'Type', 'real');
    
    % Enhanced objective function
    objectiveFcn = @(pos) enhanced_prediction_error_loss([pos.x, pos.y, pos.z], ...
        data.th_est(:,idx), squeeze(data.Sigma_est(:,:,idx)), s);
    
    results = bayesopt(objectiveFcn, [pos_x, pos_y, pos_z], ...
        'IsObjectiveDeterministic', false, ...
        'AcquisitionFunctionName', 'expected-improvement-per-second-plus', ...
        'GPActiveSetSize', 300, ...
        'NumSeedPoints', 20, ...
        'MaxObjectiveEvaluations', 10, ...
        'ExplorationRatio', 0.1, ...
        'Verbose', 0);
    
    data.x(idx+1) = results.XAtMinObjective.x;
    data.y(idx+1) = results.XAtMinObjective.y;
    data.z(idx+1) = results.XAtMinObjective.z;
end

function data = tree_based_nbv_original(data, s, idx)
    % Original tree approach
    tree = generateTree(s.depth);
    
    tic
    tree = traverseTree(tree, data.th_est(:, idx), data.Sigma_est(:, :, idx), ...
        data.x(idx), data.y(idx), data.z(idx), s);
    toc
    
    best_action = getBestActionSequence(tree);
    [data.x(idx+1), data.y(idx+1), data.z(idx+1)] = update_pos(data.x(idx), data.y(idx), data.z(idx), s, best_action(1));
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

function data = rrt_based_nbv(data, s, idx)
    % RRT-based NBV planning for efficient exploration
    
    % Initialize RRT parameters
    if ~isfield(s, 'rrt_max_iter'), s.rrt_max_iter = 200; end
    if ~isfield(s, 'rrt_step_size'), s.rrt_step_size = 2.0; end
    if ~isfield(s, 'rrt_goal_bias'), s.rrt_goal_bias = 0.1; end
    if ~isfield(s, 'rrt_max_nodes'), s.rrt_max_nodes = 100; end
    
    % Current position
    current_pos = [data.x(idx), data.y(idx), data.z(idx)];
    
    % Build RRT tree for exploration
    rrt_tree = build_rrt_exploration_tree(current_pos, s);
    
    % Evaluate information gain for RRT nodes
    best_info_gain = -inf;
    best_pos = current_pos;
    
    for i = 1:length(rrt_tree.nodes)
        pos = rrt_tree.nodes(i).position;
        if is_valid_position(pos, s)
            info_gain = calculate_information_gain(pos, data.th_est(:, idx), data.Sigma_est(:, :, idx), s);
            
            % Add exploration bonus for nodes further from current position
            exploration_bonus = norm(pos - current_pos) / (s.d_x + s.d_y + s.d_z);
            total_score = info_gain + 0.1 * exploration_bonus;
            
            if total_score > best_info_gain
                best_info_gain = total_score;
                best_pos = pos;
            end
        end
    end
    
    data.x(idx+1) = best_pos(1);
    data.y(idx+1) = best_pos(2);
    data.z(idx+1) = best_pos(3);
end

function data = rrt_star_based_nbv(data, s, idx)
    % RRT* (optimal) based NBV planning with path optimization
    
    % Initialize RRT* parameters
    if ~isfield(s, 'rrt_max_iter'), s.rrt_max_iter = 300; end
    if ~isfield(s, 'rrt_step_size'), s.rrt_step_size = 1.5; end
    if ~isfield(s, 'rrt_goal_bias'), s.rrt_goal_bias = 0.05; end
    if ~isfield(s, 'rrt_search_radius'), s.rrt_search_radius = 8.0; end
    
    % Current position
    current_pos = [data.x(idx), data.y(idx), data.z(idx)];
    
    % Build RRT* tree with path optimization
    rrt_star_tree = build_rrt_star_exploration_tree(current_pos, s);
    
    % Evaluate nodes considering both information gain and path cost
    best_score = -inf;
    best_pos = current_pos;
    
    for i = 1:length(rrt_star_tree.nodes)
        node = rrt_star_tree.nodes(i);
        pos = node.position;
        
        if is_valid_position(pos, s)
            info_gain = calculate_information_gain(pos, data.th_est(:, idx), data.Sigma_est(:, :, idx), s);
            path_cost = node.cost; % Cost from RRT* optimization
            
            % Combine information gain with path efficiency
            score = info_gain - 0.1 * path_cost; % Prefer high info gain, low path cost
            
            if score > best_score
                best_score = score;
                best_pos = pos;
            end
        end
    end
    
    data.x(idx+1) = best_pos(1);
    data.y(idx+1) = best_pos(2);
    data.z(idx+1) = best_pos(3);
end

function rrt_tree = build_rrt_exploration_tree(start_pos, s)
    % Build RRT tree for exploration in 3D space
    
    % Initialize tree
    rrt_tree.nodes = struct('position', {}, 'parent', {}, 'children', {});
    rrt_tree.nodes(1).position = start_pos;
    rrt_tree.nodes(1).parent = -1;
    rrt_tree.nodes(1).children = [];
    
    for iter = 1:s.rrt_max_iter
        if length(rrt_tree.nodes) >= s.rrt_max_nodes
            break;
        end
        
        % Sample random point (with bias toward high-uncertainty regions)
        if rand < s.rrt_goal_bias
            % Goal-biased sampling - sample toward unexplored regions
            rand_point = sample_biased_position(s);
        else
            % Uniform random sampling
            rand_point = sample_random_position(s);
        end
        
        % Find nearest node
        [nearest_idx, nearest_node] = find_nearest_node(rrt_tree, rand_point);
        
        % Extend toward random point
        new_pos = extend_toward_point(nearest_node.position, rand_point, s.rrt_step_size, s);
        
        % Check if new position is valid and not too close to existing nodes
        if is_valid_position(new_pos, s) && min_distance_to_nodes(rrt_tree, new_pos) > s.rrt_step_size/2
            % Add new node
            new_idx = length(rrt_tree.nodes) + 1;
            rrt_tree.nodes(new_idx).position = new_pos;
            rrt_tree.nodes(new_idx).parent = nearest_idx;
            rrt_tree.nodes(new_idx).children = [];
            rrt_tree.nodes(nearest_idx).children(end+1) = new_idx;
        end
    end
end

function rrt_tree = build_rrt_star_exploration_tree(start_pos, s)
    % Build RRT* tree with path optimization
    
    % Initialize tree
    rrt_tree.nodes = struct('position', {}, 'parent', {}, 'children', {}, 'cost', {});
    rrt_tree.nodes(1).position = start_pos;
    rrt_tree.nodes(1).parent = -1;
    rrt_tree.nodes(1).children = [];
    rrt_tree.nodes(1).cost = 0;
    
    for iter = 1:s.rrt_max_iter
        % Sample random point
        if rand < s.rrt_goal_bias
            rand_point = sample_biased_position(s);
        else
            rand_point = sample_random_position(s);
        end
        
        % Find nearest node
        [nearest_idx, nearest_node] = find_nearest_node(rrt_tree, rand_point);
        
        % Extend toward random point
        new_pos = extend_toward_point(nearest_node.position, rand_point, s.rrt_step_size, s);
        
        if is_valid_position(new_pos, s)
            % Find nodes within search radius
            near_indices = find_near_nodes(rrt_tree, new_pos, s.rrt_search_radius);
            
            % Choose parent with minimum cost
            min_cost = inf;
            best_parent = nearest_idx;
            
            for near_idx = near_indices
                edge_cost = norm(new_pos - rrt_tree.nodes(near_idx).position);
                total_cost = rrt_tree.nodes(near_idx).cost + edge_cost;
                if total_cost < min_cost
                    min_cost = total_cost;
                    best_parent = near_idx;
                end
            end
            
            % Add new node
            new_idx = length(rrt_tree.nodes) + 1;
            rrt_tree.nodes(new_idx).position = new_pos;
            rrt_tree.nodes(new_idx).parent = best_parent;
            rrt_tree.nodes(new_idx).children = [];
            rrt_tree.nodes(new_idx).cost = min_cost;
            rrt_tree.nodes(best_parent).children(end+1) = new_idx;
            
            % Rewire tree (RRT* optimization)
            for near_idx = near_indices
                if near_idx ~= best_parent
                    edge_cost = norm(rrt_tree.nodes(near_idx).position - new_pos);
                    new_cost = min_cost + edge_cost;
                    if new_cost < rrt_tree.nodes(near_idx).cost
                        % Rewire
                        old_parent = rrt_tree.nodes(near_idx).parent;
                        rrt_tree.nodes(old_parent).children = ...
                            rrt_tree.nodes(old_parent).children(rrt_tree.nodes(old_parent).children ~= near_idx);
                        
                        rrt_tree.nodes(near_idx).parent = new_idx;
                        rrt_tree.nodes(near_idx).cost = new_cost;
                        rrt_tree.nodes(new_idx).children(end+1) = near_idx;
                        
                        % Update costs of descendants
                        update_descendants_cost(rrt_tree, near_idx);
                    end
                end
            end
        end
    end
end

function pos = sample_random_position(s)
    % Sample random position within bounds
    pos = [
        s.x_min + rand * (s.x_max - s.x_min);
        s.y_min + rand * (s.y_max - s.y_min);
        s.z_min + rand * (s.z_max - s.z_min)
    ]';
end

function pos = sample_biased_position(s)
    % Sample position biased toward unexplored regions
    % This is a simplified version - could be enhanced with actual coverage maps
    
    % Sample with higher probability in outer regions
    radius = s.x_max * (0.5 + 0.5 * rand);
    theta = 2 * pi * rand;
    phi = pi * rand;
    
    pos = [
        radius * sin(phi) * cos(theta);
        radius * sin(phi) * sin(theta);
        s.z_min + rand * (s.z_max - s.z_min)
    ]';
    
    % Clamp to bounds
    pos(1) = max(s.x_min, min(s.x_max, pos(1)));
    pos(2) = max(s.y_min, min(s.y_max, pos(2)));
end

function [nearest_idx, nearest_node] = find_nearest_node(rrt_tree, point)
    % Find nearest node in RRT tree
    min_dist = inf;
    nearest_idx = 1;
    
    for i = 1:length(rrt_tree.nodes)
        dist = norm(rrt_tree.nodes(i).position - point);
        if dist < min_dist
            min_dist = dist;
            nearest_idx = i;
        end
    end
    
    nearest_node = rrt_tree.nodes(nearest_idx);
end

function near_indices = find_near_nodes(rrt_tree, point, radius)
    % Find all nodes within radius of point
    near_indices = [];
    
    for i = 1:length(rrt_tree.nodes)
        if norm(rrt_tree.nodes(i).position - point) <= radius
            near_indices(end+1) = i;
        end
    end
end

function new_pos = extend_toward_point(from_pos, to_pos, step_size, s)
    % Extend from one point toward another with step size limit
    direction = to_pos - from_pos;
    distance = norm(direction);
    
    if distance <= step_size
        new_pos = to_pos;
    else
        direction = direction / distance; % Normalize
        new_pos = from_pos + step_size * direction;
    end
    
    % Ensure within bounds
    new_pos(1) = max(s.x_min, min(s.x_max, new_pos(1)));
    new_pos(2) = max(s.y_min, min(s.y_max, new_pos(2)));
    new_pos(3) = max(s.z_min, min(s.z_max, new_pos(3)));
end

function min_dist = min_distance_to_nodes(rrt_tree, point)
    % Find minimum distance to any existing node
    min_dist = inf;
    
    for i = 1:length(rrt_tree.nodes)
        dist = norm(rrt_tree.nodes(i).position - point);
        if dist < min_dist
            min_dist = dist;
        end
    end
end

function update_descendants_cost(rrt_tree, node_idx)
    % Recursively update costs of all descendants after rewiring
    node = rrt_tree.nodes(node_idx);
    
    for child_idx = node.children
        edge_cost = norm(rrt_tree.nodes(child_idx).position - node.position);
        rrt_tree.nodes(child_idx).cost = node.cost + edge_cost;
        update_descendants_cost(rrt_tree, child_idx);
    end
end

% Helper functions (to be implemented separately)
function positions = generate_candidate_positions(x, y, z, s)
    % Generate candidate positions in a sphere around current position
    n_candidates = 10; % Adjustable parameter
    positions = [];
    
    for i = 1:n_candidates
        % Random position within movement constraints
        dx = (rand - 0.5) * 2 * s.d_x * 3; % Within 3 steps
        dy = (rand - 0.5) * 2 * s.d_y * 3;
        dz = (rand - 0.5) * 2 * s.d_z * 3;
        
        new_pos = [x + dx, y + dy, z + dz];
        positions = [positions; new_pos];
    end
end

function valid = is_valid_position(pos, s)
    % Check if position is within bounds
    valid = pos(1) >= s.x_min && pos(1) <= s.x_max && ...
            pos(2) >= s.y_min && pos(2) <= s.y_max && ...
            pos(3) >= s.z_min && pos(3) <= s.z_max && ...
            sqrt(pos(1)^2 + pos(2)^2) <= s.x_max;
end

function info_gain = calculate_information_gain(pos, mu_th, Sigma_thth, s)
    % Calculate information gain using entropy reduction
    try
        [~, Sigma_new] = step_ukf_filter(nan, @(th)forward_model(th, pos, s), mu_th, Sigma_thth, s.Sigma_rr);
        info_gain = trace(Sigma_thth) - trace(Sigma_new);
    catch
        info_gain = -inf;
    end
end

function uncertainty_reduction = calculate_uncertainty_reduction(pos, mu_th, Sigma_thth, s)
    % Calculate uncertainty reduction (similar to information gain but normalized)
    try
        [~, Sigma_new] = step_ukf_filter(nan, @(th)forward_model(th, pos, s), mu_th, Sigma_thth, s.Sigma_rr);
        uncertainty_reduction = (trace(Sigma_thth) - trace(Sigma_new)) / trace(Sigma_thth);
    catch
        uncertainty_reduction = -inf;
    end
end

function coverage = calculate_coverage_score(pos, s)
    % Simple coverage score based on distance from explored areas
    % This is a placeholder - could be enhanced with actual coverage maps
    coverage = sqrt(pos(1)^2 + pos(2)^2 + pos(3)^2) / sqrt(s.x_max^2 + s.y_max^2 + s.z_max^2);
end

function efficiency = calculate_efficiency_score(pos, current_pos, s)
    % Efficiency score based on movement cost
    distance = norm(pos - current_pos);
    max_distance = sqrt((2*s.d_x)^2 + (2*s.d_y)^2 + (2*s.d_z)^2);
    efficiency = 1 - (distance / max_distance); % Closer positions are more efficient
end

function loss = enhanced_prediction_error_loss(pos, mu_th, Sigma_thth, s)
    % Enhanced version of prediction error loss with additional considerations
    if sqrt(pos(1)^2 + pos(2)^2) > s.x_max
        loss = 1e6;
        return
    end
    
    % Original loss calculation
    base_loss = prediction_error_loss(pos, mu_th, Sigma_thth, s);
    
    % Add exploration bonus for unvisited areas
    exploration_bonus = calculate_exploration_bonus(pos, s);
    
    % Combine with weights
    loss = base_loss - 0.1 * exploration_bonus; % Negative because we want to minimize loss
end

function bonus = calculate_exploration_bonus(pos, s)
    % Simple exploration bonus - could be enhanced with actual visited position tracking
    % For now, bonus increases with distance from origin
    bonus = sqrt(pos(1)^2 + pos(2)^2 + pos(3)^2) / sqrt(s.x_max^2 + s.y_max^2 + s.z_max^2);
end 