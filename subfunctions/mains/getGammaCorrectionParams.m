function options=getGammaCorrectionParams()

% Sets parameters for Curve-fitting and Gamma-corrections.
% function options=getGammaCorrectionParams()
%
% This function sets parameters for curve-fitting and gamma-corrections.
% You can edit values in this fule when you want to change the fit parameters.
%
% [input]
% no input variable. To use different fit parameters, please change the
% values in this file directly. Or you can comment-out some variables
% when you want to use the default values for them.
%
% [output]
% options : option parameters for curve-fitting and gamma-correction.
%           a MATLAB structure with fields listed below.
%           .monotonic_flg  : whether applying monotonic filter, [0|1], 1 by default.
%           .lowpass_flg    : whether applying lowpass filter to the raw lum data, [0|1], 0 by default.
%           .lowpass_cutoff : cutoff frequencty of the lowpass filter, 0.085 by default.
%           .epsilon        : a cutoff value to be used in smoothing the data, 0.01 by default.
%           .breaks         : N-breaks of the data for robust spline, 8 (= 7 pieces) by default.
%
%
% Created    : "2013-12-16 09:59:15 ban"
% Last Update: "2013-12-16 10:06:19 ban"

% set curve-fitting and gamma-correction parameters
% the default parameters are as below.
% options.monotonic_flg=1;
% options.lowpass_flg=0;
% options.lowpass_cutoff=0.085;
% options.epsilon=0.01;
% options.breaks=8;

options.monotonic_flg=1;
options.lowpass_flg=0;
options.lowpass_cutoff=0.085;
options.epsilon=0.01;
options.breaks=8;

return
