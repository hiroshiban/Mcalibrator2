function out=ResLibCal_TASview(out)
% ResLibCal_TASview: display the TAS geometry in a figure
%
%  out:  EXP ResLib structure 
%
% Returns:
%   out: full output from ResLibCal, with resolution

if nargin < 1, out = ''; end

if isempty(out)
  out = ResLibCal_Compute;
end

if ~isfield(out, 'resolution') 
  disp([ mfilename ': Input argument does not contain resolution. Skipping.' ]); 
  return
end
if isfield(out, 'EXP');
  EXP = out.EXP;
else
  disp([ mfilename ': Input argument does not contain EXP structure. Skipping.' ])
  return
end
cla;

if iscell(out.resolution)
  i = ceil(length(out.resolution)/2);
  angles    = out.resolution{i}.angles*pi/180;
else
  i = 1;
  angles    = out.resolution.angles*pi/180;
end
% the angles shown on the plot are reversed wrt the one in the computation, due 
% to the choice of the XY frame for plotting. When angle>0 it e.g. increases X
% on the plot whereas it decreases in reality (to the left).
A1 = -angles(1); A2 = -angles(2); A3 = -angles(3); A4 = -angles(4); A5 = -angles(5); A6 = -angles(6);
distances = EXP.arms(1:4);
x = 0; y = 0; direction=0;

x0=x; y0=y;
% plot the Source --------------------------------------------------------------
translate = 0; rotate = 0*(pi/180);
direction = direction+rotate;
x = x+translate*sin(direction);
y = y+translate*cos(direction);

% create a square source
X = [ -EXP.beam.width/2  -EXP.beam.width/2   EXP.beam.width/2  EXP.beam.width/2  -EXP.beam.width/2];
Z = [  EXP.beam.height/2 -EXP.beam.height/2 -EXP.beam.height/2 EXP.beam.height/2  EXP.beam.height/2];
Y = zeros(1,5)+0;
l=line(X+x,Y+y,Z); 
t=text(X(1)+x,Y(1)+y,Z(1),'Beam/Source'); 
set([ l t ],'Color','blue');

x0=x; y0=y;
% plot the Monochromator -------------------------------------------------------
translate = distances(1); rotate = 0;
direction = direction+rotate;
x = x+translate*sin(direction);
y = y+translate*cos(direction);
l=line([ x x0 ], [y y0], [ 0 0 ]); set(l,'Color','cyan', 'LineStyle','--');

% create a square Monochromator
X = [ -EXP.mono.width/2  -EXP.mono.width/2   EXP.mono.width/2   EXP.mono.width/2  -EXP.mono.width/2]*sin(A1);
Z = [  EXP.mono.height/2 -EXP.mono.height/2 -EXP.mono.height/2  EXP.mono.height/2  EXP.mono.height/2];
Y = X*cos(A1);
l=line(X+x,Y+y,Z); 
t=text(X(1)+x,Y(1)+y,Z(1),'Monochromator'); 
set([ l t ],'Color','red');

x0=x; y0=y;
% plot the Sample --------------------------------------------------------------
translate=distances(2); rotate = A2;
direction = direction+rotate;
x = x+translate*sin(direction);
y = y+translate*cos(direction);
l=line([ x x0 ], [y y0], [ 0 0 ]); set(l,'Color','cyan', 'LineStyle','--');

% create a rotated square Sample
X = [ -EXP.sample.width/2  -EXP.sample.width/2   EXP.sample.width/2  EXP.sample.width/2  -EXP.sample.width/2]*sin(A3);
Z = [  EXP.sample.height/2 -EXP.sample.height/2 -EXP.sample.height/2 EXP.sample.height/2  EXP.sample.height/2];
Y = X*cos(A3);
l1=line(X+x,Y+y,Z); 
t=text(X(1)+x,Y(1)+y,Z(1),'Sample');
X = [ -EXP.sample.depth/2  -EXP.sample.depth/2   EXP.sample.depth/2  EXP.sample.depth/2  -EXP.sample.depth/2]*sin(A3+pi/2);
Z = [  EXP.sample.height/2 -EXP.sample.height/2 -EXP.sample.height/2 EXP.sample.height/2  EXP.sample.height/2];
Y = X*cos(A3+pi/2);
l2=line(X+x,Y+y,Z);
set([ l1 l2 t ],'Color','green');

