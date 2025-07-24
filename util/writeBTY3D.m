function writeBTY3D(name_btyfil, scene, bottom_ssp, bottom_density)
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

Bathy.X = scene.X(1, :);
Bathy.Y = scene.Y(:, 1)';
Bathy.depth = scene.floor;

% write bathymetry
try
    writebdry3d(name_btyfil, interp_type, Bathy, bottom_ssp, bottom_density);
    fprintf('Wrote BTY file. \n');
catch ME
    error('Failed to write bathymetry file. Make sure ''writebdry3d'' is in the path and works correctly. Error: %s', ME.message);
end

if extra_output
    figure
    title('BTY plot','FontSize',10);
    plotbdry3d(name_btyfil)
end

end
