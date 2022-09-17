function result = iqdelay(data, fs, delay)
% Apply a <delay> to an input vector <data> with samplerate <fs>.
% <delay> is given in seconds (does not have to be multiple of the
% sample interval). 
% If data is complex, keeps the imaginary part unchanged.

% determine number of samples
n = length(data);
% make sure the input data has the right format (row-vector)
if (size(data,1) == 1)
    cflag = 0;
elseif (size(data,2) == 1)
    cflag = 1;
    data = reshape(data, 1, n);
else
    error('expect a vector');
end
% the algorithm works only for even number of samples
if (mod(n,2) ~= 0)
    n = 2 * n;
    data = repmat(data, 1, 2);
    dflag = 1;
else
    dflag = 0;
end
% convert to frequency domain
fdata = fftshift(fft(real(data)))/n;
% create linear phase vector (= delay)
phd = (-n/2:n/2-1)/n*2*pi*(delay*fs);
% convert it into frequency domain
fdelay = exp(1j*(-phd));
% apply delay (convolution ~ multiplication)
fresult = fdata .* fdelay;
% ...and convert back into time domain
result = real(ifft(fftshift(fresult)))*n;
% get imaginary part from input vector
if (~isreal(data))
    result = complex(result, imag(data));
end
if (cflag)
    result = result.';
end
if (dflag)
    result = result(1:n/2);
end
