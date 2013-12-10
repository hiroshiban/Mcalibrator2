function displayroutines=displayroutine_list()

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
% Created    : "2013-12-10 15:08:42 ban (ban.hiroshi@gmail.com)"
% Last Update: "2013-12-10 15:20:41 ban (ban.hiroshi@gmail.com)"

displayroutines{1}={'MATLAB figure','DisplayColorWindow'};
displayroutines{2}={'Psychtoolbox','DisplayColorWindowPTB'};
displayroutines{3}={'BITS++ with Psychtoolbox','DisplayColorWindowBITS'};

return
