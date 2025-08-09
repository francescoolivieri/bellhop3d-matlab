classdef Visualization
    % VISUALIZATION  Internal helper functions for plotting environment and TL.

    methods (Static)
        function drawEnvironment(s, scene)
            global extra_output
            if extra_output
                figure; title('SSP','FontSize',10);
                if s.sim_use_ssp_file
                    plotssp3d(s.bellhop_file_name + ".ssp");
                else
                    plotssp(s.bellhop_file_name + ".env");
                end
            end
            bellhop3d(s.bellhop_file_name);
            figure; title('Transmission loss','FontSize',10);
            plotshd(char(s.bellhop_file_name + '.shd'));
        end
    end
end
