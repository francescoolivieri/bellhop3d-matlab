function tree = traverseTreeMemoized(tree, mu_parent, Sigma_parent, x_parent, y_parent, z_parent, sim, position_cache, Sigma_rr, action_path)
    if nargin < 10
        action_path = []; % Initialize action path at root
    end

    s = sim.settings;

    if isfield(tree, 'branch')
        % Non-leaf node: iterate through child branches (27 possible actions)
        for k = 1:numel(tree.branch)
            
            % Update position using parent's, and current action k (with 27-action model)
            [x_updated, y_updated, z_updated] = update_pos(x_parent, y_parent, z_parent, s, k);

            % Create cache key for this position
            cache_key = sprintf('%.6f_%.6f_%.6f', x_updated, y_updated, z_updated);
            
            % Check if position is valid and if we've computed this before
            if isfinite(x_updated) && isfinite(y_updated) && isfinite(z_updated)
                if isKey(position_cache, cache_key)
                    % Use cached result
                    cached_result = position_cache(cache_key);
                    Sigma_updated = cached_result.Sigma;
                else
                    % Compute and cache new result
                    fwd_model = @(theta) fwd_with_params(sim, sim.params.getEstimationParameterNames, theta, [x_updated y_updated z_updated]);
                    [~, Sigma_updated] = step_ukf_filter(nan, fwd_model, mu_parent, Sigma_parent, Sigma_rr);
                    cached_result.Sigma = Sigma_updated;
                    cached_result.position = [x_updated, y_updated, z_updated];
                    position_cache(cache_key) = cached_result;
                end
            else
                Sigma_updated = NaN(size(Sigma_parent));
            end

            % Assign updated values to child node
            tree.branch(k).mu = mu_parent;
            tree.branch(k).Sigma = Sigma_updated;
            tree.branch(k).x = x_updated;
            tree.branch(k).y = y_updated;
            tree.branch(k).z = z_updated;

            % Append current branch index to action path
            new_action_path = [action_path, k];

            % Recursive call to process subtree
            tree.branch(k) = traverseTreeMemoized(tree.branch(k), mu_parent, Sigma_updated, x_updated, y_updated, z_updated, sim, position_cache, Sigma_rr, new_action_path);
        end
    else
        % Leaf node: store action sequence/path
        tree.actions = action_path;
    end
end 
