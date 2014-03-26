function [fig_id,success]=DisplayColorWindowPTB10Bit(rgb,fullscr_flg,fig_id,scr_num)

% Displays a color patch window (using Psychtoolbox Screen() function) with specific RGB values (force 10-bit color depth precision).
% function [fig_id,success]=DisplayColorWindowPTB10Bit(rgb,:fullscr_flg,:fig_id,:scr_num)
% (: is optional)
%
% displays a Psychtoolbox color window with specific RGB values (force to use 10-bit color depth precision)
%
% [input]
% rgb         : color (RGB) to be displayed
%               [gray_scale], [r,g,b], (color display mode), 999 (adjust_mode), or -999 (close fig_id)
% fullscr_flg : whether displaying the window in
%               full-screen mode, [0|1], 1 by default
%               !!!NOTICE!!!
%               if fig_is is set and the previous window is not full-screen,
%               this option will be disabled
% fig_id      : figure handle, e.g. fig_id=figure;
% scr_num     : screen ID (for dual display setting etc), scr_num=1,2,..., 1 by default
%
% [output]
% fig_id      : a handle of the generated figure
% success     : if 1, display will be done without any problem. if 0, failed
%
%
% Created    : "2012-04-09 22:56:39 ban"
% Last Update: "2014-03-26 15:10:50 ban"

warning off; %#ok

