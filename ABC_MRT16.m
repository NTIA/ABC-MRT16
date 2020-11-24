function [phi_hat,success]= ABC_MRT16(speech_path,cond_num,n_files,verbose)
%--------------------------Background--------------------------
%ABC_MRT16.m implements the ABC-MRT16 algorithm for objective estimation of 
%speech intelligibility.  The algorithm is discussed in detail in [1] and
%[2].
%
%The Modified Rhyme Test (MRT) is a protocol for evaluating speech
%intelligibility using human subjects [3]. The subjects are presented
%with the task of identifying one of six different words that take the
%phonetic form CVC.  The six options differ only in the leading or
%trailing consonant. MRT results take the form of success rates
%(corrected for guessing) that range from 0 (guessing) to 1 
%(correct identification in every case).  These success rates form a 
%measure of speech intelligibility in this specific (MRT) context.
%
%The 2016 version of Articulation Band Correlation-MRT, (ABC-MRT16) is a 
%signal processing algorithm that processes MRT audio files and produces
%success rates.
%
%The goal of ABC-MRT16 is to produce success rates that agree with those
%produced by MRT. Thus ABC-MRT16 is an automated or objective version of
%MRT and no human subjects are required. ABC-MRT16 uses a very simple and
%specialized speech recognition algorithm to decide which word was spoken.
%This version has been tested on narrowband, wideband, superwideband,
%and fullband speech.
%
%Information on preparing test files and running ABC_MRT16.m can be found
%in the readme file included in the distribution.  ABC_MRTdemo16.m shows
%example use.
%
%--------------------------Use--------------------------
%[phi_hat,success]=ABC_MRT16(speech_path,cond_num,n_files,verbose)
%
% - speech_path is a string that gives the path to the speech files
%
% - cond_num is the condition number, 0 to 99. This is used to form the
%   end of the path and the filenames as specified below.
%
% - n_files is the number of speech files to use, 16 <= N <= 1200.
%   Using more speech files gives a more robust result, but takes longer.
%   One can use filelist.m to generate the list of .wav files required
%   for any valid values of n_files and cond_num.
%
% - verbose is set to any nonzero value to force progress reporting
%
% - success is a column vector with length n_files that gives the success
%   rate for each file involved in the test. The entries in success are
%   the success flags c_j defined in equation (8) in [1].
%
% - phi_hat is a scalar that gives the final intelligibility estimate for
%   the condition.  It is defined in equation (10) of [1], using the values
%   of alpha and beta given in the final full paragraph on page 3 of [1].
%   phi_hat is produced from success by averaging over all files, correcting
%   for guessing and applying an affine transformation.  phi_hat is
%   expected to range from 0 to 1, similar to MRT results. Larger values
%   of phi_hat indicate higher levels of speech intelligibility
%
%--------------------------File Convention--------------------------
%Note that ABC_MRT16.m is expecting a specific naming convention. Here are
%some examples:
%
%ABC_MRT16(e:/soundfiles/MRT/,1,1200,*), requires 1200 .wav
%files of the form e:/soundfiles/MRT/C01/TT_bnn_wm_c01.wav
%
%ABC_MRT16(e:/soundfiles/MRT/,17,16,*), requires 16 .wav
%files of the form e:/soundfiles/MRT/C17/TT_bnn_wm_c17.wav
%
%In every case the base of the filenames takes the form TT_bnn_wm with:
%   TT=F1,F3, M3, or M4 (talker specification)
%   nn=1 to 50 (list specification)
%   m=1 to 6 (word specification)
%(Note that 4 x 50 x 6 =1200, so these ranges allow specification of all
%1200 files)
%
%--------------------------References--------------------------
%[1] S. Voran "Using articulation index band correlations to objectively
%estimate speech intelligibility consistent with the modified rhyme test,"
%Proc. 2013 IEEE Workshop on Applications of Signal Processing to Audio and
%Acoustics, New Paltz, NY, October 20-23, 2013.  Available at
%www.its.bldrdoc.gov/audio after October 20, 2013.
%
%[2] S. Voran " A multiple bandwidth objective speech intelligibility 
%estimator based on articulation index band correlations and attention,"
%Proc. 2017 IEEE International Conference on Acoustics, Speech, and 
%Signal Processing, New Orleans, March 5-9, 2017.  Available at
%www.its.bldrdoc.gov/audio.
%
%[3] ANSI S3.2, "American national standard method for measuring the 
% intelligibility of speech over communication systems," 1989.
%
%--------------------------Legal--------------------------
%THE NATIONAL TELECOMMUNICATIONS AND INFORMATION ADMINISTRATION,
%INSTITUTE FOR TELECOMMUNICATION SCIENCES ("NTIA/ITS") DOES NOT MAKE
%ANY WARRANTY OF ANY KIND, EXPRESS, IMPLIED OR STATUTORY, INCLUDING,
%WITHOUT LIMITATION, THE IMPLIED WARRANTY OF MERCHANTABILITY, FITNESS FOR
%A PARTICULAR PURPOSE, NON-INFRINGEMENT AND DATA ACCURACY.  THIS SOFTWARE
%IS PROVIDED "AS IS."  NTIA/ITS does not warrant or make any
%representations regarding the use of the software or the results thereof,
%including but not limited to the correctness, accuracy, reliability or
%usefulness of the software or the results.
%
%You can use, copy, modify, and redistribute the NTIA/ITS developed
%software upon your acceptance of these terms and conditions and upon
%your express agreement to provide appropriate acknowledgments of
%NTIA's ownership of and development of the software by keeping this
%exact text present in any copied or derivative works.
%
%The user of this Software ("Collaborator") agrees to hold the U.S.
%Government harmless and indemnifies the U.S. Government for all
%liabilities, demands, damages, expenses, and losses arising out of
%the use by the Collaborator, or any party acting on its behalf, of
%NTIA/ITS' Software, or out of any use, sale, or other disposition by
%the Collaborator, or others acting on its behalf, of products made
%by the use of NTIA/ITS' Software.

