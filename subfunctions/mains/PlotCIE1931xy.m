function PlotCIE1931xy(xy,Phosphor,new_fig_flg,tri_flg,color_flg,marker_type)

% Plots CIE1931 xy value(s) with a CIE1931 chromaticity diagram frame.
% function PlotCIE1931xy(xy,:Phosphor,:new_fig_flg,:tri_flg,:color_flg,:marker_type)
% (: is optional)
%
% This function plots CIE1931 xy value(s) with a CIE1931 chromaticity diagram frame.
%
% [input]
% xy      : CIE1931 chromaticity value(s), [2 x n] matrix
%           when a empty matrix is given, only CIE1931 xy diagram will be displayed.
% Phosper : a 3 by 3 matrix. Each column is
%           chromaticities and maximum luminance(xyY) of a phosper:
%           [Rx Gx Bx; Ry Gy By; RY GY BY]
% new_fig_flg : if 1,  CIE1931 xy and diagram will be displayed in the new figure window.
%               if 0,  CIE1931 xy and diagram will be displayed in the existing figure window.
%               if -1, the plots will be clear first and redisplayed without any toolbar and menubar
%                      in the existing figure window
%               1 by default
% tri_flg     : if 1, triangle enclosed by 3 phosphor xy values will be displayed, 0 by default
% color_flg   : if 1, CIE 9131 xy color disk will be displayed, 1 by default
% marker_type : if 1, marker='o', if 0, marker='x', 1 by default
%
%
% [output]
% no output variable
% the output will be displayed as a figure
%
%
% Created    : "2012-04-09 21:46:42 ban"
% Last Update: "2013-12-13 09:35:10 ban"

% persistent variables
persistent gen_flg;
persistent hline;
persistent htext;
persistent hdisk;
persistent htri;

% check input variable
if nargin<1, help(mfilename()); return; end
if nargin<2 || isempty(Phosphor)
  % set phosphor xyY values measured at HBRC, Kyoto University, as 'dummy' phosphor data
  Phosphor=[0.68,0.23,0.13; 0.32,0.71,0.075; 51.56,128.30,25.60];
end
if nargin<3 || isempty(new_fig_flg), new_fig_flg=1; end
if nargin<4 || isempty(tri_flg), tri_flg=0; end
if nargin<5 || isempty(color_flg), color_flg=1; end
if nargin<6 || isempty(marker_type), marker_type=1; end

if size(Phosphor,1)~=3 || size(Phosphor,2)~=3
  error('Phosphor should be [Rx Gx Bx; Ry Gy By; RY GY BY]. check input variable.');
end

% generate figure window
if new_fig_flg==1
  figure('Name','CIE1931 Chromaticity Diagram','NumberTitle','off','ToolBar','none','MenuBar','figure');
elseif new_fig_flg==0
  figexist=get(0,'CurrentFigure'); % check whether a figure already exists or not
  if isempty(figexist)
    figure('Name','CIE1931 Chromaticity Diagram','NumberTitle','off','ToolBar','none','MenuBar','figure');
    new_fig_flg=1;
  else
    %set(gcf,'Name','CIE1931 Chromaticity Diagram','NumberTitle','off','ToolBar','none','MenuBar','figure');
    set(gcf,'ToolBar','none','MenuBar','none');
  end
elseif new_fig_flg==-1
  figexist=get(0,'CurrentFigure'); % check whether a figure already exists or not
  if isempty(figexist)
    figure('Name','CIE1931 Chromaticity Diagram','NumberTitle','off','ToolBar','none','MenuBar','figure');
    new_fig_flg=1;
  else
    cla; gen_flg=[];
    set(gcf,'ToolBar','none','MenuBar','none');
  end
else
  error('new_fig_flg should be [0|1|-1]. check input variable.');
end
hold on;

