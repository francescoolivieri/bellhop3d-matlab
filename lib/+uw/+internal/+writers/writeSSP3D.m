function writeSSP3D(filename, x, y, z, c)
% WRITESSP3D  Write a 3-D sound-speed profile (.ssp) for Bellhop-3D.
%   writeSSP3D(FILE, X, Y, Z, C) where C is [Nx x Ny x Nz] in MATLAB
%   convention (will be permuted to Bellhop order).

c = permute(c, [3 2 1]);  % [Nz Ny Nx]
Nx = numel(x); Ny = numel(y); Nz = numel(z);
assert(isequal(size(c), [Nz, Ny, Nx]), 'c must be [Nz x Ny x Nx]');

fid = fopen(filename, 'w');
if fid == -1, error('writeSSP3D:IO', 'Could not open %s.ssp for writing.', filename); end

fprintf(fid, '%d\n', Nx); fprintf(fid, '%.6f ', x); fprintf(fid, '\n');
fprintf(fid, '%d\n', Ny); fprintf(fid, '%.6f ', y); fprintf(fid, '\n');
fprintf(fid, '%d\n', Nz); fprintf(fid, '%.6f ', z); fprintf(fid, '\n');

for iz = 1:Nz
    slice = squeeze(c(iz, :, :));  % Ny x Nx
    for iy = 1:Ny
        fprintf(fid, '%.6f ', slice(iy, :)); fprintf(fid, '\n');
    end
end

fclose(fid);
end
