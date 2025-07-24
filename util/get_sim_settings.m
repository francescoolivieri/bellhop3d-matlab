function s = get_sim_settings()
%GET_SETTINGS Returns a structure containing the variables that control the
%simulation

%% Ocean Settings
s.OceanDepth = 30; % Depth of the ocean in meters
s.OceanFloorType = 'flat'; % types: flat, smooth_waves, gaussian_features, fractal_noise

s.Ocean_x_min = -2;
s.Ocean_x_max = 2;
s.Ocean_y_min = -2;
s.Ocean_y_max = 2;

s.Ocean_step = 0.2;
s.Ocean_z_step = 8.;

s.bottom_ssp = 1550.;

%% Bellhop simulation settings
s.sim_frequency = 1000.;
s.sim_max_depth = 80.0;
s.sim_use_ssp_file = true;
s.sim_use_bty_file = true;
s.sim_sender_depth = 10.0;

s.sim_rays = true;

%% Print Parameters
s.plot_bathymetry = true;


%% External File References
s.env_file_name = "ac_env_model.env";
s.bellhop_file_name = 'ac_env_model';
s.bty_file_name = "ac_env_model.bty";


%% UAV Measurements Settings
s.z_min=5;              
s.z_max=45;

s.x_min=0;
s.x_max=200;

s.y_min=0;
s.y_max=200;


% Sensor management
s.sm=true;                          % Sensor management on/off
s.bayesian_opt=false;               % Use Bayesian optimization   

%% Measurements position settings
s.d_z=2;                            % Step distance depth [m]
s.d_x=0.2;                           % Step distance range [m]
s.d_y=0.2;                           % Step distance range [m]

s.z_start=0.030;                       % Start depth [m]
s.x_start=0.050;                       % Start x [m]
s.y_start=0.050;                       % Start y [m]

s.depth=1;                          % Depth of planing tree, i.e., how many steps ahead should we plan. 


s.N=10;                             % Total number of measurements
s.sigma_tl_noise=1;                 % Variance of the measurement noise [dB]


s.mu_th=[1600 1.5]';                % Mean of prior for theta   
s.Sigma_th=diag([20 0.1].^2);       % Covariance of prior for theta
s.Sigma_rr=1^2;                            % Filter assumed measurement noise variance [dB^2]










%% UAV Settings
s.UAVSampleTime = 0.001;
s.Gravity = 9.81;
s.DroneMass = 0.1;
assignin("base", "Gravity", s.Gravity)
assignin("base", "DroneMass", s.DroneMass)

s.InitialPosition = [0 0 -7];
s.InitialOrientation = [0 0 0];

% Proportional Gains
s.Px = 3.5;
s.Py = 3.5;
s.Pz = 4.0;

% Derivative Gains
s.Dx = 3.0;
s.Dy = 3.0;
s.Dz = 4.0;

% Integral Gains
s.Ix = 0.1;
s.Iy = 0.1;
s.Iz = 0.2;

% Filter Coefficients
s.Nx = 10;
s.Ny = 10;
s.Nz = 14.4947065605712; 

% Lidar Settings
s.AzimuthResolution = 0.5;      
s.ElevationResolution = 2;
s.MaxRange = 7;
s.AzimuthLimits = [-179 179];
s.ElevationLimits = [-15 15];

%

end