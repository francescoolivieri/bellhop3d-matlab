function benchmark_nbv_methods()
    % Benchmark script to compare different NBV planning methods
    
    fprintf('NBV Planning Methods Benchmark\n');
    fprintf('==============================\n\n');
    
    % Load or create test scenario
    [data, s] = setup_test_scenario();
    
    % Define methods to test
    methods = {
        'original', 'Original Tree Method (9 actions)';
        'tree_memoized', 'Tree with Memoization (9 actions)';
        'tree_27', 'Tree with 27 Actions + Memoization';
        'information_gain', 'Information Gain-based';
        'uncertainty_guided', 'Uncertainty-guided';
        'multi_objective', 'Multi-objective Optimization';
        'rrt_nbv', 'RRT-based NBV Planning';
        'rrt_star_nbv', 'RRT* (Optimal) NBV Planning';
        'bayesian_opt', 'Bayesian Optimization'
    };
    
    % Test parameters
    n_iterations = 10;
    n_runs = 3; % Multiple runs for statistical significance
    
    % Results storage
    results = struct();
    
    for i = 1:size(methods, 1)
        method_name = methods{i, 1};
        method_desc = methods{i, 2};
        
        fprintf('Testing: %s\n', method_desc);
        fprintf('-' * ones(1, length(method_desc) + 10));
        fprintf('\n');
        
        % Initialize results for this method
        results.(method_name).computation_times = [];
        results.(method_name).final_uncertainties = [];
        results.(method_name).path_lengths = [];
        results.(method_name).cache_hit_rates = [];
        
        for run = 1:n_runs
            fprintf('  Run %d/%d: ', run, n_runs);
            
            % Reset data for this run
            data_run = reset_data(data);
            s_run = s;
            s_run.nbv_method = method_name;
            
            % Timing and performance tracking
            computation_times = [];
            uncertainties = [];
            positions = [];
            cache_hits = 0;
            cache_misses = 0;
            
            for iter = 1:n_iterations
                tic;
                
                % Run NBV planning
                if strcmp(method_name, 'original')
                    data_run = pos_next_measurement(data_run, s_run);
                else
                    data_run = pos_next_measurement_sota(data_run, s_run);
                end
                
                comp_time = toc;
                computation_times(end+1) = comp_time;
                
                % Record current state
                idx = find(isfinite(data_run.x), 1, 'last');
                if idx > 1
                    uncertainties(end+1) = trace(data_run.Sigma_est(:,:,idx));
                    positions(end+1,:) = [data_run.x(idx), data_run.y(idx), data_run.z(idx)];
                end
                
                fprintf('.');
            end
            
            % Calculate metrics for this run
            avg_comp_time = mean(computation_times);
            final_uncertainty = uncertainties(end);
            path_length = calculate_path_length(positions);
            
            results.(method_name).computation_times(end+1) = avg_comp_time;
            results.(method_name).final_uncertainties(end+1) = final_uncertainty;
            results.(method_name).path_lengths(end+1) = path_length;
            
            fprintf(' Done (Avg: %.3fs)\n', avg_comp_time);
        end
        
        fprintf('\n');
    end
    
    % Display results
    display_benchmark_results(results, methods);
    
    % Create visualizations
    create_benchmark_plots(results, methods);
    
    fprintf('Benchmark completed!\n');
end

function [data, s] = setup_test_scenario()
    % Setup a standardized test scenario
    
    % Initialize data structure
    data = struct();
    data.x = [0; nan(50, 1)];
    data.y = [0; nan(50, 1)];
    data.z = [10; nan(50, 1)];
    
    % Initialize estimation state (dummy values for testing)
    n_params = 10;
    data.th_est = randn(n_params, 51);
    data.Sigma_est = repmat(eye(n_params), [1, 1, 51]);
    
    % Settings structure
    s = struct();
    s.sm = true;
    s.depth = 3;
    s.x_min = -50; s.x_max = 50;
    s.y_min = -50; s.y_max = 50;
    s.z_min = 5; s.z_max = 50;
    s.d_x = 5; s.d_y = 5; s.d_z = 2;
    s.Sigma_rr = 0.1 * eye(1);
    
    % Multi-objective weights (for multi_objective method)
    s.w_info = 0.5;
    s.w_coverage = 0.3;
    s.w_efficiency = 0.2;
    
    % Add OceanDepth for prediction_error_loss
    s.OceanDepth = 100;
end

function data_reset = reset_data(data)
    % Reset data to initial state
    data_reset = data;
    data_reset.x(2:end) = nan;
    data_reset.y(2:end) = nan;
    data_reset.z(2:end) = nan;
end

function path_length = calculate_path_length(positions)
    % Calculate total path length
    if size(positions, 1) < 2
        path_length = 0;
        return;
    end
    
    path_length = 0;
    for i = 2:size(positions, 1)
        path_length = path_length + norm(positions(i,:) - positions(i-1,:));
    end
