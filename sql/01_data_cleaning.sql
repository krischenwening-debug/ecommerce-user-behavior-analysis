USE taobao;

-- 1. 字段名重命名与修改
ALTER TABLE userbehavior1 CHANGE ts time_stamp INT;

-- 2. 检查缺失值
SELECT COUNT(*)
FROM userbehavior1
WHERE user_id IS NULL
   OR item_id IS NULL
   OR category_id IS NULL
   OR behavior_type IS NULL
   OR time_stamp IS NULL;

-- 3. 检查原始时间戳范围
SELECT
    FROM_UNIXTIME(MIN(time_stamp)) AS min_time,
    FROM_UNIXTIME(MAX(time_stamp)) AS max_time
FROM userbehavior1;

-- 4. 统计异常时间数据量
SELECT COUNT(*) AS abnormal_rows
FROM userbehavior1
WHERE time_stamp < UNIX_TIMESTAMP('2017-11-25 00:00:00')
   OR time_stamp > UNIX_TIMESTAMP('2017-12-03 23:59:59');

-- 5. 清理时间窗口外的异常数据
SET SQL_SAFE_UPDATES = 0;
DELETE FROM userbehavior1
WHERE time_stamp < UNIX_TIMESTAMP('2017-11-25 00:00:00')
   OR time_stamp > UNIX_TIMESTAMP('2017-12-03 23:59:59');
SET SQL_SAFE_UPDATES = 1;

SELECT COUNT(*) FROM userbehavior1;

-- 6. 构建自增主键 ID
ALTER TABLE userbehavior1 ADD COLUMN id INT FIRST;
ALTER TABLE userbehavior1 CHANGE COLUMN id id INT PRIMARY KEY AUTO_INCREMENT;

-- 7. 派生标准日期与小时字段
ALTER TABLE userbehavior1
ADD COLUMN event_time DATETIME,
ADD COLUMN event_date DATE,
ADD COLUMN event_hour TINYINT;

SET SQL_SAFE_UPDATES = 0;
UPDATE userbehavior1
SET event_time = FROM_UNIXTIME(time_stamp),
    event_date = DATE(FROM_UNIXTIME(time_stamp)),
    event_hour = HOUR(FROM_UNIXTIME(time_stamp));
SET SQL_SAFE_UPDATES = 1;

-- 8. 预览清洗后的样本
SELECT * FROM userbehavior1 LIMIT 10;
DESCRIBE userbehavior1;
