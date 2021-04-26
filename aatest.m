function [M, cones, Y] = aatest(B, myS)
    load T_cones_ss2
	load T_ss2000_Y2
	S_cones = S_cones_ss2;
	T_cones = T_cones_ss2;
	T_Y = 683*T_ss2000_Y2;
	S_Y = S_ss2000_Y2;
	T_Y = SplineCmf(S_Y,T_Y,myS);
    T_cones = SplineCmf(S_cones, T_cones, myS);

    M = T_cones * B;  % this is 3x3
    cones = T_cones;
    Y = T_Y;
    
    
    %% Basic transformation matrices.  ComputeDKL_M() does the work.
    %
    % Get matrix that transforms between incremental
    % cone coordinates and DKL coordinates 
    % (Lum, RG, S).
    [M_ConeIncToDKL,LMLumWeights] = ComputeDKL_M(bgLMS,T_cones,T_Y);
    M_DKLToConeInc = inv(M_ConeIncToDKL);

    %% Find incremental cone directions corresponding to DKL isoluminant directions.
    rgConeInc = M_DKLToConeInc*[0 1 0]';
    sConeInc = M_DKLToConeInc*[0 0 1]';

