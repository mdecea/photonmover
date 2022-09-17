function iqtools(varargin)
% start iqtools main window
%
% T.Dippon, Keysight Technologies 2011-2019
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 

% Workaround for a bug in the matlab compiler:
% http://www.mathworks.com/support/bugreports/1293244
% Deployed component GUIs and figures have different look and feel than MATLAB desktop
javax.swing.UIManager.setLookAndFeel('com.sun.java.swing.plaf.windows.WindowsLookAndFeel')

argp = 1;
while (nargin >= argp)
    switch upper(varargin{argp})
        case '-OPENGLSOFTWARE'; opengl software;
        case '-OPENGLHARDWARE'; opengl hardware;
        case '-OPENGLHARDWAREBASIC'; opengl hardwarebasic;
        case 'M8070A'; iqmain8070; return;
        case 'SERVER'; IQToolsServer_Launch(varargin{argp+1:end}); return;
        case 'STREAMTOOL'; iqstreamtool; return;
        otherwise; fprintf('unexpexted command line argument: %s\n', varargin{argp});
    end
    argp = argp + 1;
end
iqmain
