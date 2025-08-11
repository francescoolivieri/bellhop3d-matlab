function tl = fwd_with_params(sim, names, theta, pos)
    % Helper function for ukf (sigma points computation)

    sim.params.update(theta, names);
    tl = sim.computeTL(pos);
end