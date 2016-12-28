function ccagui

ccagui=findobj('tag','ccagui');
delete(ccagui);

ccagui=figure('tag','ccagui','menubar','none','position',[100 100 750 750],'name','Constrained CCA','numbertitle','off');


%%%%%%%%%%%%%%%%add file path%%%%%%%%%%%%%
pathstr=fileparts(which('ccagui.m'));
addpath([pathstr,filesep,'CCAanalysis'],[pathstr,filesep,'SharedMemory']);

warning off;
TabGroup=uitabgroup;
fMRITab=uitab(TabGroup,'title','constrained CCA');
% fMRITab=uitab(TabGroup,'title','design matrix');

warning on;
Button.exts = {  ...
%     '*.nii;*.nii.gz;*.img;*.img.gz' 'all image types'              ...
%     '*.nii'                         'nifti files'                  ...
%     '*.nii.gz'                      'compressed nifti files'       ...
%     '*.img'                         'analyze files'                ...
%     '*.img.gz'                      'compressed analyze files'     ...
    '*.mat'                         'cell array with file names'   ...
%     '*.txt'                         'file names'
    };

Button.exts=reshape(Button.exts,2,[])';

%%%%%%%%%%%%%%%% add buttons%%%%%%%%%%%%%%%%%%
string_set={'run cCCA','fMRI data','mask','design matrix','select fMRI data'...
    ,'select mask file','select design matrix','p value','psi value',...
    'Data selection','selected design matrix','1','1','<empty>','<fMRI empty>',...
    '<mask empty>','constraint',char('2D','3D'),'contrast','select contrast'};
tag_set={'runCCA','fMRIlabel','masklabel','designlabel','fMRIdata','mask',...
    'X','p','psi','filescaption','designcaption','pvalue','psivalue','outputlog',...
    'fMRIlist','masklist','constraint','constmode','contstlabel','contrast'};
style_set={'pushbutton','text','text','text','pushbutton','pushbutton',...
    'pushbutton','text','text','text','text','edit','edit','listbox','listbox',...
    'listbox','text','popup','text','pushbutton'};
visible_set={'on','on','on','on','on','on','on','on','on','off','off','on','on',...
    'off','on','on','on','on','on','on'};
horizonalign_set={'left','left','left','left','left','left','left','left',...
    'left','left','left','left','left','left','left','left','left','left','left'...
    ,'left'};
units_set={'normalized','normalized','normalized','normalized','normalized',...
    'normalized','normalized','normalized','normalized','normalized','normalized'...
    ,'normalized','normalized','normalized','normalized','normalized','normalized'...
    ,'normalized','normalized','normalized'};
position_set={
    [.05 .85 .45 .05]
    
    [.05 .7 .35 .05 ]
    [.05 .6 .35 .05 ]
    [.05 .5 .35 .05 ]    
    [.15 .7 .35 .05 ]
    [.15 .6 .35 .05 ]
    [.15 .5 .35 .05 ]
    [.05 .2 .35 .05 ]
    [.05 .11 .35 .05]
    [.55 .9 .35 .05]
    [.55 .8 .35 .05]
    [.15 .2 .35 .05 ]
    [.15 .11 .35 .05]
    [.55 .10 .35 .75]
    [.55 .5 .35 .2]
    [.55 .25 .35 .2]
    [.05 .29 .35 .05 ]
    [.15 .29 .35 .05 ]
    [.05 .4 .35 .05 ] 
    [.15 .4 .35 .05 ] 
    };

button_set=[style_set',string_set',units_set',tag_set',visible_set',horizonalign_set',position_set];

k=1;

Button.run=uicontrol(ccagui,...
    'style',style_set{k},...
    'string',string_set{k},...
    'units',units_set{k},...
    'tag',tag_set{k},...
    'visible',visible_set{k},...
    'horizontalalignment',horizonalign_set{1},...
    'position',position_set{k});
k=k+1;

Button.fMRIlabel=uicontrol(fMRITab,...
    'style',style_set{k},...
    'units',units_set{k},...
    'string',string_set{k},...
    'tag',tag_set{k},...
    'visible',visible_set{k},...
    'horizontalalignment',horizonalign_set{1},...
    'position',position_set{k});
k=k+1;

Button.masklabel=uicontrol(fMRITab,...
    'style',style_set{k},...
    'units',units_set{k},...
    'string',string_set{k},...
    'tag',tag_set{k},...
    'visible',visible_set{k},...
    'horizontalalignment',horizonalign_set{1},...
    'position',position_set{k});
