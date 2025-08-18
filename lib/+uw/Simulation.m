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
                sc = uw.internal.scenario.scenarioBuilder(obj.settings);
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

        function fig = printSliceTL(obj, bearing_idx)
            if nargin < 2
                % Use existing procedural builder for now
                bearing_idx = 1;
            end

            % Check idx 
            bearing_idx = mod(bearing_idx, obj.settings.sim_num_bearings);
            if bearing_idx == 0, bearing_idx = 1; end

            fig = uw.internal.Visualization.printSliceTL(obj, bearing_idx);
        end

        function printPolarTL(obj)

            % To increase accuracy of the plot -> increase settings.sim_num_bearings 
            uw.internal.Visualization.printPolarTL(obj);
        end

        function updateBellhopFiles(obj)

            uw.internal.writers.writeENV3D(obj.settings.filename + ".env", obj.settings, obj.params.getMap);
            
            if obj.settings.sim_use_bty_file
                uw.internal.writers.writeBTY3D(obj.settings.filename + ".bty", obj.scene, obj.params.getMap);
            end
            
            if obj.settings.sim_use_ssp_file
                grid_x = obj.settings.Ocean_x_min:obj.settings.Ocean_step:obj.settings.Ocean_x_max;
                grid_y = obj.settings.Ocean_y_min:obj.settings.Ocean_step:obj.settings.Ocean_y_max;
                grid_z = 0:obj.settings.Ocean_z_step:obj.settings.sim_max_depth;

                uw.internal.writers.writeSSP3D(obj.settings.filename + ".ssp", grid_x, grid_y, grid_z, obj.params.get('ssp_grid'));
            end
            pause(0.05);
        end

        % function visualizeRays(obj)
        %     % Future stub: call appropriate plotting once implemented.
        %     error('Ray visualization not yet implemented');
        % end
    end
end
