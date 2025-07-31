function tree = traverseTree(tree, mu_parent, Sigma_parent, x_parent, y_parent, z_parent, s, action_path)
    if nargin < 8
        action_path = []; % Initialize action path at root
    end

    if isfield(tree, 'branch')
        % Non-leaf node: iterate through child branches
        for k = 1:numel(tree.branch)

            
            % Update position using parent's, and current action k
            [x_updated, y_updated, z_updated] = update_pos(x_parent, y_parent, z_parent, s, k);

             
            % Update mu and Sigma using parent's values. Only update if a
            % feasable path
            if isfinite(x_updated) && isfinite(y_updated) && isfinite(z_updated) 
                [~, Sigma_updated] = step_ukf_filter(nan, @(th)forward_model(th, [x_updated y_updated z_updated], s), mu_parent, Sigma_parent, s.Sigma_rr);
            else
                Sigma_updated=NaN(size(Sigma_parent));
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
            tree.branch(k) = traverseTree(tree.branch(k), mu_parent, Sigma_updated, x_updated, y_updated, z_updated, s, new_action_path);
        end
    else
        % Leaf node: store action sequence/path
        tree.actions = action_path;
    end
end
