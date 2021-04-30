function cal = CalibrateVSGDrvr(whichMeterType)
% cal = CalibrateMonDrvr(cal,USERPROMPT,whichMeterType,blankOtherScreen)
% Must initialize spectrometer prior to calling, e.g. PR670init or
% whatever.

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
