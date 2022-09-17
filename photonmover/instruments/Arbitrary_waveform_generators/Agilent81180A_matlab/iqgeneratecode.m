function iqgeneratecode(handles, code)
% generate MATLAB code for IQTools functions
h = iqcodeview;
ch = get(h, 'Children');
editText = ch(find(strcmp(get(ch, 'Tag'), 'editText')));
code2 = sprintf('%%\n%% automatically generated code by IQTools\n%%\n%s\n', code);
set(editText, 'String', cellstr(code2));
