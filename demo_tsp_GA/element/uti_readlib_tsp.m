% Author:   Hartmut Pohlheim
% History:  08.09.98    file created
%           09.09.98    added lots of data reading, many options can be red now
%                       calculation of EUC_2D edge weights
%                       reading of edge weight with FULL_MATRIX, UPPER_ROW
% http://www.geatbx.com/ver_3_7/geaindex.html

function [TSP_DisplayData, TSP_EdgeWeight] = uti_readlib_tsp(FileName)

   % Define global variables
   global TSPLIB_FILENAME;
   global TSPLIB_NAME;
   global TSPLIB_COMMENT;
   global TSPLIB_DIMENSION;
   global TSPLIB_GLOBALOPT;
   global TSPLIB_BESTTOUR;
   global TSPLIB_DISPLAYDATA;
   global TSPLIB_EDGEWEIGHT;

   % Reassign nargout
   NAOUT = nargout;

   % Define some values and set variables empty 
   ExtDataFile = '.tsp';

   % When no file name is given, ask for one
   if isempty(FileName),
      % Open file selection dialog box
      FilePathLoad = ['*' ExtDataFile];
      [FileNameData, PathNameData]=uigetfile(FilePathLoad, 'Select file with definition of tsp problem!');
      if FileNameData == 0,
         error('The file selection of the data file failed !');
      else
         FileName = [PathNameData FileNameData];
         TSPLIB_FILENAME = strtok(FileNameData, '.');
      end
   else
      FileName = [FileName ExtDataFile];
   end

   % Set variables to empty
   TSP_Name =[]; TSP_Comment = []; TSP_Type = []; TSP_Dimension = [];
   TSP_EdgeWeightType = []; TSP_EdgeWeightFormat = []; TSP_EdgeWeight = [];
   TSP_DisplayDataType = []; TSP_NodeCoord = []; TSP_DisplayData = []; 
   
   % Open the data file and test for errors
   [fidtsplib, error_message] = fopen(FileName, 'rt');
   if fidtsplib == -1, 
      disp(sprintf('error during fopen of data file (%s): %s', FileName, error_message));
   else
      % Process data in the data file
      DataFileRead = 1;
      while DataFileRead,
         Line = fgetl(fidtsplib);
         if any([~ischar(Line), strmatch('EOF', Line)]),
            DataFileRead = 0;
            break
         end
         [TSPOpt, LineRem] = strtok(Line, ':');
         if strmatch('NAME', TSPOpt),
            TSP_Name = strtok(LineRem(2:end));
            
         elseif strmatch('COMMENT', TSPOpt),
            TSP_Comment = strvcat(TSP_Comment, LineRem(2:end));
            
         elseif strmatch('TYPE', TSPOpt),
            TSP_Type = strtok(LineRem(2:end));
            
         elseif strmatch('DIMENSION', TSPOpt),
            TSP_Dimension = sscanf(strtok(LineRem(2:end)), '%g');

         elseif strmatch('EDGE_WEIGHT_TYPE', TSPOpt),
            TSP_EdgeWeightType = strtok(LineRem(2:end));
            
         elseif strmatch('EDGE_WEIGHT_FORMAT', TSPOpt),
            TSP_EdgeWeightFormat = strtok(LineRem(2:end));

         elseif strmatch('DISPLAY_DATA_TYPE', TSPOpt),
            TSP_DisplayDataType = strtok(LineRem(2:end));

         elseif strmatch('NODE_COORD_SECTION', TSPOpt),
            IxData = 1;
            for IxData = 1:TSP_Dimension,
               Line = fgetl(fidtsplib);
               Data = sscanf(Line, '%g');
               TSP_NodeCoord(IxData, :) = Data([2:end])';
            end
         
         elseif strmatch('EDGE_WEIGHT_SECTION', TSPOpt),
            IxData = 1;
            for IxData = 1:TSP_Dimension,
               Line = fgetl(fidtsplib);
               Data = sscanf(Line, '%g');
               if strmatch('FULL_MATRIX', TSP_EdgeWeightFormat),
                  TSP_EdgeWeight(IxData, :) = Data';
               elseif strmatch('UPPER_ROW', TSP_EdgeWeightFormat),
                  if IxData > 1, AddData = TSP_EdgeWeight(1:IxData-1, IxData); else AddData = []; end
                  TSP_EdgeWeight(IxData, :) = [AddData', 0, Data'];
                  if IxData == TSP_Dimension-1,
                     IxData = IxData+1;
                     TSP_EdgeWeight(IxData, :) = [TSP_EdgeWeight(1:IxData-1, IxData)', 0];
                     break;
                  end
               end
            end

         elseif strmatch('DISPLAY_DATA_SECTION', TSPOpt),
            IxData = 1;
            for IxData = 1:TSP_Dimension,
               Line = fgetl(fidtsplib);
               Data = sscanf(Line, '%g');
               TSP_DisplayData(IxData, :) = Data(2:end)';
            end

         elseif any([isempty(TSPOpt), all(isspace(TSPOpt))]),
            % do nothing
            
         else
            warning(sprintf('unrecognized option: %s', TSPOpt));
         end

      end

      if all([isempty(TSP_DisplayData), ~(isempty(TSP_NodeCoord))]),
         if any([strmatch('COORD_DISPLAY', TSP_DisplayDataType), isempty(TSP_DisplayDataType)])
            TSP_DisplayData = TSP_NodeCoord;
         end
      end

      fclose(fidtsplib);
   end


   % Compute the Edge Weights, when not given
   if isempty(TSP_EdgeWeight),
      Nedge = size(TSP_NodeCoord, 1);
      if ~(isempty(TSP_Dimension)), 
         if Nedge ~= TSP_Dimension,
            warning('Number of coordinates and defined dimension in data file are not equal!');
         end
      end
      % Preset the edge weight matrix with zeros
      TSP_EdgeWeight = zeros([Nedge, Nedge]); 
      % Calculate the edge weight according to the edge weight type
      if strmatch('EUC_2D', TSP_EdgeWeightType),
         for iedge = 1:Nedge,
            % create full matrix with edge weights (distances), every distance twice,
            Diff1 = repmat(TSP_NodeCoord(iedge,:), [Nedge 1]);
            Diff2 = TSP_NodeCoord;
            % Diff1(1:10,:)-Diff2(1:10,:), pause
            TSP_EdgeWeight(iedge,:) = round(sqrt(sum(((Diff1 - Diff2).^2)')));
         end
         
      else
         warning(sprintf('Unknown Edge Weight Type: %s !', TSP_EdgeWeightType));
         TSP_EdgeWeight = []; 
      end
   end

   
   % Assign local data to global variables
   TSPLIB_NAME = TSP_Name;
   TSPLIB_COMMENT = TSP_Comment;
   TSPLIB_DIMENSION = TSP_Dimension;
   TSPLIB_DISPLAYDATA = TSP_DisplayData;
   TSPLIB_EDGEWEIGHT = TSP_EdgeWeight;

   % Output some data
   format compact;
   fprintf('Name: %s,  Type: %s,  Dimension: %g,  size EdgeWeight: %s (', ...
           TSPLIB_NAME, TSP_Type, TSPLIB_DIMENSION, sprintf('%g  ', size(TSPLIB_EDGEWEIGHT)));
   if ~(isempty(TSP_EdgeWeightType)), fprintf('%s', TSP_EdgeWeightType); end
   if ~(isempty(TSP_EdgeWeightFormat)), fprintf('  %s', TSP_EdgeWeightFormat); end
   fprintf('), size DisplayData: %s \n', sprintf('%g  ', size(TSPLIB_DISPLAYDATA)));
   % fprintf('size TSP_NodeCoord: %g  %g\n', size(TSP_NodeCoord,1), size(TSP_NodeCoord,2));