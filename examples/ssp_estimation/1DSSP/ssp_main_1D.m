% ssp_main_1D.m
clc
close all;

clean_files();

% Define estimate settings ------------------------------------------------

sim = uw.Simulation();
generateSSP1D(sim.settings);


% Number of iterations
N = 3;

% Note: mu/Sigma for ssp_grid, taken from CTD data
data.th_names   = {'ssp_grid'};  % Parameters to estimate


% Setup the two environments ----------------------------------------------
% True world
data.sim_true = uw.Simulation();

% Estimation world
data.sim_est = uw.Simulation();
data.sim_est.params.setEstimationParameterNames(data.th_names); 


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
config.ell_h = +inf;     % enforce horizontal constancy (1-D SSP)
config.ell_v = 50;      % vertical correlation length (m)
config.sigma_f = 1.;   % Prior std dev of the SSP field (m/s)

% Likelihood Noise
config.tl_noise_std = 0.5; % measurement noise (matches computeTL without added noise)

% MCMC Sample Parameters (pCN uses proposal_std as beta)
config.mcmc_iterations = 80;
config.mcmc_burn_in    = 5;
config.proposal_std    = 0.5;   % pCN beta (target ~25-35% acceptance)


% SSP Esimator Initialization ---------------------------------------------
% Create an instance of the class.
data.ssp_estimator = SSPGP_1D(config);  
data.sim_est.params.set('ssp_grid', data.ssp_estimator.posterior_mean_ssp);


pos_check = [0.5 1 20];
before = data.sim_true.computeTL(pos_check);
fprintf("BEGINNING TL at (%.2f %.2f %.2f) difference: %f \n", pos_check, sum(abs(before - data.sim_est.computeTL(pos_check)), 'all'));

data.start_ssp  = data.ssp_estimator.posterior_mean_ssp;

% Main estimation loop ----------------------------------------------------

