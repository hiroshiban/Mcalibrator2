% Marcel Leutenegger © November 2006
% Updated by  	Uli Klessinger 18 Jun 2012
%
% http://www.mathworks.com/matlabcentral/fileexchange/11224-andor-sif-image-reader
% http://www.andor.com/scientific-cameras

%  Copyright (c) 2006, Marcel Leutenegger
%  All rights reserved.
%
%  Redistribution and use in source and binary forms, with or without
%  modification, are permitted provided that the following conditions are
%  met:
%
%      * Redistributions of source code must retain the above copyright
%        notice, this list of conditions and the following disclaimer.
%      * Redistributions in binary form must reproduce the above copyright
%        notice, this list of conditions and the following disclaimer in
%        the documentation and/or other materials provided with the distribution
%
%  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
%  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
%  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
%  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
%  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
%  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
%  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
%  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
%  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
%  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
%  POSSIBILITY OF SUCH DAMAGE.

function info=read_sif(filename, framenumber)

file = filename;
if nargin==1
  currentFrameNumber = 0;
elseif nargin==2
  currentFrameNumber = framenumber;
end
f=fopen(file,'r');
if f < 0
  error('Could not open the file.');
end
if ~isequal(fgetl(f),'Andor Technology Multi-Channel File')
  fclose(f);
  error('Not an Andor SIF image file.');
end
skipLines(f,1);
[info]=readSection(f, currentFrameNumber);
fclose(f);
if currentFrameNumber > 0
  pic_out = info.imageData;
  %pic_plot_uint8 = uint8(pic_out/max(pic_out(:))*255);
  pic_uint8 = uint8(round(pic_out/(2^info.currentBitDepth)*255));
  %asdasd
  %size(pic_uint8)
  pic_uint8_rgb = zeros([size(pic_uint8), 3], 'uint8');
  pic_uint8_rgb(:,:,1) = pic_uint8;
  pic_uint8_rgb(:,:,2) = pic_uint8;
  pic_uint8_rgb(:,:,3) = pic_uint8;

  info.imageData_uint8_rgb = pic_uint8_rgb;
  info.imageData_orig = NaN;
  try
    pic_rgb = zeros([size(pic_uint8), 3], 'double');
    pic_rgb(:,:,1) = pic_out;
    pic_rgb(:,:,2) = pic_out;
    pic_rgb(:,:,3) = pic_out;
    info.imageData_orig = pic_rgb;
  catch
  end
end

%figure
%imagesc(pic_uint8_rgb)

%Read a file section.
%
% f File handle
% info Section data
% next Flags if another section is available
%
function [info]=readSection(f, currentFrameNumber)

settingsline = fgetl(f);
settings_cell = regexp(settingsline, '(\S)+\s', 'match');
file_timestamp_utc_in_sec = sscanf(settings_cell{5}, '%f');
temperature1_in_celsius = sscanf(settings_cell{6}, '%f');
exposureTime_in_sec = sscanf(settings_cell{13}, '%f');
cycleTime = sscanf(settings_cell{14}, '%f');
accumulateCycleTime = sscanf(settings_cell{15}, '%f');
accumulateCycles = sscanf(settings_cell{16}, '%f');
stackCycleTime = sscanf(settings_cell{18}, '%f');
pixelReadoutTimeSec = sscanf(settings_cell{19}, '%f');
EMgain = sscanf(settings_cell{22}, '%f');
verticalShiftSpeed = sscanf(settings_cell{42}, '%f');
preAmpGain = sscanf(settings_cell{44}, '%f');
temperature2_in_celsius = sscanf(settings_cell{48}, '%f');
version1 = sscanf(settings_cell{55}, '%f');
version2 = sscanf(settings_cell{56}, '%f');
version3 = sscanf(settings_cell{57}, '%f');
version4 = sscanf(settings_cell{58}, '%f');

timestamp_utc_in_sec = file_timestamp_utc_in_sec; % o(5): UTC: seconds since 1970; ACHTUNG Kamera speichert in UTC OHNE Sommer/Winterzeit
timestamp_total_matlab_orig = datenum([1970 1 1 0 0 timestamp_utc_in_sec]); %umrechnen in die Matlab zeitrechnung
isDlST = isDaylightSavingTime(timestamp_total_matlab_orig); %nachschaun obs waehrend der sommerzeit war
additionalHourDueToDlST = 0;
if isDlST
  additionalHourDueToDlST = 1;
