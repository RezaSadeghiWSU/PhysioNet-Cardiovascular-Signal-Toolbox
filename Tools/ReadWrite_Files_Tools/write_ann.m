function write_ann(recordName,HRVparams,annotator,ann,annType,subType,chan,num,comments)
%
%   write_ann(recordName,HRVparams,annotator,ann,annType,subType,chan,num,comments)
%
%   OVERVIEW: Writes data into a WFDB annotation file. The files will have 
%             the same name is the recordName but with a 'annotator' 
%             extension. You can use RDANN to verify that the write was 
%             completed sucessfully.
%   
%   INPUT:
% Required Parameters:
%   recorName
%       String specifying the name of the record
%   HRVparams
%       Struct with settings for output, generated by initialize_settings.m
%   annotator
%       String specifying the name of the annotation file to be generated
%   ann
%       Nx1 vector of integers indicating the time of the annotation, in 
%       samples, with respect to the signals in recordName. The values of 
%       ann are sample numbers (indices) with respect to the begining of the
%       record.
% Optional Parameters:
%   annType
%       Nx1 vector of the chars or scalar describing annotation type. 
%       Default is 'N'.
%       For a list of standard annotation codes used by PhyioNet, please see:
%             http://www.physionet.org/physiobank/annotations.shtml
%   subType
%       Nx1 vector of the ints or scalar describing annotation subtype.
%       Default is 0.
%   chan
%       Nx1 vector of the ints or scalar describing annotation CHAN. 
%       Default is 0.
%   num
%       Nx1 vector of the ints or scalar describing annotation NUM. 
%       Default is 0.
%   comments
%       Nx1 vector of the chars or scalar describing annotation comments. 
%       Default is ''.
% OUTPUT:
%       Binary (WFDB COMPATIBLE) or CSV formatted annotation file
% DEPENDENCIES & LIBRARIES:
%       HRV_toolbox https://github.com/cliffordlab/hrv_toolbox
% REFERENCE: 
% REPO:       
%       https://github.com/cliffordlab/hrv_toolbox
% ORIGINAL SOURCE AND AUTHORS:     
%       This script written by Qiao Li March 2,2017
%       Dependent scripts written by various authors 
%       (see scripts for details)       
% COPYRIGHT (C) 2016 
% LICENSE:    
%       This software is offered freely and without warranty under 
%       the GNU (v3 or later) public license. See license file for
%       more information
%%
if nargin<4
    display('At least four parameters: recordName,HRVparams,annotator,ann, were required.');
    return; 
end
if nargin<9 || isempty(comments)
     comments = repmat('',[length(ann) 1]);
end
if nargin<8
    %num=0;
    num = zeros(length(ann), 1);
end
if nargin<7
    %chan=0;
    chan = zeros(length(ann), 1);
end
if nargin<6
    %subType = 0;
    subType = zeros(length(ann), 1);
end
if nargin<5
    % annType='N';
    annType = repmat('N',[length(ann), 1]);
end


