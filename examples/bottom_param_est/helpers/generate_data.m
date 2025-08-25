function data=generate_data(data)

% Get index of last state
idx=find(isfinite(data.x),1,'last');

% Get the position of the sensor
pos=[data.x(idx) data.y(idx) data.z(idx)];

% Generate data
data.m(idx) = data.sim_true.computeTLWithNoise(pos);

end