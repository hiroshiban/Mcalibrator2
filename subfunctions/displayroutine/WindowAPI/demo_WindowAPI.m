function demo_WindowAPI
% Demo for WindowAPI
% The function WindowAPI has grown to an universal super tool. Unfortunately
% this reduces the readability of the help section. Therefore I've created this
% function to demonstrate the usage of all features.
%
% Author: Jan Simon, Heidelberg, (C) 2008-2016 matlab.THISYEAR(a)nMINUSsimon.de

% $JRev: R-g V:006 Sum:t/JmEwfh8W4x Date:09-Oct-2011 02:42:27 $
% $License: BSD (use/copy/change/redistribute on own risk, mention the author) $
% $File: Tools\UnitTests_\demo_WindowAPI.m $

% Initialize: ==================================================================
delay = 1.0;  % Seconds between effects

% Do the work: =================================================================
fprintf('== %s:\n', mfilename);

% Search the compiled C-Mex file:
clear('WindowAPI');
MexVersion     = WindowAPI();
whichWindowAPI = which(MexVersion);
if isempty(whichWindowAPI)
   error(['JSimon:', mfilename, ':MissingMex'], ...
      ['*** %s: WindowAPI.mex is not found in the path.\n', ...
      '    Try to compile it again.'], mfilename);
end
fprintf('Using: %s\n\n', whichWindowAPI);

