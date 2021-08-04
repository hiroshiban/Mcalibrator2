% script_test_flicker
%
% A simple script for measuring display flickering pattern with the Brontes-LL colorimeter.
% It can be used for checking a display refresh rate etc.
%
%
% Created    : "2021-08-03 15:31:16 ban"
% Last Update: "2021-08-04 17:10:01 ban"

% some constants
samples=24000;
delay=0;
integration_time=16666;

% initialize Brontes
colorimeter=brontesLL();
colorimeter=colorimeter.gen_port(); % generate USB port to communicate with Brontes-LL
colorimeter=colorimeter.initialize(500); % initialize Brontess, with setting default measurement parameters and your integration time.

fprintf('here, please present some images/movies that can be used for measuring the display flicker (e.g. a white/black flickering pattern)\n');
fprintf('then, if you are ready, please press F5 to carry on\n');

% measurement
[qq,luminance,dt]=colorimeter.measure_flicker(samples,delay,integration_time);
plot([1:1:samples].*dt,luminance); xlabel('Time[s]'); ylabel('Luminance[counts]');
