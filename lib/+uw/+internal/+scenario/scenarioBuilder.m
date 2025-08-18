function scene = scenarioBuilder(s)

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
        features = [
             [0.5, 0.5, -5, 0.5]; % Central seamount (negative = hill)
             [0, 1, -45, 0.5]; % Smaller seamount
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
        
    case 'fractal_noise'
        % Realistic procedural terrain. Last two params are: roughness and scale
        oceanFloor = generateFractalTerrain(size(X), 10, 5);

    otherwise
        oceanFloor = zeros(size(X)); % Default to flat
end

oceanFloor = (ones(size(X))*(-s.OceanDepth)) - oceanFloor; 

depthProfile = zeros(size(X)) - oceanFloor;

scene.X = X;
scene.Y = Y;
scene.floor = depthProfile;
scene.surface = waterSurface;

end


function terrain = generateFractalTerrain(gridSize, roughness, scale, varargin)
    ny = gridSize(1);
    nx = gridSize(2);
    
    % Create frequency grids
    kx = fftshift((-nx/2:nx/2-1));
    ky = fftshift((-ny/2:ny/2-1));
    [KX, KY] = meshgrid(kx, ky);
    
    % Radial frequency
    K = sqrt(KX.^2 + KY.^2);
    K(K == 0) = inf;
    
    % Create power spectrum
    H = 1 - roughness;
    beta = 2 * H + 1;
    powerSpectrum = 1 ./ (K.^beta);
    powerSpectrum(isinf(powerSpectrum)) = 0;
    
    % Generate random phases
    phases = 2 * pi * rand(ny, nx);
    
    % Create complex amplitudes
    amplitudes = sqrt(powerSpectrum) .* exp(1i * phases);
    
    % Simple Hermitian symmetry (basic version)
    for i = 1:ny
        for j = 1:nx
            i_sym = mod(-i + 1, ny) + 1;
            j_sym = mod(-j + 1, nx) + 1;
            if i_sym ~= i || j_sym ~= j
                amplitudes(i_sym, j_sym) = conj(amplitudes(i, j));
            end
        end
    end
    amplitudes(1, 1) = real(amplitudes(1, 1));
    
    % Generate terrain
    terrain = real(ifft2(ifftshift(amplitudes)));
    
    % Normalize and scale
    if std(terrain(:)) > eps
        terrain = (terrain - mean(terrain(:))) / std(terrain(:));
        terrain = scale * terrain;
    else
        terrain = zeros(size(terrain));
    end
end