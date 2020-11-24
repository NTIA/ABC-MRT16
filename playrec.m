%An example for scripting data acquisition for ABC-MRT or ABC-MRT16

N=1200;     %number of files to use
condition=4; %create conditio,n 4 for example

%Create list of playback (original) filenames
OriginalList=filelist(N,-1);

%Create list of record (condition) filenames
ConditionList=filelist(N,condition); 

for i=1:N
    %Play the file specified in OriginalList{i} and 
    %record the file specified in ConditionList{i}
    %Make certain that the recording operation is timed to include at least
    %the entire keyword (allow for the system delay).
    %In addition each recorded file must contain at least 42,000 samples.
    %File format for playback and record is .wav,
    %48,0000 smp/sec, at least 16 bits/smp, 1 channel
    pause(.1)
end
    