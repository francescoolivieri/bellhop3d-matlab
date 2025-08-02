function writeBTY3D(name_btyfil, scene, map)
%createbtyfil_3D Creates a bathymetry file from a scene structure.
%   This function extracts grid and depth data from a 'scene' struct
%   and writes it to a bathymetry file using 'writebdry3d'.
%
% Syntax:
%   createbtyfil_3d(name_btyfil, scene)
%
% Inputs:
%   bty_filename - The name for the output .bty file (e.g., 'MyBathy').
%   scene        - A struct containing X, Y and floor(Z) attributes.
%   plot         - A boolean, true -> plots the bathymetry.

global extra_output

interp_type = 'R';

% Create Bathy structure

Bdry.X = scene.X(1, :);
Bdry.Y = scene.Y(:, 1)';
Bdry.depth = scene.floor;

% write bathymetry
try
    Bdry.depth( isnan( Bdry.depth ) ) = 0.0;   % remove NaNs

    nx = length( Bdry.X );
    ny = length( Bdry.Y );
    
    fid = fopen( name_btyfil, 'wt' );
    %fprintf( fid, '''%s'' \n', interp_type );
    fprintf( fid, '''RL'' \n' );
    
    fprintf( fid, '%i \n', nx );
    %fprintf( fid, '%f %f /', Bathy.X( 1 ), Bathy.X( end ) );
    
    fprintf( fid, '%f ', Bdry.X( 1 : end ) );
    fprintf( fid, '\n');
    
    fprintf( fid, '%i \n', ny );
    %fprintf( fid, '%f %f /', Bathy.Y( 1 ), Bathy.Y( end ) );
    fprintf( fid, '%f ', Bdry.Y( 1 : end ) );
    fprintf( fid, '\n');
    
    for iy = 1 : ny
        fprintf( fid, '%9.3f ', Bdry.depth( iy, : ) );
        fprintf( fid, '\n');
    end
    
    % if 'long' format append a matrix with province types
    
    if ( length( interp_type ) > 1 )
        if ( interp_type( 2 : 2 ) == 'L' )
            for iy = 1 : ny
                fprintf( fid, '%3i ', Bdry.province( iy, : ) );
                fprintf( fid, '\n');
            end
    
            NProvinces = max( max( Bdry.province ) );
            fprintf( fid, '%i \n', NProvinces );
            for iProv = 1 : NProvinces
                fprintf( fid, '%f ', Bdry.geotype( iProv, : ) );
                fprintf( fid, '\n' );
            end
        end
    end
    
    num_sediment_types = size(map('sound_speed_sediment'), 2);
    sediment_type_counter = 1;
    for iy = 1 : ny
        for ix = 1 : nx

            if num_sediment_types > 1 

                if rem(ix, round(nx/num_sediment_types)) ~= 0
                    fprintf( fid, '%d ', sediment_type_counter);
                else
                    fprintf( fid, '%d ', sediment_type_counter);
                    sediment_type_counter = sediment_type_counter + 1;
                end 

            else
                fprintf( fid, '1 ');
            end

        end
        sediment_type_counter = 1;
        fprintf( fid, '\n');
    end

    fprintf( fid, '%d \n', num_sediment_types);
    for i = 1:num_sediment_types

        % Temporary solution
        arr = map('sound_speed_sediment');
        fprintf( fid, '%f 0 %f %f 0 \n',  arr(i), map('density_sediment'), map('attenuation_sediment'));

    end

   

    fclose( fid );

catch ME
    error('Failed to write bathymetry file. Error: %s', ME.message);
end

if extra_output
    figure
    title('BTY plot','FontSize',10);
    plotbdry3d(name_btyfil)
end

end
