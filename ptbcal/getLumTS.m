function [S,T] = getLumTS()

    S = [380, 4, 101]; % spectra returned from pr650
    load T_ss2000_Y2;
    T = SplineCmf(S_ss2000_Y2, 683*T_ss2000_Y2, S);
    clear S_ss2000_Y2;
    clear T_ss2000_Y2;
end