classdef dummy_colorimeter
  % a class of a dummy colorimeter to be used for debugging Mcalibrator2
  %
  % Created    : "2012-04-11 09:23:57 ban"
  % Last Update: "2014-04-10 13:44:25 ban"

  properties (Hidden) %(SetAccess = protected)
    portname='COM1'; % id of serial port (dummy)
    rscom=[];  % serial port object
  end

  properties
    init_flg=0;
  end

  methods

    % constructor
    function obj=dummy_colorimeter(port_name)
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
      if nargin>1 && ~isempty(port_name), obj.portname=port_name; end
      obj.rscom=[];
      obj.init_flg=1;
    end

    % reset a serial port connection
    function obj=reset_port(obj)
      obj.rscom=[];
      obj.init_flg=0;
    end

    % initialize (dummy)
    function [obj,check,integtime]=initialize(obj,integtime)
      check = 0;
    end

    % measure CIE1931 xyY of the target
    function [qq,Y,x,y,obj]=measure(obj,integtime)
      if nargin<2 || isempty(integtime), integtime=500; end %#ok
      % return all dummy codes
      qq=0;
      Y=50;
      x=0.3;
      y=0.3;
    end

  end % methods

end % classdef dummy_colorimeter
