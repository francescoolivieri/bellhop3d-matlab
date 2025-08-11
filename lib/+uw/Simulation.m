classdef Simulation < handle
    % SIMULATION  High-level façade to run Bellhop3-D scenarios.
    %
    %   Typical use-case:
    %       sim      = uw.Simulation();   % default flat scenario and
    %       simulation settings
    %       rx_pos       = [linspace(0,1,50)', zeros(50,1), 20*ones(50,1)]; % x,y,z
    %       TL       = sim.computeTL(rx_pos);
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

            % Build settings struct
            obj.settings = uw.SimSettings.default();

            % Scene -------------------------------------------------------
            if nargin < 2 || isempty(scene)
                % Use existing procedural builder for now
                sc = scenarioBuilder(obj.settings);
                obj.scene = sc;
            else
                obj.scene = scene;
            end
            obj.settings.scene = obj.scene;

            % Write files -------------------------------------------------
            if obj.settings.sim_use_ssp_file
                obj.params.set("ssp_grid", generateSSP3D(obj.settings));
            end

            if obj.settings.sim_use_bty_file
                uw.internal.writers.writeBTY3D(obj.settings.filename + ".bty", obj.scene, obj.params.getMap());
            end
            
            uw.internal.writers.writeENV3D(obj.settings.filename + ".env", obj.settings, obj.params.getMap()); 

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

        function tl = computeNoisyTL(obj, receiverPos, tl_noise)
            % computeTL  Return transmission loss for receiver positions.
            arguments
                obj
                receiverPos (:,3) double {mustBeFinite}
                tl_noise (1,1) double {mustBeFinite} = obj.settings.sigma_tl_noise
            end
          
            global units; units = obj.units;

            tl = uw.internal.ForwardModel.computeTL(obj, receiverPos) + tl_noise*randn;
        end

        function scenarioFigure = printScenario(obj)
            scenarioFigure = figure;
            title('Ocean Environment')

            % Plot ocean floor first (darker blue)
            surf(obj.scene.X, obj.scene.Y, obj.scene.oceanFloor, 'FaceColor', [0.1, 0.2, 0.4], 'FaceAlpha', 0.8, 'EdgeColor', 'none');
            hold on;
            
            % Plot water surface (lighter blue, semi-transparent)
            surf(obj.scene.X, obj.scene.Y, obj.scene.waterSurface, 'FaceColor', [0.3, 0.7, 1.0], 'FaceAlpha', 0.6, 'EdgeColor', 'none');
            
            axis on
        end

        function printSliceTL(obj, bearing_idx)
            
            % Check idx 
            bearing_idx = mod(bearing_idx, obj.settings.num_bearings);
            if bearing_idx == 0, bearing_idx = 1; end

            uw.internal.Visualization.printSliceTL(obj, bearing_idx);
        end

        function printPolarTL(obj)
            uw.internal.Visualization.printPolarTL(obj);
        end

        % function visualizeRays(obj)
        %     % Future stub: call appropriate plotting once implemented.
        %     error('Ray visualization not yet implemented');
        % end
    end
end
