function [scene, sceneFigure] = scenarioBuilder(s)

%% Define Water Surface and Ocean Environment
% Create a water surface mesh
[X, Y] = meshgrid(s.Ocean_x_min:s.Ocean_step:s.Ocean_x_max, s.Ocean_y_min:s.Ocean_step:s.Ocean_y_max);
waterSurface = zeros(size(X));

% Add some gentle waves to the water surface
waveHeight = 0.5;
waveFreq = 0.02;
waterSurface = waterSurface + waveHeight * sin(waveFreq * X) .* cos(waveFreq * Y);

switch lower(s.OceanFloorType)

    case 'flat'
        oceanFloor = zeros(size(X));

    case 'smooth_waves'
        % Simple, predictable sinusoids
        freq_x = 3.7 / 1000; % Scale down for km
        freq_y = 4.6 / 1000;
        freq_xy = 2.6 / 1000;
        oceanFloor = 5.5 * (sin(freq_x * X * 1000) .* cos(freq_y * Y * 1000) + ...
                         1.5 * cos(freq_xy * (X + Y) * 1000));
        
        % oceanFloor = 5 * (sin(0.1*X).*cos(0.08*Y) + 0.5*cos(0.2*(X+Y)));

    case 'gaussian_features'
        % Manually placed seamounts/basins
        oceanFloor = zeros(size(X));

        % Define some terrain features manually
        % Each feature: [x_center_km, y_center_km, amplitude, sigma_km]
        % Convert coordinates to km scale
        % x_range = s.Ocean_x_max - s.Ocean_x_min;
        % y_range = s.Ocean_y_max - s.Ocean_y_min;
        % x_center = (s.Ocean_x_max + s.Ocean_x_min) / 2;
        % y_center = (s.Ocean_y_max + s.Ocean_y_min) / 2;
        
        features = [
             [0.5, 0.5, -5, 0.5]; % Central seamount (negative = hill)
             [0, 0.5, 5, 0.5]; % Smaller seamount
             [0, -0.5, -5, 0.5]; % Smaller seamount
             [0, 0.5, 5, 0.5]; % Smaller seamount
        ];
        
        for k = 1:size(features, 1)
            xc = features(k, 1);
            yc = features(k, 2);
            amp = features(k, 3);
            sigma = features(k, 4);
            gauss = amp * exp(-((X - xc).^2 + (Y - yc).^2) / (2 * sigma^2));
            oceanFloor = oceanFloor + gauss;
        end
        
        % % Define some terrain features manually
        % % Each feature: [x_center, y_center, amplitude, sigma]
        % features = [
        %     [0.5, 0.5, -5, 0.5];        % Central seamount (negative = hill)
        %     [0, 0.5, -5, 0.5];    % Smaller seamount
        %     [0, -0.5, -5, 0.5];    % Smaller seamount
        %     [0, 0.5, -5, 0.5];    % Smaller seamount
        % ];
        % 
        % for k = 1:size(features, 1)
        %     xc = features(k, 1);
        %     yc = features(k, 2);
        %     amp = features(k, 3);
        %     sigma = features(k, 4);
        % 
        %     gauss = amp * exp(-((X - xc).^2 + (Y - yc).^2) / (2 * sigma^2));
        %     oceanFloor = oceanFloor + gauss;
        % end

    case 'fractal_noise'
        % Realistic procedural terrain. Last two params are: roughness and scale
        oceanFloor = generateFractalTerrain(size(X), 10, 5);

    otherwise
        oceanFloor = zeros(size(X)); % Default to flat
end

oceanFloor = (ones(size(X))*(-s.OceanDepth)) - oceanFloor; 

depthProfile = zeros(size(X)) - oceanFloor;


sceneFigure = figure;
title('Ocean Environment')
% Plot ocean floor first (darker blue)
surf(X, Y, oceanFloor, 'FaceColor', [0.1, 0.2, 0.4], 'FaceAlpha', 0.8, 'EdgeColor', 'none');
hold on;

% Plot water surface (lighter blue, semi-transparent)
surf(X, Y, waterSurface, 'FaceColor', [0.3, 0.7, 1.0], 'FaceAlpha', 0.6, 'EdgeColor', 'none');

axis on

scene.X = X;
scene.Y = Y;
scene.floor = depthProfile;
scene.surface = waterSurface;

end