function FFTvec = FrequencyTransfer( FFTvecin,fsdec,fvec )
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goe

nfft    = length(FFTvecin);

idxtmp  = floor(fvec/fsdec * nfft);
idx     = mod(idxtmp,nfft)+1;

FFTvec = FFTvecin(idx);