function grating_irregular

% Create irregular spatial frequency gratings for testing display flickers.
% function grating_irregular
%
% Test your display with grating spatial frequency
% random version
% Apr. 27 H.Ban

    % Open-GL
    opengl neverselect;

    fig = figure('Name','Irregular Grating Test','NumberTitle','off','MenuBar','none');
    hold on;
    set(gcf,'DoubleBuffer','on');
    
    % axis & view
    set(gca,'View',[0 90]);
    set(gca,'XTick',[]);
    set(gca,'XTickLabel',[]);
    set(gca,'YTick',[]);
    set(gca,'YTickLabel',[]);
    
    global hh; hh = uicontrol('pos',[260 180 60 60],'string',' ','BackgroundColor',[1 1 1],'Visible','off');
    set(hh,'Units','normalized');
    
    % parameters
    wait=1.0;
    
    set(fig,'userdata',wait);
    
    wl=1;
    step=1;
    y = create_sine(wl,step);

    % plotting
    %h=surf(Y);
    h=mesh(y);
    colormap gray;
    shading interp;
    drawnow;
    
    % Buttons
    uicontrol('pos',[20 20 60 20],'string','close','fontsize',9, ...
   'callback','close(gcbf)');
    uicontrol('pos',[20 40 60 20],'string','rotate','fontsize',9, ...
   'callback','set(gca,''View'',[90 0]+get(gca,''View''))');
    uicontrol('pos',[20 60 60 20],'string','slower','fontsize',9, ...
    'callback','set(gcbf,''userdata'',sqrt(2)*get(gcbf,''userdata''))');
    uicontrol('pos',[20 80 60 20],'string','faster','fontsize',9, ...
    'callback','set(gcbf,''userdata'',sqrt(0.5)*get(gcbf,''userdata''))');
    uicontrol('pos',[20 100 60 20],'string','stop 10','fontsize',9, ...
    'callback','pause(10)');
    uicontrol('pos',[20 120 60 20],'string','Hide','fontsize',9, ...
    'callback','global hh; set(hh,''Visible'',''off'')');
    uicontrol('pos',[20 140 60 20],'string','Show','fontsize',9, ...
    'callback','global hh; set(hh,''Visible'',''on'')');

    % anim
    while ishandle(h)
        % move
        y=[y(:,90:length(y)) y(:,1:89)];
        %mesh(y);
        set(h,'zdata',y,'cdata',y);
        drawnow;
        pause(get(fig,'userdata'));
    end;