%% Binary ATR Output
if strcmp(HRVparams.output.ann_format,'binary')
    annfile=[recordName '.' annotator];
    ann_pre=0;
    byte_write=[];
    for i=1:length(ann)
        % time from last ann
        anntime=uint16(ann(i)-ann_pre);
        % annType
        if length(annType)>=i
            annType_c=annType(i);
        else
            annType_c=annType(1);
        end
        typei=ann2int(annType_c);
        % short interval
        if anntime<=1023 % 2^10 - 1
            byte1=uint8(bitand(anntime,255));
            byte2=uint8(bitshift(anntime,-8))+bitshift(uint8(typei),2);
            byte_write=[byte_write;byte1;byte2];
        % long interval
        else % 59, SKIP, the next 4 bytes are the interval
            byte1=uint8(bitand(0,255));
            byte2=uint8(bitshift(0,-8))+bitshift(uint8(59),2);
            byte_write=[byte_write;byte1;byte2];
            anntime_L=uint32(ann(i)-ann_pre);
            byte1=uint8(bitand(bitshift(anntime_L,-16),255));
            byte2=uint8(bitand(bitshift(anntime_L,-24),255));
            byte3=uint8(bitand(anntime_L,255));
            byte4=uint8(bitand(bitshift(anntime_L,-8),255));
            byte_write=[byte_write;byte1;byte2;byte3;byte4];
            byte1=bitand(0,255);
            byte2=uint8(bitshift(0,-8))+bitshift(uint8(typei),2);
            byte_write=[byte_write;byte1;byte2];
        end
        if length(subType)>=i
            if subType(i)~=0 % 61, SUB, I = annotation subtyp field for current annotation only; otherwise, assume subtyp = 0. 
                if subType(i)>0
                    byte1=uint8(bitand(uint8(subType(i)),255)); % positive
                    byte2=uint8(bitshift(subType(i),-8))+bitshift(uint8(61),2);
                else % negative
                    byte1=uint8(bitand(uint8(subType(i)+1+255),255));
                    byte2=uint8(3+bitshift(uint8(61),2));
                end
                byte_write=[byte_write;byte1;byte2];
            end
        end
        if i==1 % first annotation
            if chan(i)~=0 % 62, CHN, I = annotation chan field for current and subsequent annotations; otherwise, assume previous chan (initially 0). 
                if chan(i)>0
                    byte1=uint8(bitand(uint8(chan(i)),255));
                    byte2=uint8(bitshift(chan(i),-8))+bitshift(uint8(62),2);
                else
                    byte1=uint8(bitand(uint8(chan(i)+1+255),255));
                    byte2=uint8(3+bitshift(uint8(62),2));
                end
                byte_write=[byte_write;byte1;byte2];
            end
            if num(i)~=0 % 60, NUM, I = annotation num field for current and subsequent annotations; otherwise, assume previous annotation num (initially 0).
                if num(i)>0
                    byte1=uint8(bitand(uint8(num(i)),255)); % ??? -/+
                    byte2=uint8(bitshift(num(i),-8))+bitshift(uint8(60),2);
                else
                    byte1=uint8(bitand(uint8(num(i)+1+255),255));
                    byte2=uint8(3+bitshift(uint8(60),2));
                end
                byte_write=[byte_write;byte1;byte2];
            end
        else % the remains
            if length(chan)>=i
                if chan(i)~=chan(i-1)
                    if chan(i)>=0
                        byte1=uint8(bitand(uint8(chan(i)),255)); % positive value
                        byte2=uint8(bitshift(chan(i),-8))+bitshift(uint8(62),2);
                    else % negative value, is there negative value for chan ???
                        byte1=uint8(bitand(uint8(chan(i)+1+255),255));
                        byte2=uint8(3+bitshift(uint8(62),2));
                    end
                    byte_write=[byte_write;byte1;byte2];
                end
            end
            if length(num)>=i
                if num(i)~=num(i-1)
                    if num(i)>=0
                        byte1=uint8(bitand(uint8(num(i)),255)); % positive value
                        byte2=uint8(bitshift(num(i),-8))+bitshift(uint8(60),2);
                    else % negative value
                        byte1=uint8(bitand(uint8(num(i)+1+255),255));
                        byte2=uint8(3+bitshift(uint8(60),2));
                    end
                    byte_write=[byte_write;byte1;byte2];
                end
            end
        end
        if length(comments)>=i % 63, AUX, I = number of bytes of auxiliary information (which is contained in the next I bytes); an extra null, not included in the byte count, is appended if I is odd. 
            com_len=uint8(length(comments{i}));
            byte1=uint8(bitand(com_len,255));
            byte2=uint8(bitshift(com_len,-8))+bitshift(uint8(63),2);
            byte_write=[byte_write;byte1;byte2];
            for j=1:com_len
                byte_write=[byte_write;uint8(comments{i}(j))];
            end
            if mod(com_len,2)
                byte_write=[byte_write;uint8(0)];
            end
        end
        ann_pre=ann(i);
    end
    byte_write=[byte_write;uint8(0);uint8(0)];
    fid=fopen(annfile,'w');
    fwrite(fid,byte_write);
    fclose(fid);
end

%% CSV Output
if strcmp(HRVparams.output.ann_format,'csv')
    filename = [recordName '.' annotator '.csv'];
    % ann,annType,subType,chan,num,comments

    % Write annotations to .txt file in WFDB compatible format
    for i = 1:length(ann)
        fileID = fopen(filename,'a');
        %fprintf(fileID, '\t%s %7d\t%c\t%5d%5d%5d\r\n',time_formatted,samples(i),ann(i),subType(i),chan(i),num(i));
        fprintf(fileID,'%d', ann(i));
        if length(annType) >= i
            fprintf(fileID,',%s',annType(i));
        end
        if length(subType) >= i
            fprintf(fileID,',%d',subType(i));
        end
        if length(chan) >= i
            fprintf(fileID,',%d',chan(i));
        end
        if length(num) >= i
            fprintf(fileID,',%d',num(i));
        end
        if length(comments) >= i
            fprintf(fileID,',%s',comments(i));
        end
        fprintf(fileID,'\n');
        fclose(fileID);
    end
    clear i
end

end % end write_ann function

%%
function typei=ann2int(ann_Type)
% input: ann_Type, annotation type, char
% output:typei, annotation code, integer

Typestr='NLRaVFJASEj/Q~|sT*D"=pB^t+u?![]en@xf(`)''r';
codeint=[1,2,3,4,5,6,7,8,9,10,11,12,13,14,16,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,39,40,40,41];

typei=codeint(findstr(Typestr,ann_Type));
end