if new_fig_flg==1 || isempty(gen_flg)

  % Load CIE1931 chromaticity diagram, 380-780 nm, 5 nm step.
  c313878xyz=LoadC313878();

  % plot CIE1931 xy diagram's border & texts
  c314070xyz=(c313878xyz((400-380)/5+1:(700-380)/5+1,:))';
  monoc_xyY=XYZ2xyY(c314070xyz);
  monoc_xy=monoc_xyY(1:2,:);  % 400-700 nm, x & y
  hline(1)=plot(monoc_xy(1,:),monoc_xy(2,:),'Color','k','Visible','off');

  [m,n]=size(monoc_xy);
  hline(2)=plot(monoc_xy(1,1:2:n),monoc_xy(2,1:2:n),'ko','MarkerSize',2,'MarkerFaceColor',[0,0,0],'Visible','off');
  hline(3)=line([monoc_xy(1,1),monoc_xy(1,n)],[monoc_xy(2,1),monoc_xy(2,n)],'Color','k','Visible','off');
  dx=0.025;
  % 4steps = 20nm
  htext(1)=text(monoc_xy(1,1)-dx, monoc_xy(2,1), num2str(400),'FontSize',8,'HorizontalAlignment','right','Visible','off');
  htext(2)=text(monoc_xy(1,17)-dx,monoc_xy(2,17),num2str(480),'FontSize',8,'HorizontalAlignment','right','Visible','off');
  htext(3)=text(monoc_xy(1,21)-dx,monoc_xy(2,21),num2str(500),'FontSize',8,'HorizontalAlignment','right','Visible','off');
  htext(4)=text(monoc_xy(1,25)-dx,monoc_xy(2,25),num2str(520),'FontSize',8,'HorizontalAlignment','right','Visible','off');
  htext(5)=text(monoc_xy(1,29)+dx,monoc_xy(2,29),num2str(540),'FontSize',8,'HorizontalAlignment','left','Visible','off');
  htext(6)=text(monoc_xy(1,33)+dx,monoc_xy(2,33),num2str(560),'FontSize',8,'HorizontalAlignment','left','Visible','off');
  htext(7)=text(monoc_xy(1,37)+dx,monoc_xy(2,37),num2str(580),'FontSize',8,'HorizontalAlignment','left','Visible','off');
  htext(8)=text(monoc_xy(1,41)+dx,monoc_xy(2,41),num2str(600),'FontSize',8,'HorizontalAlignment','left','Visible','off');
  htext(9)=text(monoc_xy(1,45)+dx,monoc_xy(2,45),num2str(620),'FontSize',8,'HorizontalAlignment','left','Visible','off');
  htext(10)=text(monoc_xy(1,61)+dx,monoc_xy(2,61),num2str(700),'FontSize',8,'HorizontalAlignment','left','Visible','off');

  % plot CIE1931 color plane
  [cxx,cyy,czz,cCC]=LoadCIE1931xy();
  hdisk=surf(cxx,cyy,czz,cCC,'FaceColor','interp','EdgeColor','none','Visible','off');
  clear cxx cyy czz cCC;

  % plot triangle enclosed by 3 phosphor xy values
  htri(1)=plot(Phosphor(1,1:2),Phosphor(2,1:2),'k-','Visible','off');
  htri(2)=plot(Phosphor(1,2:3),Phosphor(2,2:3),'k-','Visible','off');
  htri(3)=plot(Phosphor(1,[1,3]),Phosphor(2,[1,3]),'k-','Visible','off');
  htri(4)=plot(Phosphor(1,1),Phosphor(2,1),'Marker','o','MarkerSize',10,'MarkerFaceColor','r','MarkerEdgeColor',[0,0,0],'Visible','off');
  htri(5)=plot(Phosphor(1,2),Phosphor(2,2),'Marker','o','MarkerSize',10,'MarkerFaceColor','g','MarkerEdgeColor',[0,0,0],'Visible','off');
  htri(6)=plot(Phosphor(1,3),Phosphor(2,3),'Marker','o','MarkerSize',10,'MarkerFaceColor','b','MarkerEdgeColor',[0,0,0],'Visible','off');

  gen_flg=true;

end % if new_fig_flg==1 || isempty(gen_flg)

% set axis
axis([-0.1 0.9 -0.1 0.9]);
axis('square');
grid on;
xlabel('x');
ylabel('y');
title('CIE 1931 chromaticity diagram');

% set visibility of handle objects
set(hline(1),'Visible','on');
set(hline(2),'Visible','on');
for ii=1:1:10, set(htext(ii),'Visible','on'); end
if color_flg
  set(hline(3),'Visible','off');
  set(hdisk,'Visible','on');
else
  set(hline(3),'Visible','on');
  set(hdisk,'Visible','off');
end
if tri_flg
  for ii=1:1:6, set(htri(ii),'Visible','on'); end
else
  for ii=1:1:6, set(htri(ii),'Visible','off'); end
end

% plot xy values
if ~isempty(xy)
  rgb=xyY2RGB([xy;100*ones(1,size(xy,2))],Phosphor); % get RGB value(s) for input xy(+ dummy Y);
  rgb(rgb>1.0)=1.0;
  rgb(rgb<0.0)=0.0;
  for nn=1:1:size(xy,2)
    if marker_type==1
      plot(xy(1,nn),xy(2,nn),...
           'Marker','o','MarkerSize',10,'MarkerFaceColor',(rgb(:,nn))','MarkerEdgeColor',[0,0,0]);
    else
      plot(xy(1,nn),xy(2,nn),...
           'Marker','x','MarkerSize',10,'Color',[0,0,0]);
    end
  end
end
hold off;

return
