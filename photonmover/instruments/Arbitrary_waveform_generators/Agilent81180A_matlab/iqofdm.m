function [iqdata, data, channelMapping]= iqofdm(varargin)
% Generate OFDM waveform
% Parameters are passed as property/value pairs. Properties are:
% 'correction' - decide if amplitude corretion is used
% 'fftlength' - FFT Length each OFDM Symbol 
% 'oversampling' - Oversampling factor
% 'resourcemap' - Resource map array for OFDM signal
% 'resourcemodulation' - Resource modulation array for OFDM signal
% 'quamidentifier' - Quam identifier array for OFDM signal generation
% 'quamlevels' - Quam level array for OFDM signal generation
% 'pilotdefinitions' - Array with defined pilot values (real, imag, ...)
% 'preambleiqvalues' - Array with defined preamble values (real, imag, ...)
% 'numguardlowersubcarriers' - Number of lower subcarriers, N=0,1,2,....
% 'numguardhighersubcarriers' -  Number of upper subcarriers, N=0,1,2,....
% 'resourcerepeatindex' - Loop back to symbol defined by index, N=0,1,...,('numsymbols'-1)
% 'prefix' - Guard interval, value must be 1/N, N=1,2,3,.... 
% 'ofdmsamplefrequency' - Sample frequency for OFDM signal in Hz
% 'fshift' - Center frequency in Hz OFDM signal uses only one channel if >0
% 'burstinterval' - Length of the pause in s, after N='numsymbols, if 0 two channel OFDM Signal is created otherwise one channel' 
% 'numsymbols' - Number of Symbols to be created in one package
% 'isranddata' - Decision if randomdata is created or user defined data is used (0=user data, 1=randomdata)
% 'data' - user defined data if 'isranddata' is not selected
% 'numpackages' - Number of OFDM packages with 'numsymbols' 
% 'NumWindow' - Number of Samples for wich a windowing is used
% 'FilterTyp' - Filter function used for windowing
% If called without arguments, opens a graphical user interface to specify
% parameters
%
% Thomas Dippon, Keysight Technologies 2011-2016
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 

if (nargin == 0)
    iqofdm_gui;
    return;
end

    correction = 0;
    FFTLength=8;
    oversampling=4;
    oversampling = 4;
    ResourceMap = [0, 1, 0, 4, 0, 1, 0];    %Resource Map needs to be coded in Format: -4,-3,-2,-1,0,1,2,3 for FFT Lenght of 8 
    ResourceModulation = [3, 3, 3, 1, 3, 3, 1];
    QuamIdentifier = [0, 1, 2, 3, 4, 5];
    QuamLevels = [0, 1, 2, 4, 6, 8]; 
    PilotDefinitions = [1, -1/3,1/3,- 1];   
    PreambleIQValues = [0.95,0.95,1.41,1.41];     
    numGuardLowerSubcarriers = 1;            
    numGuardHigherSubcarriers = 0;
    ResourceRepeatIndex=0; 
    prefix=0.0;
    OFDMSystemFrequency=2e9;
    fshift=2e9;
    BurstInterval=0;
    IsRandata=1;
    NumSymbols=143;
    NumPackages=1;
    NumWindow=0; 
    FilterTyp='blackman';
    
    iqdatapack=[];     %OFDM signal returned by function
    datapack=[];       %Binary data returned by function
    data = [];         %Array containing the binary data for one pack
    datalenght=0;      %Length of data array (for testing)
    FFTData = [];      %FFT Data for one symbol (without subcarrier)
    IFFTData = [];     %Time Signal for one symbol 
    iqdata=[];         %Array containing iq data for one package
    channelMapping = [1 0; 0 1];
 

    
