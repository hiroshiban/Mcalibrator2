function y=dho(varargin)
% y = dho(p, x, [y]) : Damped harmonic oscillator
%
%   iFunc/dho Damped harmonic oscillator fitting function, including Bose factor.
%     y=p(1)*p(3) *p(2)^2.*(1+1./(exp(abs(x)/p(5))-1))./((x.^2-p(2)^2).^2+(p(3)*x).^2)
%
% Reference: B. Fak, B. Dorner / Physica B 234-236 (1997) 1107-1108
%
% input:  p: Damped harmonic oscillator model parameters (double)
%            p = [ Amplitude Centre HalfWidth BackGround Temperature(in x units)]
%          or 'guess'
%         x: axis (double)
%         y: when values are given and p='guess', a guess of the parameters is performed (double)
% output: y: model value
% ex:     y=dho([1 0 1 1], -10:10); or y=plot(dho);
%
% Version: $Revision: 1035 $
% See also iData, iFunc/fits, iFunc/plot

y.Name       = [ 'Damped-harmonic-oscillator (1D) [' mfilename ']' ];
y.Description='Damped harmonic oscillator S(q,w) fitting function. Ref: B. Fak, B. Dorner / Physica B 234-236 (1997) 1107-1108';
y.Parameters = {'Amplitude one phonon structure factor Zq=exp(-2W)|Q.e|²/2M','Centre renormalized frequency Omega_q','HalfWidth phonon linewidth Gamma_q','Background','Temperature kT in "x" unit'};
y.Expression = @(p,x) (1./(exp(x/p(5))-1)+1)*p(1)*4.*x*p(3)/pi./((x.^2-p(2)^2).^2 + 4*x.^2*p(3)^2) + p(4);
y.Dimension  = 1;
% moments of distributions
m1 = @(x,s) sum(s(:).*x(:))/sum(s(:));
m2 = @(x,s) sqrt(abs( sum(x(:).*x(:).*s(:))/sum(s(:)) - m1(x,s).^2 ));

y.Guess     = @(x,s) [ NaN m1(x, s-min(s(:))) m2(x, s-min(s(:))) NaN 1 ];

y = iFunc(y);

if length(varargin)
  y = y(varargin{:});
end
