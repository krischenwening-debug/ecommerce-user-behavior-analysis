USE taobao;

-- 1. 聚合“用户-商品”维度的基础行为频次
DROP TABLE IF EXISTS user_behavior_total;
CREATE TABLE user_behavior_total AS
SELECT
    user_id,
    item_id,
    COUNT(IF(behavior_type = 'pv', 1, NULL)) AS pv,
    COUNT(IF(behavior_type = 'cart', 1, NULL)) AS cart,
    COUNT(IF(behavior_type = 'fav', 1, NULL)) AS fav,
    COUNT(IF(behavior_type = 'buy', 1, NULL)) AS buy
FROM userbehavior1
GROUP BY 1, 2;

-- 2. 行为矩阵二值化转换（0或1）
DROP TABLE IF EXISTS user_behavior_total_standard;
CREATE TABLE user_behavior_total_standard AS
SELECT
    user_id,
    item_id,
    IF(pv > 0, 1, 0) AS ifpv,
    IF(cart > 0, 1, 0) AS ifcart,
    IF(fav > 0, 1, 0) AS iffav,
    IF(buy > 0, 1, 0) AS ifbuy
FROM user_behavior_total;

-- 3. 拼接转化路径状态
DROP TABLE IF EXISTS user_path;
CREATE TABLE user_path AS
SELECT
    user_id,
    item_id,
    CONCAT(ifpv, ifcart, iffav, ifbuy) AS path
FROM user_behavior_total_standard;

-- 4. 统计具体行为转化路径细分频次
DROP TABLE IF EXISTS user_path_num;
CREATE TABLE user_path_num AS
SELECT
    path,
    CASE
        WHEN path = '1101' THEN '浏览-收藏-/-购买'
        WHEN path = '1011' THEN '浏览-/-加购-购买'
        WHEN path = '1111' THEN '浏览-收藏-加购-购买'
        WHEN path = '1001' THEN '浏览-/-/-购买'
        WHEN path = '1010' THEN '浏览-/-加购-/'
        WHEN path = '1100' THEN '浏览-收藏-/'
        WHEN path = '1110' THEN '浏览-收藏-加购-/'
        ELSE '浏览-/-/-/'
    end AS description,
    COUNT(*) AS path_num
FROM user_path
WHERE SUBSTRING(path, 1, 1) <> '0'
GROUP BY path;

-- 5. 沉淀核心环节转化漏斗数据表
DROP TABLE IF EXISTS df_buy_path;
CREATE TABLE df_buy_path (
    buy_path VARCHAR(55),
    buy_path_num INT(9)
);

INSERT INTO df_buy_path
SELECT '浏览', SUM(path_num) FROM user_path_num;

INSERT INTO df_buy_path
SELECT '浏览后收藏加购', SUM(IF(path IN ('1101', '1100', '1010', '1011', '1110', '1111'), path_num, NULL)) FROM user_path_num;

INSERT INTO df_buy_path
SELECT '浏览后收藏加购后购买', SUM(IF(path IN ('1101', '1011', '1111'), path_num, NULL)) FROM user_path_num;
