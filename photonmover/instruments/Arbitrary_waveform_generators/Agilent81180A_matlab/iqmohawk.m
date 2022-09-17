%
% MOHAWK Calibration
%
function iqmohawk(visaAddr)
  f = iqopen(visaAddr);
  if (isempty(f))
      return;
  end
  
  % ...implement your code here...
  % f is a handle to communicate with Mohawk
  
  fclose(f);
end