k=k+1;

Button.designlabel=uicontrol(fMRITab,...
    'style',style_set{k},...
    'units',units_set{k},...
    'string',string_set{k},...
    'tag',tag_set{k},...
    'visible',visible_set{k},...
    'horizontalalignment',horizonalign_set{1},...
    'position',position_set{k});
k=k+1;

Button.fMRI=uicontrol(fMRITab,...
    'style',style_set{k},...
    'units',units_set{k},...
    'string',string_set{k},...
    'tag',tag_set{k},...
    'visible',visible_set{k},...
    'horizontalalignment',horizonalign_set{1},...
    'position',position_set{k});
k=k+1;

Button.mask=uicontrol(fMRITab,...
    'style',style_set{k},...
    'units',units_set{k},...
    'string',string_set{k},...
    'tag',tag_set{k},...
    'visible',visible_set{k},...
    'horizontalalignment',horizonalign_set{1},...
    'position',position_set{k});
k=k+1;

Button.design=uicontrol(fMRITab,...
    'style',style_set{k},...
    'units',units_set{k},...
    'string',string_set{k},...
    'tag',tag_set{k},...
    'visible',visible_set{k},...
    'horizontalalignment',horizonalign_set{1},...
    'position',position_set{k});
k=k+1;

Button.p=uicontrol(fMRITab,...
    'style',style_set{k},...
    'units',units_set{k},...
    'string',string_set{k},...
    'tag',tag_set{k},...
    'visible',visible_set{k},...
    'horizontalalignment',horizonalign_set{1},...
    'position',position_set{k});
k=k+1;

Button.psi=uicontrol(fMRITab,...
    'style',style_set{k},...
    'units',units_set{k},...
    'string',string_set{k},...
    'tag',tag_set{k},...
    'visible',visible_set{k},...
    'horizontalalignment',horizonalign_set{1},...
    'position',position_set{k});
k=k+1;

Button.fmricaption=uicontrol(fMRITab,...
    'style',style_set{k},...
    'units',units_set{k},...
    'string',string_set{k},...
    'tag',tag_set{k},...
    'visible',visible_set{k},...
    'horizontalalignment',horizonalign_set{1},...
    'position',position_set{k});
k=k+1;

% Button.designcaption=uicontrol(fMRITab,...
%     'style',style_set{k},...
%     'units',units_set{k},...
%     'string',string_set{k},...
%     'tag',tag_set{k},...
%     'visible',visible_set{k},...
%     'horizontalalignment',horizonalign_set{1},...
%     'position',position_set{k});
k=k+1;

Button.pvalue=uicontrol(fMRITab,...
    'style',style_set{k},...
    'units',units_set{k},...
    'string',string_set{k},...
    'tag',tag_set{k},...
    'visible',visible_set{k},...
    'horizontalalignment',horizonalign_set{1},...
    'position',position_set{k});
k=k+1;

Button.psivalue=uicontrol(fMRITab,...
    'style',style_set{k},...
    'units',units_set{k},...
    'string',string_set{k},...
    'tag',tag_set{k},...
    'visible',visible_set{k},...
    'horizontalalignment',horizonalign_set{1},...
    'position',position_set{k});
k=k+1;

Button.outputlog=uicontrol(fMRITab,...
    'style',style_set{k},...
    'units',units_set{k},...
    'string',string_set{k},...
    'tag',tag_set{k},...
    'visible',visible_set{k},...
    'horizontalalignment',horizonalign_set{1},...
    'position',position_set{k});
k=k+1;

Button.fMRIlist=uicontrol(fMRITab,...
    'style',style_set{k},...
    'units',units_set{k},...
    'string',string_set{k},...
    'tag',tag_set{k},...
    'visible',visible_set{k},...
    'horizontalalignment',horizonalign_set{1},...
    'position',position_set{k});
k=k+1;

Button.masklist=uicontrol(fMRITab,...
    'style',style_set{k},...
    'units',units_set{k},...
    'string',string_set{k},...
    'tag',tag_set{k},...
    'visible',visible_set{k},...
    'horizontalalignment',horizonalign_set{1},...
    'position',position_set{k});
k=k+1;

% Button.designlist=uicontrol(fMRITab,...
%     'style',style_set{k},...
%     'units',units_set{k},...
%     'string',string_set{k},...
%     'tag',tag_set{k},...
%     'visible',visible_set{k},...
%     'horizontalalignment',horizonalign_set{1},...
%     'position',position_set{k});
% k=k+1;

