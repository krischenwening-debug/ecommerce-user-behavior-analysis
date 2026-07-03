USE taobao;

-- 1. 构建每日大盘流量指标数据表（PV/UV/人均浏览量）
DROP TABLE IF EXISTS df_pv_uv;
CREATE TABLE df_pv_uv(
    dates VARCHAR(10),
    pv INT(9),
    uv INT(9),
    pvuv DECIMAL(10,2)
);

INSERT INTO df_pv_uv
SELECT
    event_date,
    COUNT(IF(behavior_type = 'pv', 1, NULL)) AS pv,
    COUNT(DISTINCT user_id) AS uv,
    COUNT(IF(behavior_type = 'pv', 1, NULL)) / COUNT(DISTINCT user_id) AS pvuv
FROM userbehavior1
GROUP BY 1;

SELECT * FROM df_pv_uv LIMIT 10;

-- 2. 构建用户留存分析指标数据表（次日留存/三日留存）
DROP TABLE IF EXISTS df_retention_1;
CREATE TABLE df_retention_1(
    dates VARCHAR(10),
    retention_1 DECIMAL(10,4),
    retention_3 DECIMAL(10,4)
);

INSERT INTO df_retention_1
SELECT
    first_dates,
    COUNT(DISTINCT IF(DATEDIFF(u1.event_date, a1.first_dates) = 1, a1.user_id, NULL)) / COUNT(DISTINCT a1.user_id) AS retention_1,
    COUNT(DISTINCT IF(DATEDIFF(u1.event_date, a1.first_dates) = 3, a1.user_id, NULL)) / COUNT(DISTINCT a1.user_id) AS retention_3
FROM (
    SELECT user_id, MIN(event_date) AS first_dates
    FROM userbehavior1
    GROUP BY user_id
) a1
LEFT JOIN userbehavior1 u1 ON a1.user_id = u1.user_id AND a1.first_dates < u1.event_date
GROUP BY first_dates;

-- 3. 构建 24 小时分时时序大盘多度量数据表
DROP TABLE IF EXISTS df_timeseries;
CREATE TABLE df_timeseries(
    dates VARCHAR(10),
    hours INT(9),
    pv INT(9),
    cart INT(9),
    fav INT(9),
    buy INT(9)
);

INSERT INTO df_timeseries
SELECT
    event_date,
    event_hour,
    COUNT(IF(behavior_type = 'pv', 1, NULL)) AS pv,
    COUNT(IF(behavior_type = 'cart', 1, NULL)) AS cart,
    COUNT(IF(behavior_type = 'fav', 1, NULL)) AS fav,
    COUNT(IF(behavior_type = 'buy', 1, NULL)) AS buy
FROM userbehavior1
GROUP BY 1, 2
ORDER BY 1, 2;