i = 1;
while (i <= nargin)
    if (ischar(varargin{i}))
        switch lower(varargin{i})
            case 'correction';                correction = varargin{i+1};
            case 'fftlength';                 FFTLength = varargin{i+1};
            case 'oversampling';              oversampling = varargin{i+1};
            case 'resourcemap';               ResourceMap = varargin{i+1};
            case 'resourcemodulation';        ResourceModulation = varargin{i+1};
            case 'quamidentifier';            QuamIdentifier = varargin{i+1};
            case 'quamlevels';                QuamLevels = varargin{i+1};
            case 'pilotdefinitions';          PilotDefinitions = varargin{i+1};
            case 'preambleiqvalues';          PreambleIQValues = varargin{i+1};
            case 'numguardlowersubcarriers';  numGuardLowerSubcarriers = varargin{i+1};
            case 'numguardhighersubcarriers'; numGuardHigherSubcarriers = varargin{i+1};
            case 'resourcerepeatindex';       ResourceRepeatIndex = varargin{i+1};
            case 'prefix';                    prefix = varargin{i+1};
            case 'ofdmsamplefrequency';       OFDMSystemFrequency=varargin{i+1};
            case 'fshift';                    fshift=varargin{i+1};
            case 'burstinterval';             BurstInterval=varargin{i+1};
            case 'numsymbols';                NumSymbols=varargin{i+1};
            case 'isranddata';                IsRandata=varargin{i+1};
            case 'data';                      data=varargin{i+1};
            case 'numpackages';               NumPackages=varargin{i+1};
            case 'numwindow';                 NumWindow=varargin{i+1};
            case 'channelmapping';            channelMapping = varargin{i+1};
            otherwise error(['unexpected argument: ' varargin{i}]);
        end
    else
        error('string argument expected');
    end
    i = i+2;
end

%If Signal is bursted, control if the Burstlength is a multiplier of AWG
%Sample Rate (necessary, because a natural number of zeros need to be
%filled into the signal as burst period)
if(BurstInterval>0)
   if( BurstInterval*(OFDMSystemFrequency*oversampling)~=round(BurstInterval*(OFDMSystemFrequency*oversampling)))
      N=BurstInterval*(OFDMSystemFrequency*oversampling);
      N=ceil(N);
      BurstInterval=N/(OFDMSystemFrequency*oversampling);
   end
elseif(BurstInterval<0)
      BurstInterval=0;
end

%If it is selected not to create random data and the data pattern to be looped is empty,
%then create random data
if(IsRandata==0)
   if(length(data)==0) 
      IsRandata=1;
      msgbox('Data pattern to be looped is empty, random data will be created','Message');
   end
end

%Calculate the number of Symbols which are coded via one resource map entry
%CalculatedValues (must be n=1,2,3,... or Resource Map must be changed)
%value is return value used to control if NumSymbolsperMap is N=1,2,3,...
[value NumSymbolsperMap]=calculateN(FFTLength,ResourceMap,numGuardHigherSubcarriers,numGuardLowerSubcarriers); 
%If more than one Symbol is used, the created binary data and the FFT
%data are repeated from the Index Repeat on in the Resource Map Array 
Repeatat=ResourceRepeatIndex*(FFTLength-numGuardLowerSubcarriers-numGuardHigherSubcarriers)+1;

 
%Generate modem objects (to be faster defined at the beginning)
%Set array type
hmodem=[modem.qammod(2)];
%Demodulation Objects
hdemodem=[modem.qamdemod(hmodem(1))];

 for i=1:length(QuamLevels)
   
   if(isscalar(QuamLevels(i))&& QuamLevels(i)>=0)
       
       switch QuamLevels(i)
           case 0 
           %unknown modulation (set to BPSK)    
           hmodem(i)= modem.pskmod(2); 
           hdemodem(i)=modem.pskdemod(hmodem(i));
           case 1 
           %BPSK Modulation    
           hmodem(i)= modem.pskmod(2);
           hdemodem(i)=modem.pskdemod(hmodem(i));
           case 2   
           %4 Quam Modulation
           hmodem(i)= modem.qammod('M',2^QuamLevels(i),'SymbolOrder','Gray');
           hdemodem(i)=modem.qamdemod(hmodem(i));
           %4PSK Modulation (alternatively)
           %hmodem(i)= modem.pskmod(4); 
           %hdemodem(i)=modem.pskdemod(hmodem(i));  
           case 3
           %8PSK Modulation
           hmodem(i)= modem.pskmod(8); 
           hdemodem(i)=modem.pskdemod(hmodem(i)); 
           %8Quam Modulation (alternatively)
           %hmodem(i)= modem.qammod('M',2^QuamLevels(i),'SymbolOrder','Gray');
           %hdemodem(i)=modem.qamdemod(hmodem(i));  
           case 4 
           %Quam 16 modulation    
           hmodem(i)= modem.qammod('M',2^QuamLevels(i),'SymbolOrder','user-defined');    
           hmodem(i).SymbolMapping=[14 6 2 10 12 4 0 8 13 5 1 9 15 7 3 11];
           %hmodem(i).SymbolMapping=[0 1 3 2 4 5 7 6 12 13 15 14 8 9 11 10]
           hdemodem(i)=modem.qamdemod(hmodem(i));
           hdemodem(i).SymbolMapping=[14 6 2 10 12 4 0 8 13 5 1 9 15 7 3 11];
           %hdemodem(i).SymbolMapping=[0 1 3 2 4 5 7 6 12 13 15 14 8 9 11 10]
           otherwise
           %higher Quam modulations    
           hmodem(i)= modem.qammod('M',2^QuamLevels(i),'SymbolOrder','Gray');
           hdemodem(i)=modem.qamdemod(hmodem(i)); 
       end
       
   else
           %Set to BPSK if QuamLevel entry is not valid 
           hmodem(i)= modem.qammod(2);             
           hdemodem(i)=modem.qamdemod(hmodem(i));
   end
      
           hmodem(i).inputtype='bit';
           hdemodem(i).outputtype='bit';
 end

