function data=init_filter(data,sb)

% Number of parameters to estimate
dim_th = numel(sb.mu_th);

% Allocate memory for mean and covariance
data.th_est = nan(dim_th, sb.N + 1);
data.Sigma_est = nan(dim_th, dim_th, sb.N + 1);

% Initial state based upon prior
data.th_est(:,1)=sb.mu_th;
data.Sigma_est(:,:,1)=sb.Sigma_th;

% Allocate meamory for receiver positions
data.x=nan(1,sb.N+1);
data.y=nan(1,sb.N+1);
data.z=nan(1,sb.N+1);

% Start location
data.x(1)=sb.x_start;
data.y(1)=sb.y_start;
data.z(1)=sb.z_start;

% Measurements
data.m=nan(1,sb.N+1);

end