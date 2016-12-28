function [cor,Alp,Beta,statistic,opt_Yind]=ccaCombo(X,Y,C,S,flag,mode)
% [cor,Alp,H_alpha]=cca_combov4(X,Y,C,S,flag,mode)
% dcor is verified
% mode = 'simple','sum','dominance','glm',[p,phi]
if nargin==5
    mode = 'simple';
end

if strcmpi(mode,'simple')==1
    [cor,Alp,Beta,opt_Yind]=ccaSimple(X,Y,S);
elseif strcmpi(mode,'sum')==1
    [cor,Alp,Beta,opt_Yind]=ccaSum(X,Y,C,flag);
elseif strcmpi(mode,'nonneg')==1
    [cor,Alp,Beta,opt_Yind]=LSSQPCCA_nonneg(S);
elseif strcmpi(mode,'dominance')==1
    [cor,Alp,Beta,opt_Yind]=LSSQPCCA_max(S);
%     [cor,Alp,Beta,opt_Yind]=ccaDominance(X,Y,flag);
elseif strcmpi(mode,'Single voxel')==1
    [cor,Alp,Beta,opt_Yind]=ccaGlm(X,Y,S,flag);    
elseif numel(mode)==2
    [cor,Alp,Beta,opt_Yind]=LSSQPCCA(S,mode);
%     [cor,Alp,Beta,opt_Yind]=ccaFlex_test(X,Y,S,mode(2),mode(1));
%     [cor,Alp,Beta,opt_Yind]=ccaFlexConstraint_GRG(S,mode);
%     [cor,Alp,Beta,opt_Yind]=ccaFlexConstraint(X,Y,S,flag,mode);
%     [cor,Alp,Beta,opt_Yind]=ccaSingleBFGS(X,Y,S,flag,mode);
else
    error('no correct mode is specified in cca_combo() function');
end
if strcmpi(mode,'nonneg')==1||strcmpi(mode,'sum')==1||strcmpi(mode,'dominance')==1||numel(mode)==2
%     statistic = 0;
    statistic = lambdastatistic(X,Y,Alp,C,opt_Yind); % F statistic
elseif strcmpi(mode,'Single voxel')==1
    statistic = Tstatistic(X,Y,C,Beta);
else 
    statistic = zeros(size(C,2),1);
end

end
    