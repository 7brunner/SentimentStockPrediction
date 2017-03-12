prices_json = urlread('https://chartapi.finance.yahoo.com/instrument/1.0/IBM/chartdata;type=quote;range=15d/json');
prices_struct = loadjson(prices_json(31:end-1));

p = cellfun(@(x) x.close,prices_struct.series);
t = cellfun(@(x) x.Timestamp,prices_struct.series)';
tt = datetime(t,'ConvertFrom','posixtime','Format','yyyyMMddHHmm');

tweets_merck = MyTwitterAPI(TwitterAppCredentials);
tweets_merck.downloadAllTweets('Merck','since','2010-01-01');
tw = tweets_merck;

vecTweets = tw.vecTweets;
vecTweets_Timestamp = tw.vecTweets_Timestamp;

pr = MyYahooIntradayAPI('Merck');
vecPrices = pr.vecPrices;
vecPrices_Timestamp = pr.vecPrices_Timestamp;

scoreFile = 'C:\Users\Administrator\Desktop\SentimentStockPrediction\AFINN\AFINN-111.txt';
AFINN = readtable(scoreFile,'Delimiter','\t','ReadVariableNames',0);
AFINN.Properties.VariableNames = {'Term','Score'};