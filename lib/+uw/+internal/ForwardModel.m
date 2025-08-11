classdef ForwardModel
    % FORWARDMODEL  Static methods wrapping Bellhop-3D forward simulation.
    %   Internal helper, not intended for public use. Provides a single
    %   compute(map, pos, s) method that returns transmission loss (dB).

    methods (Static)
        function tl = computeTL(arg1, pos, s)
            % computeTL  Return transmission loss for receiver positions.
            % Usage 1: tl = computeTL(sim, pos)            (preferred)
            % Usage 2: tl = computeTL(map, pos, settings)  (legacy)

            if isa(arg1, 'uw.Simulation')
                sim = arg1;
                map = sim.params.getMap();
                s   = sim.settings;
                scene = sim.scene;
            else
                map   = arg1;
                scene = s.scene;
            end

            global units
            if units == "km"
                pos(:,1:2) = pos(:,1:2) * 1000;  % convert to metres for Bellhop
            end


            % Create environment and auxiliary files
            uw.internal.writers.writeENV3D(s.filename + ".env", s, map);
            if s.sim_use_bty_file
                uw.internal.writers.writeBTY3D(s.filename + ".bty", scene, map);
            end

            
            if s.sim_use_ssp_file
                %% SHOULD I WRITE IT EVERY TIME ?

                grid_x = s.Ocean_x_min:s.Ocean_step:s.Ocean_x_max;
                grid_y = s.Ocean_y_min:s.Ocean_step:s.Ocean_y_max;
                grid_z = 0:s.Ocean_z_step:s.sim_max_depth;

                uw.internal.writers.writeSSP3D(s.filename + ".ssp", grid_x, grid_y, grid_z, map('ssp_grid'));

                %copyfile("ssp_estimate.ssp", [filename '.ssp']);
            end
            pause(0.05);

            % Run Bellhop
            bellhop3d(s.filename);

            % Read SHD
            [~, ~, ~, ~, ~, Pos, pressure] = read_shd(s.filename + ".shd");
            num_bearings = length(Pos.theta);
            [rGrid, zGrid] = meshgrid(Pos.r.r, Pos.r.z);

            tl = zeros(size(pos,1),1);
            for i = 1:size(pos,1)
                bearing_deg = atan2d(pos(i,2), pos(i,1));
                if bearing_deg < 0, bearing_deg = bearing_deg + 360; end
                bearing_idx = mod(round(bearing_deg/(360/num_bearings)), num_bearings) + 1;

                my_range = sqrt(pos(i,1)^2 + pos(i,2)^2);
                my_depth = pos(i,3);
                slice = double(abs(squeeze(pressure(bearing_idx,1,:,:))));
                tl_temp = interp2(rGrid, zGrid, slice, my_range, my_depth, "linear");
                tl(i) = tl_temp;
            end

            tl = max(tl,1e-37);
            tl = -20*log10(tl);

            % delete(filename + ".prt"); delete(filename + ".env"); delete(filename + ".shd");
            % if s.sim_use_bty_file, delete(filename + ".bty"); end
            % if s.sim_use_ssp_file, delete(filename + ".ssp"); end
            pause(0.05);
        end
    end
end
