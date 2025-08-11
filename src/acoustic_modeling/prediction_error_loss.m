function V = prediction_error_loss(pos, mu_th, Sigma_thth, s)

s = data

if sqrt(pos(1)^2 + pos(2)^2) > s.x_max
    V = 1e6;  % Large penalty
    disp(size(pos))
    return
end

% Calculate parameter covariance after measurement
fwd_model = @(theta) fwd_with_params(data.sim_est, data.th_names, theta, [x_updated y_updated z_updated]);
[~, Sigma_thth] = step_ukf_filter(nan,fwd_model,mu_th,Sigma_thth,s.Sigma_rr);

% Create vectors for z and r
x_values = s.x_min:0.3:s.x_max;
y_values = s.y_min:0.3:s.y_max;
z_values = s.z_min:8:s.OceanDepth;

% Generate grid points
[Z, Y, X] = meshgrid(z_values, y_values, x_values);
pos = [X(:), Y(:), Z(:)];

% Apply circular mask
mask = sqrt(pos(:,1).^2 + pos(:,2).^2) <= s.x_max;
pos = pos(mask, :);

Np = 15;
Y_pred = zeros(size(pos,1),Np);

parfor pp = 1:Np
    % Sample parameter values
    th_sample = mu_th + chol(Sigma_thth,'lower')*randn(size(mu_th));
    
    Y_pred(:, pp) = forward_model(param_map_sample, pos, s);
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

function tl = forward_model_wrapper(th_array, pos, s)
    % Wrapper function for backward compatibility with UKF
    param_map = createParameterMapFromArray(th_array, s);
    tl = forward_model(param_map, pos, s);
end