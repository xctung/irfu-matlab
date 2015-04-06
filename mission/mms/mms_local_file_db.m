classdef mms_local_file_db < mms_file_db
  %UNTITLED3 Summary of this class goes here
  %   Detailed explanation goes here
  
  properties (SetAccess = immutable)
    dbRoot 
  end
  
  methods
    function obj = mms_local_file_db(rootPath)
      if nargin == 0, obj.dbRoot = '.'; return, end
      if ~ischar(rootPath) || exist(rootPath,'dir')~=7
        errStr = 'rootPath must be a directory path name';
        irf.log('critical',errStr), error(errStr)
      end
      obj.dbRoot = rootPath;
    end
    %% LIST FILES
    function fileList = list_files(obj,filePrefix)
      if length(filePrefix) < 3 || ~strcmp(filePrefix(1:3),'mms')
        errStr = 'filePrefix must begin with mms*';
        irf.log('critical',errStr), error(errStr)
      end
      C = strsplit(filePrefix,'_');
      if length(C)<3
        errStr = 'filePrefix too short';
        irf.log('critical',errStr), error(errStr)
      end
      if strcmp(C{2},'ancillary'),
        fileList = load_ancillary();
      else
        fileList = load_sci();
      end
      % END LIST_FILES
      %% LOAD ANCILLARY
      function fileList = load_ancillary()
        fileList = [];
        fileDir = [obj.dbRoot filesep 'ancillary' filesep C{1} filesep C{3}];
        if exist(fileDir,'dir')~=7, return, end
        filePref = [upper(C{1}) '_' upper(C{3})];
        listing = dir([fileDir filesep filePref '*.V*']);
        if isempty(listing), return, end
        for iFile = 1:length(listing)
          addToList(listing(iFile).name)
        end
        function addToList(name)
          [~,fName,fExt] = fileparts(name);
          ver = str2double(fExt(3:4));
          entry = struct('name',name,'ver',fExt(3:4),'dir',fileDir,...
            'start',[],'stop',[]);
          if isempty(fileList), fileList = add_ss(entry); return, end
          hasFile = arrayfun(@(x) ~isempty(strfind(x.name,fName)),fileList);
          if ~any(hasFile), fileList = [fileList add_ss(entry)]; return, end
          iSame = find(hasFile);
          if length(iSame) > 1, error('multiple files with same name'),end
          if ver>str2double(fileList(iSame).ver)
            fileList(iSame) = add_ss(entry);
          end
          function e = add_ss(e)
            e.start = get_time('start');
            e.stop = get_time('stop');
            function epoch = get_time(s)
              epoch = [];
              cmd = sprintf('grep -m1 -i %s_time %s/%s | awk ''{print $3}''',...
                s,e.dir,e.name);
              [sta,out] = unix(cmd); if sta>0, return, end
              if isempty(out)
                cmd = sprintf('grep -m1 -i %stime %s/%s | awk ''{print $3}''',...
                  s,e.dir,e.name);
                [sta,out] = unix(cmd); if sta>0 || isempty(out), return, end
              end
              sss = [irf_time([str2double(out(1:4)), str2double(out(6:8))],...
                'doy>utc_yyyy-mm-dd') 'T' out(10:21) '000000Z'];
              epoch = EpochTT2000(sss);
            end
          end
        end
      end
      %% LOAD SCI
      function fileList = load_sci()
        fileList = {};
        fileDir = obj.dbRoot;
        for i=1:length(C), fileDir = [fileDir filesep C{i}]; end %#ok<AGROW>
        if exist(fileDir,'dir')~=7, return, end
        listingY = dir(fileDir);
        for iDir = 1:length(listingY)
          % Loop over years
          if ~listingY(iDir).isdir, continue, end
          dNameY = listingY(iDir).name;
          if length(dNameY)~=4, continue, end
          yyyy = str2double(dNameY);
          if yyyy<2015 || yyyy > 2050, continue, end
          listingM = dir([fileDir filesep dNameY]);
          for iDirMo = 1:length(listingM)
            if ~listingM(iDirMo).isdir, continue, end
            dNameM = listingM(iDirMo).name;
            if length(dNameM)~=2, continue, end
            switch dNameM(1)
              case '0', if ~any(dNameM(2)=='123456789'), continue, end
              case '1', if ~any(dNameM(2)=='012'), continue, end
              otherwise, continue
            end
            curDir = [fileDir filesep dNameY filesep dNameM];
            listingD = dir([curDir filesep filePrefix '*.cdf']);
            if isempty(listingD), continue, end
            for iFile = 1:length(listingD)
              fileList = [fileList {[curDir filesep listingD(iFile).name]}]; %#ok<AGROW>
            end
          end
        end
      end
    end
  end
  
end

