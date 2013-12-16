function strings=load_information_strings()

% Defines strings displayed in Information window of Mcalibrator2.
% function strings=load_information_strings()
%
% This function defines strings displayed in Information window
%
%
% Created    : "2012-04-15 01:23:24 ban"
% Last Update: "2013-12-16 09:17:30 ban"

% string for "config" tab
strings{1}=...
    {'save_dir : set a directory where the measurement results are stored.',...
     ['date : you can add some prefix like ',sprintf('%s_1.',datestr(now,'yymmdd')),'.',' !NOTE! the results are stored in save_dir/date. Please be careful.'],...
     'apparatus : an apparatus to be used.',...
     'display routine : select color display routine.',...
     'sampling points: the number of sampling points (video input).',...
     'sampling interval: equally or biased intervals.',...
     '#lut steps : the number of elements in a generated LUT. Select 256 for PTB3.',...
     '#repetitions : #repetition of measurements and a method to gather measured data.',...
     'phosepher(s) : color(s) to be measured.',...
     'Flare Corr. : if checked, do flare correction.',...
     '',...
     'Press "OK" to proceed to the next steps.',...
     'To change the parameters, release "OK" toggle button.',...
     'To load pre-defined configurations, press "Load config"',...
     'To save the current configurations for future use, press "Save config".',...
     'The configuration files will be stored in ~/Mcalibrator2/config directory.'};

% string for "measure" tab
strings{2}=...
    {'Adjust Position : adjust position of the colorimeter using a guide window.',...
     'screen ID : set ID (1,2,3,...) of the screen to be used. 1 is the current.',...
     'Serial/USB : set numbor of COM/USB port.',...
     'Create : create a serial object to communicate with a colorimeter.',...
     'Reset : delete a serial object.',...
     'Initialize Apparatus : initialize colorimeter.',...
     'Measure CIE1931 xyY : measure xyY values specified in "phosphor(s)"... in "config" tab',...
     '',...
     'Measured CIE1931 Y values of selected phosphors are displayed on the plot panel on this tab.',...
     '',...
     'The results are also stored as *.mat file in ~/Mcalibrator2/data directory.'};

% string for "LUT" tab
strings{3}=...
    {'Fit a model : fit a model to the data.',...
     'fitting method : a fitting model, Gain-offset-gamma for CRT and cubic-spline for LCD/DLP are recommended.',...
     'Create Color Lookup Table : generate LUTs. The results are stored both *.mat and *.lut (text) formats in ~/Mcalibrator2/data directory.',...
     'Check the linearity : check the quality of generated LUTs.',...
     '',...
     'If "eacy check" toggle button is released, luminance values for several video inputs selected from generated LUTs are measured again.'};

% string for "Color Calculator" tab
strings{4}=...
    {'Initialize : load RGB phosphors'' xyY as a transformation matrix.',...
     'If LUT is selected, generated LUTs are used. If RGB is selected, RGB values are used directly.',...
     ['you want : set xyY and then press "convert xyY" button. You can directly set RGB values instead.',...
      'xyY/RGB values should be set with comma and semicolon like x1,y1,Y1;x2,y2,Y2;x3,y3,Y3;...'],...
     ['load text : you can load xyY values from a text file. The text file should be organized as'],...
     'x1,y1,Y1;',...
     'x2,y2,Y2;',...
     'x3,y3,Y3;',...
     '...',...
     'measure : measure actual xyY values for RGB you set.',...
     'auto estimation : run automatic optimal estimation of xyY/RGB values.',...
     'results : measured values for xyY/RGB you set are displayed.',...
     'save : if pressed, the estimated xyY/RGB values are stored as *.mat and *.txt format in ~/Mcalibrator2/data directory.'};

% string for "about" tab
strings{5}=...
    {'Mcalibrator2 is not a medical product.',...
     ['It is not allowed to use this software directly or indirectly ',...
      'for medical diagnosis and/or treatment of humans. ',...
      'The software may be used exclusively in the field of scientific ',...
      'research and not for curative purposes. '],...
      '',...
      'See the copyright notice below and license.txt in doc directory for more information.',...
      '',...
     ['Redistribution and use in source and binary forms, with or without ',...
      'modification, are permitted provided that the following conditions are ',...
      'met:'],...
     ['* Redistributions of source code must retain the above copyright ',...
      'notice, this list of conditions and the following disclaimer.'],...
     ['* Redistributions in binary form must reproduce the above copyright ',...
      'notice, this list of conditions and the following disclaimer in ',...
      'the documentation and/or other materials provided with the distribution.'],...
      '',...
      ['This software is distributed WITHOUT ANY WARRANTY; without even ',...
      'the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR ',...
      'PURPOSE.']};

% string for "warning"
strings{6}=...
    {'you are going to change the optimization parameter settings.',...
     'This may affect the performance of Mcalibrator2.',...
     'Do you want to proceed?'};

return
