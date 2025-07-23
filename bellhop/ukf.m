function data = ukf(data, s)

% Get index of last state
idx=find(isfinite(data.y),1,'last');

% Get the position of the sensor
pos=[data.r(idx) data.z(idx)];
    
% Get measurement
y=data.y(:, idx);

% Update the filter state given the measurements
 [data.th_est(:, idx),data.Sigma_est(:, :, idx)]=...
     step_ukf_filter(y,@(th)forward_model(th, pos),...
     data.th_est(:, idx-1),data.Sigma_est(:, :, idx-1),s.r);

end

