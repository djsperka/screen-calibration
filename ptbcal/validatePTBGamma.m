function [lumR,lumG,lumB,lumW] = validatePTBGamma(windowIndex, calfile)
%validatePTBGamma Validates linearity of current monitor using fixstim
%(connect via tcp) and spectrometer. 
%   Spectrometer assumed to be connected (you call old650init prior)

if ~old650isReady()
    error('old650 not initialized. Call old650init(comport) first.');
end

% % Open window on screen 
% PsychDefaultSetup(2);
% w = PsychImaging('OpenWindow', screen, [.5, .5, .5]);

% Load cal file and get gamma table
% cal = myLoadCalFile(calfile);

% Default spectra returned from pr650.
S0 = [380, 4, 101];

% T will be needed to compute luminance.
load T_cones_ss2
load T_ss2000_Y2
T = SplineCmf(S_ss2000_Y2, 683*T_ss2000_Y2, S0);


% values to test
values = (0:.1:1)';
r=zeros(length(values),3);
g=zeros(length(values),3);
b=zeros(length(values),3);
w=zeros(length(values),3);
r(:,1) = values;
g(:,2) = values;
b(:,3) = values;
w(:,1) = values;
w(:,2) = values;
w(:,3) = values;


fprintf(1,'Pausing for 10 sec...');
pause(10);

lumR = measure_lum(windowIndex, r, S0, T);
lumG = measure_lum(windowIndex, g, S0, T);
lumB = measure_lum(windowIndex, b, S0, T);
lumW = measure_lum(windowIndex, w, S0, T);

% plot
figure;
plot(values, lumR, 'r');
hold on;
plot(values, lumG, 'g');
plot(values, lumB, 'b');
plot(values, lumW, 'k');
hold off;

end


function [lum] = measure_lum(w, colors, S, T)

    lum = zeros(size(colors, 1), 1);
    for i=1:size(colors, 1)

        Screen('FillRect', w, colors(i,:));
        Screen('Flip', w);
        [spd, qual] = old650measspd(S,'on');
        lum(i) = T * spd;
        fprintf(1, 'color (%f,%f,%f), qual %d lum %f\n', colors(i,1), colors(i,2), colors(i,3), qual, lum(i));
    
    end


end

