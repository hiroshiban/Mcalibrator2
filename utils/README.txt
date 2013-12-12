****************************************
README.txt on utility functions of Mcalibrator2

Created    : "2012-04-12 11:29:15 ban"
Last Update: "2013-12-12 11:38:08 ban"
****************************************

The MATLAB packages here are used to develop Mcalibrator2 GUI window and to generate/update html-based help documents.

1. To modify Mcalibrator2 GUI for your own purposes and functions,
   please run the commands below on MATLAB (please do not use a MATLAB-native "guide" function)

   >> addpath('path_to_tabpanel2.8.1_here')
   >> tabpanel('Mcalibrator2.fig','McalibratorTab');

   *acknowledgment*
   A MATLAB tool, tabpanel was developed by Elmar Tarajan.
   [ref] http://www.mathworks.com/matlabcentral/fileexchange/6996-tabpanel-constructor-v2-8-2010

2. To update Mcalibrator2 html-based help files, please run
   ~/Mcalibrator2/update_Mcalibrator2_html_docs.m
   on MATLAB shell.
