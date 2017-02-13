prices_json = urlread('https://chartapi.finance.yahoo.com/instrument/1.0/IBM/chartdata;type=quote;range=15d/json');
prices_struct = loadjson(prices_json(31:end-1));

p = cellfun(@(x) x.close,prices_struct.series);
t = cellfun(@(x) x.Timestamp,prices_struct.series)';
tt = datetime(t,'ConvertFrom','posixtime','Format','yyyyMMddHHmm');