end
additionalHourDueToTimezone = 1; %sind ja gmt+1!!
matlab_correction = additionalHourDueToTimezone/24 + additionalHourDueToDlST/24;
timestamp_total_matlab_corrected = timestamp_total_matlab_orig + matlab_correction;
timestamp_total_matlab_corrected_vec = datevec(timestamp_total_matlab_corrected);
timestamp_total_matlab_corrected_vec_day = [timestamp_total_matlab_corrected_vec(1:3) 0 0 0];
timestamp_rel_in_sec = etime(timestamp_total_matlab_corrected_vec, timestamp_total_matlab_corrected_vec_day);
timestamp_rel_in_ms = timestamp_rel_in_sec*1000;

%% Werte aus dem Sif file
info.date = datestr(timestamp_total_matlab_corrected);
info.filetype = 'andor-sif-file';
if temperature1_in_celsius~=-999
  info.temperature = temperature1_in_celsius;
else
  info.temperature = sprintf('%d UNSTABLE', temperature2_in_celsius);
end
info.accumulateCycles = accumulateCycles;
info.accumulateCycleTime = accumulateCycleTime;
info.cycleTime = cycleTime;
info.EMgain = EMgain;
info.exposureTime = exposureTime_in_sec;
info.pixelReadoutTimeSec = pixelReadoutTimeSec;
info.preAmpGain = preAmpGain;
info.stackCycleTime = stackCycleTime;
info.Version = sprintf('%d.%d.%d.%d', version1, version2, version3, version4);
info.verticalShiftSpeed = verticalShiftSpeed;

%% Daraus berechnete Werte
time_between_to_pics = info.stackCycleTime;

%% In die Ausgabe uebernehmen
info.framerate = 1/time_between_to_pics; %nicht sicher ob das stimmt
info.PixelReadoutRateHz=1/info.pixelReadoutTimeSec;
info.time_between_to_pics = time_between_to_pics;

%% Weitere Daten aus dem Sif file
info.detectorType=readLine(f);
if strcmp(info.detectorType, 'DU897_BV')
  info.currentBitDepth = 14;
else
  info.currentBitDepth = 11;
end

info.detectorSize=fscanf(f,'%d',[1 2]);
info.fileName=readString(f);
info.possibleBitDepth=fscanf(f,'%d',[1 2]);

current_line_text = '';
while isempty(strfind(current_line_text, 'Pixel number'))
  current_line_text = fgetl(f);
end
skipLines(f,1)
imageArealine = fgetl(f);
frameArealine = fgetl(f);
imageAreaData=sscanf(imageArealine,'Pixel number%d %d %d %d %d %d %d %d %d');
frameAreaData=sscanf(frameArealine,'%d %d %d %d %d %d %d');
pixelPerImage = imageAreaData(9);
pixelInVideo = imageAreaData(8);
leftPixel = frameAreaData(2);
topPixel = frameAreaData(3);
rightPixel = frameAreaData(4);
bottomPixel = frameAreaData(5);
imageArea = [imageAreaData(2) imageAreaData(5) imageAreaData(7);imageAreaData(4) imageAreaData(3) imageAreaData(6)];
frameArea = [leftPixel bottomPixel; rightPixel topPixel]; %left, top, right, bottom!
vBin = frameAreaData(7); %vielleicht genau andersrum
hBin = frameAreaData(6); %vielleicht genau andersrum
frameBins = [vBin hBin]; %vielleicht genau andersrum

width = (rightPixel - leftPixel + 1)/hBin;
height = (topPixel - bottomPixel + 1)/vBin;

info.Width = width;
info.Height = height;
info.imageArea = imageArea;
info.frameArea = frameArea;
info.vBin = vBin;
info.hBin = hBin;
resolution=(1 + diff(info.frameArea))./frameBins;
NumFrames=1 + diff(info.imageArea(5:6));
info.NumFrames = NumFrames;
info.resolution = resolution;
info.pixelPerFrame = prod(resolution);

timestamps_from_siffile = fscanf(f,'%d\n', info.NumFrames); %sind aber angeblich auch nur berechnet
info.timestamps = timestamp_rel_in_ms + (1/info.framerate*(0:(info.NumFrames-1)))*1000;

%Read a line.
%
% f File handle
% o Read line
%
function o=readLine(f)
  o=fgetl(f);
  if isequal(o,-1)
    fclose(f);
    error('Inconsistent image header.');
  end
  o=deblank(o);

%Skip bytes.
%
% f File handle
% N Number of bytes to skip
%
function skipBytes(f,N)
  [~,n]=fread(f,N,'uint8');
  if n < N
    fclose(f);
    error('Inconsistent image header.');
  end

%Skip lines.
%
% f File handle
% N Number of lines to skip
%
function skipLines(f,N)
  for n=1:N
    if isequal(fgetl(f),-1)
      fclose(f);
      error('Inconsistent image header.');
    end
  end 
