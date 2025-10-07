classdef cs150 < handle
  % A class to manipulate Konica Minolta CS-150
  % by launching and controlling a custom-made C# server executable.
  % This class and the following methods will work only on the "Windows" OS.
  %
  % [usage]
  % % launching server and connect to the colorimeter
  % photometer = cs150();
  % photometer.gen_port();
  %
  % % setting the integration time
  % photometer.set_integration_time(0.5);
  %
  % % run measurement
  % [Y, x, y] = photometer.measure();
  % fprintf('Measurement with 0.5s integration:\n');
  % fprintf('  Luminance: %.4f cd/m^2, xy: (%.4f, %.4f)\n\n', Y, x, y);
  %
  % % close the server
  % clear photometer;
  %
  %
  % Created    : "2025-09-25 12:40:30 ban"
  % Last Update: "2025-10-07 18:18:19 ban"

  properties (SetAccess = private)
    port_name='COM1';  % a dummy variable for consistency with the other functions.
    rscom=[];          % a dummy variable for consistency with the other functions.
    process=[];      % Handle for the external C# process
    inputStream=[];  % Stream to send commands to the C# server
    outputStream=[]; % Stream to receive results from the C# server
    init_flg=false;
  end

  methods
    % constructor
    function obj=cs150(port_name)
      disp('Starting CS-150 measurement server...');

      % setting a path to cs150server.exe
      serverDir=fileparts(mfilename('fullpath'));
      serverPath=fullfile(serverDir,'cs150server','cs150server.exe');

      if ~exist(serverPath,'file')
        error('cs150server.exe not found at the expected location: %s', serverPath);
      end

      try
        % launch the external exe file by using .NET Process class.
        psInfo=System.Diagnostics.ProcessStartInfo(serverPath);
        psInfo.UseShellExecute=false;
        psInfo.RedirectStandardInput=true;  % redirecting the standard input
        psInfo.RedirectStandardOutput=true; % redirecting the standard output
        psInfo.CreateNoWindow=true;         % madking the console window invisible

        obj.process=System.Diagnostics.Process.Start(psInfo);

        % get streams for sending/receiving commands
        obj.inputStream=obj.process.StandardInput;
        obj.outputStream=obj.process.StandardOutput;

        % wait until the server is launched.
        pause(1.0);
        disp('Measurement server started.');

        if nargin==1 && ~isempty(port_name)
          obj.port_name=port_name;
        end

      catch ME
        error('Failed to start Cs150Server.exe. %s', ME.message);
      end
    end

    % destructor
    function delete(obj)
      if ~isempty(obj.process) && ~obj.process.HasExited
        disp('Shutting down measurement server...');
        % terminating command
        obj.inputStream.WriteLine('EXIT');
        % waiting for the termination of the prcesess
        obj.process.WaitForExit(3000); % for 3 sec
        obj.process.Close();
        disp('Server shut down.');

        % Here, we should unload the .NET assemby...However, accourding to MathWorks support site...
        % Rebooting is the only solution to this problem for the current Matlab Version (8.1.0.604, R2013a):
        % "The ability to unload an assembly is not available in MATLAB at this point of time. This may be
        % addressed in one of the future releases. Currently, to work around this issue, restart MATLAB."
        %
        % Therefore, we don't do anything
      end
    end

    % connect
    function obj=gen_port(obj,port_name)
      if nargin>1 && ~isempty(port_name), obj.port_name=port_name; end
      if obj.init_flg, disp('Already connected.'); return; end

      % sending 'CONNECT' command
      obj.inputStream.WriteLine('CONNECT');
      % receiving the reaction from the server
      response=char(obj.outputStream.ReadLine());

      parts=strsplit(response,',');
      if strcmp(parts{1},'SUCCESS')
        obj.init_flg=true;
        fprintf('Successfully connected: %s\n', parts{2});
      else
        error('Connection failed: %s', response);
      end
    end

    % reset a serial port connection
    function obj=reset_port(obj)
      obj.rscom=[];
      obj.init_flg=0;
      obj.disconnect();
    end

    % initialize CS-150
    function [obj,check,integtime]=initialize(obj,integtime)
      if nargin<2 || isempty(integtime), integtime=0.4; end

      % Sets the integration time of the CS-150.
      %
      % arugments:
      %   time: Can be a number (in seconds) for manual mode,
      %         or the string 'auto' for automatic mode.

      if ~obj.init_flg
        error('Not connected. Call connect() first.');
      end

      % making command string
      if isnumeric(integtime) && integtime > 0
        % command example: "INTEG 2"
        command = sprintf('INTEG %f',integtime);
      elseif ischar(integtime) && strcmpi(integtime,'auto')
        command = 'INTEG AUTO';
      else
        error('Invalid input. Time must be a positive number or the string ''auto''.');
      end

      % sending the generated command
      obj.inputStream.WriteLine(command);
      % receiving the reaction from the server
      response=char(obj.outputStream.ReadLine());

      % check the response
      if ~startsWith(response,'SUCCESS')
        check = 1;
        error('Failed to set integration time: %s', response);
      else
        check = 0;
        disp('Integration time set successfully.');
      end
    end

    % measure
    function [qq,Y,x,y,obj]=measure(obj,integtime)
      if nargin<2 || isempty(integtime), integtime=0.4; end

      if ~obj.init_flg
        error('Not connected. Call connect() first.');
      end

      % sending the 'MEASURE' command
      obj.inputStream.WriteLine('MEASURE');
      % receiving the reaction from the server
      response=char(obj.outputStream.ReadLine());

      parts=strsplit(response, ',');
      if strcmp(parts{1},'SUCCESS')
        Y=str2double(parts{2});
        x=str2double(parts{3});
        y=str2double(parts{4});
        qq=0;
      else
        Y=NaN; x=NaN; y=NaN;
        error('Measurement failed: %s', response);
        qq=1;
      end
    end

    % backlight
    function backlight(obj,mode)
      if nargin<2 || isempty(mode), mode=1; end

      if ~obj.init_flg
        error('Not connected. Call connect() first.');
      end

      % sending the 'MEASURE' command
      if mode==1
        obj.inputStream.WriteLine('BACKLIGHTON');
      else % if mode==0
        obj.inputStream.WriteLine('BACKLIGHTOFF');
      end

      % receiving the reaction from the server
      response=char(obj.outputStream.ReadLine());
      % check the response
      if ~startsWith(response,'SUCCESS')
        error('Failed to set backlight: %s', response);
      else
        disp('backlight set successfully.');
      end
    end

    % disconnect
    function disconnect(obj)
      if obj.init_flg
        obj.inputStream.WriteLine('DISCONNECT');
        obj.init_flg = false;
        obj.rscom=[];
        disp('Disconnected.');
      end
    end

  end % methods

end % classdef cs150
