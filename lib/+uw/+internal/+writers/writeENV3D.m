function writeENV3D(filename, s, map)
% WRITEENV3D  Create a Bellhop3-D environment (.env) file.
%   Namespaced version of the original writer located at lib/writers/writeENV3D.m.

fid = fopen(filename, 'w');
if fid == -1
    error('writeENV3D:IO', 'Could not open file %s for writing.', filename);
end

% ---------------------------------------------------------------------
% Header and frequency
fprintf(fid, ''' %s ''        ! TITLE\n', s.filename);
fprintf(fid, '%.2f                  ! FREQ (Hz)\n', map('source_frequency'));

% Media layers
fprintf(fid, '1                     ! NMEDIA\n');
if s.sim_use_ssp_file
    fprintf(fid, '''HVW''               ! SSPOPT\n');
else
    fprintf(fid, '''CVW''\t\t\t\t\t! SSPOPT\n');
end
fprintf(fid, '51 0.0  %.2f \t\t! DEPTH of bottom (m)\n', s.sim_max_depth);
if s.sim_use_ssp_file
    fprintf(fid, '   0.0  /\n   10.0  /\n   20.0  /\n   30.0  /\n   40.0  /\n   %.2f  /\n', s.sim_max_depth);
else
    fprintf(fid, '   0.0  1535.52  /\n   10.0  1530.29  /\n   20.0  1526.69  /\n   40.0  1530.69  /\n   %.2f  1600.30  /\n', s.sim_max_depth);
end

% Bottom properties (analytic or read from BTY)
if s.sim_use_bty_file
    fprintf(fid, '''A~'' 0.0 \n');
else
    fprintf(fid, '''A'' 0.0 \n');
end

ss_sediment  = map('sound_speed_sediment');
rho_sediment = map('density_sediment');
att_sediment = map('attenuation_sediment');
fprintf(fid, ' %.2f   %f 0 %f %f 0 /\n', s.sim_max_depth, ss_sediment(1), rho_sediment(1), att_sediment(1));

% Source & receiver geometry ------------------------------------------------
fprintf(fid, '1                 ! NSx\n%.2f /             ! x (km)\n', map('source_x'));
fprintf(fid, '1                 ! NSy\n%.2f /             ! y (km)\n', map('source_y'));
fprintf(fid, '1                 ! NSz\n%.2f /          ! Sz (m)\n', map('source_depth'));

fprintf(fid, '200               ! NRz\n0 %.2f /          ! Rz range (m)\n', s.sim_max_depth);
fprintf(fid, '1000              ! NRr\n0.0  %.2f /      ! Rr (km)\n', s.sim_range);
fprintf(fid, '%d                 ! Ntheta\n0.0 360.0 /         ! bearings\n', s.sim_num_bearings);

% Computational options -----------------------------------------------------
if s.sim_accurate_3d
    fprintf(fid, '''CG   3''          ! accurate\n');
else
    fprintf(fid, '''CG   2''          ! fast\n');
end

fprintf(fid, '1001              ! Nalpha\n-89 89 /    ! alpha fan\n');
fprintf(fid, '10            ! Nbeta\n0  360 /           ! beta fan\n');
fprintf(fid, '0.0  1.55 1.55 %.2f ! STEP, Box%%x, Box%%y, Box%%z\n', s.sim_max_depth + .5);

fclose(fid);
end
