function flicker_horizontal

% Displays color flier for testing display flicker -- horizontal version.
% function flicker_horizontal
%
% Color Flicker Display Test -- horizontal version
% Apr. 2004 Hiroshi Ban
    
    % set array
    X = [1 2 3 4;5 6 7 8;9 10 11 12];
    
    X01 = colorcube(12);
    X02 = [X01(2:12,:); X01(1,:)];
    X03 = [X02(2:12,:); X02(1,:)];
    X04 = [X03(2:12,:); X03(1,:)];
    X05 = [X04(2:12,:); X04(1,:)];
    X06 = [X05(2:12,:); X05(1,:)];
    X07 = [X06(2:12,:); X06(1,:)];
    X08 = [X07(2:12,:); X07(1,:)];
    X09 = [X08(2:12,:); X08(1,:)];
    X10 = [X09(2:12,:); X09(1,:)];
    X11 = [X10(2:12,:); X10(1,:)];
    X12 = [X11(2:12,:); X11(1,:)];
    
    fig = figure('Name','Horizontal Flicker Test','NumberTitle','off','MenuBar','none');
    hold on;
    set(gcf,'DoubleBuffer','on');
    h = image(X); drawnow;
    colormap(X01);
    set(gca,'XTick',[]);
    set(gca,'XTickLabel',[]);
    set(gca,'YTick',[]);
    set(gca,'YTickLabel',[]);
    
    % Run
    t=1;
    wait=1.0;
    
    set(fig,'userdata',wait);
    
    % Buttons
    uicontrol('pos',[20 20 60 20],'string','close','fontsize',9, ...
    'callback','close(gcbf)');
    uicontrol('pos',[20 40 60 20],'string','slower','fontsize',9, ...
    'callback','set(gcbf,''userdata'',sqrt(2)*get(gcbf,''userdata''))');
    uicontrol('pos',[20 60 60 20],'string','faster','fontsize',9, ...
    'callback','set(gcbf,''userdata'',sqrt(0.5)*get(gcbf,''userdata''))');
    uicontrol('pos',[20 80 60 20],'string','stop 10','fontsize',9, ...
    'callback','pause(10)');
    
    % anim
    while ishandle(h)
        % flicker
        t=t+1;
        eval(sprintf('colormap(X%02d);',rem(t,12)+1));
        drawnow;
        pause(get(fig,'userdata'));
    end;

