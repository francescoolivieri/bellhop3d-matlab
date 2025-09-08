classdef Sensor < handle
    % SENSOR  Represents a movable sensor/agent in the simulation.
    %   Simple, discoverable motion API with built-in strategies.
    %
    %   Usage:
    %     sim.sensor.move([1 1 10]);           % absolute position
    %     sim.sensor.lawnmower();              % built-in pattern
    %     sim.sensor.treeSearch(opts, state);  % IPP with estimation
    %     sim.sensor.move(@myPlanner);         % custom function

    properties
        id                      % string or numeric identifier
        role (1,1) string = "receiver"   % semantic role (e.g., "receiver", "auv")
        pos (1,3) double        % current [x y z]
        path (:,3) double = nan(0,3)  % history of positions
        bounds struct           % movement bounds and step sizes
        units (1,1) string = "km"       % x/y in km if "km"; z in m
        sim                     % back-reference to uw.Simulation (optional)
        % Strategy configuration (optional convenience)
        strategyName (1,1) string = ""   % e.g., "treeSearch", "rrtStar", "randomInfoGain", "lawnmower"
        strategyArgs cell = {}            % stored name-value args (cell array)
    end

    methods
        function obj = Sensor(role, startPos, settings)
            % SENSOR(ROLE, START_POS, SETTINGS)
            if nargin < 1 || isempty(role), role = "receiver"; end
            if nargin < 2 || isempty(startPos), startPos = [0 0 0]; end

            obj.role = string(role);
            obj.pos = startPos;
            obj.path = startPos;
            if nargin >= 3 && ~isempty(settings)
                obj.bounds = uw.Sensor.extractBounds(settings);
                if isfield(settings, 'units')
                    obj.units = string(settings.units);
                end
            else
                obj.bounds = struct();
            end
        end

        function move(obj, target)
            % MOVE  Move sensor to absolute position or via custom function.
            %   MOVE(OBJ, [x y z])        - absolute position
            %   MOVE(OBJ, @plannerFn)     - custom planner function
            %
            %   For built-in strategies, use direct methods:
            %     obj.lawnmower(), obj.treeSearch(opts, state), etc.

            if isnumeric(target) && numel(target) == 3
                next = target(:)';
            elseif isa(target, 'function_handle')
                next = target(obj);
            else
                error('Sensor:move', 'Target must be [x y z] or function handle. Use direct methods for built-in strategies.');
            end

            obj.pos = next;
            obj.path(end+1, :) = next;
        end

        %% Built-in IPP Strategies ==========================================
        
        function next = lawnmower(obj)
            % LAWNMOWER  Rectangular scanning pattern using bounds.
            b = obj.bounds;
            if isempty(obj.path)
                p = obj.pos;
            else
                p = obj.path(end, :);
            end

            temp_x = p(1); temp_y = p(2); temp_z = p(3);
            while true
                if (temp_y + b.d_y) < b.y_max
                    temp_y = temp_y + b.d_y;
                else
                    temp_y = b.y_min;
                    if (temp_x + b.d_x) < b.x_max
                        temp_x = temp_x + b.d_x;
                    else
                        temp_x = b.x_min;
                        if (temp_z + b.d_z) < b.z_max
                            temp_z = temp_z + b.d_z;
                        else
                            temp_z = b.z_min;
                        end
                    end
                end
                % Check circular constraint
                if sqrt(temp_x^2 + temp_y^2) < b.x_max
                    next = [temp_x, temp_y, temp_z];
                    obj.pos = next;
                    obj.path(end+1, :) = next;
                    return;
                end
            end
        end

        %% Strategy convenience API =========================================
        function setStrategy(obj, name, varargin)
            % SETSTRATEGY  Store strategy name and its name-value args.
            %   setStrategy("treeSearch", "depth", 2)
            %   setStrategy("rrtStar", "max_iter", 30, "step_size", 0.8)
            obj.strategyName = string(name);
            obj.strategyArgs = varargin;
        end

        function next = step(obj, estimationState)
            % STEP  Execute stored strategy once. Pass ESTIMATION as needed.
            %   step(ESTIMATION_STATE)
            if strlength(obj.strategyName) == 0
                error('Sensor:step', 'No strategy configured. Call setStrategy(name, varargin) first.');
            end
            args = obj.strategyArgs;
            % Always pass estimation state as name-value for robustness
            if nargin >= 2 && ~isempty(estimationState)
                args = [args, {'estimation'}, {estimationState}]; %#ok<AGROW>
            end
            switch lower(obj.strategyName)
                case {"lawnmower"}
                    next = obj.lawnmower();
                    return
                case {"treESearch","tree_search"}
                    next = obj.treeSearch(args{:});
                case {"rrtstar","rrt_star"}
                    next = obj.rrtStar(args{:});
                case {"randominfogain","random_information_gain","information_gain"}
                    next = obj.randomInfoGain(args{:});
                otherwise
                    error('Sensor:step', 'Unknown strategy "%s".', obj.strategyName);
            end
        end

        function next = stepFromSettings(obj, estimationState)
            % STEPFROMSETTINGS  Execute a step using sim.settings.ipp_method.
            %   Provided for convenience/transition from settings-driven flows.
            if isempty(obj.sim) || isempty(obj.sim.settings)
                error('Sensor:stepFromSettings', 'Simulation settings not available on sensor.');
            end
            s = obj.sim.settings;
            switch s.ipp_method
                case 'tree_search'
                    depth = 1; if isfield(s, 'tree_depth'), depth = s.tree_depth; end
                    next = obj.treeSearch("depth", depth, estimationState);
                case 'rrt_star'
                    next = obj.rrtStar("max_iter", 15, estimationState);
                case 'information_gain'
                    next = obj.randomInfoGain("n_candidates", 10, estimationState);
                otherwise
                    next = obj.lawnmower();
            end
        end

        function next = treeSearch(obj, varargin)
            % TREESEARCH  Tree-based IPP planning.
            %   Usage: treeSearch(estimationState)
            %          treeSearch("depth", 3, estimationState)
            %          treeSearch("depth", 2, "estimation", state)
            
            % Parse arguments
            p = inputParser;
            addOptional(p, 'depth', 1, @isnumeric);
            addParameter(p, 'estimation', struct(), @isstruct);
            
            % Handle different calling patterns
            if nargin >= 2 && isstruct(varargin{end})
                % Last argument is estimation state
                estimationState = varargin{end};
                parse(p, varargin{1:end-1});
            else
                % No estimation state or it's passed as parameter
                parse(p, varargin{:});
                if isfield(p.Results, 'estimation')
                    estimationState = p.Results.estimation;
                else
                    estimationState = struct();
                end
            end
            
            depth = p.Results.depth;
            
            % Call IPP function 
            next = tree_search_ipp(obj.pos, obj.bounds, estimationState, depth);
            
            obj.pos = next;
            obj.path(end+1, :) = next;
        end

        function next = rrtStar(obj, varargin)
            % RRTSTAR  RRT*-based IPP planning.
            %   Usage: rrtStar(estimationState)
            %          rrtStar("max_iter", 50, estimationState)
            %          rrtStar("max_iter", 20, "step_size", 0.8, estimationState)
            
            % Parse arguments
            p = inputParser;
            addParameter(p, 'max_iter', 15, @isnumeric);
            addParameter(p, 'step_size', 1.0, @isnumeric);
            addParameter(p, 'goal_bias', 0.05, @isnumeric);
            addParameter(p, 'search_radius', 8.0, @isnumeric);
            addParameter(p, 'estimation', struct(), @isstruct);
            
            % Handle different calling patterns
            if nargin >= 2 && isstruct(varargin{end})
                % Last argument is estimation state
                estimationState = varargin{end};
                parse(p, varargin{1:end-1});
            else
                % No estimation state or it's passed as parameter
                parse(p, varargin{:});
                estimationState = p.Results.estimation;
            end
            
            % Call IPP function with clean parameters
            next = rrt_star_based_ipp(obj.pos, obj.bounds, estimationState, ...
                p.Results.max_iter, p.Results.step_size, p.Results.goal_bias, p.Results.search_radius);
            
            obj.pos = next;
            obj.path(end+1, :) = next;
        end

        function next = randomInfoGain(obj, varargin)
            % RANDOMINFOGAIN  Random sampling IPP planning.
            %   Usage: randomInfoGain(estimationState)
            %          randomInfoGain("n_candidates", 20, estimationState)
            %          randomInfoGain("n_candidates", 15, "search_radius", 4, estimationState)
            
            % Parse arguments
            p = inputParser;
            addParameter(p, 'n_candidates', 10, @isnumeric);
            addParameter(p, 'search_radius', 3, @isnumeric);
            addParameter(p, 'estimation', struct(), @isstruct);
            
            % Handle different calling patterns
            if nargin >= 2 && isstruct(varargin{end})
                % Last argument is estimation state
                estimationState = varargin{end};
                parse(p, varargin{1:end-1});
            else
                % No estimation state or it's passed as parameter
                parse(p, varargin{:});
                estimationState = p.Results.estimation;
            end
            
            % Call IPP function with clean parameters
            next = random_points_ipp(obj.pos, obj.bounds, estimationState, ...
                p.Results.n_candidates, p.Results.search_radius);
            
            obj.pos = next;
            obj.path(end+1, :) = next;
        end

    end

    methods (Static)
        function bounds = extractBounds(s)
            % EXTRACTBOUNDS  Build a bounds struct from SimSettings-like s
            fields = {'x_min','x_max','y_min','y_max','z_min','z_max', ...
                      'd_x','d_y','d_z','OceanDepth','sim_max_range', ...
                      'sim_source_x','sim_source_y'};
            bounds = struct();
            for i = 1:numel(fields)
                f = fields{i};
                if isfield(s, f)
                    bounds.(f) = s.(f);
                end
            end
        end


    end
end


