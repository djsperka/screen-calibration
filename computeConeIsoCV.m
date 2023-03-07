function [lcv, mcv, scv] = computeConeIsoCV(cal, T, S, bg)
%computeConeIsoCV Given the cal struct and CMF, compute the color vectors
%which maximize available gamut (just 95%), and which are in the direction of the
%cones defined by T,S. Background color should be a column vector.
%   Detailed explanation goes here

calLMS = SetSensorColorSpace(cal, T, S);
bgLMS = PrimaryToSensor(calLMS, bg);

% These are not scaled, but are in the right direction.
lPrimary = SensorToPrimary(calLMS, [1 0 0]');
mPrimary = SensorToPrimary(calLMS, [0 1 0]');
sPrimary = SensorToPrimary(calLMS, [0 0 1]');

% Get scale factor to fit these into Gamut (i.e. all values in [0,1])
lScale = MaximizeGamutContrast(lPrimary, bg);
mScale = MaximizeGamutContrast(mPrimary, bg);
sScale = MaximizeGamutContrast(sPrimary, bg);

lConeStep = 0.95 * lScale * lPrimary;
mConeStep = 0.95 * mScale * mPrimary;
sConeStep = 0.95 * sScale * sPrimary;

lcv  = horzcat(bg - lConeStep, bg + lConeStep);
mcv  = horzcat(bg - mConeStep, bg + mConeStep);
scv  = horzcat(bg - sConeStep, bg + sConeStep);
end