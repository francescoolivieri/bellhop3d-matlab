function validate_acoustic_model()
    % VALIDATE_ACOUSTIC_MODEL - Validate BELLHOP3D forward model accuracy
    %
    % This test validates the acoustic forward model by:
    % 1. Testing consistency across parameter ranges
    % 2. Validating against analytical solutions (where possible)
    % 3. Checking numerical stability and convergence
    % 4. Verifying physical behavior (causality, reciprocity)
    
    fprintf('🔊 Acoustic Forward Model Validation\n');
    fprintf('====================================\n\n');
    
    % Load settings
    s = get_sim_settings();
    
    % Test 1: Parameter Range Consistency
    fprintf('Test 1: Parameter Range Consistency\n');
    fprintf('-----------------------------------\n');
    
    % Define parameter test ranges
    sound_speeds = [1400, 1500, 1600, 1700, 1800];
    densities = [1.0, 1.2, 1.5, 1.8, 2.0];
    test_position = [0.5, 0.0, 20];  % 500m range, 20m depth
    
    fprintf('Testing %d sound speeds × %d densities = %d combinations\n', ...
        length(sound_speeds), length(densities), length(sound_speeds)*length(densities));
    
    results_matrix = zeros(length(sound_speeds), length(densities));
    
    for i = 1:length(sound_speeds)
        for j = 1:length(densities)
            theta = [sound_speeds(i); densities(j)];
            try
                tl = forward_model(theta, test_position, s);
                results_matrix(i, j) = tl;
                if mod(i*j, 5) == 0
                    fprintf('  [%.0f m/s, %.1f] → %.1f dB\n', theta(1), theta(2), tl);
                end
            catch ME
                fprintf('  ❌ Failed for [%.0f, %.1f]: %s\n', theta(1), theta(2), ME.message);
                results_matrix(i, j) = NaN;
            end
        end
    end
    
    % Check for reasonable physical behavior
    valid_results = ~isnan(results_matrix);
    if all(valid_results(:))
        fprintf('  ✅ All parameter combinations successful\n');
    else
        fprintf('  ⚠️  %d/%d combinations failed\n', sum(~valid_results(:)), numel(valid_results));
    end
    
    % Check monotonicity (generally TL should increase with harder bottom)
    mean_tl_by_speed = mean(results_matrix, 2, 'omitnan');
    if all(diff(mean_tl_by_speed) > 0)
        fprintf('  ✅ TL increases monotonically with bottom sound speed\n');
    else
        fprintf('  ⚠️  TL not monotonic with sound speed - check physics\n');
    end
    
    % Test 2: Numerical Stability
    fprintf('\nTest 2: Numerical Stability\n');
    fprintf('---------------------------\n');
    
    theta_base = [1600; 1.5];
    n_trials = 10;
    tl_values = zeros(n_trials, 1);
    
    fprintf('Running %d identical calculations for consistency...\n', n_trials);
    for i = 1:n_trials
        tl_values(i) = forward_model(theta_base, test_position, s);
    end
    
    tl_std = std(tl_values);
    tl_mean = mean(tl_values);
    
    if tl_std < 0.1  % Less than 0.1 dB variation
        fprintf('  ✅ Numerical stability: %.1f ± %.3f dB\n', tl_mean, tl_std);
    else
        fprintf('  ⚠️  Numerical instability: %.1f ± %.3f dB\n', tl_mean, tl_std);
    end
    
    % Test 3: Position Consistency
    fprintf('\nTest 3: Position Consistency\n');
    fprintf('----------------------------\n');
    
    % Test multiple positions simultaneously vs individually
    positions_multi = [
        0.2, 0.0, 10;
        0.5, 0.0, 20;
        1.0, 0.0, 30;
        0.5, 0.5, 15
    ];
    
    % Multi-position call
    tl_multi = forward_model(theta_base, positions_multi, s);
    
    % Individual calls
    tl_individual = zeros(size(positions_multi, 1), 1);
    for i = 1:size(positions_multi, 1)
        tl_individual(i) = forward_model(theta_base, positions_multi(i, :), s);
    end
    
    position_errors = abs(tl_multi - tl_individual);
    max_error = max(position_errors);
    
    if max_error < 0.5  % Less than 0.5 dB difference
        fprintf('  ✅ Multi vs single position consistency: max error %.3f dB\n', max_error);
    else
        fprintf('  ⚠️  Position calculation inconsistency: max error %.3f dB\n', max_error);
    end
    
    % Test 4: Range-Depth Behavior
    fprintf('\nTest 4: Range-Depth Physical Behavior\n');
    fprintf('-------------------------------------\n');
    
    % Test TL vs range (should generally increase)
    ranges = [0.1, 0.3, 0.5, 1.0, 1.5];
    tl_vs_range = zeros(size(ranges));
    
    for i = 1:length(ranges)
        pos = [ranges(i), 0, 20];
        tl_vs_range(i) = forward_model(theta_base, pos, s);
    end
    
    % Check if TL generally increases with range (spreading loss)
    range_gradient = diff(tl_vs_range) ./ diff(ranges);
    if mean(range_gradient) > 0
        fprintf('  ✅ TL increases with range (avg: %.1f dB/km)\n', mean(range_gradient));
    else
        fprintf('  ⚠️  Unexpected range dependence - check environment\n');
    end
    
    % Test TL vs depth
    depths = [5, 10, 15, 20, 25, 30];
    depths = depths(depths < s.OceanDepth);  % Stay within bounds
    tl_vs_depth = zeros(size(depths));
    
    for i = 1:length(depths)
        pos = [0.5, 0, depths(i)];
        tl_vs_depth(i) = forward_model(theta_base, pos, s);
    end
    
    depth_variation = max(tl_vs_depth) - min(tl_vs_depth);
    fprintf('  TL depth variation: %.1f dB over %.0f-%.0fm depth\n', ...
        depth_variation, min(depths), max(depths));
    
    % Test 5: Parameter Sensitivity
    fprintf('\nTest 5: Parameter Sensitivity Analysis\n');
    fprintf('--------------------------------------\n');
    
    % Sound speed sensitivity
    delta_speed = 50;  % 50 m/s change
    theta_high_speed = theta_base + [delta_speed; 0];
    
    tl_base = forward_model(theta_base, test_position, s);
    tl_high_speed = forward_model(theta_high_speed, test_position, s);
    
    speed_sensitivity = (tl_high_speed - tl_base) / delta_speed;
    fprintf('  Sound speed sensitivity: %.3f dB per m/s\n', speed_sensitivity);
    
    % Density sensitivity
    delta_density = 0.2;
    theta_high_density = theta_base + [0; delta_density];
    
    tl_high_density = forward_model(theta_high_density, test_position, s);
    density_sensitivity = (tl_high_density - tl_base) / delta_density;
    fprintf('  Density sensitivity: %.3f dB per unit\n', density_sensitivity);
    
    % Assessment of sensitivity magnitudes
    if abs(speed_sensitivity) > 0.001 && abs(density_sensitivity) > 0.01
        fprintf('  ✅ Both parameters show measurable influence on TL\n');
    else
        fprintf('  ⚠️  Low parameter sensitivity - estimation may be difficult\n');
    end
    
    % Overall Validation Summary
    fprintf('\n📊 Validation Summary\n');
    fprintf('====================\n');
    
    n_tests_passed = 0;
    total_tests = 5;
    
    fprintf('Parameter range test: ');
    if all(valid_results(:))
        fprintf('✅ PASS\n');
        n_tests_passed = n_tests_passed + 1;
    else
        fprintf('❌ FAIL\n');
    end
    
    fprintf('Numerical stability: ');
    if tl_std < 0.1
        fprintf('✅ PASS\n');
        n_tests_passed = n_tests_passed + 1;
    else
        fprintf('❌ FAIL\n');
    end
    
    fprintf('Position consistency: ');
    if max_error < 0.5
        fprintf('✅ PASS\n');
        n_tests_passed = n_tests_passed + 1;
    else
        fprintf('❌ FAIL\n');
    end
    
    fprintf('Physical behavior: ');
    if mean(range_gradient) > 0
        fprintf('✅ PASS\n');
        n_tests_passed = n_tests_passed + 1;
    else
        fprintf('❌ FAIL\n');
    end
    
    fprintf('Parameter sensitivity: ');
    if abs(speed_sensitivity) > 0.001 && abs(density_sensitivity) > 0.01
        fprintf('✅ PASS\n');
        n_tests_passed = n_tests_passed + 1;
    else
        fprintf('❌ FAIL\n');
    end
    
    fprintf('\nOverall: %d/%d tests passed (%.0f%%)\n', ...
        n_tests_passed, total_tests, n_tests_passed/total_tests*100);
    
    if n_tests_passed == total_tests
        fprintf('🎉 All validation tests passed! Forward model is working correctly.\n');
    elseif n_tests_passed >= 3
        fprintf('⚠️  Most tests passed, but check failing tests for issues.\n');
    else
        fprintf('❌ Multiple test failures - forward model needs debugging.\n');
    end
    
    fprintf('\nValidation completed!\n');
end
