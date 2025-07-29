function tl = forward_model(theta, pos, s)
%
% theta [2 x 1] vector (bottom reflection factors) 
% pos [N x 3] matrix (x, y, z)                     
% s structure                                      

global units

if units == "km"
    pos(:, 1:2) = pos(:, 1:2) * 1000;
end

filename=sprintf('%07d', randi([0,9999999])); %'temporary';
%b filename = 'ac_env_model';

% Create envioreemnt file using the current parameters
writeENV3D([filename '.env'], s, theta);

% Copy bty and ssp file
if s.sim_use_bty_file
    writeBTY3D([filename '.bty'], s.scene, theta(1), theta(2));
end

if s.sim_use_ssp_file
    copyfile("ac_env_model.ssp", [filename '.ssp'])
end

pause(0.05)

%delete('temporary.shd')

% Run Bellhop
bellhop3d(filename);

% Read data
[~, ~, ~, ~, ~, Pos, pressure ] = read_shd([filename '.shd']);


% Get number of bearing angles
num_bearings = length(Pos.theta);

% Create 2D grid from bellhop output
[rGrid, zGrid] = meshgrid(Pos.r.r, Pos.r.z); % Create 2D grid

% Initialize output
tl = zeros(size(pos, 1), 1);

% Process each position
for i = 1:size(pos, 1)
    % Calculate bearing angle from source (assumed at origin) to position
    bearing_deg = atan2d(pos(i, 2), pos(i, 1));
    
    % Normalize bearing to [0, 360) degrees
    if bearing_deg < 0
        bearing_deg = bearing_deg + 360;
    end
    
    % Find the closest bearing slice
    % Assuming bearings are evenly distributed from 0 to 360-360/num_bearings
    bearing_spacing = 360 / num_bearings;
    bearing_idx = round(bearing_deg / bearing_spacing) + 1;
    
    % Handle wrap-around (bearing_idx should be between 1 and num_bearings)
    if bearing_idx > num_bearings
        bearing_idx = 1;
    end
    
    % Calculate range and depth for this position
    my_range = sqrt(pos(i, 1)^2 + pos(i, 2)^2);
    my_depth = pos(i, 3);
    
    % Interpolate using the appropriate bearing slice
    tl_temp = interp2(rGrid, zGrid, double(abs(squeeze(pressure(1, 1, :, :)))), my_range, my_depth, "linear");
    
    if isnan(tl_temp)
        disp(pos(i, :))
    end

    % Store result
    tl(i) = tl_temp;
end

% Convert to log scale
tl = double(abs(tl));
tl(tl < 1e-37) = 1e-37;          % remove zeros
tl = -20.0 * log10(tl);          % so there's no error when we take the log


delete([filename '.prt'])
delete([filename '.env'])
delete([filename '.shd'])

if s.sim_use_bty_file
    delete([filename '.bty'])
end

if s.sim_use_ssp_file
    delete([filename '.ssp'])
end

pause(0.05)

end