% persistent/global variable
persistent ptbwindow;
persistent disableJIS;

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
    if ~isempty(fig_id), Screen('Close',fig_id); ShowCursor(); fig_id=[]; success=1; end
    return
  elseif numel(rgb)==1
    rgb=repmat(rgb,1,3);
  end
  if max(rgb)>1.0, rgb=rgb./255; end % scaling 0.0<=rgb<=1.0

  % adjust screen size
  if scr_num>numel(Screen('Screens'))
    disp('scr_num exceeds the actual number of screens. using the first screen...');
    scr_num=1;
  end
  scrsz=Screen(scr_num-1,'Rect');
  if ~fullscr_flg
    scrpos=[scrsz(3)/4,scrsz(4)/4,scrsz(3)/4+2*scrsz(3)/4,scrsz(4)/4+2*scrsz(4)/4];
  else
    scrpos=[];
  end

  %% configure Psychtoolbox Screen

  % check OS (Windows or the others)
  is_windows=false;
  winstr=mexext(); winstr=winstr(end-2:end);
  if strcmpi(winstr,'w32') || strcmpi(winstr,'w64'), is_windows=true; end

  % Disable JIS key trouble & initialize key codes
  if isempty(disableJIS) || disableJIS==0
    [keyIsDown,secs,keyCode]=KbCheck();
    DisableKeysForKbCheck(find(keyCode>0));
    KbName('UnifyKeyNames');
    disableJIS=1;
  end

  % initialize a main PTB window
  if nargin<3 || isempty(fig_id)
    % set debug level, black screen during calibration
    Screen('Preference','VisualDebuglevel',3);

    % reset display gamma-function
    ResetDisplayGammaPTB();

    % force to 10-bit display output
    AssertOpenGL();
    PsychImaging('PrepareConfiguration');
    PsychImaging('AddTask','General','FloatingPoint32BitIfPossible'); % try to get 32 bpc fload precision if the hardware supports
    PsychImaging('AddTask','General','EnableNative10BitFramebuffer'); % enable 10-bit color depth (generally for ATI graphic cards, but also effective for some nVidia cards)

    % open PTB window
    if is_windows
      [ptbwindow,ptbrect]=PsychImaging('OpenWindow',scr_num-1,[255,255,255],scrpos); % decrement 1 from scr_num as PTB screen ID starts from 0.
    else
      [ptbwindow,ptbrect]=PsychImaging('OpenWindow',scr_num,[255,255,255],scrpos); % decrement 1 from scr_num as PTB screen ID starts from 0.
    end
    fig_id=ptbwindow;
  else
    ptbwindow=fig_id;
    try
      ptbrect=Screen('Rect',ptbwindow);
    catch %#ok
      error('PTB screen corresponding to fig_id is not opend.');
    end
  end

  % set the PTB runnning priority to MAX
  Priority(MaxPriority(ptbwindow,'WaitBlanking'));

  % display adjust frame or RGB
  if adjust_mode

    % draw adjust frames
    Screen('DrawLine',ptbwindow,[0,0,0],0,0,ptbrect(3),ptbrect(4),2);
    Screen('DrawLine',ptbwindow,[0,0,0],0,ptbrect(4),ptbrect(3),0,2);

    Screen('DrawLine',ptbwindow,[0,0,0],0,ptbrect(4)/2,ptbrect(3),ptbrect(4)/2,2);
    Screen('DrawLine',ptbwindow,[0,0,0],ptbrect(3)/2,0,ptbrect(3)/2,ptbrect(4),2);

    Screen('FrameRect',ptbwindow,[0,0,0],CenterRect([0,0,ptbrect(3:4)./sqrt(2)],ptbrect),2);
    Screen('FrameRect',ptbwindow,[0,0,0],CenterRect([0,0,ptbrect(3:4)./2./sqrt(2)],ptbrect),2);
    Screen('FrameRect',ptbwindow,[0,0,0],CenterRect([0,0,ptbrect(3:4)./6],ptbrect),2);
    Screen('FrameRect',ptbwindow,[0,0,0],CenterRect([0,0,ptbrect(3:4)./2],ptbrect),2);

    Screen('FrameOval',ptbwindow,[0,0,0],CenterRect(ptbrect./2,ptbrect),2);
    Screen('FrameOval',ptbwindow,[0,0,0],CenterRect(ptbrect./6,ptbrect),2);
    Screen('FrameOval',ptbwindow,[0,0,0],ptbrect,2);

    Screen('FrameOval',ptbwindow,[255,0,0],CenterRect([0,0,18,18],ptbrect),2);

    %test message
    text_message='Press ENTER/SPACE to proceed or ESC/q to terminate this PTB window';
    DrawFormattedText(ptbwindow,text_message,'center',scrsz(4)/8,0);

  else

    %Screen('FillRect',ptbwindow,rgb,ptbrect);

    % display the target color with float precision (0.0-1.0)
    ctex=Screen('MakeTexture',ptbwindow,reshape(rgb,[1,1,3]),0,0,2);
    Screen('DrawTexture',ptbwindow,ctex,[],ptbrect);
    Screen('Close',ctex);
  end

  % hide mouse cursor
  HideCursor();

  % flip the screen
  Screen('DrawingFinished',ptbwindow,0,1);
  Screen('Flip', ptbwindow,[],0,[],1);
  success=1;

  % stay until the ENTER key is pressed
  if adjust_mode
    outcode=1; while outcode~=-1, outcode=check_observer_response(); end
    Screen('CloseAll');
    ShowCursor();

    % % clear the frames
    % frameid=Screen('OpenOffscreenWindow',ptbwindow,[255,255,255],ptbrect);
    % Screen('CopyWindow',frameid,ptbwindow,ptbrect,ptbrect);
    % Screen('DrawingFinished',ptbwindow,0,1);
    % Screen('Flip', ptbwindow,[],0,[],1);
  end

catch ME

  ShowCursor();
  display(ME);
  disableJIS=[];
  fig_id=[];
  success=0;

end

return


%% subfunction

function outcode=check_observer_response()

[keyIsDown,keysecs,keyCode]=KbCheck;
outcode = 1;

if keyIsDown

  if (keyCode(KbName('q'))==1) || (keyCode(KbName('escape'))==1) % quit events - Q key or ESC
    Priority(0);
    ShowCursor;
    Screen('CloseAll');
    outcode = -1;
    finish;
    return
  elseif (keyCode(KbName('return'))==1) || (keyCode(KbName('space'))==1)
    outcode = -1;
  end

end % keyIsDown

return
