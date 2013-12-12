function [corr_val,flare,min_val,max_val]=ApplyFlareCorrection(input_val,display_flg)

% Applies flare-correction to the measured luminance data.
% function [cor_val,flare,min_val,max_val]=ApplyFlareCorrection(input_val,:display_flg)
% (: is optional)
%
% Apply Flare-correction on the measured luminance values
%
% [input]
% input_val : raw lum or xyY values, [1 (CIE1931 Y) x n] or [3 (CIE1931 x,y,Y) x n] matrix
%             The input_val should be sorted in ascending order based on the corresponding video input values.
%             Further, input_val should be processed by monotonic-increase filter.
% display_flg : whether displaying the results, [0|1]. 0 by default.
%
% [output]
% corr_val  : Flare-corrected lum or xyY values, [1 x n] or [3 x n] matrix
% flare     : subtracted lum or xyY values, [1 x n] or [3 x n] matrix
% min_val   : minimum value of input_val
% max_val   : maximum value of input_val
%
%
% Created    : "2012-04-09 23:39:09 ban"
% Last Update: "2013-12-11 17:45:19 ban"

% check input variable
if nargin<1, help(mfilename()); corr_val=[]; subt_val=[]; min_val=[]; max_val=[]; return; end
if nargin<2 || isempty(display_flg), display_flg=0; end

% apply flare-correction
[m,n]=size(input_val);
if m==1 % CIE1931 Y (luminance) only
  flare=input_val(1);%min(input_val);
  corr_val=input_val-flare;
  min_val=flare;
  max_val=input_val(n);%max(input_val);
elseif m==3 % CIE1931 xyY
  XYZ=xyY2XYZ(input_val); % transform CIE1931 xyY to XYZ
  flare=repmat(XYZ(:,1),1,n);%min(input_val,[],2);
  XYZ=XYZ-flare;
  corr_val=XYZ2xyY(XYZ);
  corr_val(corr_val<0)=0;
  corr_val(isnan(corr_val))=0;
  min_val=flare(:,1);
  max_val=input_val(:,n);%max(input_val,[],2);
  flare=XYZ2xyY(flare);
else
  error('input_val should be raw lum or xyY values ([1 (CIE1931 Y) x n] or [3 (CIE1931 x,y,Y) x n]). check input variable');
end

% plotting
if display_flg
  
  scrsz=get(0,'ScreenSize');
  figure('Name','Flare Correction Result',...
         'NumberTitle','off',...
         'Position',[scrsz(3)/4,scrsz(4)/4,scrsz(3)/2,scrsz(4)/2]);
  
  subplot(2,7,[1,2,8,9]);
  PlotCIE1931xy([],[],0); hold on;
  plot(input_val(1,:),input_val(2,:),'ro');
  title('CIE1931 xy without Flare Correction');
  
  subplot(2,7,[3,4,10,11]);
  PlotCIE1931xy([],[],0); hold on;
  plot(corr_val(1,:),corr_val(2,:),'go');
  title('CIE1931 xy with Flare Correction');
  
  subplot(2,7,[5:7]);
  plot(input_val(1:2,:)','o-');
  axis square;
  set(gca,'YLim',[0,0.9]);
  set(gca,'YTick',0:0.2:0.9);
  xlabel('measured point');
  ylabel('CIE 1931 x/y');
  title('CIE 1931 xy without Flare Correction');
  
  subplot(2,7,[12:14]);
  plot(corr_val(1:2,:)','o-');
  axis square;
  set(gca,'YLim',[0,0.9]);
  set(gca,'YTick',0:0.2:0.9);
  xlabel('measured point');
  ylabel('CIE 1931 x/y');
  title('CIE 1931 xy without Flare Correction');

end

return
