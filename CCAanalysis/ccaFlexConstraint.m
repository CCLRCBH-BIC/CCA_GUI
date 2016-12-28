function [cor,Alp,Beta,opt_Yind]=ccaFlexConstraint(X,Y,S,flag,mode)
% [cor,Alp,Beta,opt_Yind]=ccaFlexConstraint(X,Y,S,flag,mode)
% convergence = 1e-3 would be enough in BFGS
% mode = [p, phi]

neigh = size(Y,2);
cor = 0;Alp =0;Beta = 0;
setting = ones(neigh,1);
Cxx = S.Sxx;
Cyx = S.Syx;
Cyy = S.Syy;

inv_Sxx = Cxx\eye(size(Cxx));
for i = 1:2^(neigh-1)
    if neigh == 1
        setting = 1;
    else
        setting(2:end) = de2bi(i-1,neigh-1); 
    end
    Yy = Y(:,setting==1);
         
    
    Sxx = Cxx;
    Syx = Cyx(setting==1,:);
    Syy = Cyy(setting==1,setting==1);  
    K1 = real(Syy^(-0.5));
    K2 = real(Sxx^(-0.5));
    K = K1*Syx*K2;K(isnan(K))=0;
    k = rank(K);
    [U,S,V] = svd(K); U = U(:,1:k);V = V(:,1:k);S = real(diag(S(1:k,1:k))); 
    alpha = K1*U;
    B = inv_Sxx*Syx' ;%pinv(X)*Yy; 
    if sum(setting)==2
        alphap = [mode(2)^(1/mode(1));1];
        alpha = [alpha,alphap];
        if strcmpi(flag,'Pearson')==0
            betap = B*alphap;
            S_add = -constraintObjectiveS(betap,Sxx,Syx,Syy,mode);
            S = [S;S_add];
        else
            S = [S;corr(Yy*alpha(:,end),X*B*alpha(:,end))];
        end   
   elseif sum(setting)>2
        if strcmpi(flag,'Pearson')==0
            thetak3 = real(BFGS(@(theta) constraintObjectiveS(theta,Sxx,Syx,Syy,mode),rand(sum(setting)-2+size(X,2),1)));
%             thetak3 = BFGS(@(theta) constraintObjectiveS(theta,X,Yy,mode),rand(sum(setting)-2+size(X,2),1));
            Ak3 = thetak3(1:size(Syy,2)-2).^2;
            Ak1 = (mode(2)*sum([1;Ak3].^mode(1)))^(1/mode(1));
            Ak = [Ak1;1;Ak3];
            alpha = [alpha,Ak]; 
            S_add = -constraintObjectiveS(thetak3,Sxx,Syx,Syy,mode);
            S = [S;S_add]; 
        else
%             thetak3 = BFGS(@(theta) constraintObjective(theta,X,Yy,mode),rand(sum(setting)-2,1));
            [thetak3,~] = BFGS(@(theta) constraintObjectiveP(theta,X,Yy,Sxx,Syx,Syy,mode),rand(sum(setting)-2,1));
            record_rho = constraintObjectiveP(thetak3,X,Yy,Sxx,Syx,Syy,mode);
            Ak3 = thetak3(1:size(Syy,1)-2).^2;
            Ak1 = (mode(2)*sum([1;Ak3].^mode(1)))^(1/mode(1));
            Ak = [Ak1;1;Ak3];
            record_rho = sqrt(-record_rho(end));
            if record_rho>cor
                opt_Yind = setting;
                cor = record_rho;
                Alp=Ak/sqrt(Ak'*Syy*Ak);Alp = Alp*sign(Alp(1));
                Beta = B*Alp;
            end 
        end
    end   
    [cor,Alpk]=constraint(alpha,S,mode,cor,Alp);
    if isequal(Alp,Alpk)==0
        opt_Yind = setting;
        Alp = Alpk/sqrt(Alpk'*Syy*Alpk); % sqrt(size(Y,1)-1)*Alpk/norm(Yy*Alpk);
        Alp = Alp*sign(Alp(1));  
        Beta = B*Alp;     
    end   
end
end


function [opt_rho,opt_alpha]=constraint(alpha,rho,mode,rhomax,alphamax)
%% [opt_rho,opt_alpha]=constraint(alpha,rho,mode,rhomax)
% constraint() is used to choose the configuration satisfy
% 1. all alpha elements are nonnegative
% 2. alpha(1)^p >= phi*sum(alpha(2:end).^p)
% mode = [p;phi]

p = mode(1);phi = mode(2);
samesign = (~range(alpha>=0))|(~range(alpha<=0));
cor_comp = (rho>rhomax);
if isempty(cor_comp)==1 || isempty(samesign)==1
    ind = [];
else
    ind = find(cor_comp & samesign');
end
if (size(ind,1) == 0)
    opt_rho=rhomax;
    opt_alpha=alphamax;
else
    alpha = abs(alpha);
    for i = 1:size(ind,1)
        if alpha(1,ind(i))^p >= phi*sum(alpha(2:end,ind(i)).^p)
            opt_rho = rho(ind(i));
            opt_alpha = alpha(:,ind(i));
            break;
        else
            opt_rho = rhomax;
            opt_alpha=alphamax;
        end
    end
end

end

function f = constraintObjectiveP(theta,X,Y,Sxx,Syx,Syy,mode)
if nargin==6
    mode=[1;1];
end
p = mode(1);phi = mode(2);
suba = theta(1:size(Y,2)-2).^2;
a = [(phi*sum([1;suba].^p))^(1/p);1;suba]; 
a = a/sqrt(a'*Syy*a);
b = pinv(X)*Y*a;
% b = Sxx\Syx'*a;
f = -a'*Syx*b;
end

function f = constraintObjectiveS(theta,Sxx,Syx,Syy,mode)
if nargin == 4
    mode = [1;1];
end
p = mode(1);
phi = mode(2);

if size(Syy,2)>2
    suba = theta(1:size(Syy,2)-2).^2;
    a = real([(phi*sum([1;suba].^p))^(1/p);1;suba]); 
    
%     b = theta(size(Syy,2)-1:end);
elseif size(Syy,2)==2
    a = [phi^(1/p);1];
%     b = theta;
end
b = Sxx\Syx'*a;
a = a/sqrt(a'*Syy*a);
b = b/sqrt(b'*Sxx*b);
f = - a'*Syx*b;
end
