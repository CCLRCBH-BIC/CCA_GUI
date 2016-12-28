function [rho,alpha,beta]=kernelCCA(Kx,Ky,k)

if k==1
    error('k value is not supposed to be 1 in kernelCCA()');
end

%%%%%%%%%%%%%%%%%don't standarize the kernel%%%%%%%%%%%%%%%%%%%%%%%%
% N = size(Kx,1);
% mean_Kx_row = mean(Kx,2);
% mean_Kx_col = mean(Kx,1);
% Kx = Kx - diag(mean_Kx_row)*ones(N) - ones(N)*diag(mean_Kx_col) + mean(mean_Kx_row);

KxI = Kx+k/(1-k)*eye(size(Kx));
% KyI = Ky;
KyI = Ky+k/(1-k)*eye(size(Ky));

try
    % in case the matrix has singularity
    [V,D] = eig(inv(KxI)*Ky*pinv(KyI)*Kx,'vector');
catch
    rho = -1;alpha = zeros(size(Kx,1),1); beta = zeros(size(Ky,1),1);
    return;
end

[rho_sq_max,I] = max(D);

rho = sqrt(rho_sq_max);
alpha = V(:,I);

beta = pinv(KyI)*Kx*alpha;

norm_alpha = sqrt(alpha'*Kx^2*alpha+k/(1-k)*alpha'*Kx*alpha);
norm_beta = sqrt(beta'*Ky^2*beta+k/(1-k)*beta'*Ky*beta);
% norm_alpha = sqrt(alpha'*Kx^2*alpha);
% norm_beta = sqrt(beta'*Ky^2*beta);

alpha = alpha/norm_alpha;
beta = beta/norm_beta;

rho = alpha'*Kx*Ky*beta;

end