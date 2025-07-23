function tl = forward_model(theta,pos)
%
% theta [2 x 1] vector (bottom reflection factors)
% pos [N x 2 ] matrix (range depth)  

% filename=sprintf('%07d', randi([0,9999999])); %'temporary';
filename = 'ac_env_model';

% % Create envioreemnt file using the current parameters
% create_env_file(theta,[filename '.env']);

pause(0.05)

%delete('temporary.shd')

% Run Bellhop
% bellhop3d(filename);

% Read data
[~, ~, ~, ~, ~, Pos, pressure ] = read_shd([filename '.shd']);


% display(Pos.theta)
% display(Pos.s)
display(Pos.r.z)
% display(any(diff(Pos.r.z) == 0))

%Pos.r.z = Pos.r.z + 1e-8*(1:length(Pos.r.z));

% Given grid vectors
[rGrid, zGrid] = meshgrid(Pos.r.r, Pos.r.z); % Create 2D grid



my_range = sqrt(squeeze(pos(1,1))^2 + squeeze(pos(1,2))^2);
my_depth = pos(:,3);
my_pos = [my_range my_depth];
display(my_pos)

% Interpolate
tl= interp2(rGrid, zGrid, double(abs(squeeze(pressure(1,1,:,:)))), my_pos(1), my_pos(2), "linear"); % 'linear' interpolation (change as needed)

% Alternative interpolation methods: 'nearest', 'cubic', 'spline'


% Convert to log scale
tl=double( abs( tl) );
tl(tl < 1e-37) = 1e-37;          % remove zeros
tl = -20.0 * log10(tl);          % so there's no error when we take the log

display(tl);

% delete([filename '.prt'])
% delete([filename '.env'])
% delete([filename '.shd'])

end

