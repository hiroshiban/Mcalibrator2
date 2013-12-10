function a = fix(a, varargin)
% b = fix(s, parameters, ...) : sets parameter lock (fix) for further fit using the model 's'
%
%   @iFunc/mlock lock model parameters during further fit process.
%     to lock/fix a parameter model, use fix(model, parameter)
%
%   To lock/fix a set of parameters, you may use a regular expression as:
%     fix(model, regexp(model.Parameters, 'token1|token2|...'))
%
%   fix(model, {'Parameter1', 'Parameter2', ...})
%     lock/fix parameter for further fits
%   fix(model)
%     display fixed parameters
%
% input:  s: object or array (iFunc)
%         parameters: names or index of parameters to lock/fix (char or scalar)
% output: b: object or array (iFunc)
% ex:     b=fix(a,'Intensity');
%
% Version: $Revision: 1035 $
% See also iFunc, iFunc/fits, iFunc/munlock, iFunc/xlim

% calls subsasgn with 'fix' for each parameter given

a = mlock(a, varargin);

if nargout == 0 && ~isempty(inputname(1))
  assignin('caller',inputname(1),a);
end

