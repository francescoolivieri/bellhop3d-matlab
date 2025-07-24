function writeENV3D(filename, s, theta)
%WRITEENV3D Summary of this function goes here
%   Detailed explanation goes here

% Open environment file
fid = fopen(filename, "w");

if fid == -1
    error('Could not open file %s for writing.', filename);
end

% Update content
fprintf(fid, '''True 3D profile''        ! TITLE\n');
fprintf(fid, '%.2f                  ! FREQ (Hz)\n', s.sim_frequency); % Insert new_frequency here
fprintf(fid, '1                     ! NMEDIA\n');
if s.sim_use_ssp_file

    fprintf(fid, '''HVW''               ! SSPOPT (Analytic or C-linear interpolation)\n');
    fprintf(fid, '51 0.0  %.2f 		! DEPTH of bottom (m)\n', s.sim_max_depth);
    fprintf(fid, '   0.0  /\n');
    fprintf(fid, '   10.0  /\n');
    fprintf(fid, '   20.0  /\n');
    fprintf(fid, '   30.0  /\n');
    fprintf(fid, '   40.0  /\n');
    fprintf(fid, '   %.2f  /\n', s.sim_max_depth);


else
    fprintf(fid, '''CVW''				! SSPOPT (Analytic or C-linear interpolation)\n');
    fprintf(fid, '51 0.0  %.2f 		! DEPTH of bottom (m)\n', s.sim_max_depth);
    fprintf(fid, '   0.0  1535.52  /\n');
    fprintf(fid, '   10.0  1530.29  /\n');
    fprintf(fid, '   20.0  1526.69  /\n');
    fprintf(fid, '   30.0  1517.78  /\n');
    fprintf(fid, '   40.0  1520.49  /\n');
    fprintf(fid, '   %.2f  1550.30  /\n', s.sim_max_depth);

end
    
if s.sim_use_bty_file
    fprintf(fid, '''A~'' 0.0 \n');
else
    fprintf(fid, '''A'' 0.0 \n');
end

fprintf(fid, ' %.2f   %.6f 0.5 %.6f /\n', s.sim_max_depth, theta(1) , theta(2));   %fprintf(fid, ' %.2f   %.2f 0.0 1.5 0.5 /\n', s.sim_max_depth, s.bottom_ssp);
fprintf(fid, '1                 ! NSx number of source coordinates in x\n');
fprintf(fid, '0.0 /             ! x coordinate of source (km)\n');
fprintf(fid, '1                 ! NSy number of source coordinates in y\n');
fprintf(fid, '0.0 /             ! y coordinate of source (km)\n');
fprintf(fid, '1                 ! NSz\n');
fprintf(fid, '%.2f /          ! Sz(1 : NSz) (m)\n', s.sim_sender_depth); 
fprintf(fid, '200               ! NRz\n');
fprintf(fid, '0 %.2f /          ! Rz(1 : NRz) (m)\n', s.sim_max_depth);
fprintf(fid, '1000              ! NRr\n');
fprintf(fid, '0.0  1.5 /      ! Rr(1 : NRr ) (km)\n');
fprintf(fid, '361                 ! Ntheta (number of bearings)\n');
fprintf(fid, '0.0 360.0 /         ! bearing angles (degrees)\n');
fprintf(fid, '''CG   2''          ! ''R/C/I/S''\n');
fprintf(fid, '1001              ! Nalpha\n');
fprintf(fid, '-89 89 /    ! alpha1, 2 (degrees) Elevation/declination angle fan\n');
fprintf(fid, '21            ! Nbeta\n');
fprintf(fid, '0  360 /           ! beta1, beta2 (degrees) bearine angle fan\n');
fprintf(fid, '0.0  1.55 1.55 %.2f ! STEP (m), Box%%x (km) Box%%y (km) Box%%z (m)\n', s.sim_max_depth+.5); % Use %% for literal %

% Close the file.
fclose(fid);



end