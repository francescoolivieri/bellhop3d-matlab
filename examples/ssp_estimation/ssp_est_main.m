% ssp_estimation_main.m
clc
close all;

clean_files();

% Define estimate settings ------------------------------------------------

% Number of iterations
N = 4;

% Note: mu/Sigma for ssp_grid, taken from CTD data
data.th_names   = {'ssp_grid'};  % Parameters to estimate


% Setup the two environments ----------------------------------------------
% True world
data.sim_true = uw.Simulation();

% Estimation world
data.sim_est = uw.Simulation();
data.sim_est.params.setEstimationParameterNames(data.th_names); 
data.sim_est.params.update(data.th_est, data.th_names);

% __ init the data structure __
% Allocate meamory for receiver positions
data.x = nan(1,N+1);
data.y = nan(1,N+1);
data.z = nan(1,N+1);

% Start location
data.x(1) = data.sim_est.settings.x_start;
data.y(1) = data.sim_est.settings.y_start;
data.z(1) = data.sim_est.settings.z_start;

% SSP Estimator setup -----------------------------------------------------
% Initialize GP model for estimation
config.ell_h = 400;    % horizontal correlation length (m)
config.ell_v = 20;     % vertical correlation length (m)
config.sigma_f = 1.0;   % Prior std dev of the SSP field (m/s)

% Likelihood Noise
config.tl_noise_std = 2.; % measurement noise

% MCMC Sample Parameters
% Should tune these
config.mcmc_iterations = 30; % Total steps in the MCMC chain (more the better)
config.mcmc_burn_in = 3;      % Steps to discard to let the chain converge
config.proposal_std = 0.05;   % Scales the size of MCMC proposal steps.


% SSP Esimator Initialization ---------------------------------------------
% Create an instance of the class.
data.ssp_estimator = SSPGaussianProcessMCMC(config);  
data.sim_est.params.set('ssp_grid', data.ssp_estimator.posterior_mean_ssp);


pos_check = [0.5 1 20];
before = data.sim_true.computeTL(pos_check);
fprintf("BEGINNING TL at (%.2f %.2f %.2f) difference: %f \n", pos_check, sum(abs(before - data.sim_est.computeTL(pos_check)), 'all'));

% Main estimation loop ----------------------------------------------------

