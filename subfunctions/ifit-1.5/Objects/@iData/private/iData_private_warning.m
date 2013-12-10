function iData_private_warning(a,b)
% function iData_private_warning
%
% iData_private_warning('enter');  stores the current warning level and unactivate 
%                                  further warning when level is higher than 1.
% iData_private_warning('exit');   restores the previous warning level state
% iData_private_warning('mfilename','MSG');

% the warning should be displayed:
% * when the 'stack' indicates an execution from a master command
% * when the message is different from previous ones

persistent warn;   % store the warning level

if nargin == 0
  a = 'enter'; b='unknown';
end

if isempty(warn)  % create the persistent variable the first time
  warn.level  ={};  % will hold the caller history
end

% ==============================================================================
% standard messages (a=not a mfilename)

% reset/initiate the warning level stack (e.g. when outdated/invalid)
if isempty(warn.level) || strcmp(a, 'reset')
  warn.level = {'root'};
  warn.date  = clock;
  warn.lastwarn='';
  this_state = [ ...
    warning('on','iData:setaxis') warning('on','iData:getaxis') ...
    warning('on','iData:get')     warning('on','iData:subsref') ];
  warn.structs= { this_state };
end

if strcmp(a, 'enter')
  % save the current warning state (level)
  warn.date = clock;
  warn.level{end+1} = b;% store caller mfilename (passed as arg to warning call)
  %disp([ a ' ' b ]); 
  %disp(warn.level);
  % unactivate warnings if not directly the caller
  if length(warn.level) >= 3  % first is 'root', then main caller, then children
    this_state = [ ...
      warning('off','iData:setaxis') warning('off','iData:getaxis') ...
      warning('off','iData:get')     warning('off','iData:subsref') ];
  else
    this_state = warn.structs{end}; % copy the one from the previous state
  end
  warn.structs{end+1} = this_state;
  warn.lastwarn = lastwarn;
  
elseif strcmp(a, 'exit')
  % restore the previous warning state
  this_state = warn.structs{end};
  warning(this_state); % restore previous state
  warn.structs(end) = [];
  warn.level(end) = [];         % remove last entry
  %disp([ a ' ' b ]); 
  %disp(warn.level);
  warn.lastwarn='';
elseif nargin == 2     % normal warning message ===============================
  if ~strcmp(lastwarn, warn.lastwarn)
    b = [ 'iData/' a ': ' b ];  % MSG
    if any(strcmp(a,{'setaxis','getaxis'}))
      if length(warn.level) < 3
        fprintf(1, [ 'Warning: ' b '\n' ]);
      end
    else
      a = [ 'iData:' a ];         % ID
      warning(a,sprintf(b));
    end
    warn.lastwarn = lastwarn;
  end
end

