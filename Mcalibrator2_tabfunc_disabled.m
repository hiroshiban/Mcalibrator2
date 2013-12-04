function varargout = Mcalibrator2_tabfunc_disabled(varargin)

  % function varargout = Mcalibrator2_tabfunc_disabled(varargin)
  %
  % MCALIBRATOR2_TABFUNC_DISABLED M-file for Mcalibrator2_tabfunc_disabled.fig
  %      MCALIBRATOR2_TABFUNC_DISABLED, by itself, creates a new MCALIBRATOR2_TABFUNC_DISABLED or raises the existing
  %      singleton*.
  %
  %      H = MCALIBRATOR2_TABFUNC_DISABLED returns the handle to a new MCALIBRATOR2_TABFUNC_DISABLED or the handle to
  %      the existing singleton*.
  %
  %      MCALIBRATOR2_TABFUNC_DISABLED('CALLBACK',hObject,eventData,handles,...) calls the local
  %      function named CALLBACK in MCALIBRATOR2_TABFUNC_DISABLED.M with the given input arguments.
  %
  %      MCALIBRATOR2_TABFUNC_DISABLED('Property','Value',...) creates a new MCALIBRATOR2_TABFUNC_DISABLED or raises the
  %      existing singleton*.  Starting from the left, property value pairs are
  %      applied to the GUI before Mcalibrator2_tabfunc_disabled_OpeningFcn gets called.  An
  %      unrecognized property name or invalid value makes property application
  %      stop.  All inputs are passed to Mcalibrator2_tabfunc_disabled_OpeningFcn via varargin.
  %
  %      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
  %      instance to run (singleton)".
  %
  % See also: GUIDE, GUIDATA, GUIHANDLES
  %
  % Edit the above text to modify the response to help Mcalibrator2_tabfunc_disabled
  %
  % Last Modified by GUIDE v2.5 04-Dec-2013 16:12:41
  %
  %
  % Created    : "2012-04-13 07:36:14 ban"
  % Last Update: "2013-12-04 16:13:58 ban (ban.hiroshi@gmail.com)"
  % <a
  % href="mailto:ban.hiroshi+mcalibrator@gmail.com">email to Hiroshi Ban</a>

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % functions for initializing Mcalibrator2_tabfunc_disabled GUI
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % add path to subfunctions
  addpath(genpath(fullfile(fileparts(mfilename('fullpath')),'subfunctions')));

  % change directory to the Mcalibrator2_tabfunc_disabled directory
  tgt=mfilename('fullpath'); %which('Mcalibrator2');
  cd(fileparts(tgt));

  % Begin initialization code - DO NOT EDIT
  gui_Singleton = 1;
  gui_State = struct('gui_Name',       mfilename, ...
                     'gui_Singleton',  gui_Singleton, ...
                     'gui_OpeningFcn', @Mcalibrator2_tabfunc_disabled_OpeningFcn, ...
                     'gui_OutputFcn',  @Mcalibrator2_tabfunc_disabled_OutputFcn, ...
                     'gui_LayoutFcn',  [] , ...
                     'gui_Callback',   []);
  if nargin && ischar(varargin{1})
      gui_State.gui_Callback = str2func(varargin{1});
  end

  if nargout
      [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
  else
      gui_mainfcn(gui_State, varargin{:});
  end
  % End initialization code - DO NOT EDIT


% --- Executes just before Mcalibrator2_tabfunc_disabled is made visible.
function Mcalibrator2_tabfunc_disabled_OpeningFcn(hObject, eventdata, handles, varargin)

  % This function has no output args, see OutputFcn.
  % hObject    handle to figure
  % eventdata  reserved - to be defined in a future version of MATLAB
  % handles    structure with handles and user data (see GUIDATA)
  % varargin   command line arguments to Mcalibrator2_tabfunc_disabled (see VARARGIN)

  global tabhandle;

  % add path to subfunctions
  addpath(genpath(fullfile(fileparts(mfilename('fullpath')),'subfunctions')));

  % Choose default command line output for Mcalibrator2_tabfunc_disabled
  handles.output = hObject;

  % Update handles structure
  guidata(hObject, handles);

  % UIWAIT makes Mcalibrator2_tabfunc_disabled wait for user response (see UIRESUME)
  % uiwait(handles.figure1);

  % set text message
  set(handles.information_uipanel,'Title','Welcome to Mcalibrator2');
  strings=load_information_strings;
  set(handles.information_text,'FontAngle','normal','FontName','Tahoma','FontSize',10.0,'FontUnits','pixels','String',[{'This is Mcalibrator2 config panel.',''},strings{1}]);

  % disable some tabs when opening Mcalibrator2_tabfunc_disabled
  tabselectionfcn(hObject,'McalibratorTab',2:4,'off');
  tabhandle=hObject;


% --- Outputs from this function are returned to the command line.
function varargout = Mcalibrator2_tabfunc_disabled_OutputFcn(hObject, eventdata, handles)

  % Get default command line output from handles structure
  varargout{1} = handles.output;


% --- Outputs from this function are returned to the command line.
%function varargout = Mcalibrator2_DeleteFcn(hObject, eventdata, handles)
function varargout = Mcalibrator2_DeleteFcn(hObject, eventdata, handles)

  global colorimeterhandler; %#ok
  global displayhandler; %#ok

  % remove path
  tgt=fileparts(mfilename('fullpath')); %fileparts(which('Mcalibrator2'));
  rmpath(genpath(fullfile(tgt,'subfunctions')));

  % delete object
  delete colorimeterhandler;
  delete displayhandler;

  % clear global variables
  clear global all;
  clear persistent all;
  clear all;
  close all;
  clear mex;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% functions for config tab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% these are empty, just required to handle GUI
function date_edit_Callback(hObject, eventdata, handles)
function repetition_edit_Callback(hObject, eventdata, handles)
function red_radiobutton_Callback(hObject, eventdata, handles)
function green_radiobutton_Callback(hObject, eventdata, handles)
function blue_radiobutton_Callback(hObject, eventdata, handles)
function gray_radiobutton_Callback(hObject, eventdata, handles)
function magenda_radiobutton_Callback(hObject, eventdata, handles)
function yellow_radiobutton_Callback(hObject, eventdata, handles)
function cyan_radiobutton_Callback(hObject, eventdata, handles)
function flare_correction_radiobutton_Callback(hObject, eventdata, handles)


% these are a kind of dummy functions, just required to handle GUI
function apparatus_popupmenu_Callback(hObject, eventdata, handles)
function apparatus_popupmenu_CreateFcn(hObject, eventdata, handles)
  if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
  end
  % set colorimeter names to GUI
  colorimeters=colorimeter_list();
  str_colorimeter=[];
  for ii=1:1:length(colorimeters), str_colorimeter=[str_colorimeter,colorimeters{ii}(1)]; end %#ok
  set(hObject,'String',str_colorimeter);
  set(hObject,'Value',1);


function display_routine_popupmenu_Callback(hObject, eventdata, handles)
function display_routine_popupmenu_CreateFcn(hObject, eventdata, handles)
  if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
  end


function sampling_popupmenu_Callback(hObject, eventdata, handles)
function sampling_popupmenu_CreateFcn(hObject, eventdata, handles)
  if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
  end


function interval_popupmenu_Callback(hObject, eventdata, handles)
function interval_popupmenu_CreateFcn(hObject, eventdata, handles)
  if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
  end


function lutoutbit_popupmenu_Callback(hObject, eventdata, handles)
function lutoutbit_popupmenu_CreateFcn(hObject, eventdata, handles)
  if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
  end


function gathermethod_popupmenu_Callback(hObject, eventdata, handles)
function gathermethod_popupmenu_CreateFcn(hObject, eventdata, handles)
  if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
  end


% main procedures
function manageConfigTab(handles,state)

  % state : 'on' or 'off'
  set(handles.date_edit,'Enable',state);
  set(handles.apparatus_popupmenu,'Enable',state);
  set(handles.display_routine_popupmenu,'Enable',state);
  set(handles.sampling_popupmenu,'Enable',state);
  set(handles.interval_popupmenu,'Enable',state);
  set(handles.lutoutbit_popupmenu,'Enable',state);
  set(handles.repetition_edit,'Enable',state);
  set(handles.gathermethod_popupmenu,'Enable',state);
  set(handles.red_radiobutton,'Enable',state);
  set(handles.green_radiobutton,'Enable',state);
  set(handles.blue_radiobutton,'Enable',state);
  set(handles.gray_radiobutton,'Enable',state);
  set(handles.magenda_radiobutton,'Enable',state);
  set(handles.yellow_radiobutton,'Enable',state);
  set(handles.cyan_radiobutton,'Enable',state);
  set(handles.flare_correction_radiobutton,'Enable',state);


function manageMeasureTab(handles,state)

  % state : 'on' or 'off'
  set(handles.scr_num_edit,'Enable',state);
  set(handles.com_num_edit,'Enable',state);
  set(handles.pos_adjust_pushbutton,'Enable',state);
  set(handles.create_serial_pushbutton,'Enable',state);
  set(handles.reset_serial_pushbutton,'Enable',state);
  set(handles.initialize_pushbutton,'Enable',state);
  set(handles.measure_pushbutton,'Enable',state);


function manageLUTTab(handles,state)

  % state : 'on' or 'off'
  set(handles.curvefitting_pushbutton,'Enable',state);
  set(handles.fitting_popupmenu,'Enable',state);
  set(handles.create_lut_pushbutton,'Enable',state);
  set(handles.check_lut_pushbutton,'Enable',state);
  set(handles.easycheck_togglebutton,'Enable',state);


function manageColorTab(handles,state)

  % state : 'on' or 'off'
  set(handles.load_phospher_pushbutton,'Enable',state);
  set(handles.use_LUT_radiobutton,'Enable',state);
  set(handles.use_RGB_radiobutton,'Enable',state);
  set(handles.xyY_edit,'Enable',state);
  set(handles.RGB_edit,'Enable',state);
  set(handles.xyY_RGB_convert_pushbutton,'Enable',state);
  set(handles.load_text_pushbutton,'Enable',state);
  set(handles.calculator_method_popupmenu,'Enable',state);
  set(handles.calculator_measure_pushbutton,'Enable',state);
  set(handles.results_xyY_edit,'Enable',state);
  set(handles.results_RGB_edit,'Enable',state);
  set(handles.calculator_view_pushbutton,'Enable',state);
  set(handles.calculator_save_pushbutton,'Enable',state);


function param=setparam(handleobject)

  tmp=get(handleobject,'String');
  id=get(handleobject,'value');
  param.name=tmp{id};
  param.id=id;


function config_ok_togglebutton_Callback(hObject, eventdata, handles)

  global tabhandle;
  global config;
  global colorimeterhandler;
  global displayhandler;

  if get(handles.config_ok_togglebutton,'Value')

    % enable some tabs
    tabselectionfcn(tabhandle,'McalibratorTab',2:4,'on');
    manageConfigTab(handles,'off');
    manageMeasureTab(handles,'on');
    manageLUTTab(handles,'on');
    manageColorTab(handles,'on');

    % store the current configurations and save them to a file
    config.date=get(handles.date_edit,'String');

    config.apparatus=setparam(handles.apparatus_popupmenu);
    config.display_routine=setparam(handles.display_routine_popupmenu);
    config.sampling=setparam(handles.sampling_popupmenu);
    config.interval=setparam(handles.interval_popupmenu);
    config.lutoutbit=setparam(handles.lutoutbit_popupmenu);

    config.repetition=setparam(handles.gathermethod_popupmenu);
    config.repetition.num=get(handles.repetition_edit,'String');

    config.usered=get(handles.red_radiobutton,'Value');
    config.usegreen=get(handles.green_radiobutton,'Value');
    config.useblue=get(handles.blue_radiobutton,'Value');
    config.usegray=get(handles.gray_radiobutton,'Value');
    config.usemagenda=get(handles.magenda_radiobutton,'Value');
    config.useyellow=get(handles.yellow_radiobutton,'Value');
    config.usecyan=get(handles.cyan_radiobutton,'Value');
    config.flare_correction=get(handles.flare_correction_radiobutton,'Value');

    % set object/function handler
    colorimeters=colorimeter_list();
    if isempty(colorimeterhandler)
      colorimeterhandler=eval(sprintf('%s;',colorimeters{config.apparatus.id}{2}));
    elseif isstructmember(colorimeterhandler,'init_flg')
      if colorimeterhandler.init_flg==0
        colorimeterhandler=eval(sprintf('%s;',colorimeters{config.apparatus.id}{2}));
      else
        colorimeterhandler.reset_port();
        delete colorimeterhandler;
        colorimeterhandler=eval(sprintf('%s;',colorimeters{config.apparatus.id}{2}));
      end
    else
      colorimeterhandler=eval(sprintf('%s;',colorimeters{config.apparatus.id}{2}));
    end
    if colorimeters{config.apparatus.id}{3}==0 % serial connection
      set(handles.com_text,'String','Serial');
      set(handles.com_num_edit,'String','COM1');
      %set(handles.com_num_edit,'Enable','on');
      %set(handles.create_serial_pushbutton,'Enable','on');
      %set(handles.reset_serial_pushbutton,'Enable','on');
    elseif colorimeters{config.apparatus.id}{3}==1 % USB connection
      set(handles.com_text,'String','USB');
      set(handles.com_num_edit,'String','USB port');
      set(handles.com_num_edit,'Enable','off');
      %set(handles.create_serial_pushbutton,'Enable','off');
      %set(handles.reset_serial_pushbutton,'Enable','off');
    else
      set(handles.information_text,'String',...
          'Currently, only [0(SERIAL)|1(USB)] can be accepted as the third variable of colorimeter_list. Check the list file.');
      return
    end

    if strcmp(config.display_routine.name,'MATLAB figure')
      displayhandler=@DisplayColorWindow;
    elseif strcmp(config.display_routine.name,'Psychtoolbox')
      displayhandler=@DisplayColorWindowPTB;
    elseif strcmp(config.display_routine.name,'BITS++ with Psychtoolbox')
      displayhandler=@DisplayColorWindowBITS;
    end

    % check whether Psychtoolbox is installed
    if strcmp(config.display_routine.name,'Psychtoolbox') || strcmp(config.display_routine.name,'BITS++ with Psychtoolbox')
      if exist('Screen','file')~=3 % does not exist mex file named 'Screen' = Psychtoolbox is not installed
        PlaySound(0);
        set(handles.information_text,'String','Psychtoolbox is not installed on this computer. Install it first.');

        % disable some tabs
        tabselectionfcn(tabhandle,'McalibratorTab',2:4,'off');
        manageConfigTab(handles,'on');
        manageMeasureTab(handles,'off');
        manageLUTTab(handles,'off');
        manageColorTab(handles,'off');

        return;
      end
    end

    % save the configurations
    save_dir=fullfile(fileparts(mfilename('fullpath')),'data',config.date);
    if ~exist(save_dir,'dir'), mkdir(save_dir); end
    save_fname=fullfile(save_dir,sprintf('mcalibrator2_results_%s.mat',config.date));
    if ~exist(save_fname,'file')
      save(save_fname,'config');
    else
      eval(sprintf('save %s config -append;',save_fname));
    end

    PlaySound(1);

  else

    % disable some tabs
    tabselectionfcn(tabhandle,'McalibratorTab',2:4,'off');
    manageConfigTab(handles,'on');
    manageMeasureTab(handles,'off');
    manageLUTTab(handles,'off');
    manageColorTab(handles,'off');

  end


function load_pushbutton_Callback(hObject, eventdata, handles)

  global config;

  [filename,filepath]=uigetfile({'config_*.mat','config file (config_*.mat)';'*.*','All Files (*.*)'},'select a config file');
  load(fullfile(filepath,filename));
  set(handles.date_edit,'String',datestr(now,'yymmdd'));
  set(handles.apparatus_popupmenu,'Value',config.apparatus.id);
  set(handles.display_routine_popupmenu,'Value',config.display_routine.id);
  set(handles.sampling_popupmenu,'Value',config.sampling.id);
  set(handles.interval_popupmenu,'Value',config.interval.id);
  set(handles.lutoutbit_popupmenu,'Value',config.lutoutbit.id);
  set(handles.repetition_edit,'String',config.repetition.num);
  set(handles.gathermethod_popupmenu,'Value',config.repetition.id);
  set(handles.red_radiobutton,'Value',config.usered);
  set(handles.green_radiobutton,'Value',config.usegreen);
  set(handles.blue_radiobutton,'Value',config.useblue);
  set(handles.gray_radiobutton,'Value',config.usegray);
  set(handles.magenda_radiobutton,'Value',config.usemagenda);
  set(handles.yellow_radiobutton,'Value',config.useyellow);
  set(handles.cyan_radiobutton,'Value',config.usecyan);
  set(handles.flare_correction_radiobutton,'Value',config.flare_correction);

  PlaySound(1);


function save_pushbutton_Callback(hObject, eventdata, handles)

  global config;

  config.date=get(handles.date_edit,'String');

  config.apparatus=setparam(handles.apparatus_popupmenu);
  config.display_routine=setparam(handles.display_routine_popupmenu);
  config.sampling=setparam(handles.sampling_popupmenu);
  config.interval=setparam(handles.interval_popupmenu);
  config.lutoutbit=setparam(handles.lutoutbit_popupmenu);

  config.repetition=setparam(handles.gathermethod_popupmenu);
  config.repetition.num=get(handles.repetition_edit,'String');

  config.usered=get(handles.red_radiobutton,'value');
  config.usegreen=get(handles.green_radiobutton,'value');
  config.useblue=get(handles.blue_radiobutton,'value');
  config.usegray=get(handles.gray_radiobutton,'value');
  config.usemagenda=get(handles.magenda_radiobutton,'value');
  config.useyellow=get(handles.yellow_radiobutton,'value');
  config.usecyan=get(handles.cyan_radiobutton,'value');
  config.flare_correction=get(handles.flare_correction_radiobutton,'value');

  save_dir=fullfile(fileparts(mfilename('fullpath')),'config');
  if ~exist(save_dir,'dir'), mkdir(save_dir); end
  save(fullfile(save_dir,sprintf('config_%s.mat',config.date)),'config');

  PlaySound(1);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% functions for measure tab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% these are a kind of dummy functions, just required to handle GUI
function scr_num_edit_Callback(hObject, eventdata, handles)
function scr_num_edit_CreateFcn(hObject, eventdata, handles)
  if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
  end

function com_num_edit_Callback(hObject, eventdata, handles)
function com_num_edit_CreateFcn(hObject, eventdata, handles)
  if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
  end


% main procedures
function pos_adjust_pushbutton_Callback(hObject, eventdata, handles)

  global displayhandler;

  set(handles.information_uipanel,'Title','information');
  scr_num=str2num(get(handles.scr_num_edit,'String')); %#ok
  displayhandler(999,1,[],scr_num);
  set(handles.information_text,'String',{'adjust the position and focus of the colorimeter and press Adjust OK button.',...
                                         '','then, press F5 on MATLAB console to proceed.'});


function create_serial_pushbutton_Callback(hObject, eventdata, handles)

  global colorimeterhandler;

  set(handles.information_uipanel,'Title','information');

  set(handles.information_text,'String','Creating a communication port to colorimeter.....');
  port_name=get(handles.com_num_edit,'String');
  colorimeterhandler=colorimeterhandler.gen_port(port_name);
  set(handles.information_text,'String','A communication port to colorimeter is properly created.');

  PlaySound(1);


function reset_serial_pushbutton_Callback(hObject, eventdata, handles)

  global colorimeterhandler;

  set(handles.information_uipanel,'Title','information');

  set(handles.information_text,'String','Resetting a communication port.....');
  colorimeterhandler=colorimeterhandler.reset_port();
  set(handles.information_text,'String','A communication port is properly reset.');

  PlaySound(1);


function initialize_pushbutton_Callback(hObject, eventdata, handles)

  global colorimeterhandler;

  set(handles.information_uipanel,'Title','information');

  set(handles.information_text,'String','Initializing the colorimeter.....');
  check=1; count=1;
  while check~=0 && count<=5 % try to do at most 5 times
    [colorimeterhandler,check]=colorimeterhandler.initialize();
    count=count+1;
    set(handles.information_text,'String','Initializing Error...Re-Initializing');
  end
  if count==6
    set(handles.information_text,'String','You couldn''t initialize the apparatus.');
    PlaySound(0);
    return;
  end
  set(handles.information_text,'String','Initializing the colorimeter.....Done');

  PlaySound(1);


function measure_pushbutton_Callback(hObject, eventdata, handles)

  global config;
  global colorimeterhandler;
  global displayhandler;

  set(handles.information_uipanel,'Title','information');

  % create luminance file format
  save_dir=fullfile(fileparts(mfilename('fullpath')),'data',config.date);
  save_fname=fullfile(save_dir,sprintf('mcalibrator2_results_%s.mat',config.date));

  % set the sampling interval (0.0-1.0).
  sampnum=str2num(config.sampling.name); %#ok
  if strcmp(config.interval.name,'equally spaced')
    samppoints=0:1/(sampnum-1):1;
  elseif strcmp(config.interval.name,'low-biased')
    samppoints=(0:1/(sampnum-1):1).^2;
  elseif strcmp(config.interval.name,'high-biased')
    samppoints=sqrt(0:1/(sampnum-1):1);
  end

  % constant variables to display information or plot result
  color_str={'red','green','blue','gray','magenda','yellow','cyan'};
  colors={[1,0,0],[0,1,0],[0,0,1],[0.3,0.3,0.3],[1,0,1],[1,1,0],[0,1,1]};

  % constant variables to display color window
  color_msk={[1,0,0],[0,1,0],[0,0,1],[1,1,1],[1,0,1],[1,1,0],[0,1,1]};
  measure_flg=[config.usered,config.usegreen,config.useblue,config.usegray,config.usemagenda,config.useyellow,config.usecyan];

  mRGBs=cell(length(color_str),1);
  for ii=1:1:length(color_str)
    if ~measure_flg(ii)
      mRGBs{ii}=NaN;
    else
      mRGBs{ii}=repmat(samppoints,3,1).*repmat((color_msk{ii})',1,numel(samppoints));
    end
  end

  % colors to be used
  lum=cell(length(color_str),1);
  for ii=1:1:length(color_str), lum{ii}=zeros(4,numel(samppoints)); end % 4 = sampling-point, x, y, Y

  % initialize color window
  scr_num=str2num(get(handles.scr_num_edit,'String')); %#ok
  fig_id=displayhandler([255,255,255],1,[],scr_num); pause(0.2);

  % measure CIE1931 xyY values
  [Ys,xs,ys,displayhandler,colorimeterhandler]=...
    MeasureCIE1931xyYs(displayhandler,colorimeterhandler,mRGBs,1,fig_id,str2num(config.repetition.num),config.repetition.name); %#ok
  for ii=1:1:length(color_str)
    if ~measure_flg(ii), continue; end;
    lum{ii}(1,:)=samppoints; lum{ii}(4,:)=Ys{ii}; lum{ii}(2,:)=xs{ii}; lum{ii}(3,:)=ys{ii};
  end
  displayhandler(-999,1,fig_id);

  % plotting
  axes(handles.lum_figure); %#ok
  hold on;
  for ii=1:1:length(color_str)
    if ~measure_flg(ii), continue; end;
    plot(lum{ii}(1,:),lum{ii}(4,:),'Marker','o','MarkerSize',3,'MarkerFaceColor',colors{ii},'MarkerEdgeColor',colors{ii});
  end
  set(gca,'XLim',[0,1]);
  set(gca,'XTick',0:0.2:1.0);
  xlabel('video input (0.0-1.0)');
  ylabel('luminance (cd/m^2)');
  title('measured luminance');

  % save the results
  eval(sprintf('save %s lum -append;',save_fname));

  PlaySound(1);


function clear_lum_pushbutton_Callback(hObject, eventdata, handles)

  axes(handles.lum_figure); %#ok
  cla;

  PlaySound(1);


function measure_separate_pushbutton_Callback(hObject, eventdata, handles)

  f2=figure;
  axes(handles.lum_figure); %#ok
  c=copyobj(gca,f2);
  axes(c); %#ok
  set(c,'Position',[0.13,0.11,0.7750,0.8150]);
  set(gcf,'Name','Mcalibrator2: measured luminance','NumberTitle','off')

  PlaySound(1);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% functions for LUT tab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% these are empty, just required to handle GUI
function fitting_popupmenu_Callback(hObject, eventdata, handles)
function easycheck_togglebutton_Callback(hObject, eventdata, handles)


% main procedures
function fitmethod=getfitmethod(fitting_method)

  if strcmp(fitting_method,'Gain-offset-gamma')
    fitmethod='gog';
  elseif strcmp(fitting_method,'cubic spline')
    fitmethod='cbs';
  elseif strcmp(fitting_method,'robust cubic spline')
    fitmethod='rcbs';
  elseif strcmp(fitting_method,'power function')
    fitmethod='pow';
  elseif strcmp(fitting_method,'diff of 2 power function')
    fitmethod='pow2';
  elseif strcmp(fitting_method,'log space')
    fitmethod='log';
  elseif strcmp(fitting_method,'linear')
    fitmethod='lin';
  elseif strcmp(fitting_method,'5th order polynomial')
    fitmethod='poly';
  elseif strcmp(fitting_method,'sigmoid')
    fitmethod='sig';
  elseif strcmp(fitting_method,'Weibull function')
    fitmethod='wbl';
  elseif strcmp(fitting_method,'grid search with robust spline')
    fitmethod='gs';
  end


function curvefitting_pushbutton_Callback(hObject, eventdata, handles)

  global config;

  set(handles.information_uipanel,'Title','information');

  % create luminance file format
  save_dir=fullfile(fileparts(mfilename('fullpath')),'data',config.date);
  save_fname=fullfile(save_dir,sprintf('mcalibrator2_results_%s.mat',config.date));

  load(save_fname); % load measured luminance data
  if ~exist('lum','var')
    set(handles.information_text,'String','no luminance data. measure luminance first.');
    return;
  end

  % initialize variables
  measure_flg=[config.usered,config.usegreen,config.useblue,config.usegray,config.usemagenda,config.useyellow,config.usecyan];
  color_str={'red','green','blue','gray','magenda','yellow','cyan'};
  colors={[1,0,0],[0,1,0],[0,0,1],[0.3,0.3,0.3],[1,0,1],[1,1,0],[0,1,1]};
  fitlum=cell(length(color_str),1);
  for ii=1:1:length(color_str)
    if ~measure_flg(ii), continue; end;
    fitlum{ii}=zeros(2,size(lum{ii},2)); %#ok % lum is already loaded on memory
    fitlum{ii}(1,:)=lum{ii}(1,:);
  end

  % set fitting parameters
  tmp=get(handles.fitting_popupmenu,'String');
  id=get(handles.fitting_popupmenu,'Value');
  fitting_method=tmp{id};
  fitmethod=getfitmethod(fitting_method);

  monotonic_flg=1;
  lowpass_flg=0;
  flare_correction_flg=config.flare_correction;
  display_flg=0;
  save_flg=0;

  % fitting
  for ii=1:1:length(color_str)
    if ~measure_flg(ii), continue; end;
    set(handles.information_text,'String',sprintf('fitting a model to the measured %s phospher...',color_str{ii}));
    fitlum{ii}(2,:)=ApplyCurveFitting(lum{ii}([1,4],:),fitmethod,monotonic_flg,lowpass_flg,flare_correction_flg,display_flg,save_flg);
    set(handles.information_text,'String',sprintf('fitting a model to the measured %s phospher...Done.',color_str{ii}));
  end

  axes(handles.lum_figure); %#ok
  cla;

  for ii=1:1:length(color_str)
    if ~measure_flg(ii), continue; end;
    axes(handles.lum_figure); %#ok
    hold on;
    plot(lum{ii}(1,:),lum{ii}(4,:),'o','MarkerSize',3,'MarkerFaceColor',colors{ii},'MarkerEdgeColor','none');
    plot(fitlum{ii}(1,:),fitlum{ii}(2,:),'-','Color',colors{ii},'LineWidth',2);
    set(gca,'XLim',[0,1]);
    set(gca,'XTick',0:0.2:1.0);
    xlabel('video input (0.0-1.0)');
    ylabel('luminance (cd/m^2)');
    title(sprintf('fitting result, method: %s',fitmethod));
  end

  axes(handles.lum_figure); %#ok
  hold off;

  % create luminance file format
  eval(sprintf('save %s fitting_method fitlum -append;',save_fname));

  PlaySound(1);


function create_lut_pushbutton_Callback(hObject, eventdata, handles)

  global config;

  % create luminance file format
  save_dir=fullfile(fileparts(mfilename('fullpath')),'data',config.date);
  save_fname=fullfile(save_dir,sprintf('mcalibrator2_results_%s.mat',config.date));

  load(save_fname); % load measured luminance data
  if ~exist('lum','var')
    set(handles.information_text,'String','no luminance data. measure luminance first.');
    return;
  end

  % initialize variables

  measure_flg=[config.usered,config.usegreen,config.useblue,config.usegray,config.usemagenda,config.useyellow,config.usecyan];
  color_str={'red','green','blue','gray','magenda','yellow','cyan'};
  colors={[1,0,0],[0,1,0],[0,0,1],[0.3,0.3,0.3],[1,0,1],[1,1,0],[0,1,1]};
  lutoutbit=str2num(config.lutoutbit.name); %#ok
  lut=cell(length(color_str),1);
  for ii=1:1:length(color_str), lut{ii}=zeros(2,lutoutbit); end

  % initialize an object to communicate with Microsoft Powerpoint
  windows_flg=0;
  if strcmp(mexext,'mexw32') || strcmp(mexext,'mexw64') % OS = Windows
    windows_flg=1;
    ppt=AddSlide2PPT;
    if ~isempty(ppt.app_handle)
      ppt=ppt.addTitleSlide(sprintf('Mcalibrator2%sDisplay Calibration Results',ppt.newline()),datestr(now,'yymmdd'));

      % add config information to PPT slide
      config_info=sprintf('colorimeter     : %s\r\n',config.apparatus.name);
      config_info=[config_info,sprintf('Sampling        : %s\r\n',config.sampling.name)];
      config_info=[config_info,sprintf('Interval        : %s\r\n',config.interval.name)];
      config_info=[config_info,sprintf('Repetition      : %s (%s)\r\n',config.repetition.num,config.repetition.name)];
      config_info=[config_info,sprintf('Flare Correction: %d\r\n',config.flare_correction)];
      tmp=get(handles.fitting_popupmenu,'String');
      id=get(handles.fitting_popupmenu,'Value');
      fitting_method=tmp{id};
      config_info=[config_info,sprintf('Fitting Model   : %s\r\n',fitting_method)];
      ppt=ppt.addTextSlide('Parameters',config_info);
    else
      windows_flg=0;
    end
  end

  % set fitting parameters
  tmp=get(handles.fitting_popupmenu,'String');
  id=get(handles.fitting_popupmenu,'Value');
  fitting_method=tmp{id};
  fitmethod=getfitmethod(fitting_method);

  monotonic_flg=1;
  lowpass_flg=0;
  flare_correction_flg=config.flare_correction;
  display_flg=1;
  save_flg=0;

  % generate Color Lookup Tables
  axes(handles.lut_figure); %#ok
  cla;
  for ii=1:1:length(color_str)
    if ~measure_flg(ii), continue; end;

    set(handles.information_text,'String',sprintf('Generating LUT for %s phospher...',color_str{ii}));
    lut{ii}=ApplyGammaCorrection(lum{ii}([1,4],:),fitmethod,lutoutbit,...
                                 monotonic_flg,lowpass_flg,flare_correction_flg,display_flg,save_flg); %#ok % lum is already loaded on memory
    set(gcf,'Name',[get(gcf,'Name'),sprintf(' %s',color_str{ii})]);

    % save images as a PPT slide
    if windows_flg
      tmpimgfile=fullfile(save_dir,'gamma_result.png');
      set(gcf,'PaperPositionMode','auto');
      print(gcf,tmpimgfile,'-dpng','-r0');
      %saveas(gcf,tmpimgfile,'bmp');
      ppt=ppt.addImageSlide(color_str{ii},tmpimgfile);
      delete(tmpimgfile);
    end
    if exist(fullfile(pwd,sprintf('gamma_corr_result_%s.png',fitmethod)),'file')
      delete(fullfile(pwd,sprintf('gamma_corr_result_%s.png',fitmethod)));
    end

    % plotting
    axes(handles.lut_figure); %#ok
    hold on;
    plot(1:1:size(lut{ii},2),lut{ii}(1,:),'-','Marker','o','MarkerSize',3,'MarkerFaceColor',colors{ii},'Color',colors{ii});
    xlabel('LUT ID');
    set(gca,'XLim',[0,size(lut{ii},2)]);
    ylabel('video input (0.0-1.0)');
    title('generated LUTs');

    % save the generated LUT to a text file
    fid=fopen(fullfile(save_dir,sprintf('%s.lut',color_str{ii})),'w');
    if fid==-1, error('can not open a %s LUT file to write.',color_str{ii}); PlaySound(0); end
    for mm=1:1:size(lut{ii},2), fprintf(fid,'% 4d %.4f\n',mm,lut{ii}(1,mm)); end
    fclose(fid);

    set(handles.information_text,'String',sprintf('Generating LUT for %s phospher...Done.',color_str{ii}));
  end
  hold off;

  % save the generated PPT slides
  if windows_flg, ppt.saveAs(fullfile(save_dir,'display_calibration_result.ppt')); end

  % save the results
  eval(sprintf('save %s fitting_method lut -append;',save_fname));

  % save the generaged LUT(s) for PTB3
  if lutoutbit==256
    if measure_flg(1) && measure_flg(2) && measure_flg(3)
      gammatable=[lut{1}(2,:);lut{2}(2,:);lut{3}(2,:)]'; %#ok
      save(fullfile(save_dir,'gammatablePTB.mat'),'gammatable');
    elseif measure_flg(4)
      gammatable=(lut{4}(2,:))'; %#ok
      save(fullfile(save_dir,'gammatablePTB.mat'),'gammatable');
    end
  end

  PlaySound(1);


function check_lut_pushbutton_Callback(hObject, eventdata, handles)

  global config;
  global colorimeterhandler;
  global displayhandler;

  set(handles.information_uipanel,'Title','information');

  % create luminance file format
  save_dir=fullfile(fileparts(mfilename('fullpath')),'data',config.date);
  save_fname=fullfile(save_dir,sprintf('mcalibrator2_results_%s.mat',config.date));

  load(save_fname); % load measured luminance data
  if ~exist('lut','var')
    set(handles.information_text,'String','no LUT data. generate LUT first.');
    return;
  end

  % initialize variables
  measure_flg=[config.usered,config.usegreen,config.useblue,config.usegray,config.usemagenda,config.useyellow,config.usecyan];
  color_str={'red','green','blue','gray','magenda','yellow','cyan'};
  colors={[1,0,0],[0,1,0],[0,0,1],[0.3,0.3,0.3],[1,0,1],[1,1,0],[0,1,1]};
  color_msk={[1,0,0],[0,1,0],[0,0,1],[1,1,1],[1,0,1],[1,1,0],[0,1,1]};

  % check linearity of the generated LUTs
  if get(handles.easycheck_togglebutton,'Value') % easy mode

    axes(handles.lut_figure); %#ok
    cla;

    for ii=1:1:length(color_str)
      if ~measure_flg(ii), continue; end;

      set(handles.information_text,'String',sprintf('checking linearity of %s LUT...',color_str{ii}));
      axes(handles.lut_figure); %#ok
      hold on;
      plot(linspace(0,1.0,size(lut{ii},2)),lut{ii}(2,:),'-','Marker','o','MarkerSize',3,'MarkerFaceColor',colors{ii},...
           'Color',colors{ii}); %#ok % lut is already loaded on memory
      set(gca,'XLim',[0,1]);
      set(gca,'XTick',0:0.2:1.0);
      xlabel('LUT ID');
      ylabel('luminance (cd/m^2)');
      title('linearity of LUTs');
      set(handles.information_text,'String',sprintf('checking linearity of %s LUT...Done.',color_str{ii}));
    end
    hold off;

  else % measure luminance again and check linearity

    % initialize seed of random sequence
    InitializeRandomSeed();

    % get/set 20 points for re-measure the luminance
    for ii=1:1:length(color_str)
      if ~measure_flg(ii), continue; end;
      checklumval=lut{ii}(1,floor(linspace(1,str2num(config.lutoutbit.name),20))); %#ok
    end

    % set luminance values
    checklum=cell(length(color_str),1);
    for ii=1:1:length(color_str)
      if ~measure_flg(ii), continue; end;
      checklum{ii}=zeros(5,20); % 4 = measured_val, x, y, Y
      checklum{ii}(1,:)=linspace(0,1,20);%checklumval;
      checklum{ii}(2,:)=checklumval;
    end

    % initialize color window
    scr_num=str2num(get(handles.scr_num_edit,'String')); %#ok
    fig_id=displayhandler([255,255,255],1,[],scr_num); pause(0.2);

    % measure CIE1931 xyY
    for ii=1:1:length(color_str)
      if ~measure_flg(ii), continue; end;

      set(handles.information_text,'String',sprintf('Measuring CIE 1931 xyY of %s...',color_str{ii}));
      mesorder=shuffle(1:1:numel(checklumval));%1:1:numel(checklumval)
      for mm=mesorder
        [checklum{ii}(5,mm),checklum{ii}(3,mm),checklum{ii}(4,mm),displayhandler,colorimeterhandler]=...
          MeasureCIE1931xyY(displayhandler,colorimeterhandler,repmat(checklumval(mm),1,3).*color_msk{ii},1,fig_id);
      end
      set(handles.information_text,'String',sprintf('Measuring CIE 1931 xyY of %s...Done',color_str{ii}));
      hold off;
    end
    displayhandler(-999,1,fig_id);

    axes(handles.lut_figure); %#ok
    cla;

    % plotting
    rho=zeros(length(color_str),1);
    pval=zeros(length(color_str),1);
    rms=zeros(length(color_str),1);
    for ii=1:1:length(color_str)
      if ~measure_flg(ii), continue; end;

      set(handles.information_text,'String',sprintf('checking linearity of %s LUT...',color_str{ii}));
      axes(handles.lut_figure); %#ok
      hold on;
      plot(checklum{ii}(1,:),checklum{ii}(5,:),'Marker','o','MarkerSize',3,'MarkerFaceColor',colors{ii},'Color',colors{ii});

      % linear fitting
      p=polyfit(checklum{ii}(1,:),checklum{ii}(5,:),1);
      linfit=p(1)*checklum{ii}(1,:)+p(2);
      plot(checklum{ii}(1,:),linfit,'-','Color',colors{ii},'LineWidth',2);

      % RMSE
      e=(checklum{ii}(5,:)-linfit)./linfit*100;
      rms(ii)=sqrt(e*e')./sqrt(size(checklum{ii}(5,:),2));

      % goodness of linearity by correlation-coefficient & its p-value
      [rho(ii),pval(ii)]=corr(checklum{ii}(1,:)',(checklum{ii}(5,:))');

      set(gca,'XLim',[0,1]);
      set(gca,'XTick',0:0.2:1.0);
      xlabel('LUT ID');
      ylabel('luminance (cd/m^2)');
      title('linearity of LUTs');
      set(handles.information_text,'String',sprintf('checking linearity of %s LUT...Done.',color_str{ii}));
    end % for ii=1:1:length(color_str)

    % display the goodness of linearity on the information window
    fit_str={'Linearity check, results',''};
    for ii=1:1:length(color_str)
      if ~measure_flg(ii), continue; end;
      fit_str=[fit_str,{sprintf('%s: rmse=%.2f, corr=%.2f, p-value=%.2f',color_str{ii},rms(ii),rho(ii),pval(ii)),''}]; %#ok
    end
    set(handles.information_text,'String',fit_str);

    axes(handles.lut_figure); %#ok
    hold off;

    % create luminance file format
    eval(sprintf('save %s checklum -append;',save_fname));

  end % if handles.easycheck_togglebutton % easy mode

  PlaySound(1);


function clear_lut_pushbutton_Callback(hObject, eventdata, handles)

  axes(handles.lut_figure); %#ok
  cla;

  PlaySound(1);


function LUT_separate_pushbutton_Callback(hObject, eventdata, handles)

  f2=figure;
  axes(handles.lut_figure); %#ok
  cxlim=get(gca,'XLim');
  cxtick=get(gca,'XTick');
  cxticklabel=get(gca,'XTickLabel');
  %cxlabel=get(gca,'XLabel');

  c=copyobj(gca,f2);
  axes(c); %#ok
  set(c,'Position',[0.13,0.11,0.7750,0.8150]);
  set(gcf,'Name','Mcalibrator2: generated LUTs','NumberTitle','off')

  axes(handles.lut_figure); %#ok
  set(gca,'XLim',cxlim);
  set(gca,'XTick',cxtick);
  set(gca,'XTickLabel',cxticklabel);

  axes(c); %#ok
  PlaySound(1);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% functions for Color Calculator tab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% these are a kind of dummy functions, just required to handle GUI
function xyY_edit_Callback(hObject, eventdata, handles)
function xyY_edit_CreateFcn(hObject, eventdata, handles)
  if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
  end


function RGB_edit_Callback(hObject, eventdata, handles)
function RGB_edit_CreateFcn(hObject, eventdata, handles)
  if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
  end

function calculator_method_popupmenu_Callback(hObject, eventdata, handles)
function calculator_method_popupmenu_CreateFcn(hObject, eventdata, handles)
  if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
  end
  % set measurement method to GUI
  meas_methods=measurement_method_list();
  str_meas_method=[];
  for ii=1:1:length(meas_methods), str_meas_method=[str_meas_method,meas_methods{ii}(1)]; end %#ok
  set(hObject,'String',str_meas_method);
  set(hObject,'Value',1);


function results_xyY_edit_Callback(hObject, eventdata, handles)
function results_xyY_edit_CreateFcn(hObject, eventdata, handles)
  if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
  end


% fucntions to handle GUI
function use_LUT_radiobutton_Callback(hObject, eventdata, handles)

  if get(handles.use_LUT_radiobutton,'Value')
    set(handles.use_RGB_radiobutton,'Value',0);
    set(handles.use_LUT_radiobutton,'Value',1);
    set(handles.RGB_text,'String','LUT');
    set(handles.measured_RGB_text,'String','LUT')
  else
    set(handles.use_RGB_radiobutton,'Value',1);
    set(handles.use_LUT_radiobutton,'Value',0);
    set(handles.RGB_text,'String','R,G,B');
    set(handles.measured_RGB_text,'String','R,G,B')
  end


function use_RGB_radiobutton_Callback(hObject, eventdata, handles)

  if get(handles.use_RGB_radiobutton,'Value')
    set(handles.use_RGB_radiobutton,'Value',1);
    set(handles.use_LUT_radiobutton,'Value',0);
    set(handles.RGB_text,'String','R,G,B');
    set(handles.measured_RGB_text,'String','R,G,B')
  else
    set(handles.use_RGB_radiobutton,'Value',0);
    set(handles.use_LUT_radiobutton,'Value',1);
    set(handles.RGB_text,'String','LUT');
    set(handles.measured_RGB_text,'String','LUT')
  end


% main procedures
function load_phospher_pushbutton_Callback(hObject, eventdata, handles)

  global config;
  global colorimeterhandler;
  global displayhandler;
  global phosphers;
  global flares;

  set(handles.information_uipanel,'Title','information');

  % create luminance file format
  save_dir=fullfile(fileparts(mfilename('fullpath')),'data',config.date);
  save_fname=fullfile(save_dir,sprintf('mcalibrator2_results_%s.mat',config.date));

  % get/set phospher CIE1931 xyY
  load(save_fname); % load measured luminance data
  if ( ~isempty(phosphers) && ~isempty(flares) ) || sum(phosphers(:))~=0

    % empty, use already acquired phosphers and flares values

  elseif exist('lum','var') && sum(lum{1}(1,:))~=0 && sum(lum{2}(1,:))~=0 && sum(lum{3}(1,:))~=0 %#ok

    phosphers=zeros(3,3); % phosphers = [rx,gx,bx;ry,gy,by;rY,gY,bY];
    phosphers(:,1)=[lum{1}(2,end);lum{1}(3,end);lum{1}(4,end)];
    phosphers(:,2)=[lum{2}(2,end);lum{2}(3,end);lum{2}(4,end)];
    phosphers(:,3)=[lum{3}(2,end);lum{3}(3,end);lum{3}(4,end)];

    flares=zeros(3,3); % zero-level light
    flares(:,1)=[lum{1}(2,1);lum{1}(3,1);lum{1}(4,1)];
    flares(:,2)=[lum{2}(2,1);lum{2}(3,1);lum{2}(4,1)];
    flares(:,3)=[lum{3}(2,1);lum{3}(3,1);lum{3}(4,1)];
    flares=mean(flares,2);

  else

    phosphers=zeros(3,3); % phosphers = [rx,ry,rY; gx,gy,gY; bx,by,bY];
    flares=zeros(3,3); % leaked (zero-level) light

    set(handles.information_text,'String',{'RGB phospher chromaticities have not been acquired yet.',...
                        'starting to measure CIE1931 xyY for RGB phosphers....'});

    % initialize color window
    scr_num=str2num(get(handles.scr_num_edit,'String')); %#ok
    fig_id=displayhandler([255,255,255],1,[],scr_num); pause(0.2);

    % measure CIE1931 xyY for RGB phosphers
    color_str={'red','green','blue'};
    colors={[1,0,0],[0,1,0],[0,0,1]};
    for ii=1:1:length(color_str)
      set(handles.information_text,'String',sprintf('Measuring CIE 1931 xyY of %s...',color_str{ii}));
      [phosphers(3,ii),phosphers(1,ii),phosphers(2,ii),displayhandler,colorimeterhandler]=...
          MeasureCIE1931xyY(displayhandler,colorimeterhandler,colors{ii},1,fig_id);
      set(handles.information_text,'String',sprintf('Measuring CIE 1931 xyY of %s...Done',color_str{ii}));
    end

    % measure leaked light (zero-level) luminance
    for ii=1:1:3
      set(handles.information_text,'String','Measuring CIE 1931 xyY of flare...');
      [flares(3,ii),flares(1,ii),flares(2,ii),displayhandler,colorimeterhandler]=...
          MeasureCIE1931xyY(displayhandler,colorimeterhandler,[0,0,0],1,fig_id);
      set(handles.information_text,'String','Measuring CIE 1931 xyY of flare...Done');
    end
    flares=mean(flares,2);
    displayhandler(-999,1,fig_id);

  end
  set(handles.information_text,'String',{'RGB phospher chromaticities have not been acquired yet.','starting to measure CIE1931 xyY for RGB phosphers....Done.'});

  % plotting phospher CIE1931 xy
  axes(handles.color_figure); %#ok
  hold off;
  PlotCIE1931xy([],phosphers,-1,1,1);
  hold off;

  % save the results
  eval(sprintf('save %s phosphers flares -append;',save_fname));

  PlaySound(1);


function xyY_RGB_convert_pushbutton_Callback(hObject, eventdata, handles)

  global config;
  global phosphers;
  global flares;

  set(handles.information_uipanel,'Title','information');

  if isempty(phosphers) || sum(phosphers(:))==0
    set(handles.information_text,'String','RGB phospher chromaticities have not been acquired yet. Measure them first.');
    PlaySound(0);
    return
  else
    % convert chromaticities from xyY to RGB
    myxyY=(getDataFromStr(get(handles.xyY_edit,'String')))';

    % flare correction
    if config.flare_correction
      flare_xyY=flares;%repmat(flares,1,size(myxyY,2));
    else
      flare_xyY=[];
    end
    rgbdata=xyY2RGB(myxyY,phosphers,flare_xyY);
    rgbdata(rgbdata<0)=0;
    rgbdata(rgbdata>1)=1.0;

    % set RGB or LUT values
    if get(handles.use_LUT_radiobutton,'Value')
      lut=LoadLUTs();
      if isempty(lut), set(handles.information_text,'String','can not load RGB LUTs. Generate them first.'); PlaySound(0); return; end

      % get lut ID corresponding to the target rgb
      lutdata=getLUTidx(lut,rgbdata);

      % set lut ID to RGB_edit
      str_lut=[];
      for ii=1:1:size(lutdata,1)
        str_lut=[str_lut,num2str(lutdata(ii,1)),',',num2str(lutdata(ii,2)),',',num2str(lutdata(ii,3)),';']; %#ok
      end
      set(handles.RGB_edit,'String',str_lut);
    else
      % set rgb values to RGB_edit
      str_rgb=[];
      for ii=1:1:size(rgbdata,2)
        str_rgb=[str_rgb,num2str(rgbdata(1,ii)),',',num2str(rgbdata(2,ii)),',',num2str(rgbdata(3,ii)),';']; %#ok
      end
      set(handles.RGB_edit,'String',str_rgb);
    end
  end % if ~exist(phosphers,'var') || sum(phosphers(:))==0

  if get(handles.use_LUT_radiobutton,'Value')
    set(handles.information_text,'String','xyY values were converted to RGB values.');
  else
    set(handles.information_text,'String','xyY values were converted to LUT IDs.');
  end
  PlaySound(1);


function load_text_pushbutton_Callback(hObject, eventdata, handles)

  set(handles.information_uipanel,'Title','information');

  [filename,filepath]=uigetfile({'*.txt','xyY file (*.txt)';'*.*','All Files (*.*)'},'select a text file (x1,y1,Y1;(enter)x2,y2,Y2;(enter)x3,y3,...)');
  xyYdata=load(fullfile(filepath,filename));
  if size(xyYdata,2)~=3
    set(handles.information_text,'String',{'text file format error','xyY text file should be organized as x1,y1,Y1;[ENTER]y1,y2,Y2;[ENTER]x3,y3,Y3;. check the file again'});
    clear filename filepath;
    return
  else
    str_xyY=[];
    for ii=1:1:size(xyYdata,1)
      str_xyY=[str_xyY,num2str(xyYdata(ii,1)),',',num2str(xyYdata(ii,2)),',',num2str(xyYdata(ii,3)),';']; %#ok
    end
  end
  set(handles.xyY_edit,'String',str_xyY);

  PlaySound(1);


function calculator_measure_pushbutton_Callback(hObject, eventdata, handles)

  % set a function to measure/estimate CIE1931 xyY and run it
  meas_methods=measurement_method_list();
  eval(sprintf('%s(hObject,eventdata,handles);',meas_methods{get(handles.calculator_method_popupmenu,'Value')}{2}));

  PlaySound(1);


function calculator_view_pushbutton_Callback(hObject, eventdata, handles)

  set(handles.information_uipanel,'Title','information');

  if isempty(get(handles.xyY_edit,'String')) || isempty(get(handles.RGB_edit,'String')) || ...
     isempty(get(handles.results_xyY_edit,'String')) || isempty(get(handles.results_RGB_edit,'String'))
    set(handles.information_text,'String','Data has not acquired. Measure xyY values you want first.');
    PlaySound(0);
    return
  end

  set(handles.information_text,'String','Loading CIE1931 xyY data...');

  % gather data: 1. xyY you want, 2. RGB you want, 3. xyY measured, 4. RGB measured
  my_xyY=getDataFromStr(get(handles.xyY_edit,'String'));
  my_RGB=getDataFromStr(get(handles.RGB_edit,'String'));
  results_xyY=getDataFromStr(get(handles.results_xyY_edit,'String'));
  results_RGB=getDataFromStr(get(handles.results_RGB_edit,'String'));

  % display on the measured results on command window
  if get(handles.use_LUT_radiobutton,'Value')
    fprintf('\n***** wanted/measured xyY and the corresponding LUT values *****\n\n');
    for ii=1:1:size(my_xyY,1)
      fprintf('color [%03d] : xyY[%.3f, %.3f, %.3f], LUT[%03d, %03d, %03d]\n',...
              ii,my_xyY(ii,1),my_xyY(ii,2),my_xyY(ii,3),my_RGB(ii,1),my_RGB(ii,2),my_RGB(ii,3));
      fprintf(' --measured : xyY[%.3f, %.3f, %.3f], LUT[%03d, %03d, %03d]\n\n',...
              results_xyY(ii,1),results_xyY(ii,2),results_xyY(ii,3),results_RGB(ii,1),results_RGB(ii,2),results_RGB(ii,3));
    end
  else
    fprintf('\n***** wanted/measured xyY and the corresponding RGB values *****\n\n');
    for ii=1:1:size(my_xyY,1)
      fprintf('color [%03d] : xyY[%.3f, %.3f, %.3f], RGB[%.3f, %.3f, %.3f]\n',...
              ii,my_xyY(ii,1),my_xyY(ii,2),my_xyY(ii,3),my_RGB(ii,1),my_RGB(ii,2),my_RGB(ii,3));
      fprintf(' --measured : xyY[%.3f, %.3f, %.3f], RGB[%.3f, %.3f, %.3f]\n\n',...
              results_xyY(ii,1),results_xyY(ii,2),results_xyY(ii,3),results_RGB(ii,1),results_RGB(ii,2),results_RGB(ii,3));
    end
  end

  set(handles.information_text,'String','Loading CIE1931 xyY data...Done.');

  PlaySound(1);


function calculator_save_pushbutton_Callback(hObject, eventdata, handles)

  global config;

  set(handles.information_uipanel,'Title','information');

  % create luminance file format
  save_dir=fullfile(fileparts(mfilename('fullpath')),'data',config.date);
  save_fname=fullfile(save_dir,sprintf('mcalibrator2_results_%s.mat',config.date));

  if isempty(get(handles.xyY_edit,'String')) || isempty(get(handles.RGB_edit,'String')) || ...
     isempty(get(handles.results_xyY_edit,'String')) || isempty(get(handles.results_RGB_edit,'String'))
    set(handles.information_text,'String','Data has not acquired. Measure xyY values you want first.');
    PlaySound(0);
    return
  end

  % store data as matlab variable

  set(handles.information_text,'String','Saving CIE1931 xyY data...');

  % estimation method
  if get(handles.use_LUT_radiobutton,'Value')
    estimate.method='LUT';
  else
    estimate.method='RGB';
  end

  % gather data: 1. xyY you want, 2. RGB you want, 3. xyY measured, 4. RGB measured
  estimate.my_xyY=getDataFromStr(get(handles.xyY_edit,'String'));
  estimate.my_RGB=getDataFromStr(get(handles.RGB_edit,'String'));
  estimate.results_xyY=getDataFromStr(get(handles.results_xyY_edit,'String'));
  estimate.results_RGB=getDataFromStr(get(handles.results_RGB_edit,'String'));

  % save the results
  eval(sprintf('save %s estimate -append;',save_fname));

  % save the results to a text file
  estimate_files=wildcardsearch(save_dir,'estimate_*.txt');
  if isempty(estimate_files)
    estimate_file='estimate_files_001.txt';
  else
    idx=length(estimate_files)+1;
    estimate_file=sprintf('estimate_files_%03d.txt',idx);
  end

  fid=fopen(fullfile(save_dir,estimate_file),'w');
  if fid==-1, warning('can not open a file to save the estimated xyY & RGB.'); PlaySound(0); return; end %#ok
  fprintf(fid,'***********************************************\n');
  fprintf(fid,'Mcalibrator2, chromaticity estimation results\n');
  fprintf(fid,'date: %s\n',datestr(now,'mmmm dd YYYY, HH:MM:SS'));
  fprintf(fid,'***********************************************');
  fprintf(fid,'\n');
  fprintf(fid,['colorID x_you_want y_you_want Y_you_want R_you_want G_you_want B_you_want ',...
               'x_estimated y_estimated Y_estimated R_estimated G_estimated B_estimated ',...
               'percentage_error_x percentage_error_y percentage_error_Y\n']);
  for nn=1:1:size(estimate.my_xyY,1)
    prc_error=(estimate.my_xyY(nn,:)-estimate.results_xyY(nn,:))./estimate.my_xyY(nn,:).*100;
    fprintf(fid,'color_%04d %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f\n',...
            nn,estimate.my_xyY(nn,1),estimate.my_xyY(nn,2),estimate.my_xyY(nn,3),...
               estimate.my_RGB(nn,1),estimate.my_RGB(nn,2),estimate.my_RGB(nn,3),...
               estimate.results_xyY(nn,1),estimate.results_xyY(nn,2),estimate.results_xyY(nn,3),...
               estimate.results_RGB(nn,1),estimate.results_RGB(nn,2),estimate.results_RGB(nn,3),...
               prc_error(1),prc_error(2),prc_error(3));
  end
  fclose(fid);

  set(handles.information_text,'String','Saving CIE1931 xyY data...Done.');

  PlaySound(1);


function clear_color_pushbutton_Callback(hObject, eventdata, handles)

  axes(handles.color_figure); %#ok
  PlotCIE1931xy([],[],-1,0,1);

  PlaySound(1);


function color_separate_pushbutton_Callback(hObject, eventdata, handles)

  f2=figure;
  axes(handles.color_figure); %#ok
  c=copyobj(gca,f2);
  axes(c);
  set(c,'Position',[0.13,0.11,0.7750,0.8150]);
  axis square;
  set(gcf,'Name','Mcalibrator2: CIE1931 chromaticity diagram','NumberTitle','off')

  PlaySound(1);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% functions for about tab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function display_test_pushbutton_Callback(hObject, eventdata, handles)

  display_test();


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% functions to handle information_text according to TAB change
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function McalibratorTab_TabSelectionChange_Callback(hObject, eventdata, handles)

  persistent strings;

  % load strings to be displayed in Information window
  if isempty(strings), strings=load_information_strings; end

  tabid=get(handles.McalibratorTab,'Value');
  if tabid(1)==1
    set(handles.information_uipanel,'Title','config tab: setup Mcalibrator2');
    set(handles.information_text,'FontAngle','normal','FontName','Tahoma','FontSize',10.0,'FontUnits','pixels','String',strings{1});
  elseif tabid(2)==1
    set(handles.information_uipanel,'Title','measure tab: measure CIE1931 xyY');
    set(handles.information_text,'FontAngle','normal','FontName','Tahoma','FontSize',11.0,'FontUnits','pixels','String',strings{2});
  elseif tabid(3)==1
    set(handles.information_uipanel,'Title','LUT tab: generate Color Lookup Table(s)');
    set(handles.information_text,'FontAngle','normal','FontName','Tahoma','FontSize',11.0,'FontUnits','pixels','String',strings{3});
  elseif tabid(4)==1
    set(handles.information_uipanel,'Title','Color Calculator tab: get colors you want');
    set(handles.information_text,'FontAngle','normal','FontName','Tahoma','FontSize',10.0,'FontUnits','pixels','String',strings{4});
  elseif tabid(5)==1
    set(handles.information_uipanel,'Title','about Mcalibrator2');
    set(handles.information_text,'FontAngle','normal','FontName','Tahoma','FontSize',10.0,'FontUnits','pixels','String',strings{5});
  end
