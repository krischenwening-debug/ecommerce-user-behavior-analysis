USE taobao;

-- 1. 提取流量最高的热门品类 TOP 10
DROP TABLE IF EXISTS df_popular_category;
CREATE TABLE df_popular_category AS
SELECT
    category_id,
    COUNT(IF(behavior_type = 'pv', 1, NULL)) AS category_pv
FROM userbehavior1
GROUP BY category_id
ORDER BY 2 DESC
LIMIT 10;

-- 2. 提取流量最高的热门商品 TOP 10
DROP TABLE IF EXISTS df_popular_item;
CREATE TABLE df_popular_item AS
SELECT
    item_id,
    COUNT(IF(behavior_type = 'pv', 1, NULL)) AS item_pv
FROM userbehavior1
GROUP BY item_id
ORDER BY 2 DESC
LIMIT 10;

-- 3. 构建全品类转化率关联矩阵数据表（用于四象限分析）
DROP TABLE IF EXISTS df_category_conv_rate;
CREATE TABLE df_category_conv_rate AS
SELECT
    category_id,
    COUNT(IF(behavior_type = 'pv', 1, NULL)) AS pv,
    COUNT(IF(behavior_type = 'fav', 1, NULL)) AS fav,
    COUNT(IF(behavior_type = 'cart', 1, NULL)) AS cart,
    COUNT(IF(behavior_type = 'buy', 1, NULL)) AS buy,
    COUNT(DISTINCT IF(behavior_type = 'buy', user_id, NULL)) / COUNT(DISTINCT user_id) AS category_conv_rate
FROM userbehavior1
GROUP BY category_id
ORDER BY 6 DESC;
