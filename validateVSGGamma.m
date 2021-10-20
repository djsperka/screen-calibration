function [] = validateVSGGamma(comport)
%validateVSGGamma Validates linearity of current monitor using fixstim
%(connect via tcp) and spectrometer. 
%   Detailed explanation goes here

% load files of constants
load T_cones_ss2
load T_ss2000_Y2
S_cones = S_cones_ss2;
T_cones = T_cones_ss2;
T_Y = 683*T_ss2000_Y2;
S_Y = S_ss2000_Y2;

% Assuming old650, which gives us its spd with [390 5 81]
T_Y81 = SplineCmf(S_Y,T_Y,[390 5 81]);

% attempt connection with fixstim. Response to connection should be "HELLO"
tcp = tcpclient("127.0.0.1", 7001);
resp = char(read(tcp));

% initialize spectrometer
old650init(comport);

% talk to fixstim
u = udpport;
write(u, 'tcp 7001', 'localhost', 7000);

tcp=tcpclient('localhost', 7001);
resp = char(read(tcp));
fprintf(1, 'tcp connection resp: %s\n', resp);



r=zeros(11,3);
g=zeros(11,3);
b=zeros(11,3);
w=zeros(11,3);
r(:,1) = 0:.1:1;
g(:,2) = 0:.1,1;
b(:,3) = 0:.1:1;
w(:,1) = 0:.1:1;
w(:,2) = 0:.1:1;
w(:,3) = 0:.1:1;


spdRed = measure_spd(tcp, r);
spdGreen = measure_spd(tcp, g);
spdBlue = measure_spd(tcp, b);
spdWhite = measure_spd(tcp, w);

% quit connection to fixstim
write(tcp, 'quit;');
fprintf(1, 'Closed connection with fixstim: %s\n', char(read(tcp)));

% plot
figure;
plot([0:.1:1.0], spdRed, 'r', T_Y81);
hold on;
plot([0:.1:1.0], spdGreen, 'g', T_Y81);
plot([0:.1:1.0], spdBlue, 'b', T_Y81);
plot([0:.1:1.0], spdWhite, 'k', T_Y81);
hold off;

end


function [lum] = measure_lum(tcp, colors, T)

    lum = zeros(size(colors, 1), 1);
    for i=1:size(colors, 1)

        cmd = sprintf('b [%f/%f/%f];', rgbw(i,1), rgbw(i,2), rgbw(i,3));
        write(tcp, cmd);
        resp = char(read(tcp));
        [spd, qual] = old650meassspd();
        lum(i) = T_Y81 * spd;
        fprintf(1, 'color %s, resp %s lum %f\n', cmd, resp, lum(i));
    
    end


end

