function estimation_state = ukf_step(estimation_state, measurement, position)

% Build forward model at current position
fwd_model = @(theta) fwd_with_params(estimation_state.sim_est, estimation_state.th_names, theta, position);

% Run one UKF update step
[mu_th, Sigma_thth] = step_ukf_filter( ...
    measurement, fwd_model, ...
    estimation_state.mu, estimation_state.Sigma, estimation_state.Sigma_rr);

% Persist updated state and propagate to simulation parameters
estimation_state.mu = mu_th;
estimation_state.Sigma = Sigma_thth;
estimation_state.sim_est.params.update(mu_th, estimation_state.th_names);

end


