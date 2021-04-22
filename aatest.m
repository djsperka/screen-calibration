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