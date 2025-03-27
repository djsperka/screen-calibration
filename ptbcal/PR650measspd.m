function [spd, qual] = PR650measspd(S,syncMode)
% [spd,qual] = PR650measspd(S,[syncMode])
%   This function, along with CMClose and PR650measspd, should
%   be put in the matlab path BEFORE the same functions in PTB. When  you
%   run the calibration function CalibrateMonSpd, these functions will
%   replace the PTB versions and use my pr650 code instead of the
%   not-working-well PTB code.
    [spd,qual] = old650measspd(S,syncMode);
end
