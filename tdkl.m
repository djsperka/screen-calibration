function tdkl(altbkgd, calfile, bkgd)
% tdkl - find RGB color combinations in an isoluminant plane defined by an
% input color. 
%
% Computes DKL conversion matrix using the background color 'bkgd' (1x3) 
% and calibration file arguments. 
% Using that matrix, creates a figure of the isoluminant 
% plane defined by the color 'altbkgd'. User may select points on the
% figure (click on the figure, then hit Enter), and the corresponding RGB
% is printed. To end, hit Enter without clicking on a point in the figure.
%

%% Define parameters.  Image size should be an odd number.
imageSize = 513;
whichCones = 'StockmanSharpe';

% load files of constants
load T_cones_ss2
load T_ss2000_Y2
S_cones = S_cones_ss2;
T_cones = T_cones_ss2;
T_Y = 683*T_ss2000_Y2;
S_Y = S_ss2000_Y2;
T_Y = SplineCmf(S_Y,T_Y,S_cones);



%% Load calibration file, then set up conversions for LMS, Lum 
% The cone sensitivities are defined in T_cones and S_cones. 
% The luminance function T_Y and S_Y goes into the luminance conversions. 

[ path, name, ext] = fileparts(calfile);
fprintf(1,'\nLoading cal \"%s\" from folder %s\n', name, path);
commandwindow;
cal = LoadCalFile(name, [], path);

calLMS = SetSensorColorSpace(cal,T_cones,S_cones);
calLMS = SetGammaMethod(calLMS,1);
calLum = SetSensorColorSpace(cal,T_Y,S_Y);

%% Background input is RGB, here convert to LMS. 
% In ptb, 'Primary' refers to RGB, the primary colors used by the monitor. 
% The 'Sensor' coordinates are
% what the calibration object has been set to use (see SetSensorColorSpace
% call above). 
bgLMS = PrimaryToSensor(calLMS, bkgd');

%% Basic transformation matrices.  ComputeDKL_M() does the work.
%
% Get matrix that transforms between incremental
% cone coordinates and DKL coordinates 
% (Lum, RG, S).
%
% DJS: "incremental cone coordinates" - Think "incremental"  as the
% change (inc or decrement) relative to the bkgd point. To get inc cone
% coords, get LMS, and subtract bgLMS.

[M_ConeIncToDKL,LMLumWeights] = ComputeDKL_M(bgLMS,T_cones,T_Y);
M_DKLToConeInc = inv(M_ConeIncToDKL);

%% Find incremental cone directions corresponding to DKL isoluminant directions.
rgConeInc = M_DKLToConeInc*[0 1 0]';
sConeInc = M_DKLToConeInc*[0 0 1]';

% These directions are not scaled in an interesting way,
% need to scale them.  Here we'll find units so that 
% a unit excursion in the two directions brings us to
% the edge of the monitor gamut, with a little headroom.

% DJS here is where I modify the demo script to make an isoluminant plane
% at the luminance of an arbitrary color.
% This block replaces the commented block below. Goal is to make rgConeInc
% and sConeInc, which will maximize the available gamut at the given
% luminance. Only change here is to set bgLMS to be the alternate/target
% color instead of the given background for the DKL space. 

bgLMS = PrimaryToSensor(calLMS, altbkgd');

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

fprintf('target color %f %f %f lum %f\n', bgPrimary(1), bgPrimary(2), bgPrimary(2), PrimaryToSensor(calLum, bgPrimary));
fprintf('rgConeInc %f %f %f\n', rgConeInc(1), rgConeInc(2), rgConeInc(3));
fprintf('sConeInc %f %f %f\n', sConeInc(1), sConeInc(2), sConeInc(3));






%% Make a picture
%
% Now we have the coordinates we desire, make a picture of the
% isoluminant plane.
[X,Y] = meshgrid(0:imageSize-1,0:imageSize-1);
X = X-(imageSize-1)/2; Y = Y-(imageSize-1)/2;
X = X/max(abs(X(:))); Y = Y/max(abs(Y(:)));
XVec = reshape(X,1,imageSize^2); YVec = reshape(Y,1,imageSize^2);
imageLMS = bgLMS*ones(size(XVec))+rgConeInc*XVec+sConeInc*YVec;
[imageRGB,badIndex] = SensorToSettings(calLMS,imageLMS);
bgRGB = SensorToSettings(calLMS,bgLMS);
imageRGB(:,find(badIndex == 1)) = bgRGB(:,ones(size(find(badIndex == 1))));
rPlane = reshape(imageRGB(1,:),imageSize,imageSize);
gPlane = reshape(imageRGB(2,:),imageSize,imageSize);
bPlane = reshape(imageRGB(3,:),imageSize,imageSize);
theImage = zeros(imageSize,imageSize,3);
theImage(:,:,1) = rPlane;
theImage(:,:,2) = gPlane;
theImage(:,:,3) = bPlane;

% Show the image for illustrative purposes
figure; clf; image(theImage);

fprintf('Select a point in the figure.\n');
[x, y] = ginput(1);
while ~isempty(x)
    rgb = SensorToPrimary(calLMS, bgLMS + (x-257)/256 * rgConeInc + (y-257)/256 * sConeInc);
    fprintf('RGB is %f,%f,%f lum is %f\n', rgb(1), rgb(2), rgb(3), PrimaryToSensor(calLum, rgb));
    fprintf('\nSelect another point in the figure (hit return without selecting point to quit).\n');
    [x, y] = ginput(1);
end


