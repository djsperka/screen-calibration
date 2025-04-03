function [lumR,lumG,lumB,lumW] = validatePTBGamma(screen, calfile, npts)
%validatePTBGamma Validates linearity of current monitor using fixstim
%(connect via tcp) and spectrometer. 
%   Spectrometer assumed to be connected (you call old650init prior)

    arguments
        screen {mustBeNumeric},
        calfile char {mustBeFile},
        npts {mustBePositive} = 11
    end


    if ~old650isReady()
        error('old650 not initialized. Call old650init(comport) first.');
    end
    
    % open window
    [windowIndex, ~] = openLinearWindowFullScreen(screen, calfile, false, .5);

% values to test
values = linspace(0, 1, npts)';
r=zeros(npts,3);
g=zeros(npts,3);
b=zeros(npts,3);
w=zeros(npts,3);
r(:,1) = values;
g(:,2) = values;
b(:,3) = values;
w(:,1) = values;
w(:,2) = values;
w(:,3) = values;

% make a stack of r;g;b;w, 4*npts X 3
rgbwStack=vertcat(r,g,b,w);

% randomize the order of the colors presented
iorder = randperm(size(rgbwStack, 1));

fprintf(1,'Pausing for 5 sec...');
pause(5);

% spectral params for PR650 and T for luminance calculation.
% S0 is determined by the spectrometer - it is the default spectrum param
% [381,4,101] or something like that.
[S0, T] = getLumTS();

% measure the luminances
luminances = measure_lum(windowIndex, rgbwStack(iorder,:), S0, T);

% rearrange for plotting
lumtmp(iorder(:)) = luminances(:);
lumRGBW = reshape(lumtmp, npts, 4);
lumR = lumRGBW(:,1);
lumG = lumRGBW(:,2);
lumB = lumRGBW(:,3);
lumW = lumRGBW(:,4);

% linear fit to each line
cR = polyfit(values, lumR, 1);
cG = polyfit(values, lumG, 1);
cB = polyfit(values, lumB, 1);
cW = polyfit(values, lumW, 1);

% plot nice
figure;
plot(values, lumR, 'r+', values, lumG, 'g+', values, lumB, 'b+', values, lumW, 'k+');
hold on
plot(values, polyval(cR,values), 'r');
plot(values, polyval(cG,values), 'g');
plot(values, polyval(cB,values), 'b');
plot(values, polyval(cW,values), 'k');

title('Inverse Gamma Validation');
ylabel('Measured luminance (Cd/m**2)');
end


function [lum] = measure_lum(w, colors, S, T)

    lum = zeros(size(colors, 1), 1);
    for i=1:size(colors, 1)

        Screen('FillRect', w, colors(i,:));
        Screen('Flip', w);
        [spd, qual] = old650measspd(S,'off');
        lum(i) = T * spd;
        fprintf(1, '%d/%d color (%f,%f,%f), qual %d lum %f\n', i, size(colors, 1), colors(i,1), colors(i,2), colors(i,3), qual, lum(i));
    
    end


end

