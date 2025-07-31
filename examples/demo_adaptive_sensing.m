function demo_adaptive_sensing()
    % DEMO_ADAPTIVE_SENSING - Demonstrate intelligent sensor placement
    %
    % This demo shows how NBV planning improves parameter estimation:
    % 1. Compare random vs intelligent sensor placement
    % 2. Show uncertainty reduction over time
    % 3. Demonstrate different NBV strategies
    
    fprintf('🚁 Adaptive Sensing for Bottom Parameter Estimation\n');
    fprintf('==================================================\n\n');
    
    % Load settings and define true parameters
    s = get_sim_settings();
    s.N = 12;  % Fewer measurements for demo
    theta_true = [1620; 1.4];
    
    fprintf('True parameters: [%.0f m/s, %.2f]\n', theta_true(1), theta_true(2));
    fprintf('Prior uncertainty: [±%.0f m/s, ±%.2f]\n', ...
        sqrt(s.Sigma_th(1,1)), sqrt(s.Sigma_th(2,2)));
    
    % Test different sensing strategies
    strategies = {
        'random', 'Random Placement';
        'rrt_star_nbv', 'RRT* Path Planning';
        'information_gain', 'Information Gain';
        'uncertainty_guided', 'Uncertainty Guided'
    };
    
    results = cell(size(strategies, 1), 1);
    
    for strat_idx = 1:size(strategies, 1)
        strategy = strategies{strat_idx, 1};
        strategy_name = strategies{strat_idx, 2};
        
        fprintf('\n🔄 Testing strategy: %s\n', strategy_name);
        
        % Configure strategy
        s_test = s;
        if strcmp(strategy, 'random')
            s_test.sm = false;  % Disable sensor management for random
        else
            s_test.sm = true;
            s_test.nbv_method = strategy;
        end
        
        % Initialize estimation
        data = init_filter(struct(), s_test);
        
        % Store results for analysis
        estimation_error = zeros(s_test.N + 1, 2);
        uncertainty = zeros(s_test.N + 1, 2);
        positions = zeros(s_test.N + 1, 3);
        
        % Initial values
        estimation_error(1, :) = abs(data.th_est(:, 1)' - theta_true');
        uncertainty(1, :) = sqrt(diag(data.Sigma_est(:, :, 1)))';
        positions(1, :) = [data.x(1), data.y(1), data.z(1)];
        
        % Run estimation
        for i = 1:s_test.N
            % Plan next measurement
            if strcmp(strategy, 'random')
                % Random placement
                data.x(i+1) = s_test.x_min + (s_test.x_max - s_test.x_min) * rand();
                data.y(i+1) = s_test.y_min + (s_test.y_max - s_test.y_min) * rand();
                data.z(i+1) = s_test.z_min + (s_test.z_max - s_test.z_min) * rand();
            else
                % Intelligent placement
                data = pos_next_measurement(data, s_test);
            end
            
            % Simulate measurement
            pos = [data.x(i+1), data.y(i+1), data.z(i+1)];
            measurement = forward_model(theta_true, pos, s_test) + s_test.sigma_tl_noise * randn();
            data.m(i+1) = measurement;
            
            % Update estimate
            [data.th_est(:, i+1), data.Sigma_est(:, :, i+1)] = step_ukf_filter(...
                measurement, @(th)forward_model(th, pos, s_test), ...
                data.th_est(:, i), data.Sigma_est(:, :, i), s_test.Sigma_rr);
            
            % Store results
            estimation_error(i+1, :) = abs(data.th_est(:, i+1)' - theta_true');
            uncertainty(i+1, :) = sqrt(diag(data.Sigma_est(:, :, i+1)))';
            positions(i+1, :) = pos;
            
            fprintf('  Measurement %2d: Error [%.1f m/s, %.3f], Uncertainty [%.1f m/s, %.3f]\n', ...
                i, estimation_error(i+1, 1), estimation_error(i+1, 2), ...
                uncertainty(i+1, 1), uncertainty(i+1, 2));
        end
        
        % Store complete results
        results{strat_idx} = struct(...
            'strategy', strategy, ...
            'name', strategy_name, ...
            'estimation_error', estimation_error, ...
            'uncertainty', uncertainty, ...
            'positions', positions, ...
            'final_error', estimation_error(end, :), ...
            'final_uncertainty', uncertainty(end, :));
    end
    
    % Analysis and comparison
    fprintf('\n📊 Strategy Comparison:\n');
    fprintf('%-20s | %-15s | %-15s | %-10s\n', 'Strategy', 'Final Error', 'Final Uncert.', 'Score');
    fprintf('%s\n', repmat('-', 1, 70));
    
    scores = zeros(length(results), 1);
    for i = 1:length(results)
        r = results{i};
        % Score: lower error and uncertainty is better
        score = 1 / (mean(r.final_error ./ theta_true') + mean(r.final_uncertainty ./ theta_true'));
        scores(i) = score;
        
        fprintf('%-20s | [%.1f, %.3f]    | [%.1f, %.3f]    | %.2f\n', ...
            r.name, r.final_error(1), r.final_error(2), ...
            r.final_uncertainty(1), r.final_uncertainty(2), score);
    end
    
    % Find best strategy
    [~, best_idx] = max(scores);
    fprintf('\n🏆 Best strategy: %s\n', results{best_idx}.name);
    
    % Visualizations
    try
        % Plot uncertainty reduction over time
        figure('Position', [100, 100, 1200, 800]);
        
        colors = lines(length(results));
        
        % Sound speed uncertainty
        subplot(2, 2, 1);
        for i = 1:length(results)
            plot(0:s.N, results{i}.uncertainty(:, 1), 'Color', colors(i, :), ...
                'LineWidth', 2, 'DisplayName', results{i}.name);
            hold on;
        end
        xlabel('Measurement Number');
        ylabel('Sound Speed Uncertainty [m/s]');
        title('Sound Speed Uncertainty Reduction');
        legend('Location', 'best');
        grid on;
        
        % Density uncertainty
        subplot(2, 2, 2);
        for i = 1:length(results)
            plot(0:s.N, results{i}.uncertainty(:, 2), 'Color', colors(i, :), ...
                'LineWidth', 2, 'DisplayName', results{i}.name);
            hold on;
        end
        xlabel('Measurement Number');
        ylabel('Density Uncertainty');
        title('Density Factor Uncertainty Reduction');
        legend('Location', 'best');
        grid on;
        
        % Estimation error over time
        subplot(2, 2, 3);
        for i = 1:length(results)
            plot(0:s.N, results{i}.estimation_error(:, 1), 'Color', colors(i, :), ...
                'LineWidth', 2, 'DisplayName', results{i}.name);
            hold on;
        end
        xlabel('Measurement Number');
        ylabel('Sound Speed Error [m/s]');
        title('Sound Speed Estimation Error');
        legend('Location', 'best');
        grid on;
        
        % Sensor positions comparison (best vs worst)
        subplot(2, 2, 4);
        [~, worst_idx] = min(scores);
        
        % Plot positions for best and worst strategies
        best_pos = results{best_idx}.positions;
        worst_pos = results{worst_idx}.positions;
        
        scatter3(best_pos(:, 1), best_pos(:, 2), best_pos(:, 3), 100, 'g', 'filled', ...
            'DisplayName', sprintf('Best: %s', results{best_idx}.name));
        hold on;
        scatter3(worst_pos(:, 1), worst_pos(:, 2), worst_pos(:, 3), 100, 'r', 'x', ...
            'MarkerSize', 10, 'LineWidth', 2, ...
            'DisplayName', sprintf('Worst: %s', results{worst_idx}.name));
        
        xlabel('X Position [km]');
        ylabel('Y Position [km]');
        zlabel('Depth [m]');
        title('Sensor Placement Comparison');
        legend('Location', 'best');
        grid on;
        
        sgtitle('Adaptive Sensing Strategy Comparison');
        
        % Save results
        saveas(gcf, 'results/plots/adaptive_sensing_comparison.png');
        fprintf('\n📊 Results saved to results/plots/adaptive_sensing_comparison.png\n');
        
    catch ME
        fprintf('⚠️  Visualization failed: %s\n', ME.message);
    end
    
    % Summary insights
    fprintf('\n🔬 Key Insights:\n');
    
    improvement = (scores(best_idx) - scores(1)) / scores(1) * 100;  % vs first strategy
    fprintf('  • %s achieved %.1f%% better performance than %s\n', ...
        results{best_idx}.name, improvement, results{1}.name);
    
    % Calculate measurement efficiency
    random_idx = 1;  % Assuming first is random
    if best_idx ~= random_idx
        uncert_reduction_random = results{random_idx}.uncertainty(1, :) - results{random_idx}.uncertainty(end, :);
        uncert_reduction_best = results{best_idx}.uncertainty(1, :) - results{best_idx}.uncertainty(end, :);
        
        efficiency_improvement = mean(uncert_reduction_best ./ uncert_reduction_random);
        fprintf('  • Smart sensing reduces uncertainty %.1fx faster than random placement\n', ...
            efficiency_improvement);
    end
    
    fprintf('  • Different strategies excel in different scenarios - choose based on platform constraints\n');
    fprintf('  • Uncertainty quantification enables principled sensor placement decisions\n');
    
    fprintf('\nDemo completed! 🎉\n');
end
