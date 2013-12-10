function EXP = ResLibCal_RescalPar2EXP(str, EXP)
% [EXP = ResLibCal_RescalPar2EXP(str): Convert a structure into a ResLib EXP
% 
% searches for ResCal parameter fields from structrue 'str', and fill in a ResLib EXP
% 
% Returns:
%  EXP: ResLib structure

% Calls: str2struct, ResLibCal_EXP2RescalPar

persistent labels

if nargin < 1, return; end
if nargin < 2, EXP = []; end
if ischar(str)
  content = str2struct(str);  % do we directly import an EXP from char ?
else 
  content = str;
end

if isfield(content, 'EXP')    % imported a full ResLibCal structure
  EXP = content.EXP;
  str = '';
end
if isfield(content, 'sample') % imported an EXP structure
  EXP = content;
  str = '';
end

% signification of ResCal fields
  if isempty(labels) % only the first time, then stored as persistent
    [p, labels] = ResLibCal_EXP2RescalPar([]); % get ResCal5 field names
    labels = strtok(labels);
  end
  
  % is this a ResCal structure ?
  if any(isfield(content, labels)), str = content; end
  if isempty(str), return; end
  
  % convert string to structure
  if ischar(str)
    % we search for <tokens>=<value> in the string
    [start,ending,match]=regexp(str, ...
      strcat('\<',labels,'\>(\s)*='),'start','end','match','once');
    p = [];
    for index=find(~cellfun(@isempty, start))
      len   = min(ending{index}+20, length(str));
      value = strtrim(str((ending{index}+1):len)); % remove blanks, pass '='
      value = str2double(strtok(value,[' ;:,' sprintf('\n\t\f') ])); % extract next word
      if isfinite(value)
        p.(labels{index}) = value;
      end
    end
    if ~isempty(p)
      str = p; % now a structure
    end
  end

  % handle input as a numerical vector: ResCal file
  if isnumeric(str) && isvector(str)
    
    if numel(str) == 42 % legacy ResCal5 .par file
      labels=labels(1:42);
      str = mat2cell(str(:),ones(1,length(str)));
      str = cell2struct(str(:),labels(:),1);  % make a structure
    elseif numel(str) == 27
      labels=labels(42+(1:27));
      str = mat2cell(str(:),ones(1,length(str)));
      str = cell2struct(str(:),labels(:),1);  % make a structure
    end
  end
  
  % field names to search for are in 'labels'

  if isstruct(str)
    % field names provided in input structure  
    fields = fieldnames(str);
    p=[];
    for index=1:length(fields)
      found=find(~cellfun(@isempty, strfind(labels, fields{index})));
      if length(found) > 1
        % check if one of the matches is exact
        if length(find(strcmp(fields{index}, labels(found))))==1
          found=found(strcmp(fields{index}, labels(found)));
        else
          disp([ mfilename ': Token ' fields{index} ' matches more than one ResCal parameter.'])
          disp(labels(found))
          disp([ 'Using first match ' labels{found(1)} ])
          found = found(1);
        end
      elseif isempty(found), continue; end
      p.(labels{found}) = str.(fields{index});
    end
  end
  % now convert ResCal clean 'p' structure to ResLib EXP

  % ResCal parameters (pres: 42)
  if isfield(p,'DM'),   EXP.mono.d     = p.DM; end
  if isfield(p,'DA'),   EXP.ana.d      = p.DA; end
  if isfield(p,'ETAM'), EXP.mono.mosaic= p.ETAM; end
  if isfield(p,'ETAA'), EXP.ana.mosaic = p.ETAA; end
  if isfield(p,'ETAS'), EXP.sample.mosaic = p.ETAS; end
  if isfield(p,'SM'),   EXP.mono.dir = p.SM; end
  if isfield(p,'SS'),   EXP.sample.dir = p.SS; end
  if isfield(p,'SA'),   EXP.ana.dir = p.SA; end
  if isfield(p,'KFIX'), 
    V2K  = 1.58825361e-3;
    VS2E = 5.22703725e-6;
    EXP.Kfixed = p.KFIX; EXP.Lfixed=2*pi/EXP.Kfixed; V=EXP.Kfixed/V2K; EXP.efixed=V*V*VS2E;
  end
  if isfield(p,'FX')
    if p.FX==2, EXP.infin=-1; else EXP.infin=1; end
  end
  if isfield(p,'ALF1') && isfield(p,'ALF2') && isfield(p,'ALF3') && isfield(p,'ALF4')
    EXP.hcol = [ p.ALF1 p.ALF2 p.ALF3 p.ALF4 ];
  end
  if isfield(p,'BET1') && isfield(p,'BET2') && isfield(p,'BET3') && isfield(p,'BET4')
    EXP.vcol = [ p.BET1 p.BET2 p.BET3 p.BET4 ];
  end
  if isfield(p,'AS'), EXP.sample.a=p.AS; end
  if isfield(p,'BS'), EXP.sample.b=p.BS; end
  if isfield(p,'CS'), EXP.sample.c=p.CS; end
  if isfield(p,'AA'), EXP.sample.alpha=p.AA; end
  if isfield(p,'BB'), EXP.sample.beta= p.BB; end
  if isfield(p,'CC'), EXP.sample.gamma=p.CC; end
  if isfield(p,'AX') && isfield(p,'AY') && isfield(p,'AZ')
    EXP.orient1=[p.AX p.AY p.AZ];
  end
  if isfield(p,'BX') && isfield(p,'BY') && isfield(p,'BZ')
    EXP.orient2=[p.BX p.BY p.BZ];
  end
  if isfield(p,'QH'), EXP.QH=p.QH; end
  if isfield(p,'QK'), EXP.QK=p.QK; end
  if isfield(p,'QL'), EXP.QL=p.QL; end
  if isfield(p,'EN'), EXP.W =p.EN; end
  
% Popovici parameters (pinst: 27)
  if isfield(p,'WB'), EXP.beam.width     =p.WB; end
  if isfield(p,'HB'), EXP.beam.height    =p.HB; end
  if isfield(p,'WS'), EXP.sample.width   =p.WS; end
  if isfield(p,'HS'), EXP.sample.height  =p.HS; end
  if isfield(p,'TS'), EXP.sample.depth   =p.TS; end
  if isfield(p,'WD'), EXP.detector.width =p.WD; end
  if isfield(p,'HD'), EXP.detector.height=p.HD; end
  if isfield(p,'WM'), EXP.mono.width     =p.WM; end
  if isfield(p,'HM'), EXP.mono.height    =p.HM; end
  if isfield(p,'TM'), EXP.mono.depth     =p.TM; end
  if isfield(p,'WA'), EXP.ana.width     =p.WA; end
  if isfield(p,'HA'), EXP.ana.height    =p.HA; end
  if isfield(p,'TA'), EXP.ana.depth     =p.TA; end
  if isfield(p,'L1') && isfield(p,'L2') && isfield(p,'L3') && isfield(p,'L4')
    EXP.arms=[p.L1 p.L2 p.L3 p.L4];
  end
  if isfield(p,'RMH'), EXP.mono.rh=1/p.RMH; end
  if isfield(p,'RMV'), EXP.mono.rv=1/p.RMV; end
  if isfield(p,'RAH'), EXP.mono.ah=1/p.RAH; end
  if isfield(p,'RAV'), EXP.mono.av=1/p.RAV; end

% end ResLibCal_RescalPar2EXP

