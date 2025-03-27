function CMCheckInit(meterType,portString)
%CMCheckInit Replacement of PTB version for Usrey PR650.
%   This function, along with CMClose and PR650measspd, should
%   be put in the matlab path BEFORE the same functions in PTB. When  you
%   run the calibration function CalibrateMonSpd, these functions will
%   replace the PTB versions and use my pr650 code instead of the
%   not-working-well PTB code.

    if meterType == 1
        istatus = old650init(portString);
        if ~istatus
            error('Cannot connect to PR650 on port %s', portString);
        end
    end
    fprintf('PR650 on %s is ready.\n', portString);
end