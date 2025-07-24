function tl = forward_model(theta, pos, s)
%
% theta [2 x 1] vector (bottom reflection factors)
% pos [N x 2 ] matrix (range depth) 
% s structure

filename=sprintf('%07d', randi([0,9999999])); %'temporary';
%b filename = 'ac_env_model';

% Create envioreemnt file using the current parameters
writeENV3D([filename '.env'], s, theta);

% Copy bty and ssp file
copyfile("ac_env_model.ssp", [filename '.ssp'])
copyfile("ac_env_model.bty", [filename '.bty'])

pause(0.05)

%delete('temporary.shd')

% Run Bellhop
bellhop3d(filename);

% Read data
[~, ~, ~, ~, ~, Pos, pressure ] = read_shd([filename '.shd']);


% Create 2D grid from bellhop output
[rGrid, zGrid] = meshgrid(Pos.r.r, Pos.r.z); % Create 2D grid


% Process 3D position
my_range = sqrt(squeeze(pos(:,1)).^2 + squeeze(pos(:,2)).^2);
my_depth = pos(:,3);
my_pos = [my_range my_depth];

% Interpolate
tl= interp2(rGrid, zGrid, double(abs(squeeze(pressure(1,1,:,:)))), my_pos(:,1), my_pos(:,2), "linear"); % 'linear' interpolation (change as needed)

% Alternative interpolation methods: 'nearest', 'cubic', 'spline'


% Convert to log scale
tl=double( abs( tl) );
tl(tl < 1e-37) = 1e-37;          % remove zeros
tl = -20.0 * log10(tl);          % so there's no error when we take the log


delete([filename '.prt'])
delete([filename '.env'])
delete([filename '.shd'])
delete([filename '.ssp'])
pause(0.05)

end

