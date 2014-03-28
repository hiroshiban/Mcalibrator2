classdef il1700
  % !!! BETA QUALITY. PLEASE BE CAREFUL !!!
  %
  % a class to manipulate International Light IL1700 from MATLAB through a serial port connection
  %
  % Created    : "2014-03-28 16:17:19 yamamoto and ban"
  % Last Update: "2014-03-28 16:40:44 ban"

  properties (Hidden) %(SetAccess = protected)
    portname='COM1'; % id of serial port to communicate with CS-100A
    rscom=[];  % serial port object
  end

  properties
    init_flg=0;
  end

  methods

    % constructor
    function obj=il1700(port_name)
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

    % create/open a serial port connection to communicate with IL1700
    function obj=gen_port(obj,port_name)
      if nargin>1 && ~isempty(port_name)
        obj.portname=port_name;
        obj.rscom=serial(obj.portname);
      elseif ~isempty(obj.portname)
        obj.rscom=serial(obj.portname);
      else
        error('set a name of serial port.');
      end

      set(obj.rscom,'DataBits',8,'BaudRate',1200,'Parity','n','StopBits',1,'Terminator','CR/LF');

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

    % initialize IL1700
    function [obj,check,integtime]=initialize(obj,integtime)

      if isempty(obj.rscom), error('serial connection has not been established. run gen_port first.'); end

      % NOTE
      % 'integtime' is a dummy variable to match the format with the other class.
      % It is not used in this function.

      % do nothing
      pause(0.1);

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

      % When the RTS and DTR pins are subsequently set high at any time using the following code,
      % the voltage at the pins will be as expected:
      set (obj.rscom, 'DataTerminalReady' ,'on') ;
      set (obj.rscom, 'RequestToSend' ,'on') ;
      pause(0.5);

      results=fscanf(obj.rscom);

      % set the RTS and DTR pins to low using the following code:
      set (obj.rscom, 'DataTerminalReady' ,'off') ;
      set (obj.rscom, 'RequestToSend' ,'off') ;
      % and pause for some msec
      pause(0.2);
  
      % store the results
      qq=0;
      Y=str2num(results(1:6))*10^str2num(results(7:9)); %#ok
      x=NaN;
      y=NaN;
      return

    end

  end % methods

end % classdef il1700
