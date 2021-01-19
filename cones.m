% all the vsg constants
global CRS;

% init vsg and draw gray screen
ret = vsgInit;
if ret ~= 0
    error('vsgInit failed. Make sure vsg is available.');
end
crsSetVideoMode(CRS.TRUECOLOURMODE + CRS.GAMMACORRECT);
crsSetPen1([127 127 127]);
crsSetDrawPage(1);
crsDrawRect([0 0], [crsGetScreenWidth() crsGetScreenHeight()]);
crsSetZoneDisplayPage(CRS.VIDEOPAGE, 1);

% init spectrometer. COM port will need to be an input parameter - it seems
% to change. 
ret = PR670init('COM9');
if ~contains(ret, 'REMOTE MODE')
    error('PR670init failed. Check com port.');
end

% red screen
crsSetPen1([255 0 0]);
crsDrawRect([0 0], [crsGetScreenWidth() crsGetScreenHeight()]);

% measure SPD for this screen
[spdRed qRed] = PR670measspd([380 5 81], 'on');

% blue screen
crsSetPen1([0 255 0]);
crsDrawRect([0 0], [crsGetScreenWidth() crsGetScreenHeight()]);

% measure SPD for this screen
[spdBlue qBlue] = PR670measspd([380 5 81], 'on');

% green screen
crsSetPen1([0 0 255]);
crsDrawRect([0 0], [crsGetScreenWidth() crsGetScreenHeight()]);

% measure SPD for this screen
[spdGreen qGreen] = PR670measspd([380 5 81], 'on');

% now do fancy calculations.....
