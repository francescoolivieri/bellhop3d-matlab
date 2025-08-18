function data = ukf(data)

% Get index of last state
idx=find(isfinite(data.m),1,'last');

% Get the position of the sensor
pos=[data.x(idx) data.y(idx) data.z(idx)];
    
% Get measurement
m=data.m(:, idx);

fwd_model = @(theta) fwd_with_params(data.sim_est, data.th_names, theta, pos);

% Update the filter state given the measurements
 [data.th_est(:, idx), data.Sigma_est(:, :, idx)]= step_ukf_filter( ...
                m, fwd_model, ...
                data.th_est(:, idx-1), data.Sigma_est(:, :, idx-1), data.Sigma_rr);
 
 % If just values are passed, automatically update the estimates
 data.sim_est.params.update(data.th_est(:, idx));

end
