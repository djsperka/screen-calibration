% all the vsg constants
global CRS;

%% define constants
% initialize spectral sensitivities from Baylor et al, Table 1
% All wavelengths in nm.
baylorLambda = [ 381 400 420 440 459 480 500 520 541 559 579 600 622 640 659 679 700 722 740 760 781 800 811 830 ];

% this array represents the nearest SPD domain values - i.e. wavelengths
% where spd measurements are made
alignedLambda  = 380:20:840; 

% logS values for the three cones (not the RGB phosphors)
baylorRed = [-0.873 -0.890 -0.951 -0.898 -0.780 -0.512 -0.326 -0.221 -0.137 -0.000 -0.039 -0.134 -0.424 -0.735 -1.238 -1.758 -2.409 -3.116 -3.713 -4.309 -4.945 -5.453 -5.755 -6.234 ];
baylorGreen = [-0.818 -0.845 -0.826 -0.596 -0.439 -0.192 -0.053 -0.037 -0.034 -0.000 -0.214 -0.565 -1.114 -1.613 -2.256 -2.910 -3.556 -4.203 -4.819 -5.440 -5.976 -6.447 NaN NaN];
baylorBlue = [ -0.240 -0.137 -0.039 -0.000 -0.172 -0.508 -1.032 -1.764 -2.576 -3.271 -4.040 -4.934 NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN ];

% constants for interpolating Baylor logS values
lambdaMaxRed = 561;
lambdaMaxGreen = 531;
lambdaMaxBlue = 430;
lambdaR = 561;
a = [ -5.2734 -87.403 1228.4 -3346.3 -5070.3 30881 -31607 ];

%% align constants
% align baylorLambda values with the wavelengths in the measured SPD 
% Using eq (6) from Baylor et al.
alignedBaylorRed = [];
alignedBaylorBlue = [];
alignedBaylorGreen = [];
for lambda = alignedLambda
    alignedBaylorRed = [alignedBaylorRed computeLogS(lambda, lambdaMaxRed, lambdaR, a)];
    alignedBaylorGreen = [alignedBaylorGreen computeLogS(lambda, lambdaMaxGreen, lambdaR, a)];
    alignedBaylorBlue = [alignedBaylorBlue computeLogS(lambda, lambdaMaxBlue, lambdaR, a)];
end



%% init vsg
% ...and draw gray screen
ret = vsgInit;
if ret ~= 0
    error('vsgInit failed. Make sure vsg is available.');
end
crsSetVideoMode(CRS.TRUECOLOURMODE + CRS.GAMMACORRECT);
crsSetPen1([127 127 127]);
crsSetDrawPage(1);
crsDrawRect([0 0], [crsGetScreenWidth() crsGetScreenHeight()]);
crsSetZoneDisplayPage(CRS.VIDEOPAGE, 1);

%% init spectrometer
% COM port will need to be an input parameter - it seems
% to change. 
ret = PR670init('COM9');
if ~contains(ret, 'REMOTE MODE')
    error('PR670init failed. Check com port.');
end

%% Measure RGB SPDs
% red
crsSetPen1([255 0 0]);
crsDrawRect([0 0], [crsGetScreenWidth() crsGetScreenHeight()]);

% measure SPD for this screen
[spdRed qRed] = PR670measspd([380 5 81], 'on');

% blue
crsSetPen1([0 255 0]);
crsDrawRect([0 0], [crsGetScreenWidth() crsGetScreenHeight()]);

% measure SPD for this screen
[spdBlue qBlue] = PR670measspd([380 5 81], 'on');

% green screen
crsSetPen1([0 0 255]);
crsDrawRect([0 0], [crsGetScreenWidth() crsGetScreenHeight()]);

% measure SPD for this screen
[spdGreen qGreen] = PR670measspd([380 5 81], 'on');

%% calculations
%TODO - I don't know if units are correct here. 
%       The SPD taken from the PR670 is in ?????
%       The sensitivity values taken from Baylor et al are in 




function [logS] = computeLogS(lambda, lambda_m, lambda_r, a)
%computeLogS Compute logS using polynomial defined in Baylor et al
%   Sixth order polynomial and constants given in text of paper. 

    logS = 0;
    for i=0:6
        logS = logS + a(i+1)*((log(lambda_m/(1000*lambda*lambda_r)))^i);
    end
    
end


