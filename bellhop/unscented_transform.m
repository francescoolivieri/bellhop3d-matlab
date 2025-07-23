function [mu_y, Sigma_yy, Sigma_xy] = unscented_transform(f, mu_x, Sigma_xx)
    % UNSCENTED_TRANSFORM Computes the Unscented Transform (UT)
    % Inputs:
    %   f         - Function handle for the nonlinear transformation y = f(x)
    %   mu_x      - Mean vector of the input variable (column vector)
    %   Sigma_xx  - Covariance matrix of the input variable
    % Outputs:
    %   mu_y      - Transformed mean
    %   Sigma_yy  - Transformed covariance
    %   Sigma_xy  - Cross-covariance between x and y
    
    % Dimension of the input state
    L = length(mu_x);
    
    % Scaling parameters
    alpha = 1e-3;   % Small positive value to control the spread of sigma points
    kappa = 0;      % Secondary scaling parameter
    beta = 2;       % Optimal for Gaussian distributions
    
    lambda = alpha^2 * (L + kappa) - L;
    gamma = sqrt(L + lambda);
    
    % Compute sigma points
    [U, S, V] = svd(Sigma_xx);  % Use SVD for stability
    sqrt_Sigma_xx = U * sqrt(S) * V';
    
    sigma_points = zeros(L, 2 * L + 1);
    sigma_points(:,1) = mu_x;  % First sigma point (mean)
    
    for i = 1:L
        sigma_points(:,i+1)   = mu_x + gamma * sqrt_Sigma_xx(:,i);
        sigma_points(:,i+L+1) = mu_x - gamma * sqrt_Sigma_xx(:,i);
    end
    
    % Weights
    W_m = [lambda / (L + lambda), repmat(1 / (2 * (L + lambda)), 1, 2 * L)];
    W_c = W_m;
    W_c(1) = W_c(1) + (1 - alpha^2 + beta);  % Covariance weight adjustment
    
    % Transform sigma points through the function
    Y = zeros(length(f(mu_x)), 2*L+1);  % Preallocate Y (size depends on output of f)
    
    parfor i = 1:(2*L+1)
        Y(:,i) = f(sigma_points(:,i));
    end
    
    % Compute transformed mean
    mu_y = sum(Y .* W_m, 2);
    
    % Compute transformed covariance
    Sigma_yy = zeros(size(Y,1));
    for i = 1:(2*L+1)
        diff = Y(:,i) - mu_y;
        Sigma_yy = Sigma_yy + W_c(i) * (diff * diff');
    end
    
    % Compute cross-covariance
    Sigma_xy = zeros(L, size(Y,1));
    for i = 1:(2*L+1)
        Sigma_xy = Sigma_xy + W_c(i) * (sigma_points(:,i) - mu_x) * (Y(:,i) - mu_y)';
    end
end
