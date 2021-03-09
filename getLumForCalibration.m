function [] = getLumForCalibration(comPort)
%GETLUMFORCALIBRATION Gets luminance measurement on each <Enter>, 'q' to
%quit.
%   Detailed explanation goes here

%% init spectrometer
% COM port will need to be an input parameter - it seems
% to change. 
ret = PR670init(comPort);
if ~contains(ret, 'REMOTE MODE')
    error('PR670init failed. Check com port.');
end

%% loop endlessly, until user enters a non-empty string
while (1)
    s = input('Enter m to meas luminance, q to quit', 's');
    if s == 'm'
        [spd, peak, lum, qual] = PR670meas();
        fprintf(1, 'peak\t%f\tlum\t%f\n', peak, lum);
    elseif s=='q'
        break
    end
end

%% Close PR670
PR670close()

end