function [cor,Alp,Beta,opt_Yind]=ccaGlm(X,Y,S,flag)

Y = Y(:,1);
if strcmpi(flag,'Pearson')==1
    
    Beta = pinv(X)*Y;
    cor = corr(Y,X*Beta);
    Alp = 1;
else
    Beta1 = pinv(X)*Y;
    [max_beta1,max_ind] = max(Beta1);
    Cxx = S.Sxx;
    Cyx = S.Syx;
    
    Beta = Cxx\Cyx';
    
    K2 = real(Cxx^(-0.5));
    K = 1*Cyx*K2; K(isnan(K))=0;
    k = max(rank(K),1);
    [U,S,V] = svd(K); 
    U = U(:,1:k);V = V(:,1:k);S = diag(S(1:k,1:k));
    cor = S(1,1);
    Alp = 1;
%     Beta = K2*V(:,1)*sign(U); % row vector
%     Beta = Beta/Beta(max_ind)*max_beta1;
end
opt_Yind = 1;
end
    