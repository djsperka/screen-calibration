function [cal] = initVSGCalStruct()
%initVSGCalStruct Initialize an empty calibration struct for PTB3
%   There appears to be no documentation which describes how to
%   create one of these.


cal = LoadCalFile('PTB3TestCal');
cal.describe.leaveRoomTime = 10;    % seconds? 
cal.describe.nAverage = 2;
cal.describe.nMeas = 8;
cal.describe.boxsize = 400;
cal.describe.S = [380 4 81];
cal.describe.whichScreen = 0;   % vsg ignore this
cal.describe.dacsize = 14;      % for visage
cal.describe.meterDistance = input('photometer distance (m): ');
cal.describe.caltype = 'monitor';
cal.describe.computer = input('Rig: ', 's');
cal.describe.monitor = input('Monitor: ', 's');
cal.describe.driver = input('VSG s/n', 's');
cal.describe.hz = input('Refresh rate (Hz): ');
cal.describe.who = 'whoever';
cal.describe.date = datetime();
cal.describe.program = 'tbd';
cal.describe.comment = 'no comment';
cal.describe.gamma.fitType = 'crtGamma';
cal.describe.gamma.contrastThresh = 1.0000e-03;
cal.describe.gamma.fitBreakThresh = 0.0200;

cal.nDevices = 3;       % R, G, B guns
cal.nPrimaryBases = 1;  % no idea, this is in all cal files it seems
cal.manual.use = 0;
cal.bgColor = [0.7451, 0.7451, 0.7451];
cal.rawdata = [];
cal.S_device = [];
cal.P_device = [];
cal.T_device = [];
cal.gammaInput = [];
cal.gammaFormat = 0;
cal.P_ambient = [];
cal.T_ambient = [];
cal.S_ambient = [];
end

