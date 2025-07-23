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