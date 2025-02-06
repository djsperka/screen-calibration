% Load calibration matrix file
cal=LoadCalFile('alyssa-2023-08-07.mat', 1, '/home/dan/work/screen-calibration/vsg');

% Load standard cones
load T_cones_ss2
load T_ss2000_Y2
S_cones = S_cones_ss2;
T_cones = T_cones_ss2;

% Fetch vectors
[lcv, mcv, scv] = computeConeIsoCV(cal, T_cones, S_cones, [.5,.5,.5]');

% print 
fprintf('l-cone: (%.3f, %.3f, %.3f) - (%.3f, %.3f, %.3f)\n', lcv);
fprintf('m-cone: (%.3f, %.3f, %.3f) - (%.3f, %.3f, %.3f)\n', mcv);
fprintf('s-cone: (%.3f, %.3f, %.3f) - (%.3f, %.3f, %.3f)\n', scv);