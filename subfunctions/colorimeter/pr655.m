classdef pr655
  % a class to manipulate PhotoResearch PR-655 from MATLAB through a (virtual)
  % serial port connection and Psychtoolbox 3 utilities.
  %
  % * Acknowledgments *
  % Almost all the codes or subrountines below are from Psychtoolbox3's PR655 tools.
  % We would like to deeply express our appreciations for the developers of the tools.
  %
  % [dependency]
  % Psychtoolbox 3, for MEX IOPort and GetSecs fucntions
  %
  % [methods in this class]
  % obj=pr655()   : a constructor
  % obj=delete()  : a destructor
  % obj=gen_port(port_name) : build a port to communicate with PhotoResearch PR-655
  % obj=reset_port()        : reset a communication port
  % [obj,check,integtime]=initialize(integtime) : initialize a communication port
  % [qq,Y,x,y,obj]=measure(obj,integtime) : measure and get CIE 1931 xyY values
  %
  %
  % Created    : "2018-03-26 11:27:37 ban"
  % Last Update: "2018-03-26 11:30:11 ban"

  properties (Hidden) %(SetAccess = protected)
    portname='COM1'; % id of serial port to communicate with PR-655
    rscom=[];  % serial port object
  end

  properties
    init_flg=0;
  end

  methods

    % constructor
    function obj=pr655(port_name)
      if nargin>1 && ~isempty(port_name)
        obj.portname=port_name;
      end
    end

    % destructor
    function obj=delete(obj)
      if ~isempty(obj.rscom)
        % exit Remote Mode
        PR655write('Q');

        % close and clear serial port
        if ~isempty(obj.rscom)
          IOPort('close',obj.rscom);
          obj.rscom=[];
        end
        obj.init_flg=0;
      end
    end

    % create/open a serial port connection to communicate with PR-655
    function obj=gen_port(obj,port_name)
      if nargin>1 && ~isempty(port_name)
        obj.portname=port_name;
      elseif isempty(obj.port_name)
        error('set a name of serial port.');
      end

      % IOPort has above port settings 9600 baud, no parity, 8 data bits,
      % 1 stopbit, no handshake (aka FlowControl=none) already as
      % built-in defaults, so no need to pass them:
      oldverbo=IOPort('Verbosity', 2);
      if IsOSX
        % Must flush on write, ie., not don't flush on write, at least with PR655
        % on OSX 10.10, as reported in forum message #19808 for more reliable
        % connections:
        obj.rscom=IOPort('OpenSerialPort',obj.portname,'Lenient DontFlushOnWrite=0');
      else
        % On at least Linux (status on Windows is unknown atm.), we must not flush
        % on write - the opposite of OSX behaviour (see forum msg thread #15565):
        obj.rscom=IOPort('OpenSerialPort',obj.portname,'Lenient DontFlushOnWrite=1');
      end
      IOPort('Verbosity',oldverbo);

      % put in Remote Mode --No [CR] after 'PHOTO'
      cmd='PHOTO';
      for ii=1:1:numel(cmd), IOPort('write',obj.rscom,cmd(ii)); end

      % check whether PR655 is now in Remote Mode
      StartTime=GetSecs();
      retval=[];
      while isempty(retval) && GetSecs()-StartTime<10, retval=PR655read(); end

      obj.init_flg=1;
    end

    % reset a serial port connection
    function obj=reset_port(obj)
      % exit Remote Mode
      PR655write('Q');

      % close and clear serial port
      if ~isempty(obj.rscom)
        IOPort('close',obj.rscom);
        obj.rscom=[];
      end
      obj.init_flg=0;
    end

    % initialize PR-655
    function [obj,check,integtime]=initialize(obj,integtime)

      if isempty(obj.rscom), error('serial connection has not been established. run gen_port first.'); end

      % commands to be sent to PR655 for initialization should be given as below
      % 'SU***' : Unit
      % 'SE***' : Esposure
      % 'SN***' : N samples
      % 'SO***' : CIE observer
      % 'SS***' : Sync mode
      % 'SK***' : Freqency

      cmd{1}='SU1';                     % U: unit, 1 = cd/m^2
      cmd{2}=sprintf('SE%d',integtime); % E: exposure
      cmd{3}='SS1';                     % S: sync mode

      for ii=1:1:length(cmd)
        PR655write(cmd{ii});
        check=str2num(PR655read());
        if ~check
          disp(['Error: could not write ',cmdStr,' to PR-655. Config aborted.'])
          %return
        end
      end

      PR655write('D601'); % get current state of PR-655 and return string
      dummy=PR655read(); %#ok
    end

    % measure CIE1931 xyY of the target
    function [qq,Y,x,y,obj]=measure(obj,integtime)

      if isempty(obj.rscom), error('serial connection has not been established. run gen_port first.'); end
      if nargin<2 || isempty(integtime), integtime=500; end

      % Initialize
      timeout=30;

      % See if we can sync to the source
      % and set sync mode appropriately.
      syncFreq=PR655getsyncfreq();
      if ~isempty(syncFreq) && syncFreq~=0
        PR655write('SS1');
      else
        PR655write('SS0');
        disp('Warning: Could not sync to source.');
      end

      numretry=1; qq=1;
      x=NaN; y=NaN; Y=NaN;
      while numretry<=5 && qq>0
        PR655write(sprintf('SE%d',integtime)); % set integration time

        % Make measurement and get the string;
        readStr=PR655rawxyz(timeout);

        % Check returned data.
        idx=findstr(readStr,',');
        qq=str2num(readStr(1:idx(1)-1));

        % Check for other error conditions
        if qq==-1 || qq==10
          %disp('Low light level during measurement');
          %disp('Setting returned value to zero');
          xyz=zeros(3,1);
        elseif qq==0
          units=str2num(readStr(idx(1)+1:idx(2)-1));
          if units~=0
            error('Units not returned as cd/m2');
          end
          xyz=str2num(readStr(idx(2)+1:end))';
        elseif qq==18 % too low
          integtime=min(integtime*2,6000);
        elseif qq==19 % too high
          integtime=max(round(integtime/2),50);
        end

        x=xyz(1)./sum(xyz);
        y=xyz(2)./sum(xyz);
        Y=xyz(2);
      end
    end

  end % methods

  methods (Access='private');

    % a subroutine adapted from PTB3's tool for this class and Mcalibrator2
    function PR655write(obj,cmd)
      % Check for Terminator and add if necessary
      if cmd(end)~=char(13), cmd=[cmdStr,char(13)]; end

      % Write sequence of chars to PR655
      for ii=1:1:length(cmd)
        IOPort('write',obj.rscom,upper(cmd(ii)));
        pause(0.05);
      end
    end

    % a subroutine adapted from PTB3's tool for this class and Mcalibrator2
    function serialData=PR655read(obj)
      % Look for any data on the serial port.
      serialData=char(IOPort('read',obj.rscom));

      % If data exists keep reading off the port until there's nothing left.
      if ~isempty(serialData)
        tmpData=1;
        while ~isempty(tmpData)
          WaitSecs(0.050);
          tmpData=char(IOPort('read',obj.rscom));
          serialData=[serialData,tmpData]; %#ok<AGROW>
        end
      end
    end

    % a subroutine adapted from PTB3's tool for this class and Mcalibrator2
    function syncFreq=PR655getsyncfreq(obj)

      if isempty(obj.rscom), error('serial connection has not been established. run gen_port first.'); end

      % Initialize
      timeout=30;

      % Flushing buffers
      dump='0';
      while ~isempty(dump), dump=PR655read(); end

      % Make measurement
      PR655write('F')

      StartTime=GetSecs();
      waited=GetSecs()-StartTime;
      inStr=[];
      while isempty(inStr) && waited<timeout
        inStr=PR655read();
        waited=GetSecs()-StartTime;
      end
      if waited>=timeout
        error('No response after measure command');
      end
      readStr=inStr;

      % Parse return
      qual=-1;
      [raw,count]=sscanf(readStr,'%f,%f',2);
      if count==2
        qual=raw(1);
        syncFreq=raw(2);
      end

      if qual~=0, syncFreq = []; end
    end

    % a subroutine adapted from PTB3's tool for this class and Mcalibrator2
    function readStr=PR655rawxyz(obj,timeout)

      if isempty(obj.rscom), error('serial connection has not been established. run gen_port first.'); end

      % Flushing buffers.
      dump='0';
      while ~isempty(dump), dump=PR655read(); end

      % Make measurement
      PR655write('M2')
      StartTime=GetSecs();
      waited=GetSecs()-StartTime;
      inStr=[];
      while isempty(inStr) && waited<timeout
        inStr=PR655read();
        waited=GetSecs()-StartTime;
      end

      if waited==timeout
        error('Unable to get reading from radiometer');
      else
        readStr=inStr;
      end
    end

  end % methods (Access='private');

end % classdef pr655
