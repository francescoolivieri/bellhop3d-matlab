classdef Simulation < handle
    % SIMULATION  High-level façade to run Bellhop3-D scenarios.
    %
    %   Construct with defaults or provide custom parameters and/or a scene:
    %       sim   = uw.Simulation();
    %       sim   = uw.Simulation(params);
    %       sim   = uw.Simulation(params, sceneStruct);
    %
    %   Query transmission loss (TL) at receiver positions (x[km], y[km], z[m]):
    %       rx    = [linspace(0,1,50)', zeros(50,1), 20*ones(50,1)];
    %       TL    = sim.computeTL(rx);
    %
    %   This interface hides writing .env/.bty/.ssp files and invoking Bellhop3‑D.
    %   Use visualize methods to quickly inspect the environment and TL.

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
                sc = uw.internal.scenario.buildScenario(obj.settings);
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
            % computeTL  Transmission loss at receiver positions.
            %   TL = sim.computeTL(RX_POS)
            %   RX_POS is N×3 [x y z] with x,y in km (if OBJ.units=="km") and z in m.
            %   Returns TL (dB) as an N×1 vector.
            arguments
                obj
                receiverPos (:,3) double {mustBeFinite}
            end
            tl = uw.internal.ForwardModel.computeTL(obj, receiverPos);
        end

        function ssp_rcv = sampleSoundSpeed(obj, receiverPos)
            % sampleSoundSpeed  Interpolate SSP at a receiver position.
            %   C = sim.sampleSoundSpeed( RX_POS )
            %   RX_POS is N×3 [x y z] with x,y in km (if OBJ.units=="km") and z in m.
            %   Returns sound speed (m/s) at RX_POS by trilinear interpolation.
            arguments
                obj
                receiverPos (:,3) double {mustBeFinite}
            end
            % Build SSP grid coordinates from settings
            % x,y in km; z in m
            x_rcv = receiverPos(:,1);
            y_rcv = receiverPos(:,2);
            z_rcv = receiverPos(:,3);
            
            s = obj.settings;
            x = s.Ocean_x_min:s.OceanGridStep:s.Ocean_x_max;           % km east‑west
            y = s.Ocean_y_min:s.OceanGridStep:s.Ocean_y_max;           % km north‑south
            z = 0:s.Ocean_z_step:s.sim_max_depth;                   % m depth (we take simulation depth, bellhop detects where the real bty is)
            
            ssp_grid = obj.params.get('ssp_grid');

            % Interpolate SSP at receiver
            ssp_rcv = interp3(x, y, z, ssp_grid, x_rcv, y_rcv, z_rcv, 'linear');
        end

        function tl = computeTLWithNoise(obj, receiverPos, tl_noise)
            % computeTLWithNoise  TL with additive Gaussian noise.
            %   TL = computeTLWithNoise(OBJ, POS, SIGMA) or TL = sim.computeTLWithNoise(POS, SIGMA)
            %   SIGMA is the TL noise st.dev. in dB (default from settings).
            %   Returns TL (dB) as N×1 with noise added.
            arguments
                obj
                receiverPos (:,3) double {mustBeFinite}
                tl_noise (1,1) double {mustBeFinite} = obj.settings.sigma_tl_noise
            end
            % Compute TL and add Gaussian noise
            tl = uw.internal.ForwardModel.computeTL(obj, receiverPos) + tl_noise*randn;
        end


        function scenarioFigure = plotEnvironment(obj)
            % plotEnvironment  Plot water surface and ocean floor meshes.
            %   Returns the created figure handle.
            scenarioFigure = figure;
            title('Ocean Environment')

            % plotbdry3d(obj.settings.filename + ".bty")
                
            % Plot ocean floor first (darker blue)
            surf(obj.scene.X, obj.scene.Y, -obj.scene.floor, 'FaceColor', [0.1, 0.2, 0.4], 'FaceAlpha', 0.8, 'EdgeColor', 'none');
            hold on;
            
            % Plot water surface (lighter blue, semi-transparent)
            surf(obj.scene.X, obj.scene.Y, obj.scene.surface, 'FaceColor', [0.3, 0.7, 1.0], 'FaceAlpha', 0.6, 'EdgeColor', 'none');
            
            axis on
        end

        function fig = plotTLSlice(obj, bearing_idx)
            % plotTLSlice  Plot a TL slice for a given bearing index.
            %   If omitted, uses bearing_idx = 1. The bearing resolution is
            %   controlled by settings.sim_num_bearings.
            if nargin < 2
                % Use existing procedural builder for now
                bearing_idx = 1;
            end

            % Check idx 
            bearing_idx = mod(bearing_idx, obj.settings.sim_num_bearings);
            if bearing_idx == 0, bearing_idx = 1; end

            fig = uw.internal.Visualization.plotTLSlice(obj, bearing_idx);
        end

        function plotTLPolar(obj)
            % plotTLPolar  Polar TL plot around the source.
            %   Uses plotshdpol on the most recent .shd file (computes if needed).

            % To increase accuracy of the plot -> increase settings.sim_num_bearings 
            uw.internal.Visualization.plotTLPolar(obj);
        end

        function writeBellhopInputFiles(obj)
            % writeBellhopInputFiles  Regenerate .env/.bty/.ssp for current state.
            %   Useful after changing parameters or scene without recomputing TL.

            uw.internal.writers.writeENV3D(obj.settings.filename + ".env", obj.settings, obj.params.getMap);
            
            if obj.settings.sim_use_bty_file
                uw.internal.writers.writeBTY3D(obj.settings.filename + ".bty", obj.scene, obj.params.getMap);
            end
            
            if obj.settings.sim_use_ssp_file
                grid_x = obj.settings.Ocean_x_min:obj.settings.OceanGridStep:obj.settings.Ocean_x_max;
                grid_y = obj.settings.Ocean_y_min:obj.settings.OceanGridStep:obj.settings.Ocean_y_max;
                grid_z = 0:obj.settings.Ocean_z_step:obj.settings.sim_max_depth;

                uw.internal.writers.writeSSP3D(obj.settings.filename + ".ssp", grid_x, grid_y, grid_z, obj.params.get('ssp_grid'));
            end
            pause(0.05);
        end

        
    end
end
