function y=ff_core_shell(varargin)
% y = ff_core_shell(p, x, [y]) : Spherical/core shell form factor [Guinier]
%
%   iFunc/ff_core_shell concentric spherical geometry, with 2 shells
%     The 'x' wave-vector/momentum axis is usually in nm-1 or Angs-1.
%     The parameters R1,R2 are given in inverse unit of the axis (i.e nm or Angs).
%     Typical values for parameters are R1,R2=10-100 Angs, eta1,eta2=1e-6.
%     When eta2=0, the model is equivalent to ff_sphere.
%
%     Ref: Guinier, A. and G. Fournet, "Small-Angle Scattering of X-Rays", 
%            John Wiley and Sons, New York, (1955).
%          Extracted from sasfit/sasfit_ff/sasfit_ff_spherical_shell.c
%
% input:  p: sphere model parameters (double)
%            p = [ R1=Shell_Radius R2=core_radius eta1=SLD shell/matrix eta2=SLD core/shell ]
%          or 'guess'
%         x: wave-vector/momentum axis (double, e.g. nm-1 or Angs-1)
%         y: when values are given and p='guess', a guess of the parameters is performed (double)
% output: y: model value (intensity)
% ex:     y=ff_core_shell([14 11 0.1 0.1], 0:0.01:1); or plot(ff_core_shell,[14 11 0.1 0.],0:0.01:1)
%
% Version: $Revision: 1035 $
% See also iFunc, iFunc/fits, iFunc/plot, ff_sphere

y.Name      = [ 'Spherical/core shell P(q) (1D) [' mfilename ']' ];
y.Description='Concentric spherical geometry, with 2 shells form factor [Guinier]';
y.Parameters={'R1 shell (outer) sphere radius [1/x]', ...
              'R2 core (inner) sphere radius [1/x]', ...
              'eta1 scattering length density difference between shell and matrix [x^2]', ...
              'eta2 scattering length density difference between shell and core [x^2]'};
y.Expression= @(p, x) ( sqrt(ff_sphere(p([1 3]), x )) - sqrt(ff_sphere(p([2 4]), x )) ).^2;
y.Dimension = 1;
y.Guess     = @(x,signal) [ pi/std(x(:)) 1e-6 pi/std(x(:))/2 1e-6 ];
y = iFunc(y);

if length(varargin)
  y = y(varargin{:});
end

