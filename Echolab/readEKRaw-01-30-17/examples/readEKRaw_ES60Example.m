%readEKRaw_ES60Example.m
%
%  A copy of the readEKRaw_SimpleExample script using ES60 data.  In this
%  example we use alternative calibration parameters provided by calibration
%  parameter file.
%
%  THIS EXAMPLE REQURIES THE "XML Parser" LIBRARY. This package was originally
%  available from MATLAB Central but it no longer is posted there. It is now
%  packaged with the readEKRaw library.


%  define paths to example raw and bot files
%rawFile = 'data\L0424-D20060717-T134427-ES60.raw';
%outFile = 'data\L0424-D20060717-T134427-ES60.out';
rawFile = 'data\L0001-D20210706-T180147-ES60.raw';
outFile = 'data\L0001-D20210706-T180147-ES60.out';
parmFile = 'data\Example_CalParms.xml';


%  read in raw ES60 data file
disp('Reading .raw file...');
[header, rawData] = readEKRaw(rawFile);


%  read calibration parameters from .xml file
%    readEKRaw provides functions for saving and reading a simple XML based 
%    calibration parameters file.
%  NOTE!
%      The readEKRaw_ReadXMLParms() and readEKRaw_WriteXMLParms() currently
%      are broken due to an issue with the xmltree class they are dependent
%      on. If you need to provide external calibration parameters you will
%      have to develop your own function to insert them into the
%      calibration structure returned from readEKRaw_GetCalParms().
%calParms = readEKRaw_ReadXMLParms(parmFile);

%  extract cal parms from the raw file. You will have to change these
%  fields yourself if you want to provide specific calibration parameters.
calParms = readEKRaw_GetCalParms(header, rawData);


%  read in the .out file - return data as range
disp('Reading .out file...');
[header, botData] = readEKOut(outFile, calParms, rawData, ...
    'ReturnRange', true);


%  convert power to Sv
data = readEKRaw_Power2Sv(rawData, calParms);


%  convert electrical to physical angles
data = readEKRaw_ConvertAngles(data, calParms);


%  create some simple figures of the data
disp('Plotting...');
nFreqs = length(data.pings);
for n=1:nFreqs
    %  plot the echogram
    readEKRaw_SimpleEchogram(data.pings(n).Sv, data.pings(n).number, ...
        data.pings(n).range, 'Title', ...
        ['Sv  ' num2str(calParms(n).frequency)]);
    %  plot the bottom
    hold on
    plot(data.pings(n).number, botData.pings.bottomdepth(n,:), 'c');
    hold off
    
    %  plot the anglogram
    %readEKRaw_SimpleAnglogram(data.pings(n).alongship, ...
     %   data.pings(n).athwartship, data.pings(n).number, ...
     %   data.pings(n).range, 'Title', ...
    %    ['Angles  ' num2str(calParms(n).frequency)]);
    %  plot the bottom
    hold on
    plot(data.pings(n).number, botData.pings.bottomdepth(n,:), 'c');
    hold off
end