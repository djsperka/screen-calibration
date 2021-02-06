% all the vsg constants
global CRS;

%% define constants
% constants for interpolating Baylor logS values
lambdaMaxRed = 561;
lambdaMaxGreen = 531;
lambdaMaxBlue = 430;
lambdaR = 561;
a = [ -5.2734 -87.403 1228.4 -3346.3 -5070.3 30881 -31607 ];

% spd values returned by PR670 are taken at wavelengths 
% 380:5:(380+5*80), or 380, 400, 420, ..., 780.
spdLambda = 380:5:780;
spdWN = 1./spdLambda;

% compute functional form of logS using Baylor  
baylorRedFunctionalLogS = zeros(1, length(spdLambda));
baylorGreenFunctionalLogS = zeros(1, length(spdLambda));
baylorBlueFunctionalLogS = zeros(1, length(spdLambda));
for i = 1:length(spdLambda)
    lambda = spdLambda(i);
    baylorRedFunctionalLogS(i) = computeLogS(lambda, lambdaMaxRed, lambdaR, a);
    baylorGreenFunctionalLogS(i) = computeLogS(lambda, lambdaMaxGreen, lambdaR, a);
    baylorBlueFunctionalLogS(i) = computeLogS(lambda, lambdaMaxBlue, lambdaR, a);
end

% functional form of S, sensitivity.
baylorRedFunctionalS = 10.^baylorRedFunctionalLogS;
baylorGreenFunctionalS = 10.^baylorGreenFunctionalLogS;
baylorBlueFunctionalS = 10.^baylorBlueFunctionalLogS;

% Values for logS from table 1, Baylor et al
% initialize spectral sensitivities from Baylor et al, Table 1
% All wavelengths in nm.
baylorLambda = [ 381 400 420 440 459 480 500 520 541 559 579 600 622 640 659 679 700 722 740 760 781 800 811 830 ];
baylorWN = 1./baylorLambda;

% this array represents the nearest SPD domain values - i.e. wavelengths
% where spd measurements are made
alignedLambda  = 380:20:840; 

% logS values for the three cones (not the RGB phosphors)
baylorRedLogS = [-0.873 -0.890 -0.951 -0.898 -0.780 -0.512 -0.326 -0.221 -0.137 -0.000 -0.039 -0.134 -0.424 -0.735 -1.238 -1.758 -2.409 -3.116 -3.713 -4.309 -4.945 -5.453 -5.755 -6.234 ];
baylorGreenLogS = [-0.818 -0.845 -0.826 -0.596 -0.439 -0.192 -0.053 -0.037 -0.034 -0.000 -0.214 -0.565 -1.114 -1.613 -2.256 -2.910 -3.556 -4.203 -4.819 -5.440 -5.976 -6.447 NaN NaN];
baylorBlueLogS = [ -0.240 -0.137 -0.039 -0.000 -0.172 -0.508 -1.032 -1.764 -2.576 -3.271 -4.040 -4.934 NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN ];




%% plot functional values vs Baylor values
figure;
subplot(3,1,1);
plot(flip(baylorWN), flip(baylorRedLogS), 'rd');
hold on;
plot(flip(spdWN), flip(baylorRedFunctionalLogS), 'r');
hold off;
subplot(3,1,2);
plot(flip(baylorWN), flip(baylorGreenLogS), 'gd');
hold on;
plot(flip(spdWN), flip(baylorGreenFunctionalLogS), 'g');
hold off;
subplot(3,1,3);
plot(flip(baylorWN), flip(baylorBlueLogS), 'bd');
hold on;
plot(flip(spdWN), flip(baylorBlueFunctionalLogS), 'b');
hold off;

% Zero out terms in functional form for which there are no measured values 
% of logS in Baylor. I assume that means the values of sensitivity are zero.
% The only region where sensitivity=0 overlaps with the measurement range
% of the PR670 is for blue, lambda>600.
baylorBlueFunctionalS(find(spdLambda>600)) = 0;

% Finally, form matrix B
B = vertcat(baylorRedFunctionalS, baylorGreenFunctionalS, baylorBlueFunctionalS);

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

%% green
crsSetPen1([0 255 0]);
crsDrawRect([0 0], [crsGetScreenWidth() crsGetScreenHeight()]);

% measure SPD for this screen
[spdGreen qGreen] = PR670measspd([380 5 81], 'on');

%% blue screen
crsSetPen1([0 0 255]);
crsDrawRect([0 0], [crsGetScreenWidth() crsGetScreenHeight()]);

% measure SPD for this screen
[spdBlue qBlue] = PR670measspd([380 5 81], 'on');

%% form matrix M, H=BM, Hinv
M = horzcat(spdRed, spdGreen, spdBlue);
H = B*M;
Hinv = inv(H);


%% Close PR670
PR670close()

%%
function [logS] = computeLogS(lambda, lambda_m, lambda_r, a)
%computeLogS Compute logS using polynomial defined in Baylor et al
%   Sixth order polynomial and constants given in text of paper.
%   Units of lambda_m and lambda_r don't matter as long as they are the
%   same -- we have everything in nm. Units of wavenumber = 1/lambda, 
%   however, should be 1/um. That's why you see 1000/lambda.

    logS = 0;
    for i=0:6
        logS = logS + a(i+1) * (log10( (1000/lambda)*(lambda_m/lambda_r) ) )^i;
    end
    
end


