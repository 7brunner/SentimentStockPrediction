classdef MyYahooIntradayAPI < handle
    %MYYAHOOINTRADAYAPI Download 15-day intraday history from Yahoo Finance
    %   
    % Constructor: Instantiate with Ticker symbol (e.g. AAPL)
    %
    % Properties: 
    % vecPrices: vector of closing prices
    % vecPrices_Timestamp: Timestamp of prices
    
    properties
        FullDownload
        vecPrices
        vecPrices_Timestamp
    end
    
    methods
        %% Constructor
        function obj = MyYahooIntradayAPI(strTicker)
            %%%
            % Call Yahoo API
            strCall = ['https://chartapi.finance.yahoo.com/instrument/1.0/' strTicker '/chartdata;type=quote;range=15d/json'];
            prices_json = urlread(strCall);
            try
                obj.FullDownload = loadjson(prices_json(31:end-1));
            catch
                error(prices_json)
            end
        end
        
        %% Get-methods
        function vec = get.vecPrices(obj)
            vec = cellfun(@(x) x.close,obj.FullDownload.series)';
        end
        
        function vec = get.vecPrices_Timestamp(obj)
            timestamps = cellfun(@(x) x.Timestamp,obj.FullDownload.series)';
            vec = datetime(timestamps,'ConvertFrom','posixtime'); % ,'Format','yyyyMMddHHmm'
        end
    end
    
end

