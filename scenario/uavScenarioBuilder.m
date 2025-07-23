function scene = uavScenarioBuilder(s)
% Create sea scenario

scene = uavScenario("UpdateRate",100,"ReferenceLocation",[0 0 0]);
addMesh(scene,"cylinder",{[0 0 1] [0 .01]},[0 1 0]);

platUAV = uavPlatform("UAV",scene, ...
                      "ReferenceFrame","NED", ...
                      "InitialPosition",s.InitialPosition, ...
                      "InitialOrientation",eul2quat(s.InitialOrientation));
updateMesh(platUAV,"quadrotor",{2},[0 0 0],eul2tform([0 0 pi]));

%% Sensors
LidarModel = uavLidarPointCloudGenerator("UpdateRate",10, ...
                                         "MaxRange",s.MaxRange, ...
                                         "RangeAccuracy",3, ...
                                         "AzimuthResolution",s.AzimuthResolution, ...
                                         "ElevationResolution",s.ElevationResolution, ...
                                         "AzimuthLimits",s.AzimuthLimits, ...
                                         "ElevationLimits",s.ElevationLimits, ...                                       
                                         "HasOrganizedOutput",true);
uavSensor("Lidar",platUAV,LidarModel, ...
          "MountingLocation",[0 0 -0.4], ...
          "MountingAngles",[0 0 180]);
show3D(scene);

% ObstaclePositions = [10 0; 20 10; 10 20]; % Locations of the obstacles
% ObstacleHeight = 15;                      % Height of the obstacles
% ObstaclesWidth = 3;                       % Width of the obstacles
% 
% for i = 1:size(ObstaclePositions,1)
%     addMesh(scene,"polygon", ...
%         {[ObstaclePositions(i,1)-ObstaclesWidth/2 ObstaclePositions(i,2)-ObstaclesWidth/2; ...
%         ObstaclePositions(i,1)+ObstaclesWidth/2 ObstaclePositions(i,2)-ObstaclesWidth/2; ...
%         ObstaclePositions(i,1)+ObstaclesWidth/2 ObstaclePositions(i,2)+ObstaclesWidth/2; ...
%         ObstaclePositions(i,1)-ObstaclesWidth/2 ObstaclePositions(i,2)+ObstaclesWidth/2], ...
%         [0 ObstacleHeight]},0.651*ones(1,3));
% end

%% Create Ocean Environment

oceanBounds = [-100, 100, -100, 100]; % [xmin, xmax, ymin, ymax] in meters
oceanDepth = 60; % meters
waterSurfaceAltitude = 0; % Sea level reference

% Create mesh grid for ocean visualization
[X, Y] = meshgrid(oceanBounds(1):20:oceanBounds(2), oceanBounds(3):20:oceanBounds(4));
waterSurface = zeros(size(X)) + waterSurfaceAltitude;

% Add realistic ocean waves
waveHeight = 1.0;
waveFreqX = 1.5;
waveFreqY = 2;
waterSurface = waterSurface + waveHeight * sin(waveFreqX * X) .* cos(waveFreqY * Y);

% Create ocean floor
oceanFloor = waterSurface - oceanDepth;
oceanFloor = oceanFloor - 15*sin(0.008*X).*cos(0.008*Y) - 8*sin(0.015*sqrt(X.^2 + Y.^2));

color = [0.3, 0.7, 1.0];
addMesh(scene, "surface", {X, Y, waterSurface}, color );

color = [0.1, 0.2, 0.4];
addMesh(scene, "surface", {X, Y, oceanFloor}, color );

show3D(scene);

end