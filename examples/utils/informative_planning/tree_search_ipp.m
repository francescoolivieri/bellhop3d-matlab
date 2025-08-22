function data = tree_search_ipp(data, s, idx)
    % Tree approach 
    tree = generateTree(s.tree_depth);
    
    tic
    tree = traverseTree(tree, data.th_est(:, idx), data.Sigma_est(:, :, idx), ...
        data.x(idx), data.y(idx), data.z(idx), data.sim_est, data.Sigma_rr);
    toc
    
    best_action = getBestActionSequence(tree);
    [data.x(idx+1), data.y(idx+1), data.z(idx+1)] = update_pos(data.x(idx), data.y(idx), data.z(idx), s, best_action(1));
end