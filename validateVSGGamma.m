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
% old650init(comport);


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
rgbw = vertcat(r,g,b,w);

for i=1:size(rgbw, 1)

    cmd = sprintf('b [%f/%f/%f];', rgbw(i,1), rgbw(i,2), rgbw(i,3));
    write(tcp, cmd);
    resp = char(read(tcp));
    fprintf(1, 'color %s, resp %s\n', cmd, resp);
    
    
end


% set color
write(tcp, 'b [1/.25/.75];');
resp = char(read(tcp))

% quit
write(tcp, 'quit;');
resp = char(read(tcp))

end

