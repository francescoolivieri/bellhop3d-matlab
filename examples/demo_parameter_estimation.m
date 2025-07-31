function demo_parameter_estimation()
    % DEMO_PARAMETER_ESTIMATION - Basic bottom parameter estimation demo
    %
    % This demo shows the core functionality:
    % 1. 3D acoustic forward modeling with BELLHOP3D
    % 2. Bayesian parameter estimation using UKF
    % 3. Intelligent sensor placement for improved estimates
    
    fprintf('🌊 Bottom Parameter Estimation Demo\n');
    fprintf('=====================================\n\n');
    
    % Load simulation settings
    s = get_sim_settings();
    
    % True bottom parameters (unknown to estimator)
    theta_true = [1580; 1.3];  % [sound speed m/s; density factor]
    fprintf('True bottom parameters:\n');
    fprintf('  Sound speed: %.1f m/s\n', theta_true(1));
    fprintf('  Density factor: %.2f\n', theta_true(2));
    
    % Initialize filter with prior
    data = struct();
    data = init_filter(data, s);
    
    fprintf('\nPrior estimates:\n');
    fprintf('  Sound speed: %.1f ± %.1f m/s\n', s.mu_th(1), sqrt(s.Sigma_th(1,1)));
    fprintf('  Density factor: %.2f ± %.2f\n', s.mu_th(2), sqrt(s.Sigma_th(2,2)));
    
    % Run estimation with measurements
    fprintf('\n📊 Running parameter estimation...\n');
    for i = 1:s.N
        % Get next measurement position (using NBV planning)
        if s.sm
            data = pos_next_measurement(data, s);
        else
            % Simple grid pattern fallback
            data.x(i+1) = -1 + 2*rand();
            data.y(i+1) = -1 + 2*rand();  
            data.z(i+1) = 20 + 10*rand();
        end
        
        % Simulate measurement (using true parameters)
        pos = [data.x(i+1), data.y(i+1), data.z(i+1)];
        measurement = forward_model(theta_true, pos, s) + s.sigma_tl_noise*randn();
        data.m(i+1) = measurement;
        
        % Update parameter estimate
        idx = i+1;
        [data.th_est(:,idx), data.Sigma_est(:,:,idx)] = step_ukf_filter(...
            measurement, @(th)forward_model(th, pos, s), ...
            data.th_est(:,i), data.Sigma_est(:,:,i), s.Sigma_rr);
        
        % Display progress
        current_est = data.th_est(:,idx);
        current_std = sqrt(diag(data.Sigma_est(:,:,idx)));
        
        fprintf('  Measurement %2d: Position [%.2f, %.2f, %.1f], TL = %.1f dB\n', ...
            i, pos(1), pos(2), pos(3), measurement);
        fprintf('    Estimate: [%.1f ± %.1f, %.2f ± %.2f]\n', ...
            current_est(1), current_std(1), current_est(2), current_std(2));
    end
    
    % Final results
    final_est = data.th_est(:,end);
    final_std = sqrt(diag(data.Sigma_est(:,:,end)));
    
    fprintf('\n✅ Final Parameter Estimates:\n');
    fprintf('  Sound speed: %.1f ± %.1f m/s (true: %.1f)\n', ...
        final_est(1), final_std(1), theta_true(1));
    fprintf('  Density factor: %.2f ± %.2f (true: %.2f)\n', ...
        final_est(2), final_std(2), theta_true(2));
    
    % Calculate estimation errors
    error_sound_speed = abs(final_est(1) - theta_true(1));
    error_density = abs(final_est(2) - theta_true(2));
    
    fprintf('\n�� Estimation Performance:\n');
    fprintf('  Sound speed error: %.1f m/s\n', error_sound_speed);
    fprintf('  Density error: %.3f\n', error_density);
    
    if error_sound_speed < 2*final_std(1) && error_density < 2*final_std(2)
        fprintf('  ✅ Estimates within 2σ confidence bounds - Good estimation!\n');
    else
        fprintf('  ⚠️  Some estimates outside confidence bounds - May need more measurements\n');
    end
    
    fprintf('\nDemo completed! 🎉\n');
end
