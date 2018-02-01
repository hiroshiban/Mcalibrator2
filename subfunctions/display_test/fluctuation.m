function fluctuation

% Creates fluctuated L-shaped membrane animation for testing display flickers and ghost.
% function fluctuation
%
% for display fluctuation checking
%
% wriiten by Hiroshi Ban
%
% reference: vibs.m 
%   Copyright 1984-2001 The MathWorks, Inc.
%   $Revision: 5.13 $  $Date: 2001/04/15 12:02:53 $

% This demonstration solves the wave equation for the vibrations
% of an L-shaped membrane.  The solution is expressed as a linear
% combination, with time-dependent coefficients, of two-dimensional
% spatial eigenfunctions.  The eigenfunctions are computed during
% initialization by the function MEMBRANE.  The first of these
% eigenfunctions, the fundamental mode, is the MathWorks logo.
%
% The L-shaped geometry is of particular interest mathematically because
% the stresses approach infinity near the reentrant corner.  Conventional
% finite difference and finite element methods require considerable
% time and storage to achieve reasonable accuracy.  The approach used
% here employs Bessel functions with fractional order to match the
% corner singularity.

% Open-GL
opengl neverselect;

% Eigenvalues.
lambda = [9.6397238445, 15.19725192, 2*pi^2, ...
    29.5214811, 31.9126360, 41.4745099, 44.948488, ...
    5*pi^2, 5*pi^2, 56.709610, 65.376535, 71.057755];

% Eigenfunctions
for k = 1:12
   L{k} = membrane(k);
end

% Get coefficients from eigenfunctions.
for k = 1:12
    c(k) = L{k}(25,23)/3;
end
 
% Set graphics parameters.
fig = figure('Name','Fluctuation Test','NumberTitle','off','MenuBar','none');
set(gcf,'DoubleBuffer','on');
set(fig,'color','k')
x = (-15:15)/15;
h = surf(x,x,L{1});
[a,e] = view; view(a+270,e);
axis([-1 1 -1 1 -1 1]);
set(gca,'View',[0 90]);
caxis(26.9*[-1.5 1]);
%colormap(hot);
colormap(hsv);
axis off

% Buttons
uicontrol('pos',[20 20 60 20],'string','close','fontsize',9, ...
   'callback','close(gcbf)');
uicontrol('pos',[20 40 60 20],'string','slower','fontsize',9, ...
   'callback','set(gcbf,''userdata'',sqrt(0.5)*get(gcbf,''userdata''))');
uicontrol('pos',[20 60 60 20],'string','faster','fontsize',9, ...
   'callback','set(gcbf,''userdata'',sqrt(2.0)*get(gcbf,''userdata''))');
uicontrol('pos',[20 80 60 20],'string','rotate','fontsize',9, ...
   'callback','set(gca,''View'',[90 0]+get(gca,''View''))');
uicontrol('pos',[20 100 60 20],'string','stop 10','fontsize',9, ...
    'callback','pause(10)');

% Run
t = 0;
dt = 0.025;
set(fig,'userdata',dt)
while ishandle(fig)
    % Coefficients
    dt = get(fig,'userdata');
    t = t + dt;
    s = c.*sin(sqrt(lambda)*t);

    % Amplitude
    A = zeros(size(L{1}));
    for k = 1:12
      A = A + s(k)*L{k};
    end

    % Velocity
    s = lambda .*s;
    V = zeros(size(L{1}));
    for k = 1:12
      V = V + s(k)*L{k};
    end
    V(16:31,1:15) = NaN;
    
    % Surface plot of height, colored by velocity.
    set(h,'zdata',A,'cdata',V);
    drawnow
end;