%Call external function filelist.m to get the names and numbers of the 
%.wav files to use.
[L , file_numbers]=filelist(n_files,cond_num);

%The file ABC_MRT_FB_templates.mat contains a 1 by 1200 cell array called
%TFtemplatesFB.  Each cell contains a fullband time-frequency template
%for one of the 1200 talker x keyword combinations. 
load ABC_MRT_FB_templates  

alignbins=[7 8 9]; %FFT bins to use for time alignment
AI=makeAI; %Make 21 by 215 matrix that maps 215 FFT bins to 21 AI bands
AI=sparse(AI);
binsPerBand=sum(AI,2); %number of FFT bins in each AI band
success=zeros(n_files,1);

for file_pointer=1:n_files %Loop over .wav files
    file_num=file_numbers(file_pointer);
    filename=L{file_pointer};   
    x=get_speech([speech_path,filename]);
    
    if isempty(x)        
        success(file_pointer)=NaN;
    else 
        if verbose~=0
            display(['Working on Condition ',num2str(cond_num), ...
                ', file ',num2str(file_pointer), ...
                ' of ',num2str(n_files),'.'])
        end
        C=zeros(215,6);
        
        %Create time-freq representation and apply Stevens' Law
        X=abs(T_to_TF(x)).^.6;
        
        %Pointer that indicates which of the 6 words in the list was spoken
        %in the .wav file. This is known in advance from file_num.
        %As file_num runs from 1 to 1200, correctword runs
        %from 1 to 6, 200 times. 
        correctword=rem(file_num-1,6)+1;

        %Pointer to first of the six words in the list associated with the
        %present speech file. As file_num runs from 1 to 1200, first_word
        %is 1 1 1 1 1 1 7 7 7 7 7 7 ...1195 1195 1195 1195 1195 1195.
        first_word=6*(floor((file_num-1)/6)+1)-5;   
       
        %Compare the computed TF representation for the input .wav file
        %with the TF tempates for the 6 candidate words
        for word=1:6
            %Find number of columns (time samples) in template
            ncols=size(TFtemplatesFB{first_word-1+word},2);
            %Do correlation using a group of rows to find best time
            %alignment between X and template
            shift=group_corr(X(alignbins,:),TFtemplatesFB{first_word-1+word}(alignbins,:));
            %Extract and normalized the best-aligned portion of X
            XX=TFnorm(X(:,shift+1:shift+ncols));
            %Find correlation between XX and template, one result per FFT
            %bin
            C(:,word)=sum(XX.*TFtemplatesFB{first_word-1+word},2);
        end
        C=(AI*C)./repmat(binsPerBand,1,6); %Aggregate correlation values across each AI band  
        C=max(C,0); %Clamp
              
        [SAC, ~]=sort(C,'descend'); 
        %For each of the 6 word options, sort the 21 AI band correlations
        %from largest to smallest
        SAC=SAC(1:16,:);
        %Consider only the 16 largest correlations for each word
        [~,loc]=max(SAC,[],2);
        %Find which word has largest correlation in each of these 16 cases
        success(file_pointer)=mean(loc==correctword);
        %Find success rate (will be k/16 for some k=0,1,...,16)
    end
