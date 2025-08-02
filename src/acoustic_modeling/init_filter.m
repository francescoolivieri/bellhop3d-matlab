function data=init_filter(data,s)

% Number of parameters to estimate
dim_th = numel(s.mu_th);

% Allocate memory for mean and covariance
data.th_est = nan(dim_th, s.N + 1);
data.Sigma_est = nan(dim_th, dim_th, s.N + 1);

% Initial state based upon prior
data.th_est(:,1)=s.mu_th;
data.Sigma_est(:,:,1)=s.Sigma_th;

% Allocate meamory for receiver positions
data.x=nan(1,s.N+1);
data.y=nan(1,s.N+1);
data.z=nan(1,s.N+1);

% Start location
data.x(1)=s.x_start;
data.y(1)=s.y_start;
data.z(1)=s.z_start;

% Measurements
data.m=nan(1,s.N+1);

end