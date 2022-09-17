%
% wrapper around waitbar
%
classdef iqwaitbar < handle
    properties % (SetAccess = private)
        w            % the waitbar
    end
    methods
        % constructor - usage: iqwaitbar(msg) or iqwaitbar(msg,title)
        function this = iqwaitbar(msg, title)
            if (~exist('title', 'var'))
                title = 'Please wait...';
            end
            this.w = waitbar(0, msg, 'Name', title, ...
                'CreateCancelBtn','waitbar(1, gcbf, ''Canceling...''); setappdata(gcbf,''canceling'',1)');
            setappdata(this.w, 'canceling', 0);
        end
        
        function update(obj, percent, msg)
            if (~obj.canceling())
                if (exist('msg', 'var'))
                    waitbar(percent, obj.w, msg);
                else
                    waitbar(percent, obj.w);
                end
            end
        end
        
        function result = canceling(obj)
            result = getappdata(obj.w, 'canceling');
        end
        
        function delete(obj)
            delete(obj.w);
        end
    end
end
