# Conducting ABC-MRT and ABC-MRT16 Tests

S. Voran, October 28, 2013

Updated by S. Voran on March 2, 2017 to cover ABC-MRT16 as well.

## Background
This software implements the ABC-MRT and ABC-MRT16 algorithms for
objective estimation of speech intelligibility. The algorithms are
discussed in detail in [[1](#f1)] and [[2](#f2)]. ABC-MRT is short for
“Articulation Band Correlation Modified Rhyme Test.”

The Modified Rhyme Test (MRT) [[3](#f3)] is a protocol for evaluating speech 
intelligibility using human subjects. The subjects are presented with the 
task of identifying one of six different words that take the phonetic form 
CVC. The six options differ only in the leading or trailing consonant. 
MRT results take the form of success rates (corrected for guessing) that 
range from 0 (guessing) to 1 (correct identification in every case). 
These success rates form a measure of speech intelligibility in this 
specific (MRT) context.

Articulation Band Correlation-MRT (ABC-MRT) is a signal processing 
algorithm that processes MRT audio files and produces success rates. The 
goal of ABC-MRT is to produce success rates that agree with those produced 
by MRT. Thus ABC-MRT is an automated or objective version of MRT and no 
human subjects are required.
 
ABC-MRT performs a narrowband (nominally 4 kHz) analysis. ABC-MRT16
is applicable to narrowband, wideband, superwideband, and fullband speech.
ABC-MRT processes the first 17 AI bands while ABC-MRT16 processes all 20 AI
bands, as well as an additional "AI Band 21" that covers 7 kHz to 20 kHz.
Of equal importance is that ABC-MRT16 incorporates a model for attention
that allows it to properly operate across the different bandwidths without
any bandwidth detection or switching.

Unless backwards compatibility is required, ABC-MRT16 is the recommended
algorithm, even if only narrowband conditions are to be tested. The 
attention model makes it superior to ABC-MRT.

The software provided here runs in the [Matlab®](http://mathworks.com) or 
[Octave](http://www.gnu.org/software/octave) environments.

Application of ABC-MRT(16) to a speech communication system-under-test (SUT) 
requires two steps.
1. Pass a set of reference recordings through the SUT to produce a set 
of test recordings.
2. Apply ABC-MRT(16) to the test recordings to produce a success rates that 
describe the intelligibility of the SUT.

Full details for each step follow. In addition, a small demonstration 
provides an example for getting started.

## Prepare SUT Recordings 

### Locate Reference recordings
The SourceAudio folder contains 1200 `.wav` files. The 
naming convention is `TT_bnn_wm_orig.wav`. `TT={F1,F3,M3,M4}` to indicate the 
talker, `nn` is an two digit integer 01 to 50 to indicate the MRT block or 
list, and `m` is a single-digit integer 1 to 6 to indicate the word within 
that list.

You now have access to 1200 `.wav` files for ABC-MRT(16) testing. Each file 
contains the same carrier phase followed by a single keyword. For example 
in `TT_b01_w1_orig.wav` you will hear “Please select the word went.” The 
keyword is “went.” In `TT_b01_w2_orig.wav` you will hear “Please select the 
word sent.” The `.wav` file format is mono, linear PCM, with 16 bits/sample
and 48,000 samples/second.

The most thorough testing will use all 1200 files. If this is 
prohibitive, then somewhat less thorough testing can be accomplished using 
a subset of these files. The best subsets are balanced with respect to 
talker and are enumerated by `filelist.m` which produces a Matlab variable, 
a `.mat` file, and a `.txt` file. The first argument to `filelist.m` is an 
integer `N`, which tells how many `.wav` files will be used, `16<=N<=1200`. An 
input of `N=16` will produce a list of 16 files and increasing `N` to 20 will 
add 4 more files, but will not change the original 16.

We have characterized the deviation in ABC-MRT results caused by using
`N<1200` files. This deviation is measured with respect to the ABC-MRT results
with 1200 files. Note that ABC-MRT results nominally range from 0 to 1, so a
deviation of .01 is 1% of the intelligibility scale. We have calculated
these deviations across 139 different conditions:


|   N  | RMS Deviation |Maximum Absolute Deviation| Total Speech File Time |
|------|---------------|--------------------------|------------------------|
|   16 |      0.017    |           0.053          |      28 sec            |
|   32 |      0.009    |           0.033          |      57 sec            |
|   64 |      0.005    |           0.014          |     115 sec            |
|  128 |      0.003    |           0.008          |     231 sec            |
|  256 |      0.002    |           0.004          |     462 sec ( 8 min)   |
|  512 |      0.001    |           0.002          |     922 sec (15 min)   |
| 1200 |      0.000    |           0.000          |    2170 sec (36 min)   |


### Pass reference recordings through SUT

The next task is to pass the desired reference `.wav` files through each SUT 
of interest. More generally, one is often interested in a particular 
operating configuration for an SUT, possibly combined with 
environmental factors. To describe this we use the more general term 
“condition.” For example, conditions 1, 2, 3, and 4 might be SUT 1 in 
quiet, SUT 1 with car noise at 5 dB SNR, SUT 1 with babble noise at 0 dB 
SNR, and SUT 2 in quiet, respectively.

The recording of the conditions can be scripted and implemented using one 
or more computers with suitable sound I/O, but other implementations are 
possible as well. The Matlab code `playrec.m` gives one example of how one 
might script these processes.

ABC-MRT(16) expects that reference file `TT_bnn_wm_orig.wav` will produce the 
test file `testpath/Cpp/TT_bnn_wm_cpp.wav`, where `pp` is a two digit integer 
00 to 99 that can be used to identify the condition, and testpath is an 
arbitrary path identifier. For example, passing `F1_b01_w1_orig.wav` 
through condition 17 should produce `mytestpath/C17/F1_b01_w1_c17.wav`.
 
In general, a condition will have a non-zero delay so perfect 
synchronization of playing and recording may truncate the contents of the 
file. Thus the timing of the recording process must be adjusted so 
that each test file includes at least the entire keyword. In addition 
each test file must contain at least 42,000 samples (875 ms duration).
Note that ABC-MRT(16) processing time increases as file length increases.

For best results, the playback and recording processes must be virtually 
transparent relative to the condition. A/D and D/A conversion external to 
the computer may be advantageous. The playback level must be properly 
adjusted, and the recording level is especially important. If it is too 
high, clipping may impair the A/D process. If it is too low quantization 
noise may impair the A/D process.

A higher level of automation might be achieved by concatenating the 
desired reference files, playing that single long file while recording a 
single long test file, then cutting the long test file into properly named 
individual test files. Or one might modify the ABC-MRT(16) software to accept 
and properly parse a single long test file. One might attempt to further 
streamline the process by passing only keywords (and not the carrier 
phrase) through the condition. For some conditions this change may 
produce identical results. But if the condition includes any adaptive 
process (e.g., noise reduction) then this change may alter the results. 
If this is the case, then consider how the condition is used in practice. 
In many cases transmitting a sequence of sentences (carrier phrases with 
keywords) may be more realistic than transmitting a list of unrelated 
words (keywords alone).

## Apply ABC-MRT or ABC-MRT16 to the test recordings
Run `ABC_MRT.m` or `ABC_MRT16.m`. It will process all `.wav` files (up to 1200
of them) for a single condition. A simple script can apply `ABC_MRT.m`
or `ABC_MRT16.m` to multiple conditions. Examples are provided in
`ABC_MRTdemo.m` and `ABC_MRT16demo.m`.

The call to `ABC_MRT.m` is:

```
[phi_hat, success]=ABC_MRT(speech_path,cond_num,n_files,verbose)
```

and the call to `ABC_MRT16.m` is:

```
[phi_hat, success]=ABC_MRT16(speech_path,cond_num,n_files,verbose)
```

 - `speech_path` is a string that gives the path to the speech files

 - `cond_num` is the condition number, 0 to 99. This is used to form the end 
of the path and the filenames as specified below.

 - `n_files` is the number of speech files to use, 16 <= N <= 1200. Using 
more speech files gives a more robust result, but takes longer. One can 
use `filelist.m` to generate the list of `.wav` files required for any value 
of `n_files`.

 - `verbose` is set to any nonzero value to force progress reporting

 - `success` is a column vector with length n_files that gives the success 
rate for each file involved in the test.

 - `phi_hat` is a scalar that gives the final intelligibility estimate for 
the condition. `phi_hat` is expected to range from 0 to 1, similar to MRT
results. Larger values of `phi_hat` indicate higher levels of speech
intelligibility

`ABC_MRT.m` and `ABC_MRT16.m` expect a specific file naming convention. Here are some 
examples:

```
ABC_MRT(e:/soundfiles/MRT/,1,1200,*), requires 1200 .wav files of the form 
e:/soundfiles/MRT/C01/TT_bnn_wm_c01.wav

ABC_MRT(e:/soundfiles/MRT/,17,16,*), requires 16 .wav files of the form 
e:/soundfiles/MRT/C17/TT_bnn_wm_c17.wav

ABC_MRT16(e:/soundfiles/MRT/,1,1200,*), requires 1200 .wav files of the form 
e:/soundfiles/MRT/C01/TT_bnn_wm_c01.wav

ABC_MRT16(e:/soundfiles/MRT/,17,16,*), requires 16 .wav files of the form 
e:/soundfiles/MRT/C17/TT_bnn_wm_c17.wav
```

In every case the base of the filenames takes the form TT_bnn_wm with:

```
  TT=F1, F3, M3, or M4 (talker specification)
  nn=1 to 50 (list specification)
  m=1 to 6 (word specification)
```

(Note that 4 x 50 x 6 =1200, so these ranges allow specification of all 
1200 files)

## Demonstration
Run `ABC_MRTdemo.m`. It applies ABC_MRT to 6 different conditions, using 
just 16 .wav files per condition. The required files are provided in the 
demo directory. The results (phi_hat values) are plotted against actual 
MRT scores. Using 16 files is fast and it shows how the software works, 
but it gives only rough results. In practice one should use as many files 
as practical.

Or run `ABC_MRT16demo.m`. It applies ABC_MRT16 to 6 different conditions, using 
just 16 .wav files per condition. The required files are provided in the 
demo directory. The results (phi_hat values) are plotted against actual 
MRT scores. Using 16 files is fast and it shows how the software works, 
but it gives only rough results. In practice one should use as many files 
as practical.

## References
[<b id="f1">1</b>] S. Voran "Using articulation index band correlations to objectively 
estimate speech intelligibility consistent with the modified rhyme test," 
Proc. 2013 IEEE Workshop on Applications of Signal Processing to Audio and
Acoustics, New Paltz, NY, October 20- 23, 2013. Available at 
www.its.bldrdoc.gov/audio after October 20, 2013.

[<b id="f2">2</b>] S. Voran "A multiple bandwidth objective speech intelligibility 
estimator based on articulation index band correlations and attention,"
Proc. 2017 IEEE International Conference on Acoustics, Speech, and 
Signal Processing, New Orleans, March 5-9, 2017. Available at
www.its.bldrdoc.gov/audio.

[<b id="f3">3</b>] ANSI S3.2, "American national standard method for measuring the 
intelligibility of speech over communication systems," 1989.