Button.const=uicontrol(fMRITab,...
    'style',style_set{k},...
    'units',units_set{k},...
    'string',string_set{k},...
    'tag',tag_set{k},...
    'visible',visible_set{k},...
    'horizontalalignment',horizonalign_set{1},...
    'position',position_set{k});
k=k+1;

Button.constmode=uicontrol(fMRITab,...
    'style',style_set{k},...
    'units',units_set{k},...
    'string',string_set{k},...
    'tag',tag_set{k},...
    'visible',visible_set{k},...
    'horizontalalignment',horizonalign_set{1},...
    'position',position_set{k});
k=k+1;

Button.constlabel=uicontrol(fMRITab,...
    'style',style_set{k},...
    'units',units_set{k},...
    'string',string_set{k},...
    'tag',tag_set{k},...
    'visible',visible_set{k},...
    'horizontalalignment',horizonalign_set{1},...
    'position',position_set{k});
k=k+1;

Button.constlist=uicontrol(fMRITab,...
    'style',style_set{k},...
    'units',units_set{k},...
    'string',string_set{k},...
    'tag',tag_set{k},...
    'visible',visible_set{k},...
    'horizontalalignment',horizonalign_set{1},...
    'position',position_set{k});
k=k+1;

% Button.maskdir=uicontrol(fMRITab,'style','text','string','','visible','off');
Button.workdir=uicontrol(fMRITab,'style','text','string',pwd,'visible','off');

set(Button.run,'callback',{@runcCCA,Button});
set(Button.fMRI,'callback',{@getfMRIdata,Button});
set(Button.mask,'callback',{@getmaskdata,Button});
set(Button.design,'callback',{@getdesigndata,Button});
set(Button.constlist,'callback',{@getcontrast,Button});
% set(Button.psi,'callback',{@getpsi,Button});
% set(Button.fmricaption,'callback',{@get,Button});
% set(Button.designcaption,'callback',{@runcCCA,Button});
set(Button.outputlog,'callback',{@sav,Button});
% set(Button.fMRI,'callback',{@saveFMRIFiles,Button});

% set(Button.mask,'buttondownfcn',@(s, e) clrmask(Button),'value',0);
% set(Button.fMRI,'buttondownfcn',@(s, e) clrfiles(Button));
% set(Button.outputlog,'buttondownfcn',@(s, e) clr(Button));

if (exist('load_untouch_nii')~=2)
    fprintf('Nifti tools not found \n');
end
end

function getfMRIdata(hObject,event,button)

[fnames,dname]=uigetfile(button.exts,'select fMRI datasets .mat file','multiselect','off',get(button.workdir,'string'));
if (dname)
    if ~iscell(fnames);fname={fnames};end
    fMRIlist=load([dname  fname{1}]);
    fid_names=fieldnames(fMRIlist);
    if numel(fid_names)==1
        fMRIdata=getfield(fMRIlist,fid_names{1});
        if numel(fMRIdata)>=1
            fprintf('fMRI dataset selected\n');
            set(button.fMRIlist,'string',fMRIdata);
        else
            fprintf('fMRI data list is empty\n')
        end
        set(button.fMRI,'string',[dname  fname{1}]);
        drawnow;
    else
        fprintf('only one cell array of file path should be included\n');
    end   
end
end



function getmaskdata(hObject,event,button)
[fnames,dname]=uigetfile(button.exts,'select mask .mat file','multiselect','off',get(button.workdir,'string'));
if (dname)
    if ~iscell(fnames);fname={fnames};end
    masklist=load([dname  fname{1}]);
    fid_names=fieldnames(masklist);
    if numel(fid_names)==1
        maskdata=getfield(masklist,fid_names{1});
        if numel(maskdata)>=1
            fprintf('mask is selected\n');
            set(button.masklist,'string',maskdata);
            set(button.mask,'string',[dname  fname{1}]);
            drawnow;
        end
    else
        fprintf('only one cell array of file path should be included\n');
    end   
end
end

function getdesigndata(hObject,event,button)
[fnames,dname]=uigetfile(button.exts,'select design matrix .mat file','multiselect','off',get(button.workdir,'string'));
if (dname)
    if ~iscell(fnames);fname={fnames};end
    designlist=load([dname  fname{1}]);
    if numel(fieldnames(designlist))==1
%         set(button.designlist,'string',{[dname  fname{1}]});
        set(button.design,'string',[dname  fname{1}]);%,'value',1);
        drawnow;
    else
        fprintf('only one cell array of file path should be included\n');
    end   
