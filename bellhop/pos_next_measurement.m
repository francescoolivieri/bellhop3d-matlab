function data=pos_next_measurement(data,s)

% Get index of last state
idx=find(isfinite(data.x), 1,'last') + 1;

display(idx);

% Check if sensor management or not 
if s.sm

    if s.bayesian_opt

        % Define the optimization variables
        pos_r = optimizableVariable('r', [s.r_min, s.r_max],'Type', 'real');
        pos_z = optimizableVariable('z', [s.z_min, s.z_max],'Type', 'real');

        % Define the objective function
        objectiveFcn = @(pos) prediction_error_loss([pos.r, pos.z],data.th_est(:,idx),squeeze(data.Sigma_est(:,:,idx)),s); % Pass x as a 2D vector

        % Run Bayesian Optimization
        results = bayesopt(objectiveFcn, [pos_r, pos_z], ...
            'IsObjectiveDeterministic',false,...
            'AcquisitionFunctionName','expected-improvement-per-second-plus' , ...
            'GPActiveSetSize', 300,...
            'NumSeedPoints', 20,...
            'MaxObjectiveEvaluations', 40, ...
            'ExplorationRatio', 0.01,...
            'Verbose', 1);

        % Get optimal result
        data.r(idx+1)=results.XAtMinObjective.r;
        data.z(idx+1)= results.XAtMinObjective.z;
      

    else
        % Generate tree
        tree = generateTree(s.depth);

        tic
        % Polulate the tree
        tree = traverseTree(tree, data.th_est(:, idx), data.Sigma_est(:, :, idx), data.r(idx), data.z(idx),s);
        toc

        % Get best action
        best_action = getBestActionSequence(tree);

        % Update the position based upon the best acction
        [data.r(idx+1), data.z(idx+1)] = update_pos( data.r(idx), data.z(idx),s, best_action(1));
    end

else
    
    data.x(idx) = randi([s.x_min, s.x_max]);
    data.y(idx) = randi([s.y_min, s.y_max]);
    data.z(idx) = randi([s.z_min, s.z_max]);
    

   % % Move as lawn mower 
   % if (data.z(idx)+s.d_z)<s.z_max
   %      data.z(idx+1)=data.z(idx)+s.d_z;
   %      data.x(idx+1)=data.x(idx);
   %      data.y(idx+1)=data.y(idx);
   % else
   %     data.z(idx+1)=s.z_min;
   %     if (data.x(idx)+s.d_x)<s.x_max
   %         data.x(idx+1)=data.x(idx)+s.d_x;
   %     else
   %         data.z(idx+1)=s.z_min;
   %     end 
   % end

end
end


