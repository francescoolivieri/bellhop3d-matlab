function create_env_file(theta, filename)
    % Function to create a .env file with the given format
    % Input:
    %   theta - A vector containing two elements
    %   filename - Name of the .env file to create
    
    % Ensure theta has at least two elements
    if length(theta) < 2
        error('Theta must be a vector with at least three elements.');
    end
    
    % Open the file for writing
    fid = fopen(filename, 'w');
    if fid == -1
        error('Could not open file for writing.');
    end
    
    % Write the file contents
    fprintf(fid, '''Example profile''\t\t! TITLE\n');
    fprintf(fid, '50.0\t\t\t\t! FREQ (Hz)\n');
    fprintf(fid, '1\t\t\t\t! NMEDIA\n');
    fprintf(fid, '''SVF''\t\t\t\t! SSPOPT (Analytic or C-linear interpolation)\n');
    fprintf(fid, '51  0.0  50.0\t\t! DEPTH of bottom (m)\n');
    fprintf(fid, '    0.0  1535.52  /\n');
    fprintf(fid, '   10.0  1530.29  /\n');
    fprintf(fid, '   20.0  1526.69  /\n');
    fprintf(fid, '   30.0  1517.78  /\n');
    fprintf(fid, '   40.0  1520.49  /\n');
    fprintf(fid, '   50.0  1525.30  /\n');
    fprintf(fid, '''A'' 0.0\n');
    fprintf(fid, ' 50.0  %.6f 0.5 %.6f / \n', theta(1), theta(2));
    fprintf(fid, '1\t\t\t\t! NSD\n');
    fprintf(fid, '47.0 /\t\t\t! SD(1:NSD) (m)\n');
    fprintf(fid, '100\t\t\t\t! NRD\n');
    fprintf(fid, '0.0 50.0 /\t\t! RD(1:NRD) (m)\n');
    fprintf(fid, '2000\t\t\t\t! NR\n');
    fprintf(fid, '0.0  2.0 /\t\t\t! R(1:NR ) (km)\n');
    fprintf(fid, '''C''\t\t\t\t! ''R/C/I/S''\n');
    fprintf(fid, '0\t\t\t\t! NBeams\n');
    fprintf(fid, '-30.0 30.0 /\t\t\t! ALPHA1,2 (degrees)\n');
    fprintf(fid, '0.0  60.0  2.1\t\t! STEP (m), ZBOX (m), RBOX (km)\n');
    
    % Close the file
    fclose(fid);
    
end
