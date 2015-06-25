function [fig_id,success]=DisplayColorWindow(rgb,fullscr_flg,fig_id,scr_num)

% Displays a color patch window (using MATLAB-native figure) with specific RGB values.
% function [fig_id,success]=DisplayColorWindow(rgb,:fullscr_flg,:fig_id,:scr_num)
% (: is optional)
%
% This function displays a color window with specific RGB values
%
% [input]
% rgb         : color (RGB) to be displayed
%               [gray_scale], [r,g,b], (color display mode), 999 (adjust_mode), or -999 (close fig_id)
% fullscr_flg : whether displaying the window in
%               full-screen mode, [0|1], 1 by default
% fig_id      : figure handle, e.g. fig_id=figure;
%
% [output]
% fig_id      : a handle of the generated figure
% success     : if 1, display will be done without any problem. if 0, failed
%
%
% Created    : "2012-04-06 07:25:53 ban"
% Last Update: "2015-01-20 13:34:36 ban"

% persistent/global variable
persistent hpush;
%hpush=[];

% check input variables
if nargin<1, help(mfilename()); fig_id=[]; success=0; return; end
if nargin<2 || isempty(fullscr_flg), fullscr_flg=1; end
% nargin 3, fig_id will be set later
if nargin<4 || isempty(scr_num), scr_num=1; end

try

  % set adjust or color-display mode
  adjust_mode=0;
  if numel(rgb)==1 && rgb==999
    adjust_mode=1;
  elseif numel(rgb)==1 && rgb==-999
    if ~isempty(fig_id), close(fig_id); fig_id=[]; success=1; end
    return
  elseif numel(rgb)==1
    rgb=repmat(rgb,1,3);
  end
  if max(rgb)>1, rgb=rgb./255; end

  % adjust screen size
  scrsz=get(0,'MonitorPosition');
  if scr_num>size(scrsz,1)
    disp('scr_num exceeds the actual number of screens. using the first screen...');
    scr_num=1;
  end
  scrsz=scrsz(scr_num,:);
  scrsz(3)=scrsz(3)-scrsz(1)+1; % horizontal display offset
  scrsz(4)=scrsz(4)-scrsz(2)+1; % vertical display offset
  if ~fullscr_flg
    scrpos=[scrsz(3)/4,scrsz(4)/4-offset,2*scrsz(3)/4,2*scrsz(4)/4];
  else
    scrpos=scrsz;
  end

  % display window
  if adjust_mode

    if nargin<3 || isempty(fig_id)
      fig_id=figure('Name','Adjust Focus, press "Adjust OK" to proceed',...
                    'NumberTitle','off',...
                    'Position',scrpos,...
                    'ToolBar','none',...
                    'MenuBar','none',...
                    'Color',[1,1,1],...
                    'Visible','on');
    else
      set(fig_id,'Name','Adjust Focus, press "Adjust OK" to proceed',...
                 'NumberTitle','off',...
                 'Position',scrpos,...
                 'ToolBar','none',...
                 'MenuBar','none',...
                 'Color',[1,1,1],...
                 'Visible','on');
    end
    plot([0,1],[0,1],'Color',[0,0,0],'LineWidth',1.5); hold on;
    plot([0,1],[1,0],'Color',[0,0,0],'LineWidth',1.5); hold on;
    plot([0,1],[0.5,0.5],'Color',[0,0,0],'LineWidth',1.5); hold on;
    plot([0.5,0.5],[0,1],'Color',[0,0,0],'LineWidth',1.5); hold on;

    width=[0.05,0.25,0.5,0.25*sqrt(2),0.125*sqrt(2)];
    for ii=1:1:numel(width)
      plot([width(ii),width(ii)]+0.5,[-width(ii),width(ii)]+0.5,'Color',[0,0,0],'LineWidth',1.5); hold on;
      plot([-width(ii),-width(ii)]+0.5,[-width(ii),width(ii)]+0.5,'Color',[0,0,0],'LineWidth',1.5); hold on;
      plot([-width(ii),width(ii)]+0.5,[width(ii),width(ii)]+0.5,'Color',[0,0,0],'LineWidth',1.5); hold on;
      plot([-width(ii),width(ii)]+0.5,[-width(ii),-width(ii)]+0.5,'Color',[0,0,0],'LineWidth',1.5); hold on;
    end
    for ii=1:1:3
      plot(width(ii)*cos(0.0:0.01:2*pi)+0.5,width(ii)*sin(0.0:0.01:2*pi)+0.5,'Color',[0,0,0],'LineWidth',1.5); hold on;
    end
    plot(0.5,0.5,'Marker','o','MarkerSize',12,'MarkerEdgeColor',[1,0,0],'LineWidth',2); hold on;

    set(gca,'Position',[0,0,1,1]);
    set(gca,'XTickLabel',[]);
    set(gca,'YTickLabel',[]);
    %axis equal;

    % put clear user-interface
    hpush=uicontrol(gcf,'Style','pushbutton','String','Adjust OK','Position',[20 150 100 70]);
    %set(hpush,'Callback',sprintf('cla;axis off;set(gco,''Visible'',''off'');DisplayColorWindow([255,255,255],%f,%f);',...
    %                             fullscr_flg,fig_id));
    %set(hpush,'Callback','close(gcf);');
    set(hpush,'Callback','set(gcf,''Visible'',''off'')');
    uicontrol(hpush);

  else % if adjust_mode

    if nargin<3 || isempty(fig_id)
      fig_id=figure('Name',sprintf('Color Window: [R,G,B]=[%.3f,%.3f,%.3f]',rgb),...
                    'NumberTitle','off',...
                    'Position',scrpos,...
                    'ToolBar','none',...
                    'MenuBar','none',...
                    'Color',rgb,...
                    'Visible','on');
    else
      set(fig_id,'Name',sprintf('Color Window: [R,G,B]=[%.3f,%.3f,%.3f]',rgb),...
                 'NumberTitle','off',...
                 'Position',scrpos,...
                 'ToolBar','none',...
                 'MenuBar','none',...
                 'Color',rgb,...
                 'Visible','on');
    end
    cla;
    if ~isempty(hpush), set(gco,'Visible','off'); end
    axis off;

  end

  set(fig_id,'Visible','on','Position',scrpos); % to focus on the figure window
  success=1;

catch ME

  display(ME);
  fig_id=[];
  success=0;

end % try

return
