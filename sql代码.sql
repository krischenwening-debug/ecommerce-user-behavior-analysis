use taobao;

alter table userbehavior1
   change ts time_stamp int;
	-- change behavior behavior_type varchar(5);
    

SELECT COUNT(*)
FROM userbehavior1
WHERE user_id IS NULL
   OR item_id IS NULL
   OR category_id IS NULL
   OR behavior_type IS NULL
   OR time_stamp IS NULL;

 SELECT
    FROM_UNIXTIME(MIN(time_stamp)) AS min_time,
    FROM_UNIXTIME(MAX(time_stamp)) AS max_time
FROM userbehavior1;

DELETE FROM userbehavior1
WHERE time_stamp < UNIX_TIMESTAMP('2017-11-25 00:00:00')
   OR time_stamp > UNIX_TIMESTAMP('2017-12-03 23:59:59');
SELECT *
FROM userbehavior1
LIMIT 10;

DESCRIBE userbehavior1;

SELECT COUNT(*) AS abnormal_rows
FROM userbehavior1
WHERE time_stamp < UNIX_TIMESTAMP('2017-11-25 00:00:00')
   OR time_stamp > UNIX_TIMESTAMP('2017-12-03 23:59:59');

SET SQL_SAFE_UPDATES = 0;
DELETE FROM userbehavior1
WHERE time_stamp < UNIX_TIMESTAMP('2017-11-25 00:00:00')
   OR time_stamp > UNIX_TIMESTAMP('2017-12-03 23:59:59');

SET SQL_SAFE_UPDATES = 1;
select count(*) from userbehavior1;


alter table userbehavior1
add column id int first;

alter table userbehavior1
change column id id int primary key auto_increment;

alter table userbehavior1
add dates varchar(5),
add hours varchar(2);

alter table userbehavior1
change column dates dates varchar(10);

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



ALTER TABLE userbehavior1
ADD COLUMN id BIGINT AUTO_INCREMENT PRIMARY KEY;
UPDATE userbehavior1
SET event_time = FROM_UNIXTIME(time_stamp),
    event_date = DATE(FROM_UNIXTIME(time_stamp)),
    event_hour = HOUR(FROM_UNIXTIME(time_stamp))
WHERE id BETWEEN 300001 AND 500000;

select *
from userbehavior1
limit 10;

ALTER TABLE userbehavior1
DROP COLUMN dates,
DROP COLUMN hours;
drop table df_pv_uv;
create table df_pv_uv(
    dates varchar(10),
    pv int(9),
    uv int(9),
    pvuv decimal(10,2)
);
insert into df_pv_uv
select
    event_date,
    count(if(userbehavior1.behavior_type = 'pv',1,null)) pv,
    count(distinct userbehavior1.user_id) uv,
    count(if(userbehavior1.behavior_type = 'pv',1,null))/count(distinct userbehavior1.user_id) pvuv
from userbehavior1
group by 1

select * 
from df_pv_uv
limit 10;

create table df_retention_1(
    dates varchar(10),
    retention_1 decimal(10,4),
    retention_3 decimal(10,4)
);

insert into df_retention_1
select
    first_dates,
    count(distinct if(datediff(u1.event_date,a1.first_dates)=1,a1.user_id,null))/count(distinct a1.user_id) retention_1,
    count(distinct if(datediff(u1.event_date,a1.first_dates)=3,a1.user_id,null))/count(distinct a1.user_id) retention_3
from (
    (select
        user_id,
        min(event_date) as first_dates
    from userbehavior1
    group by user_id) a1
    left join userbehavior1 u1 on a1.user_id = u1.user_id and a1.first_dates < u1.event_date
)
group by first_dates;


create table df_timeseries(
    dates varchar(10),
    hours int(9),
    pv int(9),
    cart int(9),
    fav int(9),
    buy int(9)
);

insert into df_timeseries
select
    event_date,
    event_hour,
    count(if(behavior_type = 'pv',1,null)) pv,
    count(if(behavior_type = 'cart',1,null)) cart,
    count(if(behavior_type = 'fav',1,null)) fav,
    count(if(behavior_type = 'buy',1,null)) buy
from userbehavior1
group by 1,2
order by 1,2

create table user_behavior_total as
select
    user_id,
    item_id,
    count(if(behavior_type = 'pv',1,null)) pv,
    count(if(behavior_type = 'cart',1,null)) cart,
    count(if(behavior_type = 'fav',1,null)) fav,
    count(if(behavior_type = 'buy',1,null)) buy
from userbehavior1
group by 1,2;

