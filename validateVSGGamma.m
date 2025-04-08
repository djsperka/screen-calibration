function [lumR,lumG,lumB,lumW] = validateVSGGamma()
%validateVSGGamma Validates linearity of current monitor using fixstim
%(connect via tcp) and spectrometer. 
%   Spectrometer assumed to be connected (you call old650init prior)

% allow pausing
pause('on');

% load files of constants
% load T_cones_ss2
% load T_ss2000_Y2
% S_cones = S_cones_ss2;
% T_cones = T_cones_ss2;
% T_Y = 683*T_ss2000_Y2;
% S_Y = S_ss2000_Y2;
% 
% % Assuming old650, which gives us its spd with [390 5 81]
% % Use this to compute lum from spd. 
% T_Y81 = SplineCmf(S_Y,T_Y,[390 5 81]);

 [S,T] = getLumTS(); 

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


fprintf(1,'Pausing for 5 sec...');
pause(5);

% talk to fixstim. Should check response HELLO. TODO.
fprintf(1, 'Connect to fixstim control port...\n');
tcp0 = tcpclient('localhost', 7000);
configureTerminator(tcp0, 59, 26);
resp = char(readline(tcp0));
fprintf(1, 'control port connection resp: %s\n', resp);

cmd = 'tcp 7001';
writeline(tcp0, cmd);
pause(1);
clear tcp0;

% attempt connection with fixstim. Response to connection should be "HELLO;"

fprintf(1, 'Start sending commands.\n');
tcp=tcpclient('localhost', 7001);
configureTerminator(tcp, 59, 59);
resp = char(readline(tcp));
fprintf(1, 'tcp connection resp: %s\n', resp);

lumR = measure_lum(tcp, r, S, T);
lumG = measure_lum(tcp, g, S, T);
lumB = measure_lum(tcp, b, S, T);
lumW = measure_lum(tcp, w, S, T);

% quit connection to fixstim
writeline(tcp, 'quit');
fprintf(1, 'Closed connection with fixstim: %s\n', char(readline(tcp)));

% plot
figure;
plot(values, lumR, 'r');
hold on;
plot(values, lumG, 'g');
plot(values, lumB, 'b');
plot(values, lumW, 'k');
hold off;

end


function [lum] = measure_lum(tcp, colors, S, T)

    lum = zeros(size(colors, 1), 1);
    for i=1:size(colors, 1)

        cmd = sprintf('b [%f/%f/%f]', colors(i,1), colors(i,2), colors(i,3));
        fprintf(1,'vsg command: %s\n', cmd);
        writeline(tcp, cmd);
        resp = char(readline(tcp));
        pause(0.5);
        [spd, qual] = old650measspd(S, 'on');
        lum(i) = T * spd;
        fprintf(1, 'color %s, resp %s lum %f\n', cmd, resp, lum(i));
    
    end


end

