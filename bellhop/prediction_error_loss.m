function V=prediction_error_loss(pos,mu_th,Sigma_thth,s)

% Calculate parameter covariance after measurement
[~, Sigma_thth] =step_ukf_filter(nan,@(th)forward_model(th, pos),mu_th,Sigma_thth,s.r);

% Create vectors for z and r
z_values = s.z_min:s.d_z:s.z_max;
r_values = s.r_min:s.d_r:s.r_max;

% Generate grid points
[Z, R] = meshgrid(z_values, r_values);

% Combine into a matrix where each row is a grid point (z, r)
pos = [R(:), Z(:)];

Np=30;
Y=zeros(size(pos,1),Np);
parfor pp=1:Np
th=mu_th+chol(Sigma_thth,'lower')*randn(size(mu_th));  
Y(:,pp)=forward_model(th, pos);
end
var_tl=var(Y,[],2);


% % Calculate covariance of predictions
% [~, Sigma_tltl, ~] =unscented_transform(@(th)forward_model(th, pos), mu_th, Sigma_thth);
% 
% % Variance at the different points
% var_tl=diag(Sigma_tltl);

% Loss
V=mean(var_tl);

%V=sum(diag(Sigma_thth));

end