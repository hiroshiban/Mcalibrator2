% script_test_flicker
%
% A simple script for measuring display flickering pattern with the Brontes-LL colorimeter.
% It can be used for checking a display refresh rate etc.
%
%
% Created    : "2021-08-03 15:31:16 ban"
% Last Update: "2021-08-05 16:24:31 ban"

% some constants
samples=24000;          % the number of acquisition samples
delay=0;                % measurement delay
integration_time=16666; % integration time in usec

% initialize Brontes
colorimeter=brontesLL();
colorimeter=colorimeter.gen_port(); % generate USB port to communicate with Brontes-LL
colorimeter=colorimeter.initialize(500); % initialize Brontess, with setting default measurement parameters and your integration time.

fprintf('*************************************************************************\n');
fprintf('  here, please present some images/movies that can be used for\n');
fprintf('  measuring the display flicker (e.g. a white/black flickering pattern)\n');
fprintf('  then, if you are ready, please press F5 to carry on\n');
fprintf('*************************************************************************\n');
keyboard;

% measurement
[qq,luminance,dt]=colorimeter.measure_flicker(samples,delay,integration_time);

% FFT
smpfrq=1/dt;
T=numel(luminance); % timepoints
uids=(0:floor(T/2))'+1; % to select freqs <= nyquist
Y=fft(luminance',T); % spectrums
Pwr=Y(uids,:).*conj(Y(uids,:))/T; % power (periodgram)
%Pwr(1)=0; % comment this line to keep DC component here
freq=(0:floor(numel(luminance)/2))/(numel(luminance)/smpfrq); % frequency

% display results
figure; hold on;

% raw luminance time series
subplot(2,1,1);
plot([1:1:samples].*dt,luminance);
title('Display refresh rate');
xlabel('Time[s]'); ylabel('Luminance[counts]');

subplot(2,1,2);
plot(freq(1:180),log(Pwr(1:180)));
title('FFT of the display refresh rate')
xlabel('Frequency [Hz]'); ylabel('Power');
