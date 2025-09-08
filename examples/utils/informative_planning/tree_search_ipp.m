function next_pos = tree_search_ipp(current_pos, bounds, estimation_state, tree_depth)
    % Tree-based IPP planning
    % CURRENT_POS: [x y z] current position
    % BOUNDS: struct with movement constraints (d_x, d_y, d_z, etc.)
    % ESTIMATION_STATE: struct with sim_est, th_est, Sigma_est, Sigma_rr
    % TREE_DEPTH: search depth (default: 1)
    
    if nargin < 4, tree_depth = 1; end
    
    tree = generateTree(tree_depth);
    
    tic
    tree = traverseTree(tree, estimation_state.th_est, estimation_state.Sigma_est, ...
        current_pos(1), current_pos(2), current_pos(3), ...
        estimation_state.sim_est, estimation_state.Sigma_rr);
    toc
    
    best_action = getBestActionSequence(tree);
    [next_x, next_y, next_z] = update_pos(current_pos(1), current_pos(2), current_pos(3), bounds, best_action(1));
    next_pos = [next_x, next_y, next_z];
end