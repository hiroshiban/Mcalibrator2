function displayroutines=displayroutine_list()

% A list of functions to be used to display color patches in light measurement.
% function displayroutines=displayroutine_list()
%
% Mcalibrator2, displayroutine_list
%
% The cell list described here is used in selecting color patch displaying
% procedure for display calibration.
%
% If you want to add your own procedure,
% add {'name_of_color_patch_displaying_procedure_you_use','function_name_to_be_used_for_displaying'}
% into the list.
%
% [note]
% 1. Your own function file should be generated separately in the same directory with this file.
% 2. You can place your files in subdirectories too as Mcalibrator2 adds all the subdirectories to its
%    search path strcture when it is launched.
% 3. Your own function should have the following input/output variable format.
%    [fig_id,success]=your_function(rgb,fullscr_flg,fig_id,scr_num)
%    For details, please see DisplayColorWindow.m
%
%
% Created    : "2013-12-10 15:08:42 ban"
% Last Update: "2014-03-25 17:18:48 ban"

displayroutines{1}={'MATLAB figure','DisplayColorWindow'};
displayroutines{2}={'Psychtoolbox','DisplayColorWindowPTB'};
displayroutines{3}={'Psychtoolbox (10bit depth)','DisplayColorWindowPTB10Bit'};
displayroutines{4}={'BITS++ with Psychtoolbox','DisplayColorWindowBITS'};

return
