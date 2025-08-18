function data=init_filter(data, s, N)

% Number of parameters to estimate
dim_th = numel(data.th_est);

% Allocate memory for mean and covariance
prior_mu = data.th_est;
prior_Sigma = data.Sigma_est;
data.th_est = nan(dim_th, N + 1);
data.Sigma_est = nan(dim_th, dim_th, N + 1);

% Initial state based upon prior
data.th_est(:,1) = prior_mu;
data.Sigma_est(:,:,1) = prior_Sigma;

% Allocate meamory for receiver positions
data.x = nan(1,N+1);
data.y = nan(1,N+1);
data.z = nan(1,N+1);

% Start location
data.x(1) = s.x_start;
data.y(1) = s.y_start;
data.z(1) = s.z_start;

% Measurements
data.m = nan(1, N+1);

end