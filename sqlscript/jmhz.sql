﻿
/*
name		    :积木盒子
script file	:jmhz.sql
author		  :daniel
created		  :2014-12-9
modified		:2014-12-15
desc		    :
*/

#指定数据库名称
use ddbid_db;

#删除重复数据
delete from temp_subject_jmhz
 where id not in (select id from (select max(id) as id from temp_subject_jmhz  group by link) a);


#没有抓取到的数据自动结标,进入历史变更表
insert into t_subject_change_his(subject_id,process_before,process_after,change_time)
select t1.id,
			 t1.process process_before,
			 100 process_after,
			 sysdate()
	from t_subject t1
 where t1.platform_id = 3
	 and not exists(select 1 from temp_subject_jmhz t where t.link = t1.link)
;

#没有抓取到的数据自动结标,更新为100%
update t_subject t1 
	 set t1.process = 100
 where t1.platform_id = 3
	 and not exists(select 1 from temp_subject_jmhz t where t.link = t1.link)
;

/*2014-12-25更新*/
#历史表已经存在100%的标的无需进数
delete from temp_subject_jmhz 
 where process = 100 /*updated by daniel on 2014-12-31*/
	 and exists(select 1 from t_subject_his t1 where t1.link = temp_subject_jmhz.link )
;

#更新change_his表中进度大于抓取标的进度的数据
delete from t_subject_change_his /*updated by daniel on 2015-1-5*/
 where exists(select 1 from temp_subject_jmhz t, t_subject t2
											where t2.link = t.link
											  and t2.id = t_subject_change_his.subject_id
												and t_subject_change_his.process_after > t.process ) #注意此处process逻辑要修改
;

#记录进度变更历史，process取数逻辑要修改
insert into t_subject_change_his(subject_id,process_before,process_after,change_time)
select t1.id,
			 t1.process process_before,
			 t.process process_after,
			 sysdate()
	from temp_subject_jmhz t
 inner join t_subject t1 on t1.link = t.link and t1.process <> t.process  #注意此处process逻辑要修改
;

#记录进度变更历史，process取数逻辑要修改，处理temp表进度不是100，而his表进度是100的问题
insert into t_subject_change_his(subject_id,process_before,process_after,change_time)
select t1.id,
			 t1.process process_before,
			 t.process process_after,
			 sysdate()
	from temp_subject_jmhz t
 inner join t_subject_his t1 on t1.link = t.link and t1.process <> t.process  #注意此处process逻辑要修改
;

#插入进度由100变为小于100的数据
insert into t_subject(id,platform_id,link,name,amount,min_amount,income_rate,term,type,area,transfer_claim,repay_type,publish_time,end_time,reward,protect_mode,description,process,month_rate,ten_thousand_revenue,finish_amount,allow_amount,random_rank,term_name,term_unit)
select
id,
platform_id,
link,
name,
amount,
min_amount,
income_rate,
term,
type,
area,
transfer_claim,
repay_type,
publish_time,
end_time,
reward,
protect_mode,
description,
process,
income_rate/12,
income_rate/12*term/100*10000,
amount*process/100,
amount-(amount*process/100),
rand()*100000000000,
case when term < 1 then round(term * 30) else term end ,
case when term < 1 then '天' else '个月' end
from (select t1.id,
			 t.platform_id,
			 t.link,
			 t.name,
			 case when t.amount like '%万%' then replace(t.amount, '万', '') * 10000 else replace(t.amount, ',', '') end amount,
			 case t.min_amount when '' then null else replace(t.min_amount, ',', '') end min_amount,
			 replace(t.income_rate, '%', '') income_rate,
			 case when t.term like '%月%' then replace(t.term, '个月', '') else t.term end as term,
			 case when t.name like '%车%' and t.name like '%周转%' then '车贷'
						when t.name like '%房%' and t.name like '%抵%' then '房贷'
						when t.name like '%企业%' then '企业贷'
						else '个人信用贷' end type,
			 case when t.area like '%已认证%' then null when t.area like '20%' then null else t.area end area,
			 case t.transfer_claim when null then 'N' when '' then 'N' else 'Y' end transfer_claim,
			 t.repay_type,
			 t.publish_time,
			 case when t.process = '' or replace(t.process, '%', '') = 100 then sysdate() else null end end_time,
			 t.reward,
			 case when t.protect_mode like '%公司%' then '第三方担保' else t.protect_mode end protect_mode,
			 t.description,
			 t.process
	from temp_subject_jmhz t
 inner join t_subject_his t1 on t1.link = t.link) a
