function meas_methods=measurement_method_list()

% A list of color measurement/estimation methods.
% function meas_methods=measurement_method_list()
%
% Mcalibrator2, measurement_method_list
%
% The list described here is used for selecting measument procedure
% in CIE1931 xyY color calculator
%
% If you want to add your own procedure,
% add {'measurement_name_you_use','function_name_to_be_used_for_measurement'}
% into the list.
%
% [note]
% function file should be generated separately in the same directory with this file.
% For details, see some functions in Mcalibrator2/subfunctions/colorcalculator/calculator_measure_simply.m
% The functions should accept 3 input variables -- hObject, eventdata, and handles of Mcalibrator2.
%
%
% Created    : "2012-05-29 04:09:02 ban"
% Last Update: "2013-12-11 17:18:51 ban"

meas_methods{1}={'Measure simply','calculator_measure_simply'};
meas_methods{2}={'[auto] Recursive linear estimation with unifrnd()','calculator_auto_estimation_linear'};
meas_methods{3}={'[auto] Recursive linear estimation with Grid','calculator_auto_estimation_linear_grid'};
meas_methods{4}={'[auto] Adjust residuals by linear coefficients','calculator_auto_estimation_lincoeff'};
meas_methods{5}={'[auto] Non-linear (Nelder-Mead Simplex)','calculator_auto_estimation_nonlinear'};
meas_methods{6}={'[auto] Linear/non-linear hybrid','calculator_auto_estimation_hybrid'};
meas_methods{7}={'[auto] Brent-Powell with Coggins/Golden-section','calculator_auto_estimation_powell'};
meas_methods{8}={'[auto] Linear/Brent-Powell hybrid','calculator_auto_estimation_powell_hybrid'};

return