end
end

function getcontrast(hObject,event,button)
[fnames,dname]=uigetfile(button.exts,'select contrast .mat file','multiselect','off',get(button.workdir,'string'));
if (dname)
    if ~iscell(fnames);fname={fnames};end
    designlist=load([dname  fname{1}]);
    if numel(fieldnames(designlist))==1
        set(button.constlist,'string',{[dname  fname{1}]});
%         set(button.constlabel,'string',[dname  fname{1}]);%,'value',1);
        drawnow;
    else
        fprintf('only one cell array of file path should be included\n');
    end   
end
end
% function saveFMRIFiles(hObject,event,button)
% 
% [fname, dname] = uiputfile(   {'*.txt', 'txt files'}, ...
%     'file to save to', ...
%     [get(button.workdir, 'string')  'ccagui_fMRIdata.txt']);
% 
% if (fname)
%     
%     fid = fopen([dname  fname], 'w');
%     s = get(button.fMRI, 'string');
%     
%     if ~iscell(s)
%         s = {s};
%     end % if
%     
%     for i = 1:length(s)
%         fprintf(fid, '%s\n', s{i});
%     end % for
%     
%     fclose (fid);
%     
% end % if fname
% end


function clrfiles(button)

set(button.fMRI, 'string', '', 'value', 0);
clr(button); % also clear log

end

function clrmask(button)

set(button.mask, 'string', ' no mask', 'value', 0);
end

function clr(button)

set(  button.outputlog, 'string', '<empty>', ...
    'value', 1);
end

function sav(hObject,event,button)

fid=fopen([get(button.workdir,'string')  'CCA_analysis.log'],'w');
s=get(button.outputlog,'string');
if ~iscell(s)
    s={s};
end
for i=1:numel(s)
    fprintf(fid,'%s\n',s{i});
end
fclose(fid);
end




function runcCCA(hObject,event,button)

fnames=get(button.workdir,'string');

