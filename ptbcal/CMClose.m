function CMClose(meterType)
% CMClose([meterType])
%   This function, along with CMCheckInit and PR650measspd, should
%   be put in the matlab path BEFORE the same functions in PTB. When  you
%   run the calibration function CalibrateMonSpd, these functions will
%   replace the PTB versions and use my pr650 code instead of the
%   not-working-well PTB code.
%

if meterType==1
    old650close();
else
    warning('This is a modified version of CMClose, only use for meterType 1');
end
