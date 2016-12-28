function [cor,Alp,Beta,opt_Yind]=ccaSimple(X,Y,S)

neigh=size(Y,2);
cor = 0;Alp =0;
setting = ones(neigh,1);
Cxx = S.Sxx;
Cyx = S.Syx;
Cyy = S.Syy;

for i = 1:2^(neigh-1)
    setting(2:end) = de2bi(i-1,neigh-1);
    Yy = Y(:,setting==1);
    Sxx = Cxx;
    Syx = Cyx(setting==1,:);
    Syy = Cyy(setting==1,setting==1);
    K1 = real(Syy^(-0.5));
    K2 = real(Sxx^(-0.5));
    K = K1*Syx*K2;K(isnan(K))=0;
    k = rank(K);
    [U,S,V] = svd(K); U = U(:,1:k);V = V(:,1:k);S = diag(S(1:k,1:k));
    if S(1,1)>cor
        opt_Yind = setting;
        Alp = K1*U(:,1);
        Beta = K2*V(:,1);
        Beta = Beta*sign(Alp(1,1));Alp = Alp*sign(Alp(1,1));
        Alp = sqrt(size(Y,1)-1)*K1*U(:,1)/norm(Yy*Alp);
        cor = S(1,1);
    end  
    
end

end
    
    
    
    