classdef Simulation < handle
    % SIMULATION  High-level façade to run Bellhop3-D scenarios.
    %
    %   Typical use-case:
    %       params   = uw.SimulationParameters.default();
    %       sim      = uw.Simulation(params);   % default flat scenario
    %       rx       = [linspace(0,1,50)', zeros(50,1), 20*ones(50,1)]; % x,y,z
    %       TL       = sim.run(rx);
    %
    %   The class hides the details of creating .env/.bty/.ssp files and
    %   invoking Bellhop3-D.
    %
    %   Future extensions will add: parameter estimation loops, filters,
    %   NBV planning, etc.

    properties
        params   uw.SimulationParameters   % acoustic & geometric parameters
        scene                          % struct with X, Y, floor fields
        settings                        % struct (legacy) used by writers
        units   (1,1) string = "km"     % distance units for x/y ("km" or "m")
    end

    methods
        function obj = Simulation(params, scene)
            % SIMULATION([PARAMS] [, SCENE])
            %   PARAMS – uw.SimulationParameters (default: .default())
            %   SCENE  – struct, if omitted a default scenario is built.

            if nargin < 1 || isempty(params)
                params = uw.SimulationParameters.default();
            end
            obj.params = params;

            % Build legacy settings struct (to be phased out)
            obj.settings = uw.SimSettings.default();
            obj.settings.bellhop_file_name = obj.settings.bellhop_file_name + char(randi([0, 9999999]));  % base filename

            % Scene --------------------------------------------------------
            if nargin < 2 || isempty(scene)
                % Use existing procedural builder for now
                [sc, ~] = scenarioBuilder(obj.settings);
                obj.scene = sc;
            else
                obj.scene = scene;
            end
            obj.settings.scene = obj.scene;
        end

        function tl = computeTL(obj, receiverPos)
            % computeTL  Return transmission loss for receiver positions.
            arguments
                obj
                receiverPos (:,3) double {mustBeFinite}
            end
            global units; units = obj.units;

            tl = uw.internal.ForwardModel.computeTL(obj, receiverPos);
        end

        function tl = run(obj, receiverPos)
            % RUN  Alias for computeTL (legacy compatibility)
            tl = obj.computeTL(receiverPos);
        end

        function visualizeEnvironment(obj)
            uw.internal.Visualization.drawEnvironment(obj.settings, obj.scene);
        end

        function visualizeRays(obj)
            % Future stub: call appropriate plotting once implemented.
            error('Ray visualization not yet implemented');
        end
    end
end
