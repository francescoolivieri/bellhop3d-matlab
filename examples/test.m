sim    = uw.Simulation();
rx     = [0.3 0 15; 1 0 20];
TL     = sim.computeTL(rx);          % or sim.run(rx)
sim.visualizeEnvironment();          % plot SSP & TL