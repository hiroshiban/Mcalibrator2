function y=ngauss(varargin)
% y = ngauss(p, x, [y]) : multiple Gaussians
%
%   iFunc/ngauss multiple Gaussian fitting function
%     y = sum p(i)*exp(-0.5*((x-p(i+1))/p(i+2)).^2) + p(end);
%
% to initiate n gaussians use: ngauss(n)
% will result in an iFunc model of n Gaussian functions.
%
% input:  p: multiple Gaussian model parameters (double)
%            p = [ Amplitude1 Centre1 HalfWidth1 ... BackGround ]
%          or 'guess'
%         x: axis (double)
%         y: when values are given and p='guess', a guess of the parameters is performed (double)
% output: y: model value
% ex:     y=ngauss([1 0 1 0.5 2 0.5 0], -10:10); or plot(ngauss)
%
% Version: $Revision: 1035 $
% See also iFunc, iFunc/fits, iFunc/plot

if nargin > 0
  p = varargin{1};
else
  p = [];
end

if length(p) == 1 && p == ceil(p)
  n = p;
elseif isnumeric(p) && length(p) > 1
  n = floor(p)/3+1;
else
  n = 2;
end
if n == 1
  y = gauss(varargin{:});
  return
end

y.Name      = sprintf('%i Gaussians (1D) [%s(%i)]', n, mfilename, n);
y.Description=sprintf('%i 1D Gaussians model', n);

% create the multiple gaussian function

Parameters  =transpose(repmat({'Amplitude','Centre','HalfWidth'},1,n)); % n gaussians parameters
indices     =strtrim(cellstr(num2str(transpose(kron(1:n, [1 1 1])))));  % indices for gaussians
Parameters  =strcat(Parameters,'_',indices);                            % catenate parameter names and indices
Parameters{end+1} = 'BackGround';
y.Parameters = Parameters;

Expression  = @(p,x) p(1)*exp(-0.5*((x-p(2))/p(3)).^2); % single function to use as template
y.Expression = '@(p,x) gauss(p(1:3),x)';
for index=2:n
  y.Expression = [ y.Expression sprintf('+gauss(p(%i:%i),x)', 3*index-2, 3*index) ];
end
y.Expression = [ y.Expression sprintf('+p(%i)',3*n+1) ];

y.Expression= eval(y.Expression); % make it a function handle (faster to evaluate)

if length(p) > 1
  y.ParameterValues = p;
end                            

y = iFunc(y);

if length(varargin) && length(p) > 1
  y = y(varargin{:});
end

