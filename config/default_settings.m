function s = default_settings()
    % DEFAULT_SETTINGS - Default configuration for UnderwaterModeling3D
    %
    % This provides sensible defaults for different use cases.
    % Copy and modify as needed for your specific application.
    
    %% IPP Planning Method Selection
    % Options: 'rrt_star_ipp', 'multi_objective', 'information_gain', 
    %          'uncertainty_guided', 'tree_memoized', 'tree_27'
    s.ipp_method = 'rrt_star_ipp';  % Best for drone/boat planning
    
    %% RRT Parameters (for RRT-based methods)
    s.rrt_max_iter = 150;        % Iterations for tree building
    s.rrt_step_size = 1.5;       % Step size for extending tree  
    s.rrt_goal_bias = 0.1;       % Probability of goal-biased sampling
    s.rrt_search_radius = 6.0;   % Search radius for RRT* rewiring
    
    %% Multi-Objective Weights (for multi_objective method)
    s.w_info = 0.5;              % Information gain weight
    s.w_coverage = 0.3;          % Coverage weight
    s.w_efficiency = 0.2;        % Movement efficiency weight
    
    %% GP Parameters
    s.gp_ell_h = 300;            % Horizontal length scale (m)
    s.gp_ell_v = 20;             % Vertical length scale (m)
    s.gp_sigma_f = 1;            % Signal variance
    s.gp_sigma_n = 0.1;          % Noise variance
    
    %% Planning Grid Resolution
    s.grid_res_x = 10;           % Grid resolution in x (m)
    s.grid_res_y = 10;           % Grid resolution in y (m)
    s.grid_res_z = 5;            % Grid resolution in z (m)
    
    %% Performance Settings
    s.n_candidates = 50;         % Number of candidate positions
    s.use_parallel = false;      % Enable parallel processing
    s.verbose = true;            % Enable progress output
    
    fprintf('📋 Default settings loaded for method: %s\n', s.ipp_method);
end
