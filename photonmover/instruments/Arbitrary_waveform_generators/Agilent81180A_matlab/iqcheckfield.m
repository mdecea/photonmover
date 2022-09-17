function [result, value] = iqcheckfield(hObject, type, minVal, maxVal)
%
% check an edit field for valid range
% if the content is not valid, set background color to red and return 0
% if the field content is valid, set background color to white and return 1
% if result is returned as 1, value contains the numeric value of the edit
% field
%
% hObject is a handle to an "edit" uicontrol
% type is a string that can contains the words 'scalar', 'integer',
% 'notempty'
% minVal and maxVal can contain numeric values for min/max or empty
%
result = 1;
msg = [];
value = [];
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
    result = 0;
    msg = ex.message;
end
if (result ~= 0 && ~isempty(strfind(type, 'scalar')) && ~isscalar(value))
    result = 0;
    msg = 'Value does not evaluate to a scalar';
end
if (result ~= 0 && ~isempty(strfind(type, 'notempty')) && isempty(value))
    result = 0;
    msg = 'List of values must not be empty';
end
if (result ~= 0 && ~isempty(strfind(type, 'integer')) && ~isempty(find(value ~= floor(value))))
    result = 0;
    if (~isempty(strfind(type, 'scalar')))
        msg = 'Value must be an integer';
    else
        msg = 'Values must be integers';
    end
end
if (length(minVal) > 1 && length(maxVal) > 1)  % special case for multiple ranges
    if (isempty(find(value >= minVal & value <= maxVal, 1)))
        result = 0;
        msg = sprintf('Value out of range');
    end
else
    if (result ~= 0 && ~isempty(minVal) && (~isempty(find(value < minVal, 1))))
        result = 0;
        msg = sprintf('Value out of range. Minimum is %s', iqengprintf(minVal(end)));
    end
    if (result ~= 0 && ~isempty(maxVal) && (~isempty(find(value > maxVal, 1))))
        result = 0;
        msg = sprintf('Value out of range. Maximum is %s', iqengprintf(maxVal(1)));
    end
end
if (result == 1)
    set(hObject, 'BackgroundColor', 'white');
else
    set(hObject, 'BackgroundColor', 'red');
    if (~isempty(msg))
        msgbox(msg);
    end
end

