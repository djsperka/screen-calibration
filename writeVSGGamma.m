function [clutValues] = writeVSGGamma(calfile)
% myCalDemo
%
% Demonstrates basic use of the PsychCal calibraiton structure and routines.
%
% See also PsychCal, DKLDemo, RenderDemo, DumpMonCalSpd
%
% 4/30/21   djs     updated for usrey lab
% 1/15/07	dhb		Wrote it.
% 9/27/08   dhb     Prompt for filename.  Clean up plot labels
%           dhb     Prompt for gamma method.
% 5/08/14   npc     Modifications for accessing calibration data using a @CalStruct object.
% 7/9/14    dhb     Made this work with PTB original or new object oriented
%                   calibration code (available in the BrainardLabToolbox on gitHub).

% Clear
% clear; close all

% Load
% Load a calibration file. You can make this with CalibrateMonSpd if
% you have a supported radiometer.
[ frompath, basename, ext] = fileparts(calfile);
fprintf(1,'\nLoading cal \"%s\" from folder %s\n', basename, frompath);
commandwindow;
cal = LoadCalFile(basename, [], frompath);
    
S               = cal.S_device;
P_device        = cal.P_device;
gammaInput      = cal.gammaInput;
rawGammaInput   = cal.rawdata.rawGammaInput;
gammaTable      = cal.gammaTable;
rawGammaTable   = cal.rawdata.rawGammaTable;
OBJStyle = false;
calStructOBJ = cal;

DescribeMonCal(calStructOBJ);


%% Gamma correction 
% Set inversion method.  See SetGammaMethod for information on available
% methods.
defaultGammaMethod = 0;
commandwindow;
gammaMethod = input(sprintf('Enter gamma method [%d]:',defaultGammaMethod));
if (isempty(gammaMethod))
    gammaMethod = defaultGammaMethod;
end
calStructOBJ = SetGammaMethod(calStructOBJ,gammaMethod);
             
% Make the desired linear output, then convert.
linearValues = ones(3,1)*linspace(0,1,16384);
clutValues = PrimaryToSettings(calStructOBJ,linearValues);
predValues = SettingsToPrimary(calStructOBJ,clutValues);

