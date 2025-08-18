function [Cvol] = generateSSP3D(s)

%GENERATESSP Generate SSP file 

% Plot measured sound speed profile
% plot_sound_speed_profile('CTD');

% --------------------- Build a 3-D grid ---------------------------
x = s.Ocean_x_min:s.Ocean_step:s.Ocean_x_max;           % km east‑west
y = s.Ocean_y_min:s.Ocean_step:s.Ocean_y_max;           % km north‑south
z = 0:s.Ocean_z_step:s.sim_max_depth;                   % m depth (we take simulation depth, bellhop detects where the real bty is)


[X,Y,Z] = meshgrid(x,y,z);    % Cartesian grid (size Ny×Nx×Nz)


% --------------------- Generate sound‑speed volume -----------------------
Cvol = gen_sound_speed_gp(X,Y,Z);   % Generate ssp field with GP (default hyper‑parameters)

uw.internal.writers.writeSSP3D(s.filename + ".ssp", x, y, z, Cvol);

end