end
%Average over files and correct for guessing
cprime=(6/5)*(mean(success)-(1/6));
%No affine transformation needed
phi_hat=cprime;

function AI=makeAI
%This function makes the 21 by 215 matrix that maps FFT bins 1 to 215 to 21
%AI bands. These are the AI bands specified on page 38 of the book: 
%S. Quackenbush, T. Barnwell and M. Clements, "Objective measures of
%speech quality," Prentice Hall, Englewood Cliffs, NJ, 1988.
AIlims=[4     4 %AI band 1
        5     6
        7     7
        8     9
        10    11
        12    13
        14    15
        16    17
        18    19
        20    21
        22    23
        24    26
        27    28
        29    31
        32    35
        36    40 %AI band  16    
        41    45 %AI band 17
        46    52 %AI band  18
        53    62 %AI band  19
        63    76 %AI band  20
        77   215]; %Everything above AI band 20 and below 20 kHz makes 
    %"AI band 21"
    
 AI=zeros(21,215);
 for k=1:21
        firstfreq=AIlims(k,1);
        lastfreq=AIlims(k,2);
        AI(k,firstfreq:lastfreq)=1;
 end

function x=get_speech(path_and_filename)
%This function attempts to load the requested speech file.
%If successful x is an N by 1 vector with 42000<=N.
%If function fails, x is empty and message is displayed.
%Function will fail if .wav file does not exist or if file contents do not
%match this format:  1 channel, 48,0000 smp/sec, at least 16 b/smp, 
%at least 42,000 smp total.

%minimum number of samples, required to avoid error when comparing with
%longest template.  (42000 samples is 875 ms)
minlen=42000;

try
    [x,fs]=audioread(path_and_filename);
    nofile=0;
catch
    display(['Cannot load ',path_and_filename,'.'])
    nofile=1;
end

if nofile==0
    nsamples=size(x,1);
    nchannels=size(x,2);
    if fs~=48000 || nchannels > 1 || nsamples < minlen
        display(['The file ',path_and_filename,' is not in the proper format.'])
        badformat=1;
    else
        badformat=0;
    end
end
if nofile==1 || badformat==1        
    display(['Success value for ', path_and_filename,' is NaN and phi_hat will be NaN as well.'])
    x=[];
end

function X=T_to_TF(x)
%This function generates a time-frequency representation for x using
%the length 512 periodic Hann window, 75% window overlap, and FFT
% - returns only the first 215 values
% - x must be column vector
% - zero padding is used if necessary to create samples for final full window.
% - window lengh must be evenly divisible by 4
m=length(x);
n=512;
nframes=ceil((m-n)/(n/4))+1;
newm=(nframes-1)*(n/4)+n;
x=[x;zeros(newm-m,1)];
X=zeros(n,nframes);
win=.5*(1-cos(2*pi*(0:511)'/512)); %periodic Hann window;
for i=1:nframes
    start=(i-1)*(n/4)+1;
    X(:,i)=x(start:start+n-1).*win;
end
X=fft(X);
X=X(1:215,:);

function Y=TFnorm(X)
%This function removes the mean of every row of TF representation
%and scales each row so sum of squares is 1.
n=size(X,2);
X=X-(sum(X,2)/n)*ones(1,n);
Y=X./repmat(sqrt(sum(X.^2,2)),1,n);

function shift=group_corr(X,R)
%This function uses all rows of X and R together in a cross-correlation
% - number of rows in X and R must match
% - X must have no fewer columns than R
% - evaluates all possible alignments of R with X
% - returns the shift that maximizes correlation value
% - if R has q columns then a shift value s means that R is best
%   aligned with X(:,s+1:s+q)
% - assumes R is already normalized for zero mean in each row and 
%   each row has sum of squares = 1

[~,n]=size(X);
[~,q]=size(R);

nshifts=n-q+1;
C=zeros(nshifts,1);
for i=1:nshifts
    T=X(:,i:i+q-1);
    T=T-(sum(T,2)/q)*ones(1,q);
    kk=sqrt(sum(T.^2,2));
    T=T./repmat(kk,1,q);
    C(i)=sum(sum(T.*R));
end
[~,shift]=max(C);
shift=shift-1;