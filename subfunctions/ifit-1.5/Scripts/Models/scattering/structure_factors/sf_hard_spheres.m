function y=sf_hard_spheres(varargin)
% y = sf_hard_spheres(p, x, [y]) : Hard Sphere structure factor [Percus-Yevick]
%
%   iFunc/sf_hard_spheres Hard Sphere structure factor, suited for simple liquids
%     The 'x' wave-vector/momentum axis is usually in nm-1 or Angs-1.
%     The parameter RHS is given in inverse unit of the axis (that is nm or Angs).
%     Typical values for parameters are R=3-50 Angs, rho=0.2.
%     The Hard Sphere model corresponds with the Sticky Hard Sphere model with large tau.
%     The model returns the S(q) structure factor.
%
%     Ref: J. K. Percus and G. J. Yevick., Phys. Rev., 110(1):1–13, 1958.
%          A. Vrij., J. Chem. Phys., 71(8):3267–3270, 1979.
%          Extracted from sasfit/sasfit_sq/sasfit_sq_HardSphere.c
%
% input:  p: hard sphere model parameters (double)
%            p = [ R=Hard_Sphere_Radius rho=Volume_Fraction ]
%          or 'guess'
%         x: wave-vector/momentum axis (double, e.g. nm-1 or Angs-1)
%         y: when values are given and p='guess', a guess of the parameters is performed (double)
% output: y: model value (intensity)
% ex:     y=sf_hard_spheres([10 0.2], 0:0.01:1); or plot(sf_hard_spheres,[10 0.1],0:0.01:1)
%
% Version: $Revision: 1035 $
% See also iFunc, iFunc/fits, iFunc/plot

y.Name      = [ 'Hard Sphere S(q) (1D) [' mfilename ']' ];
y.Description='Hard Sphere scattering structure factor [Percus-Yevick]';
y.Parameters={'R hard sphere radius [1/x]', ...
              'rho hard sphere volume fraction'};
y.Expression= { ...
  'A=2.0*abs(p(1)*x); fp=max(0, min(p(2), 1)); '...
  'if (p(2) == 0.0) signal=ones(size(x)); else ' ...
  'alpha = power(1.0+2.0*fp,2.0)/power(1.0-fp,4.0); ' ...
  'beta  = -6.0*fp*power(1.0+fp/2.0,2.0)/power(1.0-fp,4.0); gamma = fp*alpha/2.0; ' ...
  'signal = alpha*(sin(A)-A.*cos(A))./power(A,2.0); ' ...
  'signal = signal + beta*(2.0*A.*sin(A)+(2.0-power(A,2.0)) .* cos(A)-2.0)./power(A,3.0); ' ...
  'signal = signal + gamma * (-power(A,4.0) .* cos(A) + 4.0*((3.0*power(A,2.0)-6.0).*cos(A)+(power(A,3.0)-6.0*A).*sin(A)+6.0))./power(A,5.0); ' ...
  'signal = 1.0./(1.0+24.0*fp*signal./A); signal(isnan(signal))=0; end'
};
y.Guess     = @(x,signal) [ pi/sum(signal(:).*x(:))*sum(signal(:)) max(max(signal(:)-1),0.01) ];
y = iFunc(y);

if length(varargin)
  y = y(varargin{:});
end