try
   % Create a figure to operate on: --------------------------------------------
   % The OpenGL renderer is confused by the alpha blending, so Painters is used:
   disp('  Create a figure:');
   FigH   = figure('Color', ones(1, 3), 'Renderer', 'Painters');
   FigPos = get(FigH, 'Position');
   axes('Visible', 'off', 'Units', 'normalized', 'Position', [0, 0, 1, 1]);
   TextH = text(0.5, 0.5, ' Demo: WindowAPI ', ...
      'Units',    'normalized', ...
      'FontSize', 20, ...
      'HorizontalAlignment', 'center', ...
      'BackgroundColor',     [0.4, 0.9, 0.0], ...
      'Margin',   12);
   
   % Move figure to 2nd monitor - on a single monitor setup this request should
   % be ignored silently:
   disp('  Try to move figure to 2nd monitor, if existing:');
   pause(delay);
   WindowAPI(FigH, 'Position', FigPos, 2);
   WindowAPI(FigH, 'ToMonitor');  % If 2nd monitor has different size
   pause(delay);
   
   % Get info about current monitor:
   disp('  Get info of monitor of the figure:');
   Info = WindowAPI(FigH, 'Monitor');
   disp(Info);
   pause(delay);
   
   % Set topmost status:
   disp('  Set figure to topmost, no topmost and to front:');
   WindowAPI(FigH, 'topmost');   % Command is not case-sensitive
   drawnow;
   WindowAPI(FigH, 'TopMost', 0);
   drawnow;
   WindowAPI(FigH, 'front');
   drawnow;
   
   % Nicer to have the figure on topmost for the rest of the demo:
   WindowAPI(FigH, 'topmost');
   
   % Minimize, maximize:
   disp('  Minimize, maximize, restore former size, get current status:');
   WindowAPI(FigH, 'minimize');
   disp(['    ', WindowAPI(FigH, 'GetStatus')]);
   pause(delay);
   
   WindowAPI(FigH, 'restore');
   disp(['    ', WindowAPI(FigH, 'GetStatus')]);
   pause(delay);
   
   WindowAPI(FigH, 'maximize');
   disp(['    ', WindowAPI(FigH, 'GetStatus')]);
   pause(delay);
   
   WindowAPI(FigH, 'restore');
   pause(delay);
   
   % Get the position:
   disp('  Get window position relative to nearest monitor:');
   Location = WindowAPI(FigH, 'Position');
   disp(Location);
   pause(delay);
   
   % Partial maximizing:
   disp('  Maximize horizontally or vertically only:');
   WindowAPI(FigH, 'xmax');
   pause(delay);
   WindowAPI(FigH, 'Position', Location.Position, Location.MonitorIndex);
   pause(delay);
   WindowAPI(FigH, 'ymax');
   pause(delay);
   
   disp('  Move back to 1st monitor:');
   WindowAPI(FigH, 'Position', Location.Position, 1);
   WindowAPI(FigH, 'ToMonitor');
   pause(delay);
   
   % Special maximizing such that the inner figure fill the screen:
   disp('  Maximize inner figure position to work size:');
   disp('  (Taskbar and sidebar are not concealed...)');
   WindowAPI(FigH, 'Position', 'work');
   pause(delay);
   disp('  Maximize inner figure position to full monitor:');
   WindowAPI(FigH, 'Position', 'full');  % Complete monitor
   pause(delay);
   
   % Maximize the outer position, which is similar to the standard maximization:
   disp('  Maximize the outer position of the figure:');
   disp('  (The window title and menu bar is visible)');
   WindowAPI(FigH, 'OuterPosition', 'work');
   pause(delay);
   WindowAPI(FigH, 'OuterPosition', 'full');  % Complete monitor
   pause(delay);
   
   % Move to screen and test using the HWnd handle:
   disp('  Move back to visible area automatically:');
   disp('  (OS Window handle "HWnd" is used, not working for inner position!)');
   HWnd = WindowAPI(FigH, 'GetHWnd');
   WindowAPI(HWnd, 'OuterPosition', [-100, -100, FigPos(3:4)]);
   pause(delay);
   WindowAPI(HWnd, 'ToMonitor');
   pause(delay);
   
   % Short flashing:
   disp('  A short flash of the window border:');
   WindowAPI(FigH, 'Flash');
      
   % Disable the figure:
   disp('  Disable the figure - no user intection possible:');
   WindowAPI(FigH, 'Enable', 0);
   pause(delay);
   WindowAPI(FigH, 'Enable', 1);
   
   disp('  Hide the buttons:');
   WindowAPI(FigH, 'Button', false);
   pause(delay);
   WindowAPI(FigH, 'Button', true);
   
   % If a UICONTROL is activated, the figure does *not* gain the focus back by
   % the command "figure(FigH)" in Matlab 5.3 to 2009a (or higher) - in contrary
   % to the documentation!
   disp('  Set the keyboard focus:');
   disp('  (The Matlab command "figure(FigH)" is not relialble)');
   WindowAPI(FigH, 'SetFocus');
   
   % Alpha blending and stencil color:
   disp('  Semi-transparent sphere without visible figure');
   % Painters or ZBuffer as renderer! OpenGL draws black figures sometimes.
   AxesH = axes('Units', 'pixels', 'Position', FigPos);
   sphere;
   set(AxesH, 'Visible', 'off', 'CameraViewAngle', 30);
   WindowAPI(FigH, 'Position', 'work');
   WindowAPI(FigH, 'Clip');  % No border on neighboring monitors
   WindowAPI(FigH, 'topmost');
   
   % NOTE: depending on the graphics hardware not all RGB values are working,
   % because the pixel colors can be sampled to 555 or 565 bits, especially on
   % laptops. At least 0, and 255 are always regonized, so prefer [255,255,0] or
   % similar colors:
   StencilRGB = [255, 255, 255];
   
   WindowAPI(FigH, 'Alpha', 0.7, StencilRGB);
   for angle = 40:-2:5
      set(AxesH, 'CameraViewAngle', angle);
      drawnow;
   end
   
   disp('  Release the memory used for alpha-blending (important!):');
   WindowAPI(FigH, 'Opaque');
   delete(AxesH);
   
   % Clip visible region:
   disp('  Clip window border ("splash screen"):');
   WindowAPI(FigH, 'Position', FigPos);
   WindowAPI(FigH, 'Clip');
   pause(delay);
   
   disp('  Clip specified rectangle:');
   set(TextH, 'Units', 'pixels', 'ButtonDownFcn', @cleanup, ...
      'String',    ' Click to escape! ', ...
      'Margin',    10, ...
      'EdgeColor', [0.2, 0.7, 0.0], ...
      'LineWidth', 2);
   pos = round(get(TextH, 'Extent')) + [-12, -11, 22, 22];
   WindowAPI(FigH, 'Clip', pos);
   
   % Lock mouse position:
   WindowAPI(FigH, 'LockCursor', pos);
   
   fprintf('\n  ready.   CLICK ON THE BOX TO DELETE IT!\n\n');
   
catch
   fprintf('\n%s crashed: %s\n\n', mfilename, lasterr);
   
   WindowAPI('UnlockCursor');
   delete(FigH);
end

% return;

% ******************************************************************************
function cleanup(ObjH, EventData)  %#ok<INUSD>
% Smooth fading.

FigH = ancestor(ObjH, 'figure');

% Unlock the cursor:
WindowAPI(FigH, 'LockCursor', 0);
% or: WindowAPI(FigH, 'LockCursor');
% or: WindowAPI('UnlockCursor');

% Fade out:
for alpha = linspace(1, 0, 20)
   WindowAPI(FigH, 'Alpha', alpha);
   pause(0.03);
end
delete(gcbf);

fprintf('%s: Goodbye\n', mfilename);

% return;
