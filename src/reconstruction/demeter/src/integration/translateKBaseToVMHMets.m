function [translatedMets]=translateKBaseToVMHMets(toTranslatePath)
% This functions translates metabolites inKBase/Model SEED nomenclature
% that are not yet translated to VMH nomenclature based on names/InCHi keys.
% It is recommended the resulting translated is verified through manual
% inspection.
%
% USAGE:
%
%   [translatedMets]=translateKBaseToVMHMets(toTranslatePath)
%
% INPUT:
%   toTranslatePath         String containing the path to xlsx, csv, or 
%                           txt file with metabolite IDs in KBase/ModelSEED
%                           nomenclature to translate (e.g., cpd00001)
%
% OUTPUTS:
%   translatedMets          Table with KBase metabolite IDs that could be
%                           matched to VMH metabolite IDs
%
% .. Author: Almut Heinken, 01/2021

% read in the metabolites to translate
toTranslateMets = readInputTableForPipeline(toTranslatePath);

% remove already translated metabolites
translateMets = readInputTableForPipeline('MetaboliteTranslationTable.txt');
[C,IA]=intersect(toTranslateMets,translateMets(:,1));
if ~isempty(C)
    warning('Already translated metabolites were removed.')
    toTranslateMets(IA)=[];
end

% prepare the table
toTranslate={'KBase_ID','KBase_name','KBase_formula','KBase_charge','VMH_ID','VMH_name','VMH_formula','VMH_charge'};
toTranslate(2:size(toTranslateMets,1)+1,1)=toTranslateMets;

% load the VMH metabolite database
database=loadVMHDatabase;

% get the KBase/Model SEED metabolite database on ModelSEED GitHub
system('curl -LJO https://raw.githubusercontent.com/ModelSEED/ModelSEEDDatabase/master/Biochemistry/compounds.tsv');

KBaseMets = readInputTableForPipeline('compounds.tsv');

% get some columns that can be used to match IDs
kbaseNameCol=find(strcmp(KBaseMets(1,:),'name'));
kbaseBiGGCol=find(strcmp(KBaseMets(1,:),'abbreviation'));
kbaseSmileCol=find(strcmp(KBaseMets(1,:),'smiles'));
kbaseInchiCol=find(strcmp(KBaseMets(1,:),'inchikey'));
kbaseAltNameCol=find(strcmp(KBaseMets(1,:),'aliases'));

for i=2:size(toTranslate,1)
    % get the available information on this metabolite from the KBase
    % database
    metRow=find(strcmp(KBaseMets(:,1),toTranslate{i,1}));
    metName=KBaseMets{metRow,kbaseNameCol};
    biggID=KBaseMets{metRow,kbaseBiGGCol};
    smileID=KBaseMets{metRow,kbaseSmileCol};
    inchiID=KBaseMets{metRow,kbaseInchiCol};
    altNames=strsplit(KBaseMets{metRow,kbaseAltNameCol},';');
    
    % try to match with IDs from VMH database
    findVMH=find(strcmp(database.metabolites(:,2),metName));
    if isempty(findVMH) && ~isempty(biggID)
        findVMH=find(strcmp(database.metabolites(:,1),biggID));
    end
    if isempty(findVMH) && ~isempty(inchiID)
        findVMH=find(strcmp(database.metabolites(:,9),inchiID));
    end
    if isempty(findVMH) && ~isempty(smileID)
        findVMH=find(strcmp(database.metabolites(:,10),smileID));
    end
    if isempty(findVMH)
        for j=1:length(altNames)
            findVMH=find(strcmp(database.metabolites(:,2),altNames{j}));
            if ~isempty(findVMH)
                break
            end
        end
    end
    if ~isempty(findVMH)
        % fill in the information from KBase
        toTranslate{i,2}=metName;
        toTranslate{i,3}=KBaseMets{metRow,4};
        toTranslate{i,4}=KBaseMets{metRow,8};
        
        % fill in the information from the matched VMH metabolite
        toTranslate{i,5}=database.metabolites{findVMH,1};
        toTranslate{i,6}=database.metabolites{findVMH,2};
        toTranslate{i,7}=database.metabolites{findVMH,4};
        toTranslate{i,8}=database.metabolites{findVMH,5};
    end
end

% remove untranslated metabolites
toTranslate(cellfun('isempty', toTranslate(:,5)),:)=[];
translatedMets=toTranslate;
writetable(cell2table(translatedMets),'translatedMets.txt','FileType','text','WriteVariableNames',false,'Delimiter','tab');

end