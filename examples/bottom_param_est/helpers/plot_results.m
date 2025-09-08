function plot_results(data, sim_true, sim_est)

data.x = sim_true.sensor.path(:, 1);
data.y = sim_true.sensor.path(:, 2);
data.z = sim_true.sensor.path(:, 3);

idx=find(isfinite(data.x),1,'last');

est_params_names = sim_est.params.getEstimationParameterNames();
% Plot parameter estimates over time
for ii = 1:numel(data.th)
    paramName = est_params_names{ii};  

    info = sim_est.params.getParameterDisplayInfo(paramName);

    figure(ii+2);
    clf;

    % Mean estimate
    h(1) = plot(data.th_est(ii,:), 'r'); hold on;

    % Confidence bounds
    sigma = sqrt(squeeze(data.Sigma_est(ii,ii,:)))';
    h(2) = plot(data.th_est(ii,:) + 3*sigma, 'b');
    plot(data.th_est(ii,:) - 3*sigma, 'b');

    % True value
    h(3) = plot(data.th(ii) * ones(size(data.th_est(ii,:))), 'k');

    legend(h, {'Mean', '3*Std', 'True'});

    % Apply display info
    ylabel(info.ylabel);
    title(info.title);
    xlabel('Time step');
    grid minor;

    % Style
    set(gcf, 'Color', 'w');
    ax = gca;
    ax.Color = 'w';
    ax.XColor = 'k';
    ax.YColor = 'k';

    % Set all text to black (title, labels, ticks)
    ax.Title.Color      = 'k';
    ax.XLabel.Color     = 'k';
    ax.YLabel.Color     = 'k';
    ax.ZLabel.Color     = 'k';

end


% Plot measurement trajectory in 3D
figure(100)
clf
plot3(data.x(1:idx), data.y(1:idx), data.z(1:idx), 'b-', 'LineWidth', 2);
hold on
% Highlight past positiosn
scatter3(data.x(1:idx), data.y(1:idx), data.z(1:idx), 50, 'b', 'filled');
% Highlight current position
h_current = scatter3(data.x(idx), data.y(idx), data.z(idx), 100, 'r', 'filled', 'MarkerEdgeColor', 'k');
% Highlight source position
h_source = scatter3(sim_true.settings.sim_source_x, sim_true.settings.sim_source_y, sim_true.settings.sim_source_depth, 100, 'green', 'filled', 'MarkerEdgeColor', 'k');


% Set axis properties
axis([sim_true.settings.x_min sim_true.settings.x_max sim_true.settings.y_min sim_true.settings.y_max sim_true.settings.z_min sim_true.settings.z_max])
set(gca, 'ZDir', 'Reverse') % Assuming z is depth (positive downward)
xlabel('X coordinate (km)')
ylabel('Y coordinate (km)')
zlabel('Depth (m)')
grid on
title('3D Measurement Trajectory')
view(45, 30) % Set 3D viewing angle

% Add legend
legend([h_source, h_current], {'Source', 'Current Position'}, 'Location', 'best');
legend boxoff

pause(0.1)

end