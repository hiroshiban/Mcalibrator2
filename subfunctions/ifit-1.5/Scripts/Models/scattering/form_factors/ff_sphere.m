function y=ff_sphere(varargin)
% y = ff_sphere(p, x, [y]) : Sphere form factor [Guinier]
%
%   iFunc/ff_sphere monodisperse spherical particle form factor P(q) with uniform 
%       scattering length density. 
%     The 'x' wave-vector/momentum axis is usually in nm-1 or Angs-1.
%     The parameter R is given in inverse unit of the axis (that is nm or Angs).
%     Typical values for parameters are R=10-100 Angs, eta=1e-6.
%     The value at q=0 is (4/3*pi*eta*R^3)^2
%
%     Ref: Guinier, A. and G. Fournet, "Small-Angle Scattering of X-Rays", 
%            John Wiley and Sons, New York, (1955).
%          Extracted from sasfit/sasfit_ff/sasfit_ff_sphere.c
%
% input:  p: sphere model parameters (double)
%            p = [ R=Sphere_Radius eta=SLD particle/matrix ]
%          or 'guess'
%         x: wave-vector/momentum axis (double, e.g. nm-1 or Angs-1)
%         y: when values are given and p='guess', a guess of the parameters is performed (double)
% output: y: model value (intensity)
% ex:     y=ff_sphere([10 2e-6], 0:0.01:1); or plot(ff_sphere,[10 1e-6],0:0.01:1)
%
% Version: $Revision: 1035 $
% See also iFunc, iFunc/fits, iFunc/plot, ff_core_shell

y.Name      = [ 'Sphere P(q) (1D) [' mfilename ']' ];
y.Description='Sphere form factor [Guinier]';
y.Parameters={'R sphere radius [1/x]', ...
              'eta scattering length density difference between particle and matrix [x^2]'};
y.Expression= @(p,x) ( (p(2)*4.0*pi*(sin(p(1)*x) - p(1)*x.*cos(p(1)*x))./(x+(x == 0)).^3).*(x ~= 0) ...
  + (x == 0).*(p(2)*4/3*pi*p(1)^3) ).^2;
  
y.Guess     = @(x,signal) [ pi/std(x(:)) 1e-6 ];
y = iFunc(y);

if length(varargin)
  y = y(varargin{:});
end