if ~strcmpi(fnames,'')
    fMRIlist=get(button.fMRIlist,'string');fMRIlist=fMRIlist(:);
    masklist=get(button.masklist,'string');
    if iscell(masklist)
        masklist=masklist(:);
    else
        masklist='';
    end
    designnames=get(button.design,'string');
    constnames=get(button.constlist,'string');
    
    %%%%%%%%%%%%load design matrix and contrast file%%%%%%%%%%%%%%
    des=load(designnames);
    fid_des=fieldnames(des);
    designlist=getfield(des,fid_des{1});designlist=designlist(:);
    if strcmpi(constnames,'select contrast')
        constlist='';
    else
        con=load(constnames);
        fid_con=fieldnames(con);
        constlist=getfield(con,fid_con{1});
        constlist=constlist(:);
    end
    
    n_fMRI=numel(fMRIlist);
    n_mask=numel(masklist);
    n_design=numel(designlist);
    n_const=numel(constlist);
    
    if n_design==1
        fprintf('The same design matrix is used for all subject(s)\n');
        designlist=repmat(designlist,ones(n_fMRI,1),1);
        n_design=numel(designlist);
    end
    
    if n_mask==1
        fprintf('The same mask is used for all subject(s)\n');
        masklist=repmat(masklist,ones(n_fMRI,1),1);
        n_mask=numel(masklist);
    end
    
    if n_mask==0
        fprintf('No mask selected, default mask is used\n');
    end
    
    if n_const==1
        fprintf('The same contrast is used for all subject(s)\n');
        constlist=repmat(constlist,ones(n_fMRI,1),1);
        n_const=numel(constlist);
    end
    
    if n_const==0
        fprintf('No contrast selected, t test is not performed\n');
    end
        
    if n_fMRI~=n_design
        error('Please check the input cell array size');
    end
    
    checkpvalue(hObject,event,button);
    checkpsivalue(hObject,event,button);
    for n=1:n_fMRI
        set(button.outputlog,'string',[get(button.outputlog,'string');{['running with [ '...
            fMRIlist{n}]}]);
        
        opts=[];
        opts.pvalue=str2num(get(button.pvalue,'string'));
        opts.psivalue=str2num(get(button.psivalue,'string'));
        opts.design=whiten(designlist{n});
        lst=dir(fMRIlist{n});
        tdim=size(designlist{n},1);
        if numel(lst)==0
            log=['The file(s) ', fMRIlist{n},' are not found'];
            set(button.outputlog,'string',[get(button.outputlog,'string');log]);
            fprintf('The file(s) %s are not found\n',fMRIlist{n});
            fprintf('skip\n');
            continue;
        elseif numel(lst)==1
            fMRI_hdr=load_untouch_header_only(fMRIlist{n});
            if fMRI_hdr.dime.dim(1)==3 || fMRI_dime.dim(5)~=tdim
                log=['The file(s) does not match the dimension of design matrix'];
                set(button.outputlog,'string',[get(button.outputlog,'string');log]);
                fprintf('The file(s) %s does not match the dimension of design matrix\n',fMRIlist{n});
                fprintf('skip\n');
                continue;
            end
            fMRIdata=load_untouch_nii(fMRIlist{n});
            opts.fMRIdata=permute(fMRIdata.img,[4,1:3]);
            
        elseif numel(lst)~=tdim
            log=['The number of files by does not match the dimension of design matrix'];
            set(button.outputlog,'string',[get(button.outputlog,'string');log]);
            fprintf('The number of files by %s does not match the dimension of design matrix\n',fMRIlist{n});
            fprintf('skip\n');
            continue;
        elseif numel(lst)==tdim
            opts.fMRIdata=fmrimerge(fMRIlist{n});
        end
        if n_mask==0
            mask=squeeze(mean(abs(opts.fMRIdata),1));
            opts.mask=(mask>=0.1*max(mask(:)));
        else
            try
                masknii=load_untouch_nii(masklist{n});
                opts.mask=(masknii.img>=0.1*max(masknii.img(:)));
            catch
                log='Mask is not correctly selected, default mask is used';
                set(button.outputlog,'string',[get(button.outputlog,'string');log]);
                fprintf('Mask is not correctly selected\n');
                fprintf('Default mask is used\n');
                mask=squeeze(mean(abs(opts.fMRIdata),1));
                opts.mask=(mask>=0.1*max(mask(:)));
            end
        end
        
        if n_const==0
            opts.contrast=zeros(1,size(opts.design,2));
        else
            contrast=constlist{n};% nconst x p
            if size(contrast,2)~=size(opts.design,2)
                fprintf('Contrast and design matrix have different dimension\n');
                fprintf('skip\n');
                continue;
            else
                opts.contrast=contrast;
            end
        end
        
        sz=size(opts.fMRIdata);
        if sum(size(opts.mask)-sz(2:4))~=0
            log='fMRi data and mask have different size';
            set(button.outputlog,'string',[get(button.outputlog,'string');log]);            
            error('fMRI data and mask have different size\n');
        end
        fMRIdata=reshape(opts.fMRIdata,sz(1),[]);
        fMRIdata(:,opts.mask(:)==1)=whiten(fMRIdata(:,opts.mask(:)==1));
        opts.fMRIdata=reshape(fMRIdata,sz);
        log='cCCA setup checking is done, start to run cCCA';
        set(button.outputlog,'string',[get(button.outputlog,'string');log]);
        mode_sel=get(button.constmode,'value');
        mode_opt=get(button.constmode,'string');
        opts.constmode=strtrim(mode_opt(mode_sel,:));
        ccaMaster(opts,n);        
    end
end
end

function checkpvalue(hObject,event,button)

pvalue=get(button.pvalue,'string');
try
    tst=str2num(pvalue);
catch
    fprintf('p value should be numeric\n');
end
end

function checkpsivalue(hObject,event,button)

psivalue=get(button.psivalue,'string');
try
    tst=str2num(psivalue);
catch
    fprintf('psi value should be numeric\n');
end
end

function ccaMaster(opts,n)
X=opts.design;
Y=opts.fMRIdata;
mask=opts.mask;
mode=[opts.pvalue opts.psivalue];
C=opts.contrast;
warning off;
if strcmpi(opts.constmode,'2D')==1
    [Cor,Alp,Beta,Const,opt_Yind]=ccaMain(X,Y,mask,C,[],mode);
elseif strcmpi(opts.constmode,'3D')==1
    [Cor,Alp,Beta,Const,opt_Yind]=ccaMainCube(X,Y,mask,C,[],mode);
end
warning on;
workdir=get(button.workdir,'string');
save([workdir filesep 'Sub_',num2str(n) '.mat'],'Cor','Const','opt_Yind');
fileID=fopen([workdir filesep 'output.log'],'w');
outputlog=get(button.outputlog,'string');
fprintf(fileID,'%s\n',outputlog{:});
fclose(fileID);
end