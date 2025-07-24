function data=pos_next_measurement(data,s)

% Get index of last state
idx=find(isfinite(data.x), 1,'last');


% Check if sensor management or not 
if s.sm

    if s.bayesian_opt

        % Define the optimization variables
        pos_x = optimizableVariable('x', [s.x_min, s.x_max],'Type', 'real');
        pos_y = optimizableVariable('y', [s.y_min, s.y_max],'Type', 'real');
        pos_z = optimizableVariable('z', [s.z_min, s.z_max],'Type', 'real');

        % Define the objective function
        objectiveFcn = @(pos) prediction_error_loss([pos.x, pos.y, pos.z], ...
            data.th_est(:,idx), squeeze(data.Sigma_est(:,:,idx)), s); % Pass x as a 3D vector

        % Run Bayesian Optimization
        results = bayesopt(objectiveFcn, [pos_x, pos_y, pos_z], ...
            'IsObjectiveDeterministic',false,...
            'AcquisitionFunctionName','expected-improvement-per-second-plus' , ...
            'GPActiveSetSize', 300,...
            'NumSeedPoints', 20,...
            'MaxObjectiveEvaluations', 40, ...
            'ExplorationRatio', 0.01,...
            'Verbose', 1);

        % Get optimal result
        data.x(idx+1) = results.XAtMinObjective.x;
        data.y(idx+1) = results.XAtMinObjective.y;
        data.z(idx+1) = results.XAtMinObjective.z;

    else
        % Generate tree
        tree = generateTree(s.depth);

        tic
        % Polulate the tree
        tree = traverseTree(tree, data.th_est(:, idx), data.Sigma_est(:, :, idx), ...
            data.x(idx), data.y(idx), data.z(idx), s);
        toc

        % Get best action
        best_action = getBestActionSequence(tree);

        % Update the position based upon the best acction
        [data.x(idx+1), data.y(idx+1), data.z(idx+1)] = update_pos( data.x(idx), data.y(idx), data.z(idx), s, best_action(1));
    end

else
    
    % Move as lawn mower (Sweep in y direction)
   if (data.y(idx) + s.d_y) < s.y_max
        data.y(idx+1) = data.y(idx) + s.d_y;
        data.x(idx+1) = data.x(idx);
        data.z(idx+1) = data.z(idx);
    else
        % Now X direction
        data.y(idx+1) = s.y_min;
        if (data.x(idx) + s.d_x) < s.x_max
            data.x(idx+1) = data.x(idx) + s.d_x;
            data.z(idx+1) = data.z(idx);
        else
            % Now Z direction
            data.x(idx+1) = s.x_min;
            if (data.z(idx) + s.d_z) < s.z_max
                data.z(idx+1) = data.z(idx) + s.d_z;
            else
                % Restart
                data.z(idx+1) = s.z_min;
            end
        end
    end
end
end


