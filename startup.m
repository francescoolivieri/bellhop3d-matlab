function startup()
    fprintf('🌊 Initializing bellhop3D-matlab Project...\n');
    addpath('lib');  
    addpath(genpath('lib'));
    addpath('examples');
    addpath(genpath('examples'));
    addpath('data');    

    if exist('bellhop3d', 'file') ~= 2
        fprintf('⚠️ BELLHOP not found! Install from: https://patel999jay.github.io/post/bellhop-acoustic-toolbox/\n');
    end
    
    global units; units = 'km';
    fprintf('✅ Project paths loaded successfully!\n');
end
