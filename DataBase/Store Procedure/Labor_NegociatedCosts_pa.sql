CREATE PROCEDURE [dbo].[Labor_NegociatedCosts_pa]
  @WorkorderID varchar(7)
, @WorkorderMod char(2)
, @FromDate varchar(10) = NULL
, @ToDate varchar(10) = NULL
, @AcctPeriodUniqueID int = NULL

AS

SET NOCOUNT ON

Select c.CostCode as cstcde 
, u.FirstName + ' ' + u.LastName as [person]
, dbo.GetAssemblyDescriptions_fn(@WorkorderID, @WorkorderMod, RTRIM(c.CostCode), '00', 'yes') as PayeeCol 
, MIN(ts.TSperiod) as min_trndte
, MAX(ts.TSperiod) as max_entdte
, gl.AccountingPeriod
, SUM(tsl.TSlineTotal) as hours
--, Case isnull(wp.UnitPrice,0)
--    when 0 then 'included'
--    else convert(varchar(30),(SUM(tsl.TSlineTotal) * wp.UnitPrice))
--  end as sum_cstamt
, Case 
	when bl.WorkorderPriceID is null then convert(varchar(30),(SUM(tsl.TSlineTotal) * sc.StandardCost))
	when isnull(wp.UnitPrice,0) = 0 then 'included'
    else convert(varchar(30),(SUM(tsl.TSlineTotal) * wp.UnitPrice))
  end as sum_cstamt
, 'Labor' as category
INTO #LaborCosts
FROM (select distinct GeneralLedgerID, GeneralLedgerLineID, CostCode, WorkorderID, WorkorderMod from JobCost where WorkorderID = @WorkorderID and WorkorderMod = @WorkorderMod) c 
Inner Join Workorders w On c.WorkorderID = w.WorkorderID and c.WorkorderMod = w.WorkorderMod
Inner Join GeneralLedger gl On gl.GeneralLedgerID = c.GeneralLedgerID and gl.Source = 'Timesheets'
Inner Join GeneralLedgerLines gll On gl.GeneralLedgerID = gll.GeneralLedgerID and gll.UniqueID = c.GeneralLedgerLineID
Inner Join AccountingControl ac On isnull(ac.AcctControlRef, '') = isnull(gll.AcctControlRef, '') and isnull(ac.AcctControlRef,'') = 'DL'
Inner Join TimesheetLines tsl On gl.SourceID = tsl.TSLineID
Inner Join Timesheet ts On tsl.TSid = ts.TSid and ts.TSstatus in ('Committed','Executed','Closed') 
Inner Join Users u On ts.TSAuthor = u.UserID
Inner Join EmployeeOnly eo On u.UserID = eo.UserID
Inner Join ItemCosts sc On eo.ItemCostID = sc.ItemCostID
left join BuyoutLines bl on bl.Recnum = tsl.BuyoutID
left join WorkorderPrices wp on wp.WorkorderID = w.WorkorderID and wp.WorkorderPriceID = bl.WorkorderPriceID
Where gl.Status <> 'Cancelled'
and not ac.AcctControlRef is null 
--and (@FromDate is null or ts.TSperiod >= @FromDate) 
--and (@ToDate is null or ts.TSperiod <= @ToDate)
and (
		(
			@AcctPeriodUniqueID is null and (@FromDate is null or ts.TSperiod >= @FromDate) and (@ToDate is null or ts.TSperiod <= @ToDate)
		)
		or (not @AcctPeriodUniqueID is null and gl.AccountingPeriod = @AcctPeriodUniqueID)
	)
and not c.CostCode in (
	select wi.AssemblyNumber
	from WorkorderItems wi
	inner join ItemCosts ic on ic.ItemCostID = wi.ItemCostID
	where wi.WorkorderID = @WorkorderID and wi.WorkorderMod = @WorkorderMod
	and ic.IsReimbursable = 'yes'
)
group by c.CostCode, u.FirstName + ' ' + u.LastName, c.WorkorderID, c.WorkorderMod, ac.AcctControlRef, bl.WorkorderPriceID, wp.UnitPrice, sc.StandardCost, gl.AccountingPeriod
having SUM(tsl.TSlineTotal) > 0
order by c.CostCode, u.FirstName + ' ' + u.LastName, c.WorkorderID, c.WorkorderMod


select *
, case when isnull([person],'') = '' then PayeeCol else [person] end as PayeeName
from #LaborCosts
where 1 = 1
--and (@FromDate is null or convert(datetime,min_trndte) >= @FromDate)
--and (@ToDate is null or convert(datetime,max_entdte) <= @ToDate)
and (
		(
			@AcctPeriodUniqueID is null and (@FromDate is null or convert(datetime,min_trndte) >= @FromDate) and (@ToDate is null or convert(datetime,max_entdte) <= @ToDate)
		)
		or (not @AcctPeriodUniqueID is null and AccountingPeriod = @AcctPeriodUniqueID)
	)
group by cstcde, min_trndte, max_entdte, AccountingPeriod, Hours, sum_cstamt, category, [person], PayeeCol
order by convert(datetime,min_trndte), cstcde

DROP TABLE #LaborCosts

--SET NOCOUNT OFF
 GO