USE taobao;

-- 1. 计算核心指标：构建 R（最后购买日期）和 F（购买总次数）基础表
DROP TABLE IF EXISTS df_rfm_model;
CREATE TABLE df_rfm_model AS
SELECT
    user_id,
    MAX(event_date) AS last_buy_date,
    COUNT(event_date) AS buy_times
FROM userbehavior1
GROUP BY user_id;

ALTER TABLE df_rfm_model
ADD COLUMN r_score INT(9),
ADD COLUMN f_score INT(9),
CHANGE COLUMN last_buy_date recency VARCHAR(10),
CHANGE COLUMN buy_times frequency INT(9);

-- 2. 运用 NTILE(5) 计算 R/F 百分位百分制得分
SET SQL_SAFE_UPDATES = 0;
WITH tmp1 AS (
    SELECT
        user_id,
        NTILE(5) OVER(ORDER BY recency ASC) * 20 AS r_score_hundred,
        NTILE(5) OVER(ORDER BY frequency ASC) * 20 AS f_score_hundred
    FROM df_rfm_model
)
UPDATE df_rfm_model df
LEFT JOIN tmp1 ON df.user_id = tmp1.user_id
SET df.r_score = tmp1.r_score_hundred,
    df.f_score = tmp1.f_score_hundred;

-- 3. 计算 R/F 综合大盘基线均值
ALTER TABLE df_rfm_model ADD COLUMN avg_r DECIMAL(10,2), ADD COLUMN avg_f DECIMAL(10,2);

WITH tmp2 AS (
    SELECT
        user_id,
        AVG(r_score) OVER() AS avg_r1,
        AVG(f_score) OVER() AS avg_f1
    FROM df_rfm_model
)
UPDATE df_rfm_model df
LEFT JOIN tmp2 ON df.user_id = tmp2.user_id
SET df.avg_r = tmp2.avg_r1,
    df.avg_f = tmp2.avg_f1;

-- 4. 构建五分制 RFM 细分层级最终结果表
DROP TABLE IF EXISTS df_rfm_final;
CREATE TABLE df_rfm_final AS
WITH t AS (
    SELECT
        user_id,
        recency,
        frequency,
        NTILE(5) OVER (ORDER BY recency ASC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score
    FROM df_rfm_model
)
SELECT
    *,
    CASE
        WHEN f_score >= 4 AND r_score >= 4 THEN '价值用户'
        WHEN f_score >= 4 THEN '活跃用户'
        WHEN r_score >= 4 THEN '潜力用户'
        ELSE '流失用户'
    END AS user_class
FROM t;

-- 5. 校验各类别的用户群体分布
SELECT
    user_class,
    COUNT(user_id) AS user_class_num
FROM df_rfm_final
GROUP BY user_class;

SET SQL_SAFE_UPDATES = 1;