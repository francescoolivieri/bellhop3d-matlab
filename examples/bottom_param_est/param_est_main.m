clc
close all;

clean_files();

% Define estimate settings ------------------------------------------------

% Number of iterations
N = 8;

% Note: names and according values must be in the SAME order
data.th_names   = {'sound_speed_sediment'};  % Parameters to estimate
data.th_est = [1650];              % Prior means
data.Sigma_est = diag([20].^2);     % Prior covariances
data.Sigma_rr       = 1^2;              % Filter assumed noise var

% Pick ground truth from the prob. distribution
data.th = 1620.;%  data.th_est + chol(data.Sigma_est,'lower')*randn(size(data.th_est));

% Setup the two environments ----------------------------------------------
% True world
data.sim_true = uw.Simulation();
data.sim_true.params.update(data.th , data.th_names);

% Estimation world
data.sim_est = uw.Simulation();
data.sim_est.params.setEstimationParameterNames(data.th_names); 
data.sim_est.params.update(data.th_est, data.th_names);

% Main simulation loop ----------------------------------------------------
% Initialize data structure
data = init_filter(data, data.sim_true.settings, N);

for n=2:N
    % Print state
    fprintf('\n=== Iteration nr %d ===\n', n)

    % Get action
    tic
    data = pos_next_measurement(data, data.sim_true.settings);
    toc

    % Take measurement from real world
    data = generate_data(data);

    % Update estimate
    data = ukf(data);

    % Display result
    plot_results(data, data.sim_true.settings);
    
end

final_plots(data, data.sim_est.settings, "results/no_planning_2")


function final_plots(data, s, outpath)
% Poster summary: per-parameter error, % remaining uncertainty, top-down path

idx_last = find(isfinite(data.m),1,'last');
k = 1:idx_last;

% Safety if no measurements
if isempty(idx_last) || idx_last < 1
    warning('No measurements to summarize.'); return;
end

% Per-parameter absolute error and relative error (%)
P = numel(data.th);
abs_err = zeros(P, idx_last);
rel_err_pct = zeros(1, P);
for ii = 1:P
    abs_err(ii, k) = abs(data.th_est(ii, k) - data.th(ii));
    denom = abs(data.th(ii));
    if denom > 0
        rel_err_pct(ii) = 100 * abs_err(ii, k(end)) / denom;
    else
        rel_err_pct(ii) = NaN;
    end
end

% Per-parameter % remaining uncertainty (variance)
var0 = diag(data.Sigma_est(:,:,1));
pct_unc = nan(P, idx_last);
for ii = 1:P
    v = squeeze(data.Sigma_est(ii,ii,k))';
    if var0(ii) > 0
        pct_unc(ii, k) = 100 * (v / var0(ii));
    else
        pct_unc(ii, k) = NaN;
    end
end

% Optional: overall % remaining (trace)
trace0 = sum(diag(data.Sigma_est(:,:,1)));
trace_pct = 100 * arrayfun(@(t) sum(diag(data.Sigma_est(:,:,t)))/trace0, k);

% Total 3D distance
xf = data.x(k); yf = data.y(k); zf = data.z(k);
seg = sqrt(diff(xf).^2 + diff(yf).^2 + diff(zf).^2);
dist_total = nansum(seg);

% Names
if isfield(data, 'th_names') && ~isempty(data.th_names)
    names = data.th_names;
else
    names = arrayfun(@(ii) sprintf('Param %d', ii), 1:P, 'UniformOutput', false);
end

% Figure
fig = figure(200); clf; set(fig, 'Color', 'w', 'Position', [100 100 950 750]);

% Panel 1: Per-parameter absolute error with final relative % annotations
subplot(3,1,1); hold on;
cols = lines(max(P,3));
for ii = 1:P
    plot(k, 100 * abs_err(ii,k) ./ abs(data.th(ii)), '-', 'LineWidth', 2, 'Color', cols(ii,:));
    
end
grid on; xlabel('Iteration'); ylabel('Rel. error (%)');
title('Parameter error (lines) with final relative error (%)');
set_integer_xticks(gca, idx_last);
legend(names, 'Location','northeastoutside', 'Interpreter', 'none'); legend boxoff;

% --- Collect all labels into one text block ---
label_lines = cell(P,1);
for ii = 1:P
    if ~isnan(rel_err_pct(ii))
        label_lines{ii} = sprintf('%s: %.4f%%', names{ii}, rel_err_pct(ii));
    else
        label_lines{ii} = sprintf('%s', names{ii});
    end
end
label_str = strjoin(label_lines, '\n');

% Add annotation outside axes (normalized coords)
annotation('textbox', [0.72, 0.37, 0.2, 0.4], ...
    'String', label_str, ...
    'EdgeColor', 'none', ...
    'Color', 'k', ...
    'FontSize', 9, ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', 'top', ...
    'Interpreter', 'none');

% Panel 2: % remaining uncertainty per parameter (+ trace as dashed black)
subplot(3,1,2); hold on;
for ii = 1:P
    plot(k, pct_unc(ii,k), '-', 'LineWidth', 2, 'Color', cols(ii,:));
end
plot(k, trace_pct, 'k--', 'LineWidth', 1.5);
grid on; xlabel('Iteration'); ylabel('% remaining');
title('Uncertainty (% variance remaining)');
set_integer_xticks(gca, idx_last);
legend([names, {'trace(\Sigma)'}], 'Location','northeastoutside', 'Interpreter', 'none'); legend boxoff;

% Panel 3: Top-down path with total distance
subplot(3,1,3); hold on;
plot(xf, yf, 'b-','LineWidth',2);
scatter(xf(1), yf(1), 40, 'g', 'filled'); % start
scatter(xf(end), yf(end), 60, 'r', 'filled'); % end
axis equal; grid on;
xlim([s.x_min s.x_max]); ylim([s.y_min s.y_max]);
xlabel('X'); ylabel('Y'); title('Sensor path (top view)');
txt = sprintf('Total distance: %.2f Km', dist_total);
annotation('textbox',[0.65 0.08 0.3 0.06],'String',txt,'EdgeColor','none','Color','k');

% Style all axes
set(fig, 'Color', 'w');
axs = findall(fig, 'type', 'axes');
for ax = axs'
    ax.Color = 'w'; ax.XColor = 'k'; ax.YColor = 'k'; ax.ZColor = 'k';
    ax.Title.Color = 'k'; ax.XLabel.Color = 'k'; ax.YLabel.Color = 'k'; ax.ZLabel.Color = 'k';
end

% Style all legends
legs = findall(fig, 'type', 'legend');
for lg = legs'
    lg.TextColor = 'k';
    lg.Color = 'w';  % White legend background
end

% Save
if nargin >= 3 && ~isempty(outpath)
    if ~exist(outpath,'dir'), mkdir(outpath); end
    exportgraphics(fig, fullfile(outpath, 'poster_summary.png'), 'Resolution', 300);
end
end

function set_integer_xticks(ax, idx_last)
% Force integer ticks; sub-sample if long
if idx_last <= 12
    xticks(ax, 1:idx_last);
else
    step = max(1, round(idx_last/6));
    ticks = unique([1:step:idx_last, idx_last]);
    xticks(ax, ticks);
end
xlim(ax, [1 idx_last]);
end