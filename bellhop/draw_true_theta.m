function data=draw_true_theta(s)

% % Draw random parameter according to prior distribution
% data.th=s.mu_th+chol(s.Sigma_th,'lower')*randn(size(s.mu_th));


% Generate file for the true parameters
create_env_file(data.th, 'true_parameters.env')

% Plot SSP
figure(1)
clf
subplot(2,4,[1 5])
plotssp( 'ac_env_model.env' )
title('Sound speed','FontSize',10);
grid minor;

% Run bellhop to get the true transmission loss
bellhop3d('ac_env_model');

% % Plot rays
% figure(2)
% plotray3d('ludvig.ray')
% %title('3D Ray Traces','FontSize',12,'FontWeight','bold');
% grid on;

subplot(2,4,[2 3 4 6 7 8])
plotshd('ac_env_model.shd');
hold on;
plot(0,47,'d','MarkerSize',10,'MarkerFaceColor','r','MarkerEdgeColor','k');

title('Propagation loss','FontSize',10);
% title('Transmission Loss','FontSize',12,'FontWeight','bold')
% xlabel('Range (km)','FontSize',10);
% ylabel('Depth (m)','FontSize',10);
% colorbar;
% hold off;


end