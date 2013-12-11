function [Ys,xs,ys,displayhander,colorimeterhandler]=MeasureCIE1931xyYs(displayhandler,colorimeterhandler,rgbs,fullscr_flg,fig_id,repetitions,method)

% Measures multiple CIE1931 xyY values for multiple input rgb values using displayhandler and colorimeterhandler.
% function [xyYs,displayhander,colorimeterhandler]=MeasureCIE1931xyYs(displayhandler,colorimeterhandler,rgbs,:fullscr_flg,:fig_id,:repetitions,:method)
% (: is optional)
%
% This function measures CIE1931 xyY values for multiple input rgb values using displayhandler and colorimeterhandler
%
% [input]
% displayhandler     : function handle to display color window
%                      e.g. displayhander=@DisplayColorWindow;
%                           displayhander=@DisplayColorWindowPTB;
% colorimeterhandler : object handle to manipulate the colorimeter and measure CIE1931 xyY
%                      e.g. colorimeterhandler=pr650;
% rgbs               : RGB values to be measured, cell structure, each cell has [3(r,g,b) x n] matrix
% fullscr_flg        : if 1, the color window is displayed with full-screen mode, 0 by default
% fig_id             : MATLAB figure or PTB screen handle in which RGB color is displayed
% repetitions        : the number of repetitions of measurements, 1 by default
% method             : method to gather data (mean, madian, max, min), 'mean' by default
%
% [output]
% Ys : cell structure, CIE1931 Y (luminance) values
% xs : cell structure, CIE1931 x values
% ys : cell structure, CIE1931 y values
% displayhandler     : function handle to display color window
% colorimeterhandler : object handle to manipulate the colorimeter and measure CIE1931 xyY
%
%
% Created    : "2012-04-14 23:24:35 ban"
% Last Update: "2013-12-11 17:49:07 ban (ban.hiroshi@gmail.com)"

% set global variables

% check input variables
if nargin<3, help(mfilename()); Ys=[]; xs=[]; ys=[]; return; end
if nargin<4 || isempty(fullscr_flg), fullscr_flg=0; end
if nargin<5 || isempty(fig_id), fig_id=[]; end
if nargin<6 || isempty(repetitions), repetitions=1; end
if nargin<7 || isempty(method), method='mean'; end

% initialize output variables
Ys=cell(length(rgbs),1);
xs=cell(length(rgbs),1);
ys=cell(length(rgbs),1);
for ii=1:1:length(rgbs)
  if isnan(rgbs{ii})
    Ys{ii}=NaN;
  else
    Ys{ii}=zeros(repetitions,size(rgbs{ii},2));
    xs{ii}=zeros(repetitions,size(rgbs{ii},2));
    ys{ii}=zeros(repetitions,size(rgbs{ii},2));
  end
end

% initialize seed of random sequence
InitializeRandomSeed();

% measure CIE1931 xyY values
for ii=1:1:length(rgbs)
  if isnan(rgbs{ii}), continue; end;

  % measure CIE1931 xyY
  for rr=1:1:repetitions
    mesorder=shuffle(1:1:size(rgbs{ii},2));%1:1:size(rgbs{ii},2)
    for mm=mesorder
      [Ys{ii}(rr,mm),xs{ii}(rr,mm),ys{ii}(rr,mm),displayhander,colorimeterhandler]=...
        MeasureCIE1931xyY(displayhandler,colorimeterhandler,rgbs{ii}(:,mm),fullscr_flg,fig_id);
    end
  end % for rr=1:1:repetitions

  % gather measured data
  if strcmp(method,'mean')
    Ys{ii}=mean(Ys{ii},1); xs{ii}=mean(xs{ii},1); ys{ii}=mean(ys{ii},1);
  elseif strcmp(method,'median')
    Ys{ii}=median(Ys{ii},1); xs{ii}=median(xs{ii},1); ys{ii}=median(ys{ii},1);
  elseif strcmp(method,'max')
    Ys{ii}=max(Ys{ii},1); xs{ii}=max(xs{ii},1); ys{ii}=max(ys{ii},1);
  elseif strcmp(method,'min')
    Ys{ii}=min(Ys{ii},1); xs{ii}=min(xs{ii},1); ys{ii}=min(ys{ii},1);
  end
end

return