x0=x; y0=y;
% plot the Analyzer ------------------------------------------------------------
translate = distances(3); rotate = A4;
direction = direction+rotate;
x = x+translate*sin(direction);
y = y+translate*cos(direction);
l=line([ x x0 ], [y y0], [ 0 0 ]); set(l,'Color','cyan', 'LineStyle','--');

% create a square
X = [ -EXP.ana.width/2  -EXP.ana.width/2   EXP.ana.width/2  EXP.ana.width/2  -EXP.ana.width/2]*sin(A5);
Z = [  EXP.ana.height/2 -EXP.ana.height/2 -EXP.ana.height/2 EXP.ana.height/2  EXP.ana.height/2];
Y = X*cos(A5);
l=line(X+x,Y+y,Z);
t=text(X(1)+x,Y(1)+y,Z(1),'Analyzer');
set([ l t ],'Color','magenta');

x0=x; y0=y;
% plot the Detector ------------------------------------------------------------
translate = distances(4); rotate = A6;
direction = direction+rotate;
x = x+translate*sin(direction);
y = y+translate*cos(direction);
l=line([ x x0 ], [y y0], [ 0 0 ]); set(l,'Color','cyan', 'LineStyle','--');

% create a square
X = [ -EXP.detector.width/2  -EXP.detector.width/2   EXP.detector.width/2  EXP.detector.width/2  -EXP.detector.width/2];
Z = [  EXP.detector.height/2 -EXP.detector.height/2 -EXP.detector.height/2 EXP.detector.height/2  EXP.detector.height/2];
Y = zeros(1,5)+0;
l=line(X+x,Y+y,Z);
t=text(X(1)+x,Y(1)+y,Z(1),'Detector');
set([ l t ],'Color','black');

% add contextual menu ----------------------------------------------------------
H   = EXP.QH; K=EXP.QK; L=EXP.QL; W=EXP.W;
if length(H) > 1, H=H(ceil(length(H)/2)); end
if length(K) > 1, K=K(ceil(length(K)/2)); end
if length(L) > 1, L=L(ceil(length(L)/2)); end
if length(W) > 1, W=W(ceil(length(W)/2)); end

if EXP.infin==-1, l = 'KI'; else l='KF'; end

t = { sprintf('%s=%g [Angs^{-1}] QH=%5.3g QK=%5.3g QL=%5.3g [rlu] E=%5.3g [meV]', l, EXP.Kfixed, H,K,L,W), ...
      sprintf('A1=%5.3g A2=%5.3g A3=%5.3g A4=%5.3g A5=%5.3g A6=%5.3g [deg]', angles*180/pi) };
title(t);

if isempty(findall(gcf,'Tag','ResLibCal_TASView_Context'))
  %finalize 3D plot
  box on; grid on;
  view(3); 
  xlabel('x [cm]'); ylabel('y [cm]'); zlabel('z [cm]');
  daspect([ 1 1 1]);
  
  uicm = uicontextmenu;
  uimenu(uicm, 'Label','Toggle grid', 'Callback','grid');
  uimenu(uicm, 'Label','Reset Flat/3D View', 'Callback', [ ...
      '[tmp_a,tmp_e]=view; if (tmp_a==0 & tmp_e==90) view(3); else view(2); end;' ...
      'clear tmp_a tmp_e;' ]);
  set(gca, 'UIContextMenu', uicm, 'Tag','ResLibCal_TASView_Context');
    uimenu(uicm, 'Label','Toggle Perspective','Callback', 'if strcmp(get(gca,''Projection''),''orthographic'')  set(gca,''Projection'',''perspective''); else set(gca,''Projection'',''orthographic''); end');
end