%create the windowing filter if NumWindow is grater than zero
if(NumWindow>0)
    
    switch FilterTyp
        case 'blackman'
        Windowfiltall=transpose(blackman(2*NumWindow));
        otherwise %use blackman if undefined
         Windowfiltall=transpose(blackman(2*NumWindow));    
    end
    
    
    Winfiltleft=Windowfiltall(1:NumWindow);
    Winfiltright=Windowfiltall((NumWindow+1):2*NumWindow);
end

%store the data vector in datas, necessary if user defined data is used
datas=data;

for a=1:NumPackages 

  data=[];

  if(IsRandata==1)
     
      %Start to create the 1th symbol
       nextSymbol=1;

       for i=1:NumSymbols
          symboldata= createdataforonesymbol (nextSymbol,hmodem,FFTLength,numGuardLowerSubcarriers, numGuardHigherSubcarriers,ResourceMap,QuamLevels,QuamIdentifier,ResourceModulation); 
    
          if(i>=NumSymbolsperMap)
          %Loop the Symbols from the Symbol given via ResourceRepeatIndex (create the first 1th Symbol for Resource Repeat Index 0) 
          nextSymbol=ResourceRepeatIndex+1;
          else
          nextSymbol=nextSymbol+1;       
          end
      
       data=cat(2,data,symboldata);
    
       end

  else
    
      nextSymbol=1;
      lengthdata=0;
    
      for i=1:NumSymbols
      symboldatalength= calculatebindatapersymbol (nextSymbol,hmodem,FFTLength,numGuardLowerSubcarriers, numGuardHigherSubcarriers,ResourceMap,QuamLevels,QuamIdentifier,ResourceModulation); 
    
        if(i>=NumSymbolsperMap)
          %Loop the Symbols from the Symbol given via ResourceRepeatIndex (create the first 1th Symbol for Resource Repeat Index 0) 
          nextSymbol=ResourceRepeatIndex+1;
        else
          nextSymbol=nextSymbol+1;       
        end
      lengthdata=lengthdata+symboldatalength;
    
      end
    
      N=floor(lengthdata/length(datas));
      s=repmat(datas,1,1);
      dataN=repmat(datas,1,N);
      restdatabits=lengthdata-N*length(datas);
      dataN=cat(2,dataN,datas(1:restdatabits));
      data=dataN;
    
  end
   
  datalenght=length(data);

  iqdata=[];
  %next Pilot to be read when repeat is started at resource repeat index 
  PilotStart=searchpilotpreamindex(ResourceMap,Repeatat,1);
  %next Preamble to be read when repeat is started at resource repeat index
  PreambleStart=searchpilotpreamindex(ResourceMap,Repeatat,3);
  %Start to create the 1th symbol
  nextSymbol=1;
  %next Pilot to be read (next map entry in Pilots)
  PilotCarrierIndex=1;
  %next Preamble to be read (next map entry in Preamble)
  PreambleCarrierIndex=1; 
  %start to read data bits at position in data arry
  bitposition=1;

  for i=1:NumSymbols
       [SignalTime_Oversampled,PilotCarrierIndex,PreambleCarrierIndex, bitposition]= createonesymbol (nextSymbol,hmodem,data,FFTLength,numGuardLowerSubcarriers, numGuardHigherSubcarriers, PilotDefinitions, PreambleIQValues,ResourceMap,QuamLevels,QuamIdentifier,ResourceModulation,bitposition,PilotCarrierIndex,PreambleCarrierIndex,oversampling,prefix); 
       if(nextSymbol>=NumSymbolsperMap)
          %Loop the Symbols from the Symbol given via ResourceRepeatIndex (create the first 1th Symbol for Resource Repeat Index 0) 
           nextSymbol=ResourceRepeatIndex+1;
           PilotCarrierIndex=PilotStart;
           PreambleCarrierIndex=PreambleStart;
       else
          nextSymbol=nextSymbol+1;       
       end
       %use window if window parameter is > 0
            if(NumWindow>0)
              SignalTime_Oversampled(1:NumWindow)=SignalTime_Oversampled(1:NumWindow).*Winfiltleft(1:NumWindow); 
              len=length(SignalTime_Oversampled);
              SignalTime_Oversampled(len-NumWindow+1:len)=SignalTime_Oversampled(len-NumWindow+1:len).*Winfiltright(1:NumWindow); 
              SignalTime_Window=SignalTime_Oversampled;
            else
                SignalTime_Window=SignalTime_Oversampled;
            end
       iqdata=cat(2,iqdata,SignalTime_Window);
   end

    if(fshift>0)
     %if the signal is s(t)=s1(t)+j*s2(t), then the real signal
     %s(t)=s1(t)*cos(2*pi*fshift*t)-s2(t)*sin(2*pi*fshift*t)is created
     len = length(iqdata);
     cy = round(len * fshift / (OFDMSystemFrequency*oversampling)); 
     shiftSig = exp(j * 2 * pi * cy * (linspace(0, 1 - 1/len, len)));
     iqdata=iqdata.*shiftSig;
    end

    if(BurstInterval>0)
      %Fill the time signal with N zeros
      arbConfig = loadArbConfig();
      N = round(BurstInterval*(OFDMSystemFrequency*oversampling) / arbConfig.segmentGranularity) * arbConfig.segmentGranularity;
      try
        zerotime=zeros(1,N);
        iqdata=cat(2,iqdata,zerotime);
      catch ex 
        msgbox('Can not add burst interval, burst interval too long','Message')    
      end
    end

    % make column vectors
    iqdata = iqdata.';
    data = data.';
    
   iqdatapack=cat(1,iqdatapack,iqdata);
   datapack=cat(1,datapack,data);

