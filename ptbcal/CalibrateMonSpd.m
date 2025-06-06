% CalibrateMonSpd
%
% Calling script for monitor calibration.  Assumes
% you have CMCheckInit/MeasSpd functions that initialize
% measurement hardware and return a measured spectral
% power distribution respectively.
%
% NOTE 30-June-2023: I tried to fix some of this mess, to make the functions
% more compatible with the way current operating systems, graphics cards and
% display devices work. Specifically the massive changes in how hardware gamma
% tables work on modern gpu's. I also added support for more Photo Research
% colormeters. This seems to work ok with the simulated meterType 0, but I don't
% have actual measurement hardware to verify if things work as expected. I guess
% it is less broken now, and maybe even working fine, but who knows?
%
% NOTE (dhb, 8/19/12).  This code is a bit dusty, as it is not
% being actively maintained.  In particular, the PTB display 
% control has evolved since this was last looked at carefully.
% In general, you want to calibrate through the same set of 
% display calls you'll use in your experiment.  Below is some
% prose written by Mario Kleiner that describes how the PTB
% currently wants you to control and restore your clut.  In
% an ideal world, this routine would be updated to match.  But
% more generally, if you use this code you may want to modify
% to make sure it is displaying colors the same way you will in
% your experiments.  The actual work is done in CalibrateMonDrvr
% and CalibrateAmbDrvr so that is where you would look.
%
%     We have two functions for this. LoadIdentityClut() for loading an
%     identity clut and configuring the GPU for identity pixel passthrough,
%     and RestoreCluts, which restores to the state before
%     LoadIdentityClut(). I think "sca" calls that, as well as showing the
%     cursor and other cleanup actions.
% 
%     LoadIdentityClut is also automatically called by PsychImaging etc. if
%     the image processing pipeline is used for
%     Bits++/Datapixx/Viewpixx,video attenuators etc.
% 
%     It is important to always use LoadIdentityClut() instead of self-made
%     code. Many (most?) graphics cards on most operating systems have
%     graphics driver bugs and hardware quirks which cause the self-made
%     identity clut to actually not turn out to be an identity clut in the
%     hardware. LoadIdentityClut() has heuristics to detect os/gpu combo
%     and select an appropriately fudged lut to actually get an identity
%     mapping. In case of new hardware with new quirks we should update
%     that files detection logic to cope. Additionally there is
%     SaveIdentityClut() to save a known good lut for automatic use with
%     LoadIdentityClut, overriding its choice. And there is
%     BitsPlusIdentityClutTest to test a Bits+ or Datapixx device
%     thoroughly for problems and aid in fixing them. It is easy to get
%     fooled into thinking you got it right, even when using a photometer,
%     because some of the problems are subtle and not detectable without
%     use of dynamic test patterns like in BitsPlusIdentityClutTest with
%     Mono++ mode, or special debug functionality as in the
%     DataPixx/ViewPixx devices.
% 
%     I use a DataPixx to test such stuff and PTB has builtin diagnostic to
%     utilize that hardware to make sure that the video signal is really
%     untampered.
% 
%     LoadIdentityClut also calls special functions in Screen that try to
%     workaround or fix other hardware interference. E.g., in addition to
%     cluts messing with pixel passthrough, there is also display dithering
%     on any digital video output, and some new pre- and post-gamma
%     corrections in latest generation hardware -- Screen can fix this for
%     some cards on some operating systems, but only when used through
%     LoadIdentityClut.
% 
%     E.g., almost all AMD cards will cause trouble on OSX when the
%     PsychtoolboxKernelDriver and LoadIdentityClut etc. is not used,
%     almost all NVidia cards on OSX will cause trouble unless you use some
%     special NVidia kernel driver which is somewhere referenced on the
%     Bits+ pages on our wiki. We have/need similar hacks on Windows, e.g.,
%     PsychGPUControl() for AMD cards. On Linux either PTB's low-level
%     fixes apply or they are not neccessary.
% 
%     So the CalibrateMonSpd etc. should be fixed to use
%     LoadIdentityClut/RestoreCluts, everything else is just begging for
%     trouble.
%
% 7/7/98  dhb  Wrote from generic.
%         dhb  dacsize/driver filled in by hand, Screen fails to return it.
% 4/7/99  dhb  NINEBIT -> NBITS.
%         dhb  Wrote version for Radius 10 bit cards.
% 4/23/99 dhb  Change wavelength sampling to 380 4 101, PR-650 native.
% 9/22/99 dhb, mdr  Define boxSize.
% 8/11/00 dhb  Save mon in rawdata.
% 8/18/00 dhb  More descriptive information saved.
% 8/20/00 dhb  Automatic check for RADIUS and number of DAC bits.
% 9/10/00 pbe  Added option to blank another screen while measuring. 
% 2/27/02 dhb  Various small fixes, including Radeon support.
%         dhb  Change noMeterAvail to whichMeterType.
% 11/08/06 cgb, dhb  OS/X.
% 9/27/08 dhb  Default primary bases is 1 now.  Use RefitCalLinMod to change later if desired.
% 8/19/12 mk   Ask user for choice of display output device.
% 6/30/23 mk   Use new clut mapping to fix this mess on standard gpus. Also allow
%              choice of different supported colormeters, not just PR-650.
% 8/31/23 mk   Assign cal.describe.dacsize also if g_usebitspp is already set.

