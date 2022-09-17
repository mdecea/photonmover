% Program the function generator. Only way I have been able to do this.

config = struct();
config.model = '81180A';
config.connectionType = 'visa';
config.visaAddr = 'GPIB1::2::INSTR';

f = 1e6; % desired frequency
Vpp = 0.2; % desired amplitude (in V)
offset = 0.1; % desired offset (in V)
samples_per_bit = 128;
waveform = 'prbs';  % 'square' or 'prbs' or 'double_freq' or 'sin'
f2 = 510e3;

sampling_freq = samples_per_bit*f;

if sampling_freq > 4.2e9
    fprintf("The sample frequency is too high. Reduce either samples per bit or desired bit speed.")
    return
end

if sampling_freq < 10e6
    fprintf("The sample frequency is too low. Increase either samples per bit or desired bit speed.")
    return
end


pattern = [];
% Generate the pattern
if strcmp(waveform, 'square')
    bit_pattern = '101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010';
    for i = 1:length(bit_pattern)
        pattern = [pattern, offset + str2num(bit_pattern(i))*ones(1,samples_per_bit)*Vpp/2 - Vpp/2*(1-str2num(bit_pattern(i)))*ones(1,samples_per_bit)];
    end
    
elseif strcmp(waveform, 'prbs')
    bit_pattern = '1000001100001010001111001000101100111010100111110100001110001001001101101011011110110001101001011101110011001010101111111000000';
    clk_pattern = '1010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101';
    pattern_signal = [];
    %pattern_clk = [];
    for i = 1:length(bit_pattern)
        pattern_signal = [pattern_signal, offset + str2num(bit_pattern(i))*ones(1,samples_per_bit)*Vpp/2 - Vpp/2*(1-str2num(bit_pattern(i)))*ones(1,samples_per_bit)];
        %pattern_clk = [pattern_clk, str2num(clk_pattern(i))*ones(1,samples_per_bit)*0.2 - 0.2*(1-str2num(clk_pattern(i)))*ones(1,samples_per_bit)];
    end
    pattern = pattern_signal; % + 1i*pattern_clk;
    
elseif strcmp(waveform, 'double_freq')
    t = (1:32*5000)/sampling_freq;
    pattern = offset + Vpp*sin(2*pi*f*t) + Vpp*sin(2*pi*f2*t);

elseif strcmp(waveform, 'sin')
    t = (1:32*5000)/sampling_freq;
    pattern = offset + Vpp*sin(2*pi*f*t);
end


plot(real(pattern))
hold on
plot(imag(pattern))

if mod(length(pattern),32) ~= 0
   fpintf('Pattern length must be a multiple of 32!')
   return
end

if length(pattern) > 16e6
   fpintf('Pattern too long!')
   return
end
    


% This is the command that talks to the instrument
iqdownload(pattern, sampling_freq, 'channelMapping', [1, 0; 0, 0], 'arbConfig', config);



