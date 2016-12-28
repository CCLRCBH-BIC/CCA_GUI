function [F,lambda] = lambdastatistic(X,Y,alpha,C,opt_Yind)
% [F,lambda] = lambdastatistic(X,Y,alpha,C,opt_Yind)
if exist('opt_Yind','var')==0 || isempty(opt_Yind)
    opt_Yind = ones(size(Y,2),1);
end
opt_Y = Y(:,opt_Yind==1);
opt_alp = alpha(opt_Yind==1);
B = pinv(X)*opt_Y;
[tdim,r] = size(X);
Ealpha = (opt_Y*opt_alp-X*B*opt_alp)'*(opt_Y*opt_alp-X*B*opt_alp);
% Ealpha = (alpha'*S.Syy(opt_Yind==1,opt_Yind==1)*alpha - 2*beta'*S.Sxy(:,opt_Yind==1)*alpha + beta'*S.Sxx*beta);

% hypothesis matrix
NoConst = size(C,2);
Halpha = zeros(NoConst,1);
for i = 1: NoConst
    Halpha(i) = (C(:,i)'*B*opt_alp)'*inv(C(:,i)'*inv(X'*X)*C(:,i))*(C(:,i)'*B*opt_alp);
end
lambda = Ealpha./(Ealpha+Halpha);
df_H = 1;df_E = tdim - r - sum(opt_Yind);
F = (df_E/df_H)*(1-lambda)./lambda;
F = sign(C'*B*opt_alp).*F;% signed test statistics
end