% Make a plot of the inverse lookup table.
figure; clf;
subplot(1,3,1); hold on
plot(linearValues,clutValues(1,:)','r');
axis([0 1 0 1]); axis('square');
xlabel('Linear output');
ylabel('Input value');
title('Inverse Gamma');
subplot(1,3,2); hold on
plot(linearValues,clutValues(2,:)','g');
axis([0 1 0 1]); axis('square');
xlabel('Linear output');
ylabel('Input value');
title('Inverse Gamma');
subplot(1,3,3); hold on
plot(linearValues,clutValues(3,:)','b');
axis([0 1 0 1]); axis('square');
xlabel('Linear output');
ylabel('Input value');
title('Inverse Gamma');

% Make a plot of the obtained linear values.
figure; clf;
subplot(1,3,1); hold on
plot(linearValues,predValues(1,:)','r');
axis([0 1 0 1]); axis('square');
xlabel('Desired value');
ylabel('Predicted value');
title('Gamma Correction');
subplot(1,3,2); hold on
plot(linearValues,predValues(2,:)','g');
axis([0 1 0 1]); axis('square');
xlabel('Desired value');
ylabel('Predicted value');
title('Gamma Correction');
subplot(1,3,3); hold on
plot(linearValues,predValues(3,:)','b');
axis([0 1 0 1]); axis('square');
xlabel('Desired value');
ylabel('Predicted value');
title('Gamma Correction');



%% load cones
load T_cones_ss2
load T_ss2000_Y2
S_cones = S_cones_ss2;
T_cones = T_cones_ss2;
T_Y = 683*T_ss2000_Y2;
S_Y = S_ss2000_Y2;
T_Y = SplineCmf(S_Y,T_Y,S_cones);



calLMS = SetSensorColorSpace(cal,T_cones,S_cones);
calLMS = SetGammaMethod(calLMS,1);
calLum = SetSensorColorSpace(cal,T_Y,S_Y);

%% Define background.  Here we just take the
% monitor mid-point.
bgLMS = PrimaryToSensor(calLMS,[0.5 0.5 0.5]');

%% Basic transformation matrices.  ComputeDKL_M() does the work.
%
% Get matrix that transforms between incremental
% cone coordinates and DKL coordinates 
% (Lum, RG, S).
[M_ConeIncToDKL,LMLumWeights] = ComputeDKL_M(bgLMS,T_cones,T_Y);
M_DKLToConeInc = inv(M_ConeIncToDKL);

%% Find incremental cone directions corresponding to DKL isoluminant directions.
rgConeInc = M_DKLToConeInc*[0 1 0]';
sConeInc = M_DKLToConeInc*[0 0 1]';

% These directions are not scaled in an interesting way,
% need to scale them.  Here we'll find units so that 
% a unit excursion in the two directions brings us to
% the edge of the monitor gamut, with a little headroom.
bgPrimary = SensorToPrimary(calLMS,bgLMS);
rgPrimaryInc = SensorToPrimary(calLMS,rgConeInc+bgLMS)-bgPrimary;
sPrimaryInc = SensorToPrimary(calLMS,sConeInc+bgLMS)-bgPrimary;
rgScale = MaximizeGamutContrast(rgPrimaryInc,bgPrimary);
sScale = MaximizeGamutContrast(sPrimaryInc,bgPrimary);
rgConeInc = 0.95*rgScale*rgConeInc;
sConeInc = 0.95*sScale*sConeInc;

% If we find the RGB values corresponding to unit excursions
% in rg and s directions, we should find a) that the luminance
% of each is the same and b) that they are all within gamut.
% In gamut means that the primary coordinates are all bounded
% within [0,1].
rgPlusLMS = bgLMS+rgConeInc;
rgMinusLMS = bgLMS-rgConeInc;
sPlusLMS = bgLMS+sConeInc;
sMinusLMS = bgLMS-sConeInc;
rgPlusPrimary = SensorToPrimary(calLMS,rgPlusLMS);
rgMinusPrimary = SensorToPrimary(calLMS,rgMinusLMS);
sPlusPrimary = SensorToPrimary(calLMS,sPlusLMS);
sMinusPrimary = SensorToPrimary(calLMS,sMinusLMS);
if (any([rgPlusPrimary(:) ; rgMinusPrimary(:) ; ...
		sPlusPrimary(:) ; sMinusPrimary(:)] < 0))
	fprintf('Something out of gamut low that shouldn''t be.\n');
end
if (any([rgPlusPrimary(:) ; rgMinusPrimary(:) ; ...
		sPlusPrimary(:) ; sMinusPrimary(:)] > 1))
	fprintf('Something out of gamut high that shouldn''t be.\n');
end
bgLum = PrimaryToSensor(calLum,bgPrimary);
rgPlusLum = PrimaryToSensor(calLum,rgPlusPrimary);
rgMinusLum = PrimaryToSensor(calLum,rgMinusPrimary);
sPlusLum = PrimaryToSensor(calLum,sPlusPrimary);
sMinusLum = PrimaryToSensor(calLum,sMinusPrimary);
lums = sort([bgLum rgPlusLum rgMinusLum sPlusLum sMinusLum]);
fprintf('Luminance range in isoluminant plane is %0.2f to %0.2f\n',...
	lums(1), lums(end));


%% dump to file
outfile = fullfile(frompath, basename+".vsg");
fid = fopen(outfile, "w");
fwrite(fid, bgPrimary, "double");
fwrite(fid, rgPlusPrimary, "double");
fwrite(fid, rgMinusPrimary, "double");
fwrite(fid, sPlusPrimary, "double");
fwrite(fid, sMinusPrimary, "double");
fwrite(fid, clutValues(1,:)', "double");
fwrite(fid, clutValues(2,:)', "double");
fwrite(fid, clutValues(3,:)', "double");
fclose(fid);
