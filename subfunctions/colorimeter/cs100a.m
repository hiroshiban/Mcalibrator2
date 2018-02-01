classdef cs100a
  % a class to manipulate MINOLTA CS-100A from MATLAB through a serial port connection
  %
  % Created    : "2012-04-11 09:23:57 ban"
  % Last Update: "2016-09-13 18:19:02 ban"

  properties (Hidden) %(SetAccess = protected)
    portname='COM1'; % id of serial port to communicate with CS-100A
    rscom=[];  % serial port object
  end

  properties
    init_flg=0;
  end

  methods

    % constructor
    function obj=cs100a(port_name)
      if nargin==1 && ~isempty(port_name)
        obj.portname=port_name;
      end
    end

    % destructor
    function obj=delete(obj)
      if ~isempty(obj.rscom)
        fclose(obj.rscom);
        delete(obj.rscom);
        obj.rscom=[];
        obj.init_flg=0;
      end
    end

    % create/open a serial port connection to communicate with CS-100A
    function obj=gen_port(obj,port_name)
      if nargin>1 && ~isempty(port_name)
        obj.portname=port_name;
        obj.rscom=serial(obj.portname);
      elseif ~isempty(obj.portname)
        obj.rscom=serial(obj.portname);
      else
        error('set a name of serial port.');
      end

      set(obj.rscom,'DataBits',7,'BaudRate',4800,'Parity','even','StopBits',2,'Terminator','CR/LF');

      fopen(obj.rscom);

      % NEW for MATLAB R14
      % After initializing the serial port using FOPEN,
      % you should set the RTS and DTR pins to low using the following code:
      set (obj.rscom, 'DataTerminalReady' ,'off') ;
      set (obj.rscom, 'RequestToSend' ,'off') ;
      % and pause for some msec
      pause(0.3);

      % When the RTS and DTR pins are subsequently set high at any time using the following code,
      % the voltage at the pins will be as expected:
      set (obj.rscom, 'DataTerminalReady' ,'on') ;
      set (obj.rscom, 'RequestToSend' ,'on') ;
      
      obj.init_flg=1;
    end

    % reset a serial port connection
    function obj=reset_port(obj)
      fclose(obj.rscom);
      delete(obj.rscom);
      obj.rscom=[];
      obj.init_flg=0;
    end

    % initialize CS-100A
    function [obj,check,integtime]=initialize(obj,integtime)

      if isempty(obj.rscom), error('serial connection has not been established. run gen_port first.'); end

      % NOTICE 1
      %
      % First, you must confirm electric (electrical) power supply 'OFF'.
      % Then, press 'ON' button of the CS-100A, pushing 'F' key.
      % Check whether the character 'c' was shown on the bottom right corner of the CS-100A display.
      % Through these process, CS-100A will be set as bothway communications mode.

      % NOTICE 2
      % 'integtime' is a dummy variable to match the format with the other class.
      % It is not used in this function.

      fprintf(obj.rscom, 'MDS,07'); % Set Up Measurement Parameters.
      pause(0.1);

      % Checking setting parameters.
      results=fgets(obj.rscom);

      if ~strcmp(results(1:4),'OK00')
        disp('setup error. check CS-100A and cable connections.');
        return;
      end

      % Format -MDS
      %             'MDS,[][]'
      %               00 : MINOLTA Standard Calibration Mode
      %               01 : Optional Calibration Mode
      %               04 : Chromaticity Measurement Mode
      %               05 : Color Difference Measurement Mode
      %               06 : Measurement Response Time --- 100ms Fast Mode
      %               07 : Measurement Response Time --- 400ms Slow Mode

      % Error Check Command Description
      %               ER00 : Command Error, or Parameters Error
      %               ER11 : Memory Values Error
      %               ER20 : EEPROM Error
      %               ER30 : Battely Out Error

      fprintf(obj.rscom, 'MDS,04'); % Set Up Measurement Parameters.
      pause(0.1);

      % Checking setting parameters.
      results=fgets(obj.rscom);

      if strcmp(results(1:4),'OK00')
        check = 0;
      else
        check = 1;
      end
    end

    % measure CIE1931 xyY of the target
    function [qq,Y,x,y,obj]=measure(obj,integtime)

      if isempty(obj.rscom), error('serial connection has not been established. run gen_serial first.'); end
      if nargin<2 || isempty(integtime), integtime=500; end %#ok

      % NOTICE 1
      % Terminator (delimiter) should be CR/LF (CR+LF).
      % This terminator was set by CreateSerialObjectMINOL.

      % NOTICE 2
      % 'integtime' is a dummy variable to match the format with the other class.
      % It is not used in this function.

      fprintf(obj.rscom, 'MES'); % Measure Light Under Conditions defined by the 'MDS' command line.
      pause(0.1);

      % Format -MES
      %       output : normal
      %                   'OK00,+[][][][][][],+.[][][][],+.[][][][]'
      %                     notice : here, + may chage to -
      %              : luminance and chromaticity over the measurement range
      %                   'ER10'
      %              : chromaticity over the measurement range
      %                   'OK11,+[][][][][][],+.0000,+.0000'
      %                     notice : here, + may chage to -
      %              : luminance over the measurement range
      %                   'OK12,-999999,+.[][][][],+.[][][][]'
      %                     notice : here, + may chage to -
      %              : values are over the display or maasurement range
      %                   'ER12'
      %              : luminance under the masurement range
      %                   'OK13,+[][][][][][],+.[][][][],+.[][][][]'
      %                     notice : here, + may chage to -

      results=fscanf(obj.rscom);
      %if strcmp(results(1:4),'OK00')
        qq=0;
        Y=str2num(results(6:12)); %#ok
        x=str2num(results(14:19)); %#ok
        y=str2num(results(21:26)); %#ok
        return
      %end

      % numretry=1; qq=1;
      % while numretry<=5 && qq~=0
      %   numretry=numretry+1;
      %   if strcmp(results(1:4),'OK00')
      %     Y=str2num(results(6:12)); %#ok
      %     x=str2num(results(14:19)); %#ok
      %     y=str2num(results(21:26)); %#ok
      %     qq=0;
      %   else
      %     if strcmp(results(1:4),'OK12')
      %       fprintf(obj.rscom, 'MDS,06'); % fast mode
      %       fscanf(obj.rscom); % clear data
      %     elseif strcmp(results(1:4),'OK13')
      %       fprintf(obj.rscom, 'MDS,07'); % slow mode
      %       fscanf(obj.rscom); % clear data
      %     end
      %     pause(0.1);
      %     fprintf(obj.rscom, 'MES');
      %     pause(0.1);
      %     results=fscanf(obj.rscom);
      %   end
      % end
      % 
      % if numretry>5
      %   Y=str2num(results(6:12)); %#ok
      %   x=str2num(results(14:19)); %#ok
      %   y=str2num(results(21:26)); %#ok
      % end

      % Descriptions
      % qq                  : Measurement quality code (OK00 = O.K.)
      % U                   : Unit of Measured Luminace, always 0 with CS-100A
      % Y                   : +(-)[][][][][][] 1931 CIE Y (units indicated by U)
      % x                   : +(-).[][][][] 1931 CIE x
      % y                   : +(-).[][][][] 1931 CIE y
    end

  end % methods

end % classdef cs100a
