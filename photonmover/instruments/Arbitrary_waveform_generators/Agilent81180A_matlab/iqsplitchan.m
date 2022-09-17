function [iqsplit, chMapNew] = iqsplitchan(iqdata, chMap)
% separate iqdata into multiple columns if channel map contains more than
% one channel per vector. Use this function e.g. in preparation for applying
% corrections, where it is necessary to apply different pre-distortion per
% physical channel
if (size(chMap,2) ~= 2*size(iqdata,2))
    error('chMap must have twice the number of columns of iqdata');
end
chMapNew = chMap;
% split real & imaginary parts into separate columns
iqsplit = zeros(size(iqdata, 1), 2*size(iqdata, 2));
iqsplit(:,1:2:size(iqsplit,2)) = real(iqdata);
iqsplit(:,2:2:size(iqsplit,2)) = imag(iqdata);

% make sure each input vector is mapped to no more than one channel
for col = 1:size(chMap,2)
    % find all the channels in this column
    chs = find(chMap(:,col));
    % if there are more than 2 channels, duplicate the
    % corresponding vectors and update the channel map
    for k = 2:length(chs)
        % check next real/imaginary column
        m = col + 2;
        while (m <= size(chMapNew,2))
            if (isempty(find(chMapNew(:,m), 1)))
                break;
            end
            m = m + 2;
        end
        % now, m points to an empty column
        chMapNew(chs(k), col) = 0;     % clear the old channel map bit
        chMapNew(chs(k), m) = 1;       % set the new one
        iqsplit(:,m) = iqsplit(:,col); % duplicate the input vector
        if (mod(m,2) == 1)             % make sure we always have an even number of columns
            chMapNew(:,m+1) = 0;
            iqsplit(:,m+1) = 0;
        end
    end
end
% caller can combine back into complex vectors:
% iqdata = complex(iqsplit(:,1:2:size(iqsplit,2)), iqsplit(:,2:2:size(iqsplit,2)));
