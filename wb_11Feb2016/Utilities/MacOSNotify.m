function status=MacOSNotify(msg,titl,subtitl,alert)
%NOTIFY  Display OS X notification message window
%   NOTIFY(MESSAGE,TITLE,SUBTITLE,SOUND)

rep = @(str)strrep(regexprep(str,'["\\]','\\$0'),'''','\"');
cmd = ['osascript -e ''display notification "' rep(msg)];
if nargin > 1 && ischar(titl)
    cmd = [cmd '" with title "' rep(titl)];
    if nargin > 2 && ischar(subtitl)
        cmd = [cmd '" subtitle "' rep(subtitl)];
        if nargin > 3 && ischar(alert) && ~isempty(alert)
            cmd = [cmd '" sound name "' rep(alert)];
        end
    end
else
    cmd = [cmd '" with title "Matlab'];
end
status = system([cmd '"''']);

end

%old way using terminal-notifier
% 
% function MacOSNotify(message)
%   escaped_message = strrep(message, '"', '\"');
%   [~, ~] = system(['/usr/local/bin/terminal-notifier ' ...
%                    '-title Matlab ' ...
%                    '-group com.mathworks.matlab ' ...
%                    '-activate com.mathworks.matlab ' ...
%                    '-sender com.mathworks.matlab ' ...
%                    '-message "' escaped_message '"']);
% end
% 
