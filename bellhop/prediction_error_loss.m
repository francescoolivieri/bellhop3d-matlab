function V = prediction_error_loss(pos, mu_th, Sigma_thth, s)

% Calculate parameter covariance after measurement
[~, Sigma_thth] = step_ukf_filter(nan,@(th)forward_model(th, pos, s),mu_th,Sigma_thth,s.Sigma_rr);

% Create vectors for z and r
x_values = s.x_min:s.d_x:s.x_max;
y_values = s.y_min:s.d_y:s.y_max;
z_values = s.z_min:s.d_z:s.z_max;

% Generate grid points
[Z, Y, X] = meshgrid(z_values, y_values, x_values);

% Combine into a matrix where each row is a grid point (z, r)
pos = [X(:), Y(:), Z(:)];

Np = 30;
Y_pred = zeros(size(pos,1),Np);

parfor pp = 1:Np
    th = mu_th + chol(Sigma_thth,'lower')*randn(size(mu_th));  
    Y_pred(:, pp) = forward_model(th, pos);
end
var_tl = var(Y_pred, [], 2);


% % Calculate covariance of predictions
% [~, Sigma_tltl, ~] =unscented_transform(@(th)forward_model(th, pos), mu_th, Sigma_thth);
% 
% % Variance at the different points
% var_tl=diag(Sigma_tltl);

% Loss
V = mean(var_tl);

%V=sum(diag(Sigma_thth));

end