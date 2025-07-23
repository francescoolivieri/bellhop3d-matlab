clc

s = get_sim_settings();
sb = get_bellhop_settings();

% Draw true parameters from prior
data = draw_true_theta(sb); 

% Initialize filter 
data = init_filter(data,sb);

% Get action
%data = pos_next_measurement(data,sb);


% Take measurement
% data = generate_data(data,sb);

% Initial Waypoints
InitialWaypoints = [s.InitialPosition; data.x(1) data.y(1) -7];

scene = uavScenarioBuilder(s);

legend("Start Position","Obstacles")
open_system("UAVflight.slx");

for i = 2:size(InitialWaypoints,1)
    addMesh(scene,"cylinder",{[InitialWaypoints(i,2) InitialWaypoints(i,1) 1] [0 0.1]},[1 0 0]);
end
show3D(scene);
hold on
plot3([s.InitialPosition(1,2); InitialWaypoints(:,2)],[s.InitialPosition(1,2); InitialWaypoints(:,1)],[-s.InitialPosition(1,3); -InitialWaypoints(:,3)],"-g")
legend(["Start Position","","","Waypoints","","","Direct Path"])

out = sim("UAVflight.slx");

data = generate_data(data,sb);

hold on
points = squeeze(out.trajectoryPoints(1,:,:))';
plot3(points(:,2),points(:,1),-points(:,3),"-r");
%legend(["Start Position","","","Waypoints","","","Direct Path","UAV Trajectory"])

InitialWaypoints = [data.x(1) data.y(1) -7; s.InitialPosition];

% fprintf("restart");
% out = sim("UAVflight.slx");
% fprintf("done");

hold on