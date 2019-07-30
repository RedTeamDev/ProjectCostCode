CREATE PROCEDURE [dbo].[Labor_Costs_pa]
  @WorkorderID varchar(7)
, @WorkorderMod char(2)
, @FromDate varchar(10) = NULL
, @ToDate varchar(10) = NULL
, @AcctPeriodUniqueID int = NULL
, @Summation varchar(3) = NULL

AS

SET NOCOUNT ON

Select c.CostCode as cstcde 
, u.FirstName + ' ' + u.LastName as [person]
, dbo.GetAssemblyDescriptions_fn(@WorkorderID, @WorkorderMod, RTRIM(c.CostCode), '00', 'yes') as PayeeCol 
, MIN(ts.TSperiod) as min_trndte
, MAX(ts.TSperiod) as max_entdte
, gl.AccountingPeriod
, SUM(tsl.TSlineTotal) as Hours
, SUM(gll.Amount) as sum_cstamt 
, 'Labor' as category
INTO #LaborCosts
FROM (select distinct GeneralLedgerID, GeneralLedgerLineID, CostCode, WorkorderID, WorkorderMod from JobCost where WorkorderID = @WorkorderID and WorkorderMod = @WorkorderMod) c 
Inner Join GeneralLedger gl On gl.GeneralLedgerID = c.GeneralLedgerID and gl.Source = 'Timesheets'
Inner Join GeneralLedgerLines gll On gl.GeneralLedgerID = gll.GeneralLedgerID and gll.UniqueID = c.GeneralLedgerLineID
Inner Join AccountingControl ac On isnull(ac.AcctControlRef, '') = isnull(gll.AcctControlRef, '') and isnull(ac.AcctControlRef,'') = 'DL'
Inner Join TimesheetLines tsl On gl.SourceID = tsl.TSLineID
Inner Join Timesheet ts On tsl.TSid = ts.TSid and ts.TSstatus in ('Committed','Executed','Closed') 
Inner Join Users u On ts.TSAuthor = u.UserID
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
group by c.CostCode, u.FirstName + ' ' + u.LastName, c.WorkorderID, c.WorkorderMod, ac.AcctControlRef, gl.AccountingPeriod
having SUM(tsl.TSlineTotal) > 0

UNION ALL

Select c.CostCode as cstcde 
, gll.Payee + ', '+ gll.Description as [person]
, dbo.GetAssemblyDescriptions_fn(@WorkorderID, @WorkorderMod, RTRIM(c.CostCode), '00', 'yes') as PayeeCol 
, MIN(gll.Date) as min_trndte
, MAX(gll.Date)  as max_entdte
, gl.AccountingPeriod
, 0 as Hours
, SUM(gll.Amount) as sum_cstamt 
, 'Labor' as category
FROM (select distinct GeneralLedgerID, CostCode, WorkorderID, WorkorderMod from JobCost where WorkorderID = @WorkorderID and WorkorderMod = @WorkorderMod) c 
Inner Join GeneralLedger gl On gl.GeneralLedgerID = c.GeneralLedgerID and gl.Source = 'Adjustment'
Inner Join GeneralLedgerLines gll On gl.GeneralLedgerID = gll.GeneralLedgerID 
Inner Join AccountingControl ac On isnull(ac.AcctControlRef, '') = isnull(gll.AcctControlRef, '') and isnull(ac.AcctControlRef,'') = 'DL'
Where gl.Status <> 'Cancelled' 
and not ac.AcctControlRef is null 
--and (@FromDate is null or gll.Date >= @FromDate)
--and (@ToDate is null or gll.Date <= @ToDate)
and (
		(
			@AcctPeriodUniqueID is null and (@FromDate is null or gll.Date >= @FromDate) and (@ToDate is null or gll.Date <= @ToDate)
		)
		or (not @AcctPeriodUniqueID is null and gl.AccountingPeriod = @AcctPeriodUniqueID)
	)
group by c.CostCode,  c.WorkorderID, c.WorkorderMod, ac.AcctControlRef , gll.Payee + ', '+ gll.Description, gl.AccountingPeriod

order by c.CostCode


IF @Summation = 'yes' 
	BEGIN

		SELECT 
			SUM(CONVERT(decimal(18,10),ISNULL(sum_cstamt, 0))) as total
		from #LaborCosts
		where 1 = 1
		and (@FromDate is null or convert(datetime,min_trndte) >= @FromDate)
		and (@ToDate is null or convert(datetime,max_entdte) <= @ToDate)
		group by cstcde, min_trndte, max_entdte, Hours, sum_cstamt, category, [person], PayeeCol, AccountingPeriod

	END 
ELSE
	BEGIN

		select cstcde
		, [person]
		, PayeeCol
		, min(min_trndte) as min_trndte
		, max(max_entdte) as max_entdte
		, AccountingPeriod
		, [Hours]
		, sum_cstamt
		, category
		, case when isnull([person],'') = '' then PayeeCol else [person] end as PayeeName
		from #LaborCosts
		where 1 = 1
		and (@FromDate is null or convert(datetime,min_trndte) >= @FromDate)
		and (@ToDate is null or convert(datetime,max_entdte) <= @ToDate)
		--group by cstcde, min_trndte, max_entdte, Hours, sum_cstamt, category, [person], PayeeCol, AccountingPeriod
		group by cstcde, Hours, sum_cstamt, category, [person], PayeeCol, AccountingPeriod
		order by convert(datetime,min(min_trndte)), cstcde

	END

DROP TABLE #LaborCosts

--SET NOCOUNT OFF

/*********************************************************************************/
GO