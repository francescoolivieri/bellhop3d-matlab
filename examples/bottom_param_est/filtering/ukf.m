function data = ukf(data, sim_est, measurement, position)

% Get index of last state
idx = find(isfinite(data.th_est),1,'last');

% Build forward model at current position
fwd_model = @(theta) fwd_with_params(sim_est, data.th_names, theta, position);

% Run one UKF update step
[data.th_est(:, idx+1), data.Sigma_est(:, :, idx+1)] = step_ukf_filter( ...
    measurement, fwd_model, ...
    data.th_est(:, idx), data.Sigma_est(:, :, idx), data.Sigma_rr);

% Persist updated state and propagate to simulation parameters
sim_est.params.update(data.th_est(:, idx+1));

end


