function startup()
    fprintf('🌊 Initializing UnderwaterModeling3D Project...\n');
    addpath(genpath('src'));
    addpath('scenarios');
    addpath('examples'); 
    addpath('tests');
    addpath('config');
    
    if exist('bellhop3d', 'file') ~= 2
        fprintf('⚠️ BELLHOP not found! Install from: https://patel999jay.github.io/post/bellhop-acoustic-toolbox/\n');
    end
    
    global units; units = 'km';
    fprintf('✅ Project paths loaded successfully!\n');
    fprintf('Run: mission_main or demo_gp_sound_speed_profile\n');
end