;

#删除历史表中进度为100%，但抓取的进度小于100%的标的
delete from t_subject_his
 where exists(select 1 from temp_subject_jmhz t1 where t1.link = t_subject_his.link)
;
/*2014-12-25更新结束*/

#积木盒子
replace into t_subject(id,platform_id,link,name,amount,min_amount,income_rate,term,type,area,transfer_claim,repay_type,publish_time,end_time,reward,protect_mode,description,process,month_rate,ten_thousand_revenue,finish_amount,allow_amount,random_rank,term_name,term_unit)
select
id,
platform_id,
link,
name,
amount,
min_amount,
income_rate,
term,
type,
area,
transfer_claim,
repay_type,
publish_time,
end_time,
reward,
protect_mode,
description,
process,
income_rate/12,
income_rate/12*term/100*10000,
amount*process/100,
amount-(amount*process/100),
rand()*100000000000,
case when term < 1 then round(term * 30) else term end ,
case when term < 1 then '天' else '个月' end
from (select t1.id,
			 t.platform_id,
			 t.link,
			 t.name,
			 case when t.amount like '%万%' then replace(t.amount, '万', '') * 10000 else replace(t.amount, ',', '') end amount,
			 case t.min_amount when '' then null else replace(t.min_amount, ',', '') end min_amount,
			 replace(t.income_rate, '%', '') income_rate,
			 case when t.term like '%月%' then replace(t.term, '个月', '') else t.term end as term,
			 case when t.name like '%车%' and t.name like '%周转%' then '车贷'
						when t.name like '%房%' and t.name like '%抵%' then '房贷'
						when t.name like '%企业%' then '企业贷'
						else '个人信用贷' end type,
			 case when t.area like '%已认证%' then null when t.area like '20%' then null else t.area end area,
			 case t.transfer_claim when null then 'N' when '' then 'N' else 'Y' end transfer_claim,
			 t.repay_type,
			 t.publish_time,
			 case when t.process = '' or replace(t.process, '%', '') = 100 then sysdate() else null end end_time,
			 t.reward,
			 case when t.protect_mode like '%公司%' then '第三方担保' else t.protect_mode end protect_mode,
			 t.description,
			 t.process
	from temp_subject_jmhz t
 left join t_subject t1 on t1.link = t.link) a
;

#新标的写入进度变更历史
insert into t_subject_change_his(subject_id,process_before,process_after,change_time)
select t1.id,
			 null,
			 t1.process process_after,
			 sysdate()
	from t_subject t1
 where not exists(select 1 from t_subject_change_his t2 where t2.subject_id = t1.id) 
	 and t1.platform_id = 3
;

#100%标的进入历史表
insert into t_subject_his(id,platform_id,link,name,amount,min_amount,income_rate,term,type,area,transfer_claim,repay_type,publish_time,end_time,reward,protect_mode,description,process,month_rate,ten_thousand_revenue,finish_amount,allow_amount,random_rank,term_name,term_unit)
select id,platform_id,link,name,amount,min_amount,income_rate,term,type,area,transfer_claim,repay_type,publish_time,end_time,reward,protect_mode,description,process,month_rate,ten_thousand_revenue,finish_amount,allow_amount,random_rank,term_name,term_unit
	from t_subject t1
 where t1.platform_id = 3
	 and t1.process = 100
;

#删除主表中100%的标的
delete from t_subject
 where platform_id = 3
	 and process = 100
;
