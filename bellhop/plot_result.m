function plot_result(data, s)

idx=find(isfinite(data.x),1,'last');

display(data.x)
display(idx)

% Plot parameter estimates over time
for ii=1:numel(s.mu_th)

    h=zeros(1,3);
    figure(ii+2)
    clf
    h(1)=plot(data.th_est(ii,:),'r');
    hold on;
    sigma=sqrt(squeeze(data.Sigma_est(ii,ii,:)))';
    h(2)=plot(data.th_est(ii,:)+3*sigma,'b');
    plot(data.th_est(ii,:)-3*sigma,'b')
    h(3)=plot(data.th(ii)*ones(size(data.th_est(ii,:))),'k');
    legend(h,{'Mean','3*Std','True'})
    if ii==1
        ylabel('Speed (m/s)')
        title('alphaR')
    else
        ylabel('rho (g/cm^3)')
        title('rho')
    end
    xlabel('Time step')
    grid minor;
end

% Create 3D grid for uncertainty visualization
x_values = s.x_min:s.d_x:s.x_max;
y_values = s.y_min:s.d_y:s.y_max;
z_values = s.z_min:s.d_z:s.z_max;


% Create a 2D slice at a specific y-value
y_slice = mean([s.y_min, s.y_max]); % Middle y-value

% Generate 2D grid at the y_slice
% [X_slice, Z_slice] = meshgrid(x_values, z_values);
% 
% pos_slice = [X_slice(:), repmat(y_slice, numel(X_slice), 1), Z_slice(:)];

% Full 3D grid (warning: computationally expensive)
[X, Y, Z] = meshgrid(x_values, y_values, z_values);
pos = [X(:), Y(:), Z(:)];



% % Calculate covariance of predictions
% [~, Sigma_tltl, ~] =unscented_transform(@(th)forward_model(th, pos), data.th_est(:,idx), squeeze(data.Sigma_est(:,:,idx)));
% var_tl=diag(Sigma_tltl);


% Calculate prediction uncertainty
Np = 40;
Y = zeros(size(pos, 1), Np);

parfor pp = 1:Np
    th = data.th_est(:, idx) + chol(squeeze(data.Sigma_est(:, :, idx)), 'lower') * randn(size(data.th_est(:, idx)));
    Y(:, pp) = forward_model( th, pos, s);
end
var_tl = var(Y, [], 2);

% Reshape var_tl into the same grid size as Z and R
var_tl_grid = reshape(var_tl, size(X));

% Create the pcolor plot (uncertainty plot, 2D slice)
figure(5);
pcolor(X, Z, sqrt(var_tl_grid)); % Z on the x-axis, R on the y-axis
shading interp; % Interpolated shading for smooth visualization
cb=colorbar; % Add colorbar for reference
set( gca, 'YDir', 'Reverse' )
ylabel('Depth (m)')
xlabel('X coordinate (m)')
title(sprintf('Standard deviation of predicted loss (Y-slice at %.1f m)', y_slice));
colormap jet;
caxis([0 10])
cb.Label.String = 'Std (dB)';


% Plot measurement trajectory in 3D
figure(100)
clf
plot3(data.x(1:idx), data.y(1:idx), data.z(1:idx), 'b-', 'LineWidth', 2);
hold on
scatter3(data.x(1:idx), data.y(1:idx), data.z(1:idx), 50, 'b', 'filled');
% Highlight current position
scatter3(data.x(idx), data.y(idx), data.z(idx), 100, 'r', 'filled', 'MarkerEdgeColor', 'k');

% Set axis properties
axis([s.x_min s.x_max s.y_min s.y_max s.z_min s.z_max])
set(gca, 'ZDir', 'Reverse') % Assuming z is depth (positive downward)
xlabel('X coordinate (m)')
ylabel('Y coordinate (m)')
zlabel('Depth (m)')
grid on
title('3D Measurement Trajectory')
view(45, 30) % Set 3D viewing angle


% Additional 2D projections
figure(101)
clf
subplot(2, 2, 1)
plot(data.x(1:idx), data.y(1:idx), 'b-', 'LineWidth', 2);
hold on
scatter(data.x(1:idx), data.y(1:idx), 30, 'b', 'filled');
scatter(data.x(idx), data.y(idx), 60, 'r', 'filled', 'MarkerEdgeColor', 'k');
axis([s.x_min s.x_max s.y_min s.y_max])
xlabel('X coordinate (m)')
ylabel('Y coordinate (m)')
title('Top View (X-Y)')
grid minor

% X-Z projection (side view)
subplot(2, 2, 2)
plot(data.x(1:idx), data.z(1:idx), 'b-', 'LineWidth', 2);
hold on
scatter(data.x(1:idx), data.z(1:idx), 30, 'b', 'filled');
scatter(data.x(idx), data.z(idx), 60, 'r', 'filled', 'MarkerEdgeColor', 'k');
axis([s.x_min s.x_max s.z_min s.z_max])
set(gca, 'YDir', 'Reverse')
xlabel('X coordinate (m)')
ylabel('Depth (m)')
title('Side View (X-Z)')
grid minor

% Y-Z projection (front view)
subplot(2, 2, 3)
plot(data.y(1:idx), data.z(1:idx), 'b-', 'LineWidth', 2);
hold on
scatter(data.y(1:idx), data.z(1:idx), 30, 'b', 'filled');
scatter(data.y(idx), data.z(idx), 60, 'r', 'filled', 'MarkerEdgeColor', 'k');
axis([s.y_min s.y_max s.z_min s.z_max])
set(gca, 'YDir', 'Reverse')
xlabel('Y coordinate (m)')
ylabel('Depth (m)')
title('Front View (Y-Z)')
grid minor

% Time evolution
subplot(2, 2, 4)
plot(1:idx, data.z(1:idx), 'b-', 'LineWidth', 2);
hold on
scatter(1:idx, data.z(1:idx), 30, 'b', 'filled');
scatter(idx, data.z(idx), 60, 'r', 'filled', 'MarkerEdgeColor', 'k');
set(gca, 'YDir', 'Reverse')
xlabel('Time Step')
ylabel('Depth (m)')
title('Depth vs Time')
grid minor

pause(0.1)

end