end

iqdata = iqdatapack;

%% apply amplitude correction if necessary
if (correction)
    [iqdata, channelMapping] = iqcorrection(iqdata, OFDMSystemFrequency*oversampling, 'chMap', channelMapping);
end

%% normalize the output
scale = max(max(max(abs(real(iqdata))), max(abs(imag(iqdata)))));
iqdata = iqdata / scale;

assignin('base', 'iqdata', iqdatapack);



function [value N]=calculateN(FFTLength,ResourceMap,uppercarrier,lowercarrier)
       
        if(FFTLength-uppercarrier-lowercarrier>0)
          N=length(ResourceMap)/(FFTLength-uppercarrier-lowercarrier); 
        else
          N=0;
        end
        
        if(round(N)==N&& N>=1)
          value=1; %Value is ok., Resource Map+Carriers longer than FFTLenght
          return;
        end
          value=0; %Value false
      
        
function value=searchpilotpreamindex(ResourceMap,Repeatat,a)
        
        value=0;
        %count number of pilots till repeatat
        if(Repeatat>1)
             
           for i=1:Repeatat-1 
              if(ResourceMap(i)==a)
                 value=value+1;
              end
           end
           if(value==0)
             value=1;
             return
           end
             value=2*value+1;
           else
             value=1;
        end
 
function symboldata= createdataforonesymbol (numnextsymbol,hmodem,FFTLength,numGuardLowerSubcarriers, numGuardHigherSubcarriers,ResourceMap,QuamLevels,QuamIdentifier,ResourceModulation);          
      
      symboldata=[];
      carrierstobecoded=FFTLength-numGuardLowerSubcarriers-numGuardHigherSubcarriers;
      Startcodinginresourcemapindex=(numnextsymbol-1)*carrierstobecoded;
      
       for i=1:carrierstobecoded
         %If Data Case    
         if(ResourceMap(i+Startcodinginresourcemapindex)==0)
           %If Modulation for data Carrier is defined
           if(QuamLevels(QuamIdentifier( ResourceModulation(i+Startcodinginresourcemapindex)+1)+1)~=0) 
             a=randi([0,1],1,QuamLevels(QuamIdentifier( ResourceModulation(i+Startcodinginresourcemapindex)+1)+1) );
             %If Modulation for data carrier is not defined use default (BPSK)
           else
             a=randi([0,1],1,1);  
           end
           symboldata=cat(2,symboldata,a);
         end  
       end
       
