function [Cvol] = generateSSP1D(s)

%GENERATESSP Generate SSP file 

% Plot measured sound speed profile
% plot_sound_speed_profile('CTD');

% --------------------- Build a 3-D grid ---------------------------
x = s.Ocean_x_min:s.OceanGridStep:s.Ocean_x_max;           % km east‑west
y = s.Ocean_y_min:s.OceanGridStep:s.Ocean_y_max;           % km north‑south
z = 0:s.Ocean_z_step:s.sim_max_depth;                   % m depth (we take simulation depth, bellhop detects where the real bty is)


[X,Y,Z] = meshgrid(x,y,z);    % Cartesian grid (size Ny×Nx×Nz)


% --------------------- Generate sound‑speed volume -----------------------
Cvol = gen_sound_speed_gp(X,Y,Z);   % Generate ssp field with GP (default hyper‑parameters)

sound_speed = Cvol(1,1, :);
depth = unique(Z(:));

Cvol = repmat(sound_speed, [size(Cvol,1), size(Cvol,2), 1]);


% 
% figure;
%     plot(sound_speed, depth, 'b-','LineWidth',1.5);
%     set(gca, 'YDir','reverse'); % Depth increases downward
%     xlabel('Sound Speed (m/s)');
%     ylabel('Depth (m)');
%     title('Sound Speed Profile');
%     grid on;
% 


uw.internal.writers.writeSSP3D(s.filename + ".ssp", x, y, z, Cvol);

% plotssp3d( s.filename + ".ssp" );

end

