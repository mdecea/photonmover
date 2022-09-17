function iqeyeplot(sig, fs, spb, nEyes, figNum, interpolate)
% plot an eye diagram of a waveform <sig> that is sampled with sample rate
% <fs> and <spb> samples per bit/symbol. <nEyes> is the number of "eyes" to
% be plotted (default: 2).
% If <interpolate> is greater than zero, the waveform will be re-sampled to
% <interpolate> points per UI. For legacy reasons, a value of 1 will be
% treated as 16
sig = real(sig);
if (~exist('nEyes', 'var'))
    nEyes = 2;
end
if (~exist('figNum', 'var'))
    figNum = 4;
end
if (~exist('interpolate', 'var') || interpolate == 1)
    interpolate = 16;
end
% interpolate to get a more realistic eye
factor = ceil(interpolate / spb);
if (interpolate > 0 && factor > 1)
    sig = iqresample(sig, length(sig)*factor);
    sig = sig(50:end); % waveform may not be periodic - wait until filter is fully immersed
    fs = fs * factor;
    spb = spb * factor;
end
% number of samples
nsamples = length(sig);
% number of symbols
nsym = floor(nsamples / spb);
% time axis scaling
ttime = spb/fs*nEyes;
if (ttime < 1e-9)
    tscale = 1e12;
    tunit = 'ps';
elseif (ttime < 1e-6)
    tscale = 1e9;
    tunit = 'ns';
elseif (ttime < 1e-3)
    tscale = 1e6;
    tunit = 'us';
elseif (ttime < 1)
    tscale = 1e3;
    tunit = 'ms';
else
    tscale = 1;
    tunit = 'sec';
end
% amplitude of the signal (just needed for "nice" looking plot)
amplitude = max(sig) - min(sig);
m1 = min(sig) - 0.05 * amplitude;
m2 = max(sig) + 0.05 * amplitude;
figure(figNum); clf; hold on;
% plot a vertical line per symbol boundary
% for i=0:nEyes
%     plot(tscale*[i*spb/fs i*spb/fs], [m1 m2], 'k--');
% end
% plot eye diagram
for i=0:min(nsym-nEyes-1, 1000)
    s1 = ceil(i*spb);
    s2 = floor((i+nEyes)*spb);
    t = tscale * ((s1:s2)/fs - i*spb/fs);
    plot(t, sig(s1+1:s2+1), '-');
end
xlim([0 tscale*(nEyes*spb/fs)]);
ylim([m1 m2]);
xlabel(tunit);
set(gcf(), 'Name', 'Eye diagram');
hold off;
