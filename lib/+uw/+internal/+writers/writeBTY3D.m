function writeBTY3D(name_btyfil, scene, map)
% WRITEBTY3D  Create a bathymetry (.bty) file for Bellhop3-D.
%   This is the same implementation previously located at lib/writers/writeBTY3D.m
%   but now namespaced under uw.internal.writers so that end-users do not
%   pollute the global function namespace.
%
%   WRITEBTY3D(NAME, SCENE, PARAMMAP)
%      NAME   – output filename (string)
%      SCENE  – struct with fields X, Y, floor (depth matrix)
%      PARAMMAP – containers.Map or uw.SimulationParameters map with keys:
%                 'sound_speed_sediment', 'density_sediment', 'attenuation_sediment'
%
%   The function writes an RL (rectilinear) bathymetry grid and embeds
%   bottom property layers when multiple sediment types are present.

% ----------------------------------------------------------------------

interp_type = 'R';

original_X     = scene.X(1, :);
original_Y     = scene.Y(:, 1)';
original_depth = scene.floor;

try
    original_depth(isnan(original_depth)) = 0.0;  % remove NaNs

    nx_original = length(original_X);
    ny_original = length(original_Y);

    num_sediment_types = size(map('sound_speed_sediment'), 1);

    if num_sediment_types > 1000  % heuristic threshold
        % introduce sharp transitions across sediment segments
        segment_width      = nx_original / num_sediment_types;
        transition_step    = 0.1;  % km
        transition_indices = arrayfun(@(i) round(i*segment_width), 1:num_sediment_types-1);
        transition_indices = transition_indices(transition_indices>1 & transition_indices<=nx_original);

        % X coord expansion
        new_X         = [];
        new_X_indices = [];
        for ix = 1:nx_original
            new_X         = [new_X, original_X(ix)];
            new_X_indices = [new_X_indices, ix];
            if ismember(ix, transition_indices)
                new_X         = [new_X, original_X(ix)+transition_step];
                new_X_indices = [new_X_indices, ix];
            end
        end

        % Y coord expansion (similar logic)
        transition_indices_y = arrayfun(@(i) round(i*(ny_original/num_sediment_types)), 1:num_sediment_types-1);
        transition_indices_y = transition_indices_y(transition_indices_y>1 & transition_indices_y<=ny_original);

        new_Y         = [];
        new_Y_indices = [];
        for iy = 1:ny_original
            new_Y         = [new_Y, original_Y(iy)];
            new_Y_indices = [new_Y_indices, iy];
            if ismember(iy, transition_indices_y)
                new_Y         = [new_Y, original_Y(iy)+transition_step];
                new_Y_indices = [new_Y_indices, iy];
            end
        end

        % Interpolate depth
        new_depth = zeros(length(new_Y), length(new_X));
        for iy = 1:length(new_Y)
            oiy = new_Y_indices(iy);
            for ix = 1:length(new_X)
                oix = new_X_indices(ix);
                new_depth(iy, ix) = original_depth(oiy, oix);
            end
        end

        Bdry.X     = new_X;
        Bdry.Y     = new_Y;
        Bdry.depth = new_depth;
    else
        Bdry.X     = original_X;
        Bdry.Y     = original_Y;
        Bdry.depth = original_depth;
    end

    nx = numel(Bdry.X);
    ny = numel(Bdry.Y);

    fid = fopen(name_btyfil, 'wt');
    if fid==-1, error('Cannot open %s for writing.', name_btyfil); end

    fprintf(fid, '''RL'' \n');
    fprintf(fid, '%i \n', nx);
    fprintf(fid, '%f ', Bdry.X);
    fprintf(fid, '\n');

    fprintf(fid, '%i \n', ny);
    fprintf(fid, '%f ', Bdry.Y);
    fprintf(fid, '\n');

    for iy = 1:ny
        fprintf(fid, '%9.3f ', Bdry.depth(iy, :));
        fprintf(fid, '\n');
    end

    if length(interp_type)>1 && interp_type(2)=='L'
        % Additional province logic omitted (rarely used)
    end

    % Province map & bottom properties per sediment type
    sediment_type_counter = 1;
    for iy = 1:ny
        for ix = 1:nx
            if num_sediment_types > 1
                if rem(ix, round(nx/num_sediment_types)) ~= 0
                    fprintf(fid, '%d ', sediment_type_counter);
                else
                    fprintf(fid, '%d ', sediment_type_counter);
                    sediment_type_counter = sediment_type_counter + 1;
                end
            else
                fprintf(fid, '1 ');
            end
        end
        sediment_type_counter = 1;
        fprintf(fid, '\n');
    end

    fprintf(fid, '%d \n', num_sediment_types);
    sp_arr  = map('sound_speed_sediment');
    rho_arr = map('density_sediment');
    att_arr = map('attenuation_sediment');
    for i = 1:num_sediment_types
        fprintf(fid, '%f 0 %f %f 0 \n', sp_arr(i), rho_arr(i), att_arr(i));
    end

    fclose(fid);
catch ME
    fclose('all');
    error('writeBTY3D:Failure', 'Failed to write bathymetry file: %s', ME.message);
end

end