for iter = 1:N
    % 1. Choose next measurement location
    data = pos_next_measurement(data, data.sim_est.settings);
    
    % Get current position (fix for undefined pos variable)
    idx = find(isfinite(data.x), 1, 'last');
    current_pos = [data.x(idx), data.y(idx), data.z(idx)];
    
    % 2. Take measurement (simulate using true SSP)
    tl_measurement = data.sim_true.computeTL(current_pos);
    ssp_measurement = data.sim_true.sampleSoundSpeed(current_pos);
    
    % 3. Update GP with inversion (updates also simulation)
    data.ssp_estimator.update(current_pos, tl_measurement, data.sim_est, ssp_measurement);

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

    fig = figure(200); clf; set(fig, 'Color', 'w', 'Position', [100 100 1200 900]);

    % Panel 1: RMSE vs depth
    ax1 = subplot(3,2,1);
    plot(rmse_by_depth, z_coords, 'b-', 'LineWidth', 2);
    set(ax1, 'YDir','reverse'); grid(ax1,'on');
    ylim([0 s.OceanDepth]);
    xlabel('RMSE (m/s)'); ylabel('Depth (m)'); title('SSP Reconstruction Error vs Depth');
    add_corner_note(ax1, sprintf('Mean RMSE: %.2f m/s', nanmean(rmse_by_depth)));

    % Panel 2: Uncertainty reduction vs depth
    ax2 = subplot(3,2,2);
    plot(pct_reduction, z_coords, 'r-', 'LineWidth', 2);
    set(ax2, 'YDir','reverse'); grid(ax2,'on');
    ylim([0 s.OceanDepth]);
    xlabel('Uncertainty Reduction (%)'); ylabel('Depth (m)'); title('Uncertainty Reduction vs Depth');
    add_corner_note(ax2, sprintf('Mean reduction: %.1f%%', nanmean(pct_reduction)));

    % Panel 3: True vs Estimated SSP at a representative x,y with uncertainty shading
    ax3 = subplot(3,2,3); hold(ax3,'on');
    % pick center indices
    iy = round(size(true_ssp,1)/2); ix = round(size(true_ssp,2)/2);
    true_col = squeeze(true_ssp(iy, ix, :));
    start_col = squeeze(data.start_ssp(iy, ix, :));
    est_col  = squeeze(est_ssp(iy, ix, :));
    std_col  = squeeze(unc_grid(iy, ix, :));
    % uncertainty band
    fill([est_col-2*std_col; flipud(est_col+2*std_col)], ...
     [z_coords(:); flipud(z_coords(:))], ...
     [1 0.9 0.9], 'EdgeColor','none');

    plot(est_col,   z_coords, 'r-',  'LineWidth', 2);     % posterior mean
    plot(start_col, z_coords, 'b-',  'LineWidth', 2);     % starting guess
    plot(true_col,  z_coords, 'k--', 'LineWidth', 1.5);   % ground truth
    
    set(ax3,'YDir','reverse'); 
    grid(ax3,'on'); 
    ylim([0 s.OceanDepth]);
    
    xlabel('Sound speed (m/s)'); 
    ylabel('Depth (m)'); 
    title('SSP (center column) with 95% band');
    
    legend({'±2σ band','Posterior mean','Start','True'},'Location','best');

    % Panel 4: Posterior standard deviation vs depth (avg over x,y)
    ax4 = subplot(3,2,4);
    std_by_depth = squeeze(nanmean(nanmean(unc_grid,1),2));
    plot(std_by_depth, z_coords, 'm-', 'LineWidth', 2);
    set(ax4,'YDir','reverse'); grid(ax4,'on'); ylim([0 s.OceanDepth]);
    xlabel('Posterior std (m/s)'); ylabel('Depth (m)'); title('Posterior Uncertainty vs Depth');

    % Panel 5: Measurement locations (top view)
    ax5 = subplot(3,2,5); hold(ax5,'on');
    plot(xf, yf, 'b-','LineWidth',2);
    scatter(xf(1), yf(1), 40, 'g', 'filled');
    scatter(xf(end), yf(end), 60, 'r', 'filled');
    scatter(xf, yf, 30, zf, 'filled'); 
    cb = colorbar('southoutside');
    cb.Label.String = 'Depth (m)';
    axis(ax5,'equal'); grid(ax5,'on');
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
        % TL fit diagnostic: compare measured vs predicted TL at measured positions
        try
            n_meas = find(isfinite(data.x), 1, 'last');
            if ~isempty(n_meas) && n_meas > 0
                rx = [data.x(1:n_meas)', data.y(1:n_meas)', data.z(1:n_meas)'];
                tl_true = zeros(n_meas,1);
                tl_est  = zeros(n_meas,1);
                for ii=1:n_meas
                    tl_true(ii) = data.sim_true.computeTL(rx(ii,:));
                    tl_est(ii)  = data.sim_est.computeTL(rx(ii,:));
                end
                fig2 = figure(201); clf; set(fig2,'Color','w','Position',[100 100 700 400]);
                subplot(1,2,1);
                plot(1:n_meas, tl_true, 'k-o', 1:n_meas, tl_est, 'r-s','LineWidth',1.5);
                grid on; xlabel('Measurement #'); ylabel('TL (dB)'); title('TL: true vs estimated'); legend({'True','Estimated'},'Location','best');
                subplot(1,2,2);
                plot(1:n_meas, tl_true - tl_est, 'b-o','LineWidth',1.5); yline(0,'k--'); grid on;
                xlabel('Measurement #'); ylabel('Residual (dB)'); title('TL residuals (True - Est)');
                exportgraphics(fig2, fullfile(outpath, 'tl_diagnostics.png'), 'Resolution', 300);
            end
        catch ME
            warning('TL diagnostics plotting failed: %s', ME.message);
        end
    end
end

function add_corner_note(ax, str)
    text(ax, 0.98, 0.95, str, 'Units','normalized', ...
        'HorizontalAlignment','right', 'VerticalAlignment','top', 'Color','k', ...
        'BackgroundColor','w');
end
