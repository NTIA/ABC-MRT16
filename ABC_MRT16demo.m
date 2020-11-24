%This script demonstrates ABC-MRT16 on a very small set of .wav files
%These are a tiny subset of the files in the 2008 test available at
%https://www.its.bldrdoc.gov/outreach/audio/mrt_library/overview/index.htm
%Speech files and MRT scores from 4 large tests are available at that URL.

%----Calculate ABC-MRT16 scores for 6 conditions, 16 files per condition----
speech_path='demo/';
n_files=16;
ABC_MRTscores=zeros(6,1);

for cond_num=1:6
     [phi_hat,success]=ABC_MRT16(speech_path,cond_num,n_files,1);
     ABC_MRTscores(cond_num)=phi_hat;
end


%------True MRT scores for the same 6 conditions--------------
MRTscores=[0.8808 0.4368 0.7848 0.1648 0.5808 0.0464];
%To get these scores and more, download results_2008.zip from the URL
%above, extract results2008-percondition.mat, and look at column 7 of
%the variable called cond_data

%---Make a scatter plot to compare ABC-MRT16 results with true MRT scores----
figure(1)
plot(MRTscores, ABC_MRTscores,'ob')
grid
hold on
plot([0 1],[0 1],':k')
hold off
xlabel('MRT Scores')
ylabel('ABC-MRT16 Scores')
title('Demo:  6 Conditions, 16 of 1200 files per condition (use more files for more robust results)')