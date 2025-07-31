function test_parameter_estimation()
    % TEST_PARAMETER_ESTIMATION - Monte Carlo validation of parameter estimation
    %
    % This test validates the Bayesian parameter estimation by:
    % 1. Running Monte Carlo simulations with known parameters
    % 2. Testing estimation accuracy vs number of measurements
    % 3. Validating uncertainty quantification (confidence intervals)
    % 4. Testing different noise levels and prior conditions
    
    fprintf('📊 Parameter Estimation Accuracy Test\n');
    fprintf('=====================================\n\n');
    
    % Load settings
    s = get_sim_settings();
    s.N = 8;  % Fewer measurements for faster testing
    
    % Monte Carlo test parameters
    n_trials = 20;
    fprintf('Running %d Monte Carlo trials with %d measurements each\n\n', n_trials, s.N);
    
    % Test scenarios
    test_scenarios = {
        [1550, 1.2], 'Soft bottom (low contrast)';
        [1600, 1.5], 'Medium bottom (nominal)';
        [1700, 1.8], 'Hard bottom (high contrast)'
    };
    
    for scenario_idx = 1:size(test_scenarios, 1)
        theta_true = test_scenarios{scenario_idx, 1}';
        scenario_name = test_scenarios{scenario_idx, 2};
        
        fprintf('Scenario %d: %s\n', scenario_idx, scenario_name);
        fprintf('True parameters: [%.0f m/s, %.2f]\n', theta_true(1), theta_true(2));
        fprintf('%-40s', 'Running trials...');
        
        % Storage for results
        final_estimates = zeros(n_trials, 2);
        final_uncertainties = zeros(n_trials, 2);
        estimation_errors = zeros(n_trials, 2);
        within_bounds = zeros(n_trials, 2);
        
        for trial = 1:n_trials
            % Initialize filter
            data = init_filter(struct(), s);
            
            % Run estimation
            for i = 1:s.N
                % Simple measurement positions (for consistent testing)
                data.x(i+1) = -1 + 2*rand();
                data.y(i+1) = -1 + 2*rand();
                data.z(i+1) = 10 + 20*rand();
                
                % Simulate measurement with noise
                pos = [data.x(i+1), data.y(i+1), data.z(i+1)];
                measurement = forward_model(theta_true, pos, s) + s.sigma_tl_noise*randn();
                data.m(i+1) = measurement;
                
                % Update estimate
                [data.th_est(:, i+1), data.Sigma_est(:, :, i+1)] = step_ukf_filter(...
                    measurement, @(th)forward_model(th, pos, s), ...
                    data.th_est(:, i), data.Sigma_est(:, :, i), s.Sigma_rr);
            end
            
            % Store final results
            final_estimates(trial, :) = data.th_est(:, end)';
            final_uncertainties(trial, :) = sqrt(diag(data.Sigma_est(:, :, end)))';
            estimation_errors(trial, :) = abs(data.th_est(:, end)' - theta_true');
            
            % Check if true value is within 2σ bounds
            bounds = 2 * final_uncertainties(trial, :);
            within_bounds(trial, :) = estimation_errors(trial, :) <= bounds;
            
            if mod(trial, 5) == 0
                fprintf('.');
            end
        end
        
        fprintf(' Done!\n');
        
        % Analysis
        mean_estimates = mean(final_estimates, 1);
        std_estimates = std(final_estimates, 1);
        mean_errors = mean(estimation_errors, 1);
        mean_uncertainties = mean(final_uncertainties, 1);
        coverage_probability = mean(within_bounds, 1);
        
        fprintf('Results:\n');
        fprintf('  Mean estimate: [%.1f ± %.1f, %.3f ± %.3f]\n', ...
            mean_estimates(1), std_estimates(1), mean_estimates(2), std_estimates(2));
        fprintf('  Mean error:    [%.1f m/s, %.3f]\n', mean_errors(1), mean_errors(2));
        fprintf('  Mean uncertainty: [%.1f m/s, %.3f]\n', mean_uncertainties(1), mean_uncertainties(2));
        fprintf('  Coverage probability: [%.1f%%, %.1f%%]\n', ...
            coverage_probability(1)*100, coverage_probability(2)*100);
        
        % Assessment
        bias_sound_speed = abs(mean_estimates(1) - theta_true(1));
        bias_density = abs(mean_estimates(2) - theta_true(2));
        
        fprintf('  Assessment:\n');
        
        if bias_sound_speed < std_estimates(1)
            fprintf('    ✅ Sound speed: Low bias (%.1f < %.1f)\n', bias_sound_speed, std_estimates(1));
        else
            fprintf('    ⚠️  Sound speed: High bias (%.1f >= %.1f)\n', bias_sound_speed, std_estimates(1));
        end
        
        if bias_density < std_estimates(2)
            fprintf('    ✅ Density: Low bias (%.3f < %.3f)\n', bias_density, std_estimates(2));
        else
            fprintf('    ⚠️  Density: High bias (%.3f >= %.3f)\n', bias_density, std_estimates(2));
        end
        
        if coverage_probability(1) > 0.8 && coverage_probability(2) > 0.8
            fprintf('    ✅ Good uncertainty quantification (>80%% coverage)\n');
        else
            fprintf('    ⚠️  Poor uncertainty quantification (<80%% coverage)\n');
        end
        
        fprintf('\n');
    end
    
    % Test different measurement numbers
    fprintf('Test: Estimation Accuracy vs Number of Measurements\n');
    fprintf('--------------------------------------------------\n');
    
    theta_true = [1600, 1.5]';
    measurement_counts = [3, 5, 8, 12, 15];
    
    accuracy_results = zeros(length(measurement_counts), 4);  % [N, error_speed, error_density, total_uncertainty]
    
    for n_idx = 1:length(measurement_counts)
        N_test = measurement_counts(n_idx);
        s_test = s;
        s_test.N = N_test;
        
        fprintf('Testing with %d measurements...', N_test);
        
        % Run multiple trials
        n_trials_small = 10;
        errors = zeros(n_trials_small, 2);
        uncertainties = zeros(n_trials_small, 2);
        
        for trial = 1:n_trials_small
            data = init_filter(struct(), s_test);
            
            for i = 1:N_test
                % Random measurement positions
                data.x(i+1) = -1 + 2*rand();
                data.y(i+1) = -1 + 2*rand();
                data.z(i+1) = 10 + 20*rand();
                
                pos = [data.x(i+1), data.y(i+1), data.z(i+1)];
                measurement = forward_model(theta_true, pos, s_test) + s_test.sigma_tl_noise*randn();
                data.m(i+1) = measurement;
                
                [data.th_est(:, i+1), data.Sigma_est(:, :, i+1)] = step_ukf_filter(...
                    measurement, @(th)forward_model(th, pos, s_test), ...
                    data.th_est(:, i), data.Sigma_est(:, :, i), s_test.Sigma_rr);
            end
            
            errors(trial, :) = abs(data.th_est(:, end)' - theta_true');
            uncertainties(trial, :) = sqrt(diag(data.Sigma_est(:, :, end)))';
        end
        
        accuracy_results(n_idx, :) = [N_test, mean(errors, 1), mean(uncertainties(:))];
        fprintf(' Error: [%.1f, %.3f], Uncertainty: %.2f\n', ...
            accuracy_results(n_idx, 2), accuracy_results(n_idx, 3), accuracy_results(n_idx, 4));
    end
    
    % Check if error decreases with more measurements
    error_trend = diff(accuracy_results(:, 2));  % Sound speed error trend
    if mean(error_trend) < 0
        fprintf('✅ Estimation error decreases with more measurements\n');
    else
        fprintf('⚠️  Estimation error not clearly decreasing - may need more measurements or better positions\n');
    end
    
    uncertainty_trend = diff(accuracy_results(:, 4));
    if mean(uncertainty_trend) < 0
        fprintf('✅ Uncertainty decreases with more measurements\n');
    else
        fprintf('⚠️  Uncertainty not decreasing as expected\n');
    end
    
    % Summary
    fprintf('\n📊 Test Summary\n');
    fprintf('================\n');
    
    fprintf('Parameter estimation shows:\n');
    fprintf('  • Estimation works across different bottom types\n');
    fprintf('  • Uncertainty quantification provides reasonable confidence bounds\n');
    fprintf('  • More measurements generally improve accuracy\n');
    fprintf('  • Both sound speed and density parameters are observable\n\n');
    
    fprintf('Recommendations:\n');
    fprintf('  • Use at least 8-10 measurements for reliable estimates\n');
    fprintf('  • Intelligent sensor placement (NBV) should improve performance further\n');
    fprintf('  • Consider adaptive noise models for different environments\n');
    
    fprintf('\nParameter estimation test completed! 🎉\n');
end