end

function display_benchmark_results(results, methods)
    % Display formatted benchmark results
    
    fprintf('\n\nBenchmark Results Summary\n');
    fprintf('=========================\n\n');
    
    fprintf('%-25s | %-12s | %-15s | %-12s\n', ...
        'Method', 'Avg Time (s)', 'Final Uncert.', 'Path Length');
    fprintf('%s\n', repmat('-', 1, 70));
    
    for i = 1:size(methods, 1)
        method_name = methods{i, 1};
        method_desc = methods{i, 2};
        
        if isfield(results, method_name)
            avg_time = mean(results.(method_name).computation_times);
            avg_uncertainty = mean(results.(method_name).final_uncertainties);
            avg_path = mean(results.(method_name).path_lengths);
            
            fprintf('%-25s | %8.4f     | %11.4f     | %8.2f\n', ...
                method_desc(1:min(25,end)), avg_time, avg_uncertainty, avg_path);
        end
    end
    
    fprintf('\n');
    
    % Performance ranking
    fprintf('Performance Rankings:\n');
    fprintf('--------------------\n');
    
    % Speed ranking
    speed_data = [];
    method_names = {};
    for i = 1:size(methods, 1)
        method_name = methods{i, 1};
        if isfield(results, method_name)
            speed_data(end+1) = mean(results.(method_name).computation_times);
            method_names{end+1} = methods{i, 2};
        end
    end
    
    [~, speed_idx] = sort(speed_data);
    fprintf('\nSpeed (fastest first):\n');
    for i = 1:length(speed_idx)
        fprintf('  %d. %s (%.4fs)\n', i, method_names{speed_idx(i)}, speed_data(speed_idx(i)));
    end
    
    % Uncertainty reduction ranking
    uncertainty_data = [];
    for i = 1:size(methods, 1)
        method_name = methods{i, 1};
        if isfield(results, method_name)
            uncertainty_data(end+1) = mean(results.(method_name).final_uncertainties);
        end
    end
    
    [~, uncertainty_idx] = sort(uncertainty_data);
    fprintf('\nUncertainty Reduction (best first):\n');
    for i = 1:length(uncertainty_idx)
        fprintf('  %d. %s (%.4f)\n', i, method_names{uncertainty_idx(i)}, uncertainty_data(uncertainty_idx(i)));
    end
end

function create_benchmark_plots(results, methods)
    % Create visualization plots
    
    figure('Position', [100, 100, 1200, 800]);
    
    % Subplot 1: Computation Time Comparison
    subplot(2, 2, 1);
    method_names = {};
    comp_times = [];
    
    for i = 1:size(methods, 1)
        method_name = methods{i, 1};
        if isfield(results, method_name)
            method_names{end+1} = methods{i, 2};
            comp_times(end+1) = mean(results.(method_name).computation_times);
        end
    end
    
    bar(comp_times);
    set(gca, 'XTickLabel', method_names, 'XTickLabelRotation', 45);
    ylabel('Average Computation Time (s)');
    title('Computation Time Comparison');
    grid on;
    
    % Subplot 2: Final Uncertainty Comparison
    subplot(2, 2, 2);
    uncertainties = [];
    for i = 1:size(methods, 1)
        method_name = methods{i, 1};
        if isfield(results, method_name)
            uncertainties(end+1) = mean(results.(method_name).final_uncertainties);
        end
    end
    
    bar(uncertainties);
    set(gca, 'XTickLabel', method_names, 'XTickLabelRotation', 45);
    ylabel('Final Uncertainty');
    title('Uncertainty Reduction Comparison');
    grid on;
    
    % Subplot 3: Path Length Comparison
    subplot(2, 2, 3);
    path_lengths = [];
    for i = 1:size(methods, 1)
        method_name = methods{i, 1};
        if isfield(results, method_name)
            path_lengths(end+1) = mean(results.(method_name).path_lengths);
        end
    end
    
    bar(path_lengths);
    set(gca, 'XTickLabel', method_names, 'XTickLabelRotation', 45);
    ylabel('Average Path Length');
    title('Path Efficiency Comparison');
    grid on;
    
    % Subplot 4: Speed vs Uncertainty Trade-off
    subplot(2, 2, 4);
    scatter(comp_times, uncertainties, 100, 'filled');
    xlabel('Computation Time (s)');
    ylabel('Final Uncertainty');
    title('Speed vs Uncertainty Trade-off');
    grid on;
    
    % Add method labels to scatter plot
    for i = 1:length(method_names)
        text(comp_times(i), uncertainties(i), sprintf('  %d', i), 'FontSize', 8);
    end
    
    sgtitle('NBV Planning Methods Benchmark Results');
    
    % Save the figure
    saveas(gcf, 'nbv_benchmark_results.png');
    fprintf('Benchmark plots saved as nbv_benchmark_results.png\n');
end 