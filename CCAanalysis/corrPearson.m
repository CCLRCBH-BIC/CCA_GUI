function [Sxx, Sxy, Syx, Syy]=corrPearson(X,Y)
% Verified: [Sxx, Sxy, Syx, Syy]=corrPearson(X,Y)
X = whiten(X);
Y = whiten(Y);
N=size(X,1);

Sxx=X'*X/(N-1);
Sxy=X'*Y/(N-1);
Syy=Y'*Y/(N-1);
Sxx(isnan(Sxx))=0;
Sxy(isnan(Sxy))=0;
Syy(isnan(Syy))=0;
Syx = Sxy';

if rank(Sxx)<size(Sxx,1)
    Sxx=Sxx+(1e-10)*eye(size(Sxx,1));
end

if rank(Syy)<size(Syy,1)
    Syy=Syy+(1e-10)*eye(size(Syy,1));
end  

end