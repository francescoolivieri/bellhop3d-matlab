classdef SimulationParameters < handle
    % SIMULATIONPARAMETERS  Parameter container for Bellhop3-D simulations.
    %
    %   This class provides the same functionality that "ParameterMap" used
    %   to offer, but is now namespaced inside the "uw" MATLAB package so it
    %   can serve as the public interface of the upcoming Bellhop3-D
    %   abstraction library.
    %
    %   Most existing code that relied on ParameterMap will continue to work
    %   if it uses the compatibility wrapper (see old ParameterMap.m).  New
    %   code should create parameters via:
    %
    %       params = uw.SimulationParameters.default();
    %
    %   or
    %       params = uw.SimulationParameters(struct_with_fields);
    %
    %   See the detailed help for available methods.
    % ---------------------------------------------------------------------

    properties (Access = private)
        param_map                  % containers.Map of parameter values
        estimation_param_names     % cell array of names to estimate
    end

    properties (Dependent)
        all_keys   % Return all parameter names in the map
    end

    %% Public API ---------------------------------------------------------
    methods
        function obj = SimulationParameters(initial_params, estimation_names)
            %   OBJ = SimulationParameters(STRUCT_OR_MAP [, EST_NAMES])
            %   If INITIAL_PARAMS is a containers.Map, its contents are
            %   copied.  Otherwise it must be a struct with the same fields
            %   returned by get_sim_settings() (or the new default() static
            %   constructor).  The optional EST_NAMES is a cell array of
            %   parameter names selected for estimation.

            if nargin == 0
                % No input → use simulation defaults
                initial_params = get_sim_settings();
            end

            if isa(initial_params, 'containers.Map')
                obj.param_map = containers.Map(initial_params.keys, initial_params.values);
            else
                % Construct map from struct fields
                obj.param_map = containers.Map();

                % Acoustic parameters
                obj.param_map('sound_speed_water')    = initial_params.sim_param_sp_water;     % m/s
                obj.param_map('sound_speed_sediment') = initial_params.sim_param_sp_sediment;  % m/s
                obj.param_map('density_sediment')     = initial_params.sim_param_density_sediment; % g/cm³
                obj.param_map('attenuation_sediment') = initial_params.sim_param_attenuation_sediment; % dB/λ

                % 3-D sound-speed profile grid (initialised as NaNs)
                obj.param_map('ssp_grid') = nan( ...
                    length(initial_params.Ocean_y_min:initial_params.Ocean_step:initial_params.Ocean_y_max), ...
                    length(initial_params.Ocean_x_min:initial_params.Ocean_step:initial_params.Ocean_x_max), ...
                    length(0:initial_params.Ocean_z_step:initial_params.sim_max_depth));

                % Geometric parameters
                obj.param_map('water_depth') = initial_params.sim_max_depth;  % m
                obj.param_map('source_depth') = initial_params.sim_sender_depth; % m
                obj.param_map('range')        = initial_params.sim_range;        % km or m ? (kept as-is)
            end

            % Estimation names -------------------------------------------------
            if nargin > 1
                obj.estimation_param_names = estimation_names;
            else
                obj.estimation_param_names = {};
            end
        end

        function keys = get.all_keys(obj)
            keys = obj.param_map.keys;
        end

        function value = get(obj, name)
            if obj.param_map.isKey(name)
                value = obj.param_map(name);
            else
                error('SimulationParameters:get', 'Parameter "%s" not found.', name);
            end
        end

        function set(obj, name, value)
            obj.param_map(name) = value;

            if obj.isSedimentParameter(name)
                obj.applySedimentPadding(obj.param_map);
            end
        end

        function arr = asArray(obj, names)
            if nargin < 2
                names = obj.estimation_param_names;
            end
            arr = obj.getParameterArray(names);
        end

        function update(obj, values, names)
            if nargin < 3
                names = obj.estimation_param_names;
            end

            cont = 1;
            unique_names = unique(names, 'stable');
            for i = 1:numel(unique_names)
                pname = unique_names{i};
                count = sum(strcmp(names, pname));
                if count == 1
                    obj.set(pname, values(cont));
                    cont = cont + 1;
                else
                    obj.set(pname, values(cont:cont+count-1));
                    cont = cont + count;
                end
            end
        end

        function map = getMap(obj)
            map = containers.Map(obj.param_map.keys, obj.param_map.values);
        end

        function tf = hasParameter(obj, name)
            tf = obj.param_map.isKey(name);
        end

        function copyFrom(obj, other)
            if isa(other, 'uw.SimulationParameters')
                src = other.getMap();
            else
                src = other;  % assume containers.Map
            end
            k = src.keys;
            for i = 1:numel(k)
                obj.set(k{i}, src(k{i}));
            end
        end

        function applySedimentPadding(obj, default_param_map)
            obj.param_map = paddingSedimentParams(obj.param_map, default_param_map);
        end

        function display(obj, titleStr)
            if nargin < 2, titleStr = 'Simulation Parameters'; end
            fprintf('\n=== %s ===\n', titleStr);
            disp(table(obj.param_map.keys', obj.param_map.values', 'VariableNames', {'Key', 'Value'}));
        end

        function diff = compareWith(obj, other, names)
            if nargin < 3
                names = obj.estimation_param_names;
            end
            diff = struct();
            for i = 1:numel(names)
                n = names{i};
                if obj.hasParameter(n)
                    if isa(other, 'uw.SimulationParameters') && other.hasParameter(n)
                        diff.(n) = obj.get(n) - other.get(n);
                    elseif isa(other, 'containers.Map') && other.isKey(n)
                        diff.(n) = obj.get(n) - other(n);
                    end
                end
            end
        end

        function setEstimationParameterNames(obj, names)
            obj.estimation_param_names = names;
        end

        function names = getEstimationParameterNames(obj)
            names = obj.estimation_param_names;
        end
    end

    %% Static helpers ------------------------------------------------------
    methods (Static)
        function obj = default()
            % DEFAULT  Return an instance populated with\n            %          get_sim_settings() defaults.
            p = uw.SimSettings.default();
            obj = uw.SimulationParameters(p);
        end
    end

    %% Internal helper methods --------------------------------------------
    methods (Access = private)
        function arr = getParameterArray(obj, names)
            arr = zeros(numel(names), 1);
            cont = 1;
            unique_names = unique(names, 'stable');
            for i = 1:numel(unique_names)
                pname = unique_names{i};
                if obj.param_map.isKey(pname)
                    vals = obj.param_map(pname);
                    for j = 1:numel(vals)
                        arr(cont) = vals(j);
                        cont = cont + 1;
                    end
                else
                    error('SimulationParameters:getParameterArray', ...
                          'Parameter "%s" not found.', pname);
                end
            end
        end

        function tf = isSedimentParameter(~, name)
            tf = any(strcmp(name, {'density_sediment', 'sound_speed_sediment', 'attenuation_sediment'}));
        end
    end
end

%% Local function ---------------------------------------------------------
function param_map = paddingSedimentParams(param_map, default_param_map)
    keys = {'density_sediment', 'sound_speed_sediment', 'attenuation_sediment'};
    lens = zeros(1,numel(keys));
    for i = 1:numel(keys)
        k = keys{i};
        if isKey(param_map, k)
            v = param_map(k);
            if isnumeric(v)
                lens(i) = length(v);
            else
                error('SimulationParameters:paddingSedimentParams', 'Parameter "%s" must be numeric.', k);
            end
        else
            warning('SimulationParameters:paddingSedimentParams', 'Parameter "%s" missing.', k);
            lens(i) = 0;
        end
    end
    max_len = max(lens);
    for i = 1:numel(keys)
        k = keys{i};
        if isKey(param_map, k)
            v = param_map(k);
            n_missing = max_len - length(v);
            if n_missing > 0
                default_val = default_param_map(k);
                param_map(k) = [v; repmat(default_val, n_missing, 1)];
            end
        end
    end
end
