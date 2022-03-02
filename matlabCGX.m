clear all;
close all;
clc;

% by Olav Krigolson
% software to connect to a CGX device directly to MATLAB using ble and stream data directly

% specify a Device Name
cgxName = 'CGX Quick-Series Headset'; 

% define muse BLE names and characteristics
serviceUUID1 = '180A';
serviceUUID2 = '2456E1B9-26E2-8F83-E744-F34F01E9D701';
manufacturerNameCharacteristic = '2A29';
modelNumberCharacteristic = '2A24';
firmwareRevisionCharacteristic = '2A26';
softwareRevisionCharacteristic= '2A28';
custom1Characteristic = '2456E1B9-26E2-8F83-E744-F34F01E9D703';    % this is the one we use
custom2Characteristic = '2456E1B9-26E2-8F83-E744-F34F01E9D704';

% connect to a MUSE
b = ble(cgxName);

disp('CGX Device Connected...');

% set up the custom1Charactertistic
mainCharacteristic = characteristic(b,serviceUUID2,custom1Characteristic);

% subscribe to the characteristic
subscribe(mainCharacteristic);

% initialize a few things
counter = 1;
data = [];
currentData = [];

while counter < 500
    
    % read in some new data
    newData = [];
    newData = read(mainCharacteristic);
    
    % append the new data to currentData
    currentData = [currentData newData];
    
    while size(currentData,2) >= 40
        
        % find the first 255
        findFirst255 = find(currentData == 255);
        
        % ensure there is a first 255 in currentData
        if isempty(findFirst255)
            break;
        else
            findFirst255 = findFirst255(1);
        end
        
        % throw out anything before the first 255 but protect against a 255
        % in the first position
        if findFirst255 ~= 1
            currentData(1:findFirst255-1) = [];
        end
        
        % check to see if there is enough data
        if size(currentData,2) < 40
            break
        end

        % find the second 255
        findSecond255 = find(currentData(findFirst255+1:end) == 255);
        
        % make sure there is a second 255 in currentData
        if isempty(findSecond255)
            break;
        else
            findSecond255 = findSecond255(1);
        end
        
        % if the data is good, add it to the variable "data"
        if (findSecond255 - findFirst255) == 38
            data(counter,1:39) = currentData(findFirst255:findSecond255);
            counter = counter + 1;
            currentData(findFirst255:findSecond255) = [];
        end
        
        % if the distance between the two is less than 40 chuck the data as
        % you have lost something
        if findSecond255 - findFirst255 < 38
            currentData(findFirst255:findSecond255) = [];
        end
        
        % if the distance between the two is greater than 40 chuck the data
        % as you have lost something
        if findSecond255 - findFirst255 > 38
            currentData(findFirst255:findSecond255) = [];
        end       

    end
    
end

% recieving 39 bytes
% check to see 39 bytes
% check to see if the first one is 255 (or FF)
% block counter is byte 2, should count incrementally but resets at 127
% then 8 channels of EEG data, 3 bytes each
% then 3 channels of ACC data, 3 bytes each
% then you have the impedance status, 0 or 1 = 1 byte
% then you have a battery byte, voltage as a single number 
% then 2 bytes, which is the trigger number

% need to get scale factors for eeg and acc