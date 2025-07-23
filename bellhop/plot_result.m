function plot_result(data,s)

idx=find(isfinite(data.r),1,'last');


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

% Create vectors for z and r
z_values = 0:s.d_z:50;
r_values = 0:s.d_r:1000;

% Generate grid points
[Z, R] = meshgrid(z_values, r_values);

% Combine into a matrix where each row is a grid point (z, r)
pos = [R(:), Z(:)];

% % Calculate covariance of predictions
% [~, Sigma_tltl, ~] =unscented_transform(@(th)forward_model(th, pos), data.th_est(:,idx), squeeze(data.Sigma_est(:,:,idx)));
% var_tl=diag(Sigma_tltl);


Np=40;
Y=zeros(size(pos,1),Np);
parfor pp=1:Np
th=data.th_est(:,idx)+chol(squeeze(data.Sigma_est(:,:,idx)),'lower')*randn(size(data.th_est(:,idx)));  
Y(:,pp)=forward_model(th, pos);
end
var_tl=var(Y,[],2);

% Reshape var_tl into the same grid size as Z and R
var_tl_grid = reshape(var_tl, size(R));

% Create the pcolor plot
figure(5);
pcolor(R, Z, sqrt(var_tl_grid)); % Z on the x-axis, R on the y-axis
shading interp; % Interpolated shading for smooth visualization
cb=colorbar; % Add colorbar for reference
set( gca, 'YDir', 'Reverse' )
ylabel('Depth (m)')
xlabel('Range (m)')
title('Standard deviation of predicted loss');
colormap jet; % Use jet colormap for better visibility
caxis([0 10])
cb.Label.String = 'Std (dB)';


figure(100)
clf
plot(data.r,data.z,'bs','MarkerSize',8,'MarkerFaceColor','b','MarkerEdgeColor','b')
hold on
plot(data.r(idx),data.z(idx),'bs','MarkerSize',8,'MarkerFaceColor','b','MarkerEdgeColor','r')
axis([s.r_min s.r_max s.z_min s.z_max])
set( gca, 'YDir', 'Reverse' )
ylabel('Depth (m)')
xlabel('Range (m)')
grid minor;
title('Measurement points')
pause(0.1)
end