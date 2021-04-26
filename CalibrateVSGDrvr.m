function cal = CalibrateVSGDrvr(whichMeterType)
% cal = CalibrateMonDrvr(cal,USERPROMPT,whichMeterType,blankOtherScreen)
%

cal = initVSGCalStruct();

% Measurement parameters
monWls = SToWls(cal.describe.S); %#ok<*NASGU>

% Define input settings for the measurements
mGammaInputRaw = linspace(0, 1, cal.describe.nMeas+1)';
mGammaInputRaw = mGammaInputRaw(2:end);

% Make manual measurements here if desired.  This needs to come first.
if cal.manual.use
    error('not implemented\n');
    %CalibrateManualDrvr;
end

% User prompt
fprintf('Focus radiometer on the displayed box.\n');
fprintf('Once meter is set up, hit any key - you will get %g seconds\n',...
         cal.describe.leaveRoomTime);
fprintf('to leave room.\n');

% init vsg
global CRS;
if ~isstruct(CRS)
  crsLoadConstants;
end
vsgInit;

% draw box on vsg screen
calDispPatch(0, 0);
calDispPatch([.5,.5,.5]);

% Wait for user
fprintf('Set up radiometer and hit any key when ready\n');
KbStrokeWait(-1);
fprintf('Pausing for %d seconds ...', cal.describe.leaveRoomTime);
WaitSecs(cal.describe.leaveRoomTime);
fprintf(' done\n');



% 
% 
% % Setup screen to be measured
% % ---------------------------
% 
% % Prepare imaging pipeline for Bits+ Bits++ CLUT mode, or DataPixx/ViewPixx
% % L48 CLUT mode (which is pretty much the same). If such a special output
% % device is used, the Screen('LoadNormalizedGammatable', win, clut, 2);
% % command uploads 'clut's into the device at next Screen('Flip'), taking
% % care of possible graphics driver bugs and other quirks:
% PsychImaging('PrepareConfiguration');
% 
% if g_usebitspp == 1
%     % Setup for Bits++ CLUT mode. This will automatically load proper
%     % identity gamma tables into the graphics hardware and into the Bits+:
%     PsychImaging('AddTask', 'General', 'EnableBits++Bits++Output');
% end
% 
% if g_usebitspp == 2
%     % Setup for DataPixx/ViewPixx etc. L48 CLUT mode. This will
%     % automatically load proper identity gamma tables into the graphics
%     % hardware and into the device:
%     PsychImaging('AddTask', 'General', 'EnableDataPixxL48Output');
% end
% 
% % Open the window:
% [window, screenRect] = PsychImaging('OpenWindow', cal.describe.whichScreen);
% if (cal.describe.whichScreen == 0)
%     HideCursor;
% end
% 
% theClut = zeros(256,3);
% if g_usebitspp
%     % Load zero theClut into device:
%     Screen('LoadNormalizedGammaTable', window, theClut, 2);
%     Screen('Flip', window);    
% else
%     % Load zero lut into regular graphics card:
%     Screen('LoadNormalizedGammaTable', window, theClut);
% end
% 
% % Draw a box in the center of the screen
% if ~isfield(cal.describe, 'boxRect')
% 	boxRect = [0 0 cal.describe.boxSize cal.describe.boxSize];
% 	boxRect = CenterRect(boxRect,screenRect);
% else
% 	boxRect = cal.describe.boxRect;
% end
% theClut(2,:) = [1 1 1];
% Screen('FillRect', window, 1, boxRect);
% if g_usebitspp
%     Screen('LoadNormalizedGammaTable', window, theClut, 2);
%     Screen('Flip', window, 0, 1);
% else
%     Screen('LoadNormalizedGammaTable', window, theClut);
% end
% 
% % Wait for user
% if USERPROMPT == 1
%     fprintf('Set up radiometer and hit any key when ready\n');
%     KbStrokeWait(-1);
%     fprintf('Pausing for %d seconds ...', cal.describe.leaveRoomTime);
%     WaitSecs(cal.describe.leaveRoomTime);
%     fprintf(' done\n');
% end
% 
% % Put correct surround for measurements.
% theClut(1,:) = cal.bgColor';
% if g_usebitspp
%     Screen('FillRect', window, 1, boxRect);
%     Screen('LoadNormalizedGammaTable', window, theClut, 2);
%     Screen('Flip', window, 0, 1);
% else
%     Screen('LoadNormalizedGammaTable', window, theClut);
% end
% 
% Start timing
t0 = clock;

mon = zeros(cal.describe.S(3)*cal.describe.nMeas,cal.nDevices);
for a = 1:cal.describe.nAverage
    for i = 1:cal.nDevices
        disp(sprintf('Monitor device %g',i)); %#ok<*DSPS>

        % Measure ambient
        darkAmbient1 = MeasVSGSpd([0 0 0]', cal.describe.S, 'on', whichMeterType);

        % Measure full gamma in random order
        mGammaInput = zeros(cal.nDevices, cal.describe.nMeas);
        mGammaInput(i,:) = mGammaInputRaw';
        sortVals = rand(cal.describe.nMeas,1);
        [null, sortIndex] = sort(sortVals); %#ok<*ASGLU>
        %fprintf(1,'MeasMonSpd run %g, device %g\n',a,i);
        [tempMon, cal.describe.S] = MeasVSGSpd(mGammaInput(:,sortIndex), ...
            cal.describe.S, 'on', whichMeterType);
        tempMon(:, sortIndex) = tempMon;

        % Take another ambient reading and average
        darkAmbient2 = MeasVSGSpd([0 0 0]', cal.describe.S, 'on', whichMeterType);
        darkAmbient = ((darkAmbient1+darkAmbient2)/2)*ones(1, cal.describe.nMeas);

        % Subtract ambient
        tempMon = tempMon - darkAmbient;

        % Store data
        mon(:, i) = mon(:, i) + reshape(tempMon,cal.describe.S(3)*cal.describe.nMeas,1);
    end
end
mon = mon / cal.describe.nAverage;

% Report time
t1 = clock;
fprintf('CalibrateMonDrvr measurements took %g minutes\n', etime(t1, t0)/60);

% Pre-process data to get rid of negative values.
mon = EnforcePos(mon);
cal.rawdata.mon = mon;

% Use data to compute best spectra according to desired
% linear model.  We use SVD to find the best linear model,
% then scale to best approximate maximum
disp('Computing linear models');
cal = CalibrateFitLinMod(cal);

% Fit gamma functions.
cal.rawdata.rawGammaInput = mGammaInputRaw;
cal = CalibrateFitGamma(cal, 2^cal.describe.dacsize);

return;
