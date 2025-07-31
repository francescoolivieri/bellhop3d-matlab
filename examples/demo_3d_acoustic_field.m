function demo_3d_acoustic_field(s)
    % DEMO_3D_ACOUSTIC_FIELD - Visualize 3D underwater acoustic transmission loss
    %
    % This demo shows how the 3D acoustic forward model works:
    % 1. Generate 3D acoustic field using BELLHOP3D
    % 2. Visualize transmission loss in different planes
    % 3. Show effect of different bottom parameters
    
    if nargin < 1
        s = get_sim_settings();
    end
    
    fprintf('🌊 3D Acoustic Field Visualization Demo\n');
    fprintf('========================================\n\n');
    
    % Define bottom parameter scenarios
    scenarios = {
        [1500, 1.2], 'Soft Bottom (Clay/Mud)';
        [1600, 1.5], 'Medium Bottom (Sand)'; 
        [1800, 2.0], 'Hard Bottom (Rock/Gravel)'
    };
    
    fprintf('📊 Computing 3D acoustic fields for different bottom types...\n\n');
    
    % Create 3D grid for field calculation
    x_range = linspace(s.x_min, s.x_max, 21);
    y_range = linspace(s.y_min, s.y_max, 21); 
    z_range = linspace(5, s.OceanDepth-5, 11);
    
    [X, Y, Z] = meshgrid(x_range, y_range, z_range);
    positions = [X(:), Y(:), Z(:)];
    
    % Calculate fields for each scenario
    fields = cell(size(scenarios, 1), 1);
    
    for i = 1:size(scenarios, 1)
        theta = scenarios{i, 1}';
        bottom_type = scenarios{i, 2};
        
        fprintf('Computing field for %s...\n', bottom_type);
        fprintf('  Parameters: [%.0f m/s, %.1f]\n', theta(1), theta(2));
        
        % Calculate transmission loss field
        tl_field = forward_model(theta, positions, s);
        fields{i} = reshape(tl_field, size(X));
        
        fprintf('  TL range: %.1f to %.1f dB\n', min(tl_field), max(tl_field));
    end
    
    % Visualization
    fprintf('\n📈 Creating visualizations...\n');
    
    try
        figure('Position', [100, 100, 1200, 800]);
        
        for i = 1:size(scenarios, 1)
            % Horizontal slice at mid-depth
            subplot(2, 3, i);
            mid_depth_idx = ceil(length(z_range)/2);
            slice_data = squeeze(fields{i}(:, :, mid_depth_idx));
            
            imagesc(x_range, y_range, slice_data);
            colorbar;
            title(sprintf('%s\nHorizontal Slice (%.1fm depth)', ...
                scenarios{i,2}, z_range(mid_depth_idx)));
            xlabel('X Position [km]');
            ylabel('Y Position [km]');
            axis equal tight;
            
            % Vertical slice at center
            subplot(2, 3, i+3);
            center_y_idx = ceil(length(y_range)/2);
            slice_data = squeeze(fields{i}(center_y_idx, :, :))';
            
            imagesc(x_range, z_range, slice_data);
            colorbar;
            title(sprintf('Vertical Slice (Y=%.1fkm)', y_range(center_y_idx)));
            xlabel('X Position [km]');
            ylabel('Depth [m]');
            set(gca, 'YDir', 'reverse');  % Depth increases downward
        end
        
        sgtitle('3D Acoustic Transmission Loss Fields for Different Bottom Types');
        
        % Save figure
        saveas(gcf, 'results/plots/3d_acoustic_fields.png');
        fprintf('📊 Visualization saved to results/plots/3d_acoustic_fields.png\n');
        
        % Comparative analysis
        figure('Position', [100, 200, 800, 600]);
        
        % Compare transmission loss at a specific location
        test_pos = [0.5, 0.5, 20];  % 0.5km range, 20m depth
        test_tl = zeros(size(scenarios, 1), 1);
        
        for i = 1:size(scenarios, 1)
            theta = scenarios{i, 1}';
            test_tl(i) = forward_model(theta, test_pos, s);
        end
        
        bar(test_tl);
        set(gca, 'XTickLabel', {scenarios{:,2}});
        ylabel('Transmission Loss [dB]');
        title(sprintf('Bottom Type Effect on TL\n(Position: [%.1f, %.1f, %.0f])', ...
            test_pos(1), test_pos(2), test_pos(3)));
        grid on;
        
        % Add parameter annotations
        for i = 1:length(test_tl)
            text(i, test_tl(i)+1, sprintf('[%.0f m/s, %.1f]', ...
                scenarios{i,1}(1), scenarios{i,1}(2)), ...
                'HorizontalAlignment', 'center', 'FontSize', 8);
        end
        
        saveas(gcf, 'results/plots/bottom_type_comparison.png');
        fprintf('📊 Comparison saved to results/plots/bottom_type_comparison.png\n');
        
    catch ME
        fprintf('⚠️  Visualization failed: %s\n', ME.message);
        fprintf('   (This is normal if running without display)\n');
    end
    
    % Summary statistics
    fprintf('\n📈 Acoustic Field Analysis:\n');
    for i = 1:size(scenarios, 1)
        field_data = fields{i}(:);
        fprintf('  %s:\n', scenarios{i,2});
        fprintf('    Mean TL: %.1f ± %.1f dB\n', mean(field_data), std(field_data));
        fprintf('    Range: %.1f - %.1f dB\n', min(field_data), max(field_data));
    end
    
    % Demonstrate parameter sensitivity
    fprintf('\n🔬 Parameter Sensitivity Analysis:\n');
    base_theta = [1600, 1.5]';
    test_position = [1.0, 0.0, 15];  % 1km range, 15m depth
    
    % Sound speed sensitivity
    sound_speeds = 1500:50:1700;
    tl_vs_speed = zeros(size(sound_speeds));
    for i = 1:length(sound_speeds)
        theta_test = [sound_speeds(i), base_theta(2)]';
        tl_vs_speed(i) = forward_model(theta_test, test_position, s);
    end
    
    fprintf('  Sound speed sensitivity (at [%.1f, %.1f, %.0f]):\n', test_position);
    fprintf('    TL change: %.2f dB per 100 m/s\n', ...
        (tl_vs_speed(end) - tl_vs_speed(1)) / ((sound_speeds(end) - sound_speeds(1))/100));
    
    fprintf('\nDemo completed! 🎉\n');
    fprintf('Key insights:\n');
    fprintf('  • Harder bottoms (higher sound speed/density) generally increase TL\n');
    fprintf('  • 3D effects are important - TL varies significantly with position\n');
    fprintf('  • Bottom parameters have measurable impact on acoustic propagation\n');
end