%Calculate how many data bits are coded with one symbol (nextSymbol)       
function symboldatalength= calculatebindatapersymbol (numnextsymbol,hmodem,FFTLength,numGuardLowerSubcarriers, numGuardHigherSubcarriers,ResourceMap,QuamLevels,QuamIdentifier,ResourceModulation);    
          
          symboldatalength=0;
          carrierstobecoded=FFTLength-numGuardLowerSubcarriers-numGuardHigherSubcarriers;
          Startcodinginresourcemapindex=(numnextsymbol-1)*carrierstobecoded;
          for i=1:carrierstobecoded
           %If Data Case    
            if(ResourceMap(i+Startcodinginresourcemapindex)==0)
           
               %If Modulation for data Carrier is defined
               if(QuamLevels(QuamIdentifier( ResourceModulation(i+Startcodinginresourcemapindex)+1)+1)~=0)
                 a=QuamLevels(QuamIdentifier( ResourceModulation(i+Startcodinginresourcemapindex)+1)+1);
               %If Modulation for data carrier is not defined use default (BPSK)
               else
                 a=1
               end
               symboldatalength=symboldatalength+a;
            end  
         end
          
          
function [SignalTime_Oversampled,PilotCarrierIndex,PreambleCarrierIndex, bitposition]= createonesymbol (numnextsymbol,hmodem,data,FFTLength,numGuardLowerSubcarriers, numGuardHigherSubcarriers, PilotDefinitions, PreambleIQValues,ResourceMap,QuamLevels,QuamIdentifier,ResourceModulation,bitposition,PilotCarrierIndex,PreambleCarrierIndex,oversampling,prefix) 
   
     carrierstobecoded=FFTLength-numGuardLowerSubcarriers-numGuardHigherSubcarriers;
     %Create Subcarrier Vectors
     Subcarrierlow=zeros(1,numGuardLowerSubcarriers);
     Subcarrierhigh=zeros(1,numGuardHigherSubcarriers);
     %Create FFT Data Vector without subcarriers
     FFTinnerdata=zeros(1, carrierstobecoded);
     
     Startcodinginresourcemapindex=(numnextsymbol-1)*carrierstobecoded;
     
       k=1;
       for i=1:carrierstobecoded
         
           switch ResourceMap(i+Startcodinginresourcemapindex)
           %Case coding of binary data    
           case 0
             %get Quam Identifier
             Index=QuamIdentifier(ResourceModulation(i+Startcodinginresourcemapindex)+1)+1;
             %mod is number of bits to be coded
             mod=QuamLevels(Index);
             %if no modulation decided, use BPSK (default)
             if(mod==0)
               mod=1;
             end
             hmod=hmodem(Index);
             %get the bits to be coded
             subdata=transpose(data(bitposition:(mod+bitposition-1)));
             %calculate the I+jQ values
             remoddata=modulate(hmod,subdata);
             %normalize the modulation (the same scale factor for all modulations)
             scaleFactor=sqrt(sum(abs(hmod.Constellation).^2)/hmod.M);     
             remoddata=remoddata/ scaleFactor;
             FFTinnerdata(k)= remoddata;
             %FFTinnerdata(i)=1 for testing
             bitposition=bitposition+mod;
          case 1
             %Pilot to be decoded
             y=PilotDefinitions(PilotCarrierIndex)+j*PilotDefinitions(PilotCarrierIndex+1);
             PilotCarrierIndex=PilotCarrierIndex+2;
             FFTinnerdata(k)=y;
             %Unknown Pilot (set to default value)
          case 2   
             FFTinnerdata(k)=1+j*0;
             %Preamble Value
          case 3
             y=PreambleIQValues(PreambleCarrierIndex )+j*PreambleIQValues(PreambleCarrierIndex+1);
             PreambleCarrierIndex=PreambleCarrierIndex+2;
             FFTinnerdata(k)=y;
             %Null Carrier
          case 4      
             FFTinnerdata(k)=0;
          case 5
             FFTinnerdata(k)=0;
          end
       k=k+1; 
     end
  
%note ft/2 is not used -ft/2 is used     
FFTData=cat(2,Subcarrierlow,FFTinnerdata,Subcarrierhigh);
%fprintf(sprintf('nextSym: %d, PilotIdx: %d, Pilot: %g\n', numnextsymbol, PilotCarrierIndex, FFTinnerdata(5)));
fill = zeros(1, length(FFTData)/2 * (oversampling - 1));
SignalTime_Oversampled = ifft(fftshift([fill FFTData fill]));

if (prefix~=0)
  SignalTime_Oversampled=cat(2,SignalTime_Oversampled(length(SignalTime_Oversampled)*(1-prefix)+1:length(SignalTime_Oversampled)),SignalTime_Oversampled);   
end
 


  
