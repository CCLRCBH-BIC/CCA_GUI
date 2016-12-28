function SigmaorFWHM=FWHMandSigma(FWHMorSigma,flag)

% flag==1: FWHM to sigma
if flag==1
    SigmaorFWHM=FWHMorSigma/(2*sqrt(2*log(2)));
elseif flag==2
    SigmaorFWHM=2*sqrt(2*log(2))*FWHMorSigma;
end
end