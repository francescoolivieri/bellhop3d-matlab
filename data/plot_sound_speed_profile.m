function plot_sound_speed_profile(filename)
    % Load the .mat file containing CTD data
    data = load(filename);

    sound_speed=data.CTD(:,2);
    depth=data.CTD(:,1);
    
    
    % Plot sound speed profile
    % figure;
    % plot(sound_speed, depth, 'b-','LineWidth',1.5);
    % set(gca, 'YDir','reverse'); % Depth increases downward
    % xlabel('Sound Speed (m/s)');
    % ylabel('Depth (m)');
    % title('Sound Speed Profile');
    % grid on;
end