for iter = 1:N
    % 1. Choose next measurement location
    data = pos_next_measurement(data, data.sim_est.settings);
    
    % Get current position (fix for undefined pos variable)
    idx = find(isfinite(data.x), 1, 'last');
    current_pos = [data.x(idx), data.y(idx), data.z(idx)];
    
    % 2. Take measurement (simulate using true SSP)
    measurement = data.sim_true.computeTL(current_pos);
    
    % 3. Update GP with sophisticated inversion (updates also the
    % simulation
    data.ssp_estimator.update(current_pos, measurement, data.sim_est);

    % Check status
    after = data.sim_est.computeTL(pos_check);
    fprintf("Difference at iteration %d at (%.2f %.2f %.2f) : %f \n", iter, pos_check, sum(abs(before - after), 'all'));

end

fprintf("Difference: %f \n", sum(abs(before - after), 'all'));


% --- Get the Estimated SSP ---
% This is your best guess for the current sound speed profile
estimated_ssp = data.ssp_estimator.posterior_mean_ssp;


% --- Save the Final SSP for Bellhop ---
% You can now write the final, estimated SSP to a file for other uses.
% ssp_estimator.writeSSPFile('final_estimated_ssp.ssp');
plot_ssp_poster_summary(data, data.sim_true.settings, 'results/plots');


function plot_ssp_poster_summary(data, s, outpath)
    % Poster summary for SSP field estimation

    idx_last = find(isfinite(data.x), 1, 'last');
    if isempty(idx_last) || idx_last < 1
        warning('No measurements to summarize.'); return;
    end

    % True, estimate, uncertainty
    true_ssp = data.sim_true.params.get('ssp_grid');
    est_ssp  = data.ssp_estimator.posterior_mean_ssp;
    unc_grid = data.ssp_estimator.getUncertaintyGrid();
    z_coords = data.ssp_estimator.grid_z;

    % 1) RMSE vs depth (avg over x,y)
    err = (true_ssp - est_ssp).^2;
    rmse_by_depth = squeeze(sqrt(nanmean(nanmean(err, 1), 2)));

    % 2) Uncertainty reduction vs depth (%)
    % From the class: initial posterior_var_ssp = sigma_f^2 * ones(size(...))
    prior_variance = data.ssp_estimator.sigma_f^2;  % This is the initial uniform variance
    post_variance_depth = squeeze(nanmean(nanmean(unc_grid.^2, 1), 2));  % Convert std to variance
    pct_reduction = 100 * (1 - post_variance_depth ./ prior_variance);
    
    % Clamp to reasonable range (0-100%)
    pct_reduction = max(0, min(100, pct_reduction));

    % Debug output to check values
    fprintf('Prior variance: %.4f\n', prior_variance);
    fprintf('Post variance range: %.4f - %.4f\n', min(post_variance_depth), max(post_variance_depth));
    fprintf('Reduction range: %.1f%% - %.1f%%\n', min(pct_reduction), max(pct_reduction));

    % 3) Total distance
    k = 1:idx_last;
    xf = data.x(k); yf = data.y(k); zf = data.z(k);
    seg = sqrt(diff(xf).^2 + diff(yf).^2 + diff(zf).^2);
    dist_total = nansum(seg);

    fig = figure(200); clf; set(fig, 'Color', 'w', 'Position', [100 100 900 750]);

    % Panel 1: RMSE vs depth
    ax1 = subplot(3,1,1);
    plot(rmse_by_depth, z_coords, 'b-', 'LineWidth', 2);
    set(ax1, 'YDir','reverse'); grid(ax1,'on');
    ylim([0 s.OceanDepth]);
    xlabel('RMSE (m/s)'); ylabel('Depth (m)'); title('SSP Reconstruction Error vs Depth');
    add_corner_note(ax1, sprintf('Mean RMSE: %.2f m/s', nanmean(rmse_by_depth)));

    % Panel 2: Uncertainty reduction vs depth
    ax2 = subplot(3,1,2);
    plot(pct_reduction, z_coords, 'r-', 'LineWidth', 2);
    set(ax2, 'YDir','reverse'); grid(ax2,'on');
    ylim([0 s.OceanDepth]);
    xlabel('Uncertainty Reduction (%)'); ylabel('Depth (m)'); title('Uncertainty Reduction vs Depth');
    add_corner_note(ax2, sprintf('Mean reduction: %.1f%%', nanmean(pct_reduction)));

    % Panel 3: Measurement locations (top view)
    ax3 = subplot(3,1,3); hold(ax3,'on');
    plot(xf, yf, 'b-','LineWidth',2);
    scatter(xf(1), yf(1), 40, 'g', 'filled');
    scatter(xf(end), yf(end), 60, 'r', 'filled');
    scatter(xf, yf, 30, zf, 'filled'); 
    cb = colorbar('southoutside');
    cb.Label.String = 'Depth (m)';
    axis(ax3,'equal'); grid(ax3,'on');
    xlim([s.x_min s.x_max]); ylim([s.y_min s.y_max]);
    xlabel('X (m)'); ylabel('Y (m)'); title('Measurement Locations (color = depth)');
    
    % Move distance annotation to top-left to avoid overlap
    text(ax3, 0.02, 0.98, sprintf('Total distance: %.2f m', dist_total), ...
        'Units','normalized', 'HorizontalAlignment','left', ...
        'VerticalAlignment','top', 'Color','k', 'BackgroundColor','w');

    % Style text/axes
    axs = findall(fig, 'type', 'axes');
    for ax = axs'
        ax.Color = 'w'; ax.XColor = 'k'; ax.YColor = 'k'; ax.ZColor = 'k';
        ax.Title.Color = 'k'; ax.XLabel.Color = 'k'; ax.YLabel.Color = 'k'; ax.ZLabel.Color = 'k';
    end
    legs = findall(fig, 'type', 'legend');
    for lg = legs', lg.TextColor = 'k'; lg.Color = 'w'; end

    if nargin >= 3 && ~isempty(outpath)
        if ~exist(outpath,'dir'), mkdir(outpath); end
        exportgraphics(fig, fullfile(outpath, 'ssp_poster_summary.png'), 'Resolution', 300);
    end
end

function add_corner_note(ax, str)
    text(ax, 0.98, 0.95, str, 'Units','normalized', ...
        'HorizontalAlignment','right', 'VerticalAlignment','top', 'Color','k', ...
        'BackgroundColor','w');
end