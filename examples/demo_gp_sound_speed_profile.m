% DEMO_GENERATE_VOLUME  Illustrates GEN_SOUND_SPEED_GP on a 3‑D grid.

clear; clc; close all;

% Plot measured sound speed profile
plot_sound_speed_profile('CTD')


% --------------------- Build a 3-D grid ---------------------------
x = -1000:100:1000;           % metres east‑west
y = -1000:100:1000;           % metres north‑south
z =  0:2:35;                   % depth (m, positive down)


[X,Y,Z] = meshgrid(x,y,z);    % Cartesian grid (size Ny×Nx×Nz)


% --------------------- Generate sound‑speed volume -----------------------
Cvol = gen_sound_speed_gp(X,Y,Z);   % use default hyper‑parameters

% --------------------- Visualise  ------------------------
figure;

% Get global min/max for consistent color scale
vmin = min(Cvol(:));
vmax = max(Cvol(:));

for i = 1:length(x)
    imagesc(y, z, squeeze(Cvol(:,i,:))');
    set(gca, 'YDir','reverse');
    caxis([vmin vmax]);  % fixed color range
    xlabel('y (m)');
    ylabel('depth (m)');
    title(['Vertical slice at x = ', num2str(x(i)), ' m']);
    colorbar;
    pause(0.5);
end