global g_usebitspp;

% Unified key mapping, no unit color range by default:
PsychDefaultSetup(1);

% Create calibration structure;
cal = [];

% Script parameters
whichScreen = max(Screen('Screens'));

% Type of colormeter to use for measurement of the spectra. See most up to date
% list in 'help CMCheckInit', but as of June 2023, there is a range of Photo Research
% devices:
% 0 = Simulated (Default), 1 = PR650, 4 = PR655, 5 = PR670, 6 = PR705

fprintf('\nThis is a modified version of the PTB calibration script CalibrateMonSpd.\nIt is hard-coded to use a PR-650 spectrometer.\n\n');
whichMeterType = 1;

cal.describe.leaveRoomTime = 10;
cal.describe.nAverage = 2;  
cal.describe.nMeas = 30;
cal.describe.boxSize = 400;
cal.nDevices = 3;
cal.nPrimaryBases = 1;
switch whichMeterType
    case {0,1}
        cal.describe.S = [380 4 101];
    case 2
        cal.describe.S = [380 1 401];
    otherwise
        cal.describe.S = [380 4 101]; % Or should it be [380 5 81]?
end
cal.manual.use = 0;

% Enter screen
defaultScreen = whichScreen;
whichScreen = input(sprintf('Which screen to calibrate [%g]: ', defaultScreen));
if isempty(whichScreen)
    whichScreen = defaultScreen;
end
cal.describe.whichScreen = whichScreen;

% If the global flag for using Bits++ is empty, then it hasn't been
% initialized and we ask user what to use:
if isempty(g_usebitspp)
    g_usebitspp = input('Which high-res display device? [0=None, 1=CRS Bits++/Bits#/..., 2=VPixx DataPixx/ViewPixx/ProPixx/...]');
end

switch(g_usebitspp)
    case 0
        fprintf('Using standard graphics card with 8 bpc framebuffer.\n');
        % We want dacsize to be so that 2^dacsize gives the size of the gamma
        % lut of the display device, iow. a gamma correction table is produced
        % as output, which can be loaded into the display devices hardware lut.
        % For a standard display connected to a standard gpu, the relevant gamma
        % hardware lut is the one of the gpu, with 'reallutsize' slots of size,
        % so query reallutsize from system and choose dacsize accordingly:
        [~, ~, reallutsize] = Screen('ReadNormalizedGammaTable', whichScreen);
        cal.describe.dacsize = log2(reallutsize);
    case 1
        fprintf('Using CRS Bits++/Bits# et al. device in Bits+ CLUT mode.\n');
        % For 2^8 = 256 slots builtin hw lut of CRS devices:
        cal.describe.dacsize = 8;
    case 2
        fprintf('Using VPixx DataPixx/ViewPixx et al. in L48 CLUT mode.\n');
        % For 2^8 = 256 slots builtin hw lut of VPixx devices:
        cal.describe.dacsize = 8;
    otherwise
        error('Unsupported display device. Aborted.');
end

% Blank screen
defaultBlankOtherScreen = 0;
blankOtherScreen = input(sprintf('Do you want to blank another screen? (1 for yes, 0 for no) [%g]: ', defaultBlankOtherScreen));
if isempty(blankOtherScreen)
    blankOtherScreen = defaultBlankOtherScreen;
end
if blankOtherScreen
    defaultBlankScreen = 2;
    whichBlankScreen = input(sprintf('Which screen to blank [%g]: ', defaultBlankScreen));
    if isempty(whichBlankScreen)
        whichBlankScreen = defaultBlankScreen;
    end
    cal.describe.whichBlankScreen = whichBlankScreen;
end

% Prompt for background values.  The default is a guess as to what
% produces one-half of maximum output for a typical CRT.
defBgColor = [190 190 190]'/255;
thePrompt = sprintf('Enter RGB values for background (range 0-1) as a row vector [%0.3f %0.3f %0.3f]: ',...
                    defBgColor(1), defBgColor(2), defBgColor(3));
while 1
    cal.bgColor = input(thePrompt)';
    if isempty(cal.bgColor)
        cal.bgColor = defBgColor;
    end
    [m, n] = size(cal.bgColor);
    if m ~= 3 || n ~= 1
        fprintf('\nMust enter values as a row vector (in brackets).  Try again.\n');
    elseif (any(defBgColor > 1) || any(defBgColor < 0))
        fprintf('\nValues must be in range (0-1) inclusive.  Try again.\n');
    else
        break;
    end
end

% Get distance from meter to screen.
defDistance = .80;
theDataPrompt = sprintf('Enter distance from meter to screen (in meters): [%g]: ', defDistance);
cal.describe.meterDistance = input(theDataPrompt);
if isempty(cal.describe.meterDistance)
  cal.describe.meterDistance = defDistance;
end

% Fill in descriptive information
computerInfo = Screen('Computer');
hz = Screen('NominalFrameRate', cal.describe.whichScreen);
cal.describe.caltype = 'monitor';
if isfield(computerInfo, 'consoleUserName')
    cal.describe.computer = sprintf('%s''s %s, %s', computerInfo.consoleUserName, computerInfo.machineName, computerInfo.system);
else
    % Better than nothing:
    cal.describe.computer = OSName;
end
cal.describe.monitor = input('Enter monitor name: ','s');
cal.describe.driver = sprintf('%s %s','unknown_driver','unknown_driver_version');
cal.describe.hz = hz;
cal.describe.who = input('Enter your name: ','s');
cal.describe.date = sprintf('%s %s',date,datestr(now,14));
cal.describe.program = sprintf('CalibrateMonSpd, background set to [%g,%g,%g]',...
                               cal.bgColor(1), cal.bgColor(2), cal.bgColor(3));
cal.describe.comment = input('Describe the calibration: ','s');
portString = input('Enter serial port string for PR650: ', 's');

bHaveFolder=false;
while ~bHaveFolder
    dataRoot = input('Enter root folder for cal data: ', 's');
    if isfolder(dataRoot)
        [~, msg, ~] = fileattrib(dataRoot);
        if msg.UserWrite
            bHaveFolder = true;
        else
            fprintf('You do not have write permission in the folder %s\n', dataRoot);
        end
    end
end

% Get name
defaultFileName = 'monitor';
thePrompt = sprintf('Enter calibration filename [%s]: ',defaultFileName);
newFileName = input(thePrompt,'s');
if isempty(newFileName)
    newFileName = defaultFileName;
end

% sync mode
iSyncDefault = 0;
iSync = input(sprintf('Use spectrometer syncMode? (1 for yes, 0 for no) [%g]: ', iSyncDefault));
if isempty(iSync)
    iSync = iSyncDefault;
end
if iSync
    syncMode = 'on';
else
    syncMode = 'off';
end

% Fitting parameters
cal.describe.gamma.fitType = 'crtPolyLinear';
cal.describe.gamma.contrastThresh = 0.001;
cal.describe.gamma.fitBreakThresh = 0.02;

% Initialize
switch whichMeterType
    case 0
        % Simulated only.
    case 2
        CVIOpen;
    otherwise
        CMCheckInit(whichMeterType, portString);
end
ClockRandSeed;

% Calibrate monitor
USERPROMPT = 1;
cal = CalibrateMonDrvr(cal, USERPROMPT, whichMeterType, blankOtherScreen, syncMode);

% Calibrate ambient
USERPROMPT = 0;
cal = CalibrateAmbDrvr(cal, USERPROMPT, whichMeterType, blankOtherScreen, syncMode);

% Signal end 
Beeper; WaitSecs(.75);
Beeper; WaitSecs(.75);
Beeper; WaitSecs(.75);

% Save the structure
% DJS Use the folder given by user.
fprintf(1, '\nSaving to %s.mat\n', newFileName);
SaveCalFile(cal, newFileName, dataRoot);

% Put up a plot of the essential data
figure(1); clf;
plot(SToWls(cal.S_device), cal.P_device);
xlabel('Wavelength (nm)', 'Fontweight', 'bold');
ylabel('Power', 'Fontweight', 'bold');
title('Phosphor spectra', 'Fontsize', 13, 'Fontname', 'helvetica', 'Fontweight', 'bold');
axis([380, 780, -Inf, Inf]);

figure(2); clf;
plot(cal.rawdata.rawGammaInput, cal.rawdata.rawGammaTable, '+');
xlabel('Input value', 'Fontweight', 'bold');
ylabel('Normalized output', 'Fontweight', 'bold');
title('Gamma functions', 'Fontsize', 13, 'Fontname', 'helvetica', 'Fontweight', 'bold');
hold on
plot(cal.gammaInput, cal.gammaTable);
hold off
figure(gcf);
drawnow;

% Close down meter
switch whichMeterType
    case 0
        % Simulated needs no close.
    case 2
        CVIClose;
    otherwise
        CMClose(whichMeterType);
end
