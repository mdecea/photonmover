function [freq, corr1new, corr2new] = iqmergecorr(freq1, corr1, freq2, corr2)
%
% merge two frequency/phase corrections to common frequency points.
% If the frequency points are not the same, they will be merged and
% corrections interpolated. If the frequency ranges are different,
% corrections will be extrapolated using the outermost value
% corr1 and corr2 can be column-vectors or arrays
%
if (isempty(freq1))
    freq1 = freq2;
    corr1 = ones(length(freq1));
end
if (isempty(freq2))
    freq2 = freq1;
    corr2 = ones(length(freq2));
end
% combine the frequencies - use round to avoid duplicate entries with minimal deviations
freq = union(round(freq1), round(freq2));
% interpolate corr1 and corr2 to new frequency points
corr1new = zeros(length(freq), size(corr1,2));
for i = 1:size(corr1,2)
    corr1mag = interp1([min(freq)-1; freq1; max(freq)+1], [abs(corr1(1,i)); abs(corr1(:,i)); abs(corr1(end,i))], freq, 'linear');
    corr1phs = interp1([min(freq)-1; freq1; max(freq)+1], unwrap([angle(corr1(1,i)); angle(corr1(:,i)); angle(corr1(end,i))]), freq, 'linear');
    corr1new(:,i) = corr1mag .* exp(1i * corr1phs);
end
corr2new = zeros(length(freq), size(corr2,2));
for i = 1:size(corr2,2)
    corr2mag = interp1([min(freq)-1; freq2; max(freq)+1], [abs(corr2(1,i)); abs(corr2(:,i)); abs(corr2(end,i))], freq, 'linear');
    corr2phs = interp1([min(freq)-1; freq2; max(freq)+1], unwrap([angle(corr2(1,i)); angle(corr2(:,i)); angle(corr2(end,i))]), freq, 'linear');
    corr2new(:,i) = corr2mag .* exp(1i * corr2phs);
end

