function cal = CalibrateVSGAmbDrvr(cal,whichMeterType)
% cal =  CalibrateVSGAmbDrvr(cal, whichMeterType)
%
% This script does the work for monitor ambient calibration.

% 4/4/94		dhb		Wrote it.
% 8/5/94		dhb, ccc	More flexible interface.
% 9/4/94		dhb		Small changes.
% 10/20/94	dhb		Add bgColor variable.
% 12/9/94   ccc   Nine-bit modification
% 1/23/95		dhb		Pulled out working code to be called from elsewhere.
%						dhb		Make user prompting optional.
% 1/24/95		dhb		Get filename right.
% 12/17/96  dhb, jmk  Remove big bug.  Ambient wasn't getting set.
% 4/12/97   dhb   Update for new toolbox.
% 8/21/97		dhb		Don't save files here.
%									Always measure.
% 4/7/99    dhb   NINEBIT -> NBITS
%           dhb   Handle noMeterAvail, RADIUS switches.
% 9/22/99   dhb, mdr  Make boxRect depend on boxSize, defined up one level.
% 12/2/99   dhb   Put background on after white box for aiming.
% 8/14/00   dhb   Call to CMETER('Frequency') only for OS9.
% 8/20/00   dhb   Remove bits arg to SetColor.
% 8/21/00   dhb   Remove RADIUS arg to MeasMonSpd.
% 9/11/00   dhb   Remove syncMode code, any direct refs to CMETER.
% 9/14/00   dhb   Use OpenWindow to open.
%           dhb   Made it a function.
% 7/9/02    dhb   Get rid of OpenWindow, CloseWindow.
% 9/23/02   dhb, jmh  Force background to zero when measurements come on.
% 2/26/03   dhb   Tidy comments.
% 4/1/03    dhb   Fix ambient averaging.
% 8/19/12   dhb   Add codelet suggested by David Jones to clean up at end.  See comment in CalibrateMonSpd.
% 8/19/12   mk    Rewrite setup and clut code to be able to better cope with all
%                 the broken operating systems / drivers / gpus and to also
%                 support DataPixx/ViewPixx devices.

% init vsg
fprintf('Initializing VSG, turn off gamma correction...\n');
global CRS;
if ~isstruct(CRS)
  crsLoadConstants;
end
vsgInit;
crsSetVideoMode(CRS.EIGHTBITPALETTEMODE + CRS.NOGAMMACORRECT);

% draw box on vsg screen
calDispPatch(0, 0);
calDispPatch([.5,.5,.5]);

% Wait for user
input('Focus radiometer on box and hit Enter when ready...', 's');
%KbStrokeWait(-1); requires Screen(). 
fprintf('Pausing for %d seconds ...', cal.describe.leaveRoomTime);
WaitSecs(cal.describe.leaveRoomTime);
fprintf(' done\n');

% Start timing
t0 = clock;

ambient = zeros(cal.describe.S(3), 1);
for a = 1:cal.describe.nAverage
    % Measure ambient
    ambient = ambient + MeasVSGSpd([0 0 0]', cal.describe.S, 'on', whichMeterType);
end
ambient = ambient / cal.describe.nAverage;

% Report time:
t1 = clock;
fprintf('CalibrateAmbDrvr measurements took %g minutes\n', etime(t1,t0)/60);

% Update structure
Smon = cal.describe.S;
Tmon = WlsToT(Smon);
cal.P_ambient = ambient;
cal.T_ambient = Tmon;
cal.S_ambient = Smon;

% Done:
return;
