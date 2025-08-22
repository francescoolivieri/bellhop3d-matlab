clc
close all;

clean_files();

sim    = uw.Simulation();      % construct simulation environment following default settings (lib/uw/SimSettings.m)
rx_pos = [0.5 0.5 20];         % specify receiver position
sim.printScenario
sim.printPolarTL();

% sim    = uw.Simulation();      % construct simulation environment following default settings (lib/uw/SimSettings.m)
% rx_pos = [0.5 0.5 20];         % specify receiver position
% disp( sim.computeTL(rx_pos) )  % read and display TL at rx_pos