create table user_behavior_total_standard as
select
    user_id,
    item_id,
    if(pv > 0 ,1,0) ifpv,
    if(cart > 0 ,1,0) ifcart,
    if(fav > 0 ,1,0) iffav,
    if(buy > 0 ,1,0) ifbuy
from user_behavior_total;

create table user_path as
select
    user_id,
    item_id,
    concat(ifpv,ifcart,iffav,ifbuy) path
from user_behavior_total_standard;


create table user_path_num as
select
    path,
    case
        when path = 1101 then '浏览-收藏-/-购买'
        when path = 1011 then '浏览-/-加购-购买'
        when path = 1111 then '浏览-收藏-加购-购买'
        when path = 1001 then '浏览-/-/-购买'
        when path = 1010 then '浏览-/-加购-/'
        when path = 1100 then '浏览-收藏-/-/'
        when path = 1110 then '浏览-收藏-加购-/'
        else '浏览-/-/-/'
    end as description,
    count(*) path_num
from user_path
where substring(path,1,1) <> 0
group by path;

create table df_buy_path (
    buy_path varchar(55),
    buy_path_num int(9)
);

insert into df_buy_path
select
    '浏览',
    sum(path_num) buy_path_num
from user_path_num;

insert into df_buy_path
select
    '浏览后收藏加购',
    sum(if(path in (1101,1100,1010,1011,1110,1111),path_num,null)) buy_path_num
from user_path_num;

insert into df_buy_path
select
    '浏览后收藏加购后购买',
    sum(if(path in (1101,1011,1111),path_num,null)) buy_path_num
from user_path_num;


create table df_rfm_model as
select
    user_id,
    max(event_date) last_buy_date,
    count(event_date) buy_times
from userbehavior1
group by user_id;

alter table df_rfm_model
add r_score int(9),
add f_score int(9),
change last_buy_date recency varchar(10),
change buy_times frequency int(9);

select *
from df_rfm_model
limit 5;

SET SQL_SAFE_UPDATES = 0;
with tmp1 as(
select
    user_id,
    ntile(5)over(order by df_rfm_model.recency asc) * 20 r_score_hundred,
    ntile(5)over(order by df_rfm_model.frequency asc) * 20 f_score_hundred
from df_rfm_model
)

update df_rfm_model df
left join tmp1 on df.user_id = tmp1.user_id
set r_score = r_score_hundred,
    f_score = f_score_hundred;

alter table df_rfm_model
add avg_r decimal(10,2),
add avg_f decimal(10,2);

select *
from df_rfm_model
limit 5;

with tmp2 as(
select
    user_id,
    avg(r_score)over() avg_r1,
    avg(f_score)over() avg_f1
from df_rfm_model
)

update df_rfm_model df
left join tmp2 on df.user_id = tmp2.user_id
set avg_r = tmp2.avg_r1,
    avg_f = tmp2.avg_f1;

select *
from df_rfm_model
limit 5;

alter table df_rfm_model
add user_class varchar(10);

select *
from df_rfm_model
limit 5;

SET SQL_SAFE_UPDATES = 0;
CREATE TABLE df_rfm_result AS
SELECT
    user_id,
    recency,
    frequency,
    NTILE(5) OVER (ORDER BY recency) AS r_score,
    NTILE(5) OVER (ORDER BY frequency) AS f_score,
    CASE
        WHEN NTILE(5) OVER (ORDER BY frequency) >= 4
         AND NTILE(5) OVER (ORDER BY recency) >= 4
        THEN '价值用户'
        WHEN NTILE(5) OVER (ORDER BY frequency) >= 4
        THEN '活跃用户'
        ELSE '普通用户'
    END AS user_class
FROM df_rfm_model;

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

select *
from df_rfm_model
limit 5;

select
    user_class,
    count(user_id) user_class_num
from df_rfm_model
group by user_class;
SET SQL_SAFE_UPDATES = 1;

# -- 热门品类
create table df_popular_category as
    select
        category_id,
        count(if(behavior_type = 'pv',1,null)) category_pv
    from userbehavior1
    group by category_id
    order by 2 desc
    limit 10;

# -- 热门商品
create table df_popular_item as
    select
        item_id,
        count(if(behavior_type = 'pv',1,null)) item_pv
    from userbehavior1
    group by item_id
    order by 2 desc
    limit 10


create table df_category_conv_rate as
    select
        category_id,
        count(if(behavior_type = 'pv',1,null)) pv,
        count(if(behavior_type = 'fav',1,null)) fav,
        count(if(behavior_type = 'cart',1,null)) cart,
        count(if(behavior_type = 'buy',1,null)) buy,
        count(distinct if(behavior_type = 'buy',user_id,null))/count(distinct user_id) category_conv_rate
    from userbehavior1
    group by category_id
    order by 6
