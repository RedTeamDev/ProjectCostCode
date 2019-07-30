CREATE PROCEDURE [dbo].[RTS_Labor_Costs_ByTransactions]
  @WorkorderID varchar(7)
, @WorkorderMod char(2) = NULL
, @FromDate varchar(10) = NULL
, @ToDate varchar(10) = NULL
, @AcctPeriodUniqueID int = NULL

AS

SET NOCOUNT ON

Select gl.GeneralLedgerID as id
, c.GeneralLedgerLineID
, c.CostCode as cstcde 
, u.FirstName + ' ' + u.LastName as [person]
, ts.TSperiod as min_trndte
, ts.TSperiod as max_entdte
, gl.AccountingPeriod
, tsl.TSlineTotal as Hours
, gll.Amount as sum_cstamt 
, 'Labor' as category
, 'ET-' + ltrim(gl.GeneralLedgerID) as SourceID
, c.WorkorderMod as scope
INTO #LaborCosts
FROM (select distinct GeneralLedgerID, GeneralLedgerLineID, CostCode, WorkorderID, WorkorderMod from JobCost where WorkorderID = @WorkorderID and (@WorkorderMod is null or WorkorderMod = @WorkorderMod)) c 
Inner Join GeneralLedger gl On gl.GeneralLedgerID = c.GeneralLedgerID and gl.Source = 'Timesheets'
Inner Join GeneralLedgerLines gll On gl.GeneralLedgerID = gll.GeneralLedgerID and gll.UniqueID = c.GeneralLedgerLineID
Inner Join AccountingControl ac On isnull(ac.AcctControlRef, '') = isnull(gll.AcctControlRef, '') and isnull(ac.AcctControlRef,'') = 'DL'
Inner Join TimesheetLines tsl On gl.SourceID = tsl.TSLineID
Inner Join Timesheet ts On tsl.TSid = ts.TSid and ts.TSstatus in ('Committed','Executed','Closed') 
Inner Join Users u On ts.TSAuthor = u.UserID
Where gl.Status <> 'Cancelled' 
and not ac.AcctControlRef is null 
and tsl.TSlineTotal > 0

UNION

Select gl.GeneralLedgerID as id
, c.GeneralLedgerLineID
, c.CostCode as cstcde 
, gll.Payee + ', '+ gll.Description as [person]
, gll.Date as min_trndte
, gll.Date  as max_entdte
, gl.AccountingPeriod
, 0 as Hours
, gll.Amount as sum_cstamt 
, 'Labor' as category
, 'AE-' + ltrim(gl.GeneralLedgerID) as SourceID
, c.WorkorderMod as scope
FROM (select distinct GeneralLedgerID, GeneralLedgerLineID, CostCode, WorkorderID, WorkorderMod from JobCost where WorkorderID = @WorkorderID and (@WorkorderMod is null or WorkorderMod = @WorkorderMod)) c 
Inner Join GeneralLedger gl On gl.GeneralLedgerID = c.GeneralLedgerID and gl.Source = 'Adjustment'
Inner Join GeneralLedgerLines gll On gl.GeneralLedgerID = gll.GeneralLedgerID 
Inner Join AccountingControl ac On isnull(ac.AcctControlRef, '') = isnull(gll.AcctControlRef, '') and isnull(ac.AcctControlRef,'') = 'DL'
Where gl.Status <> 'Cancelled'
and not ac.AcctControlRef is null 
order by c.CostCode

select *
from #LaborCosts
WHERE 1 = 1
--and (@FromDate is null or convert(datetime,min_trndte) >= @FromDate)
--and (@ToDate is null or convert(datetime,max_entdte) <= @ToDate)
and (
		(
			@AcctPeriodUniqueID is null and (@FromDate is null or convert(datetime,min_trndte) >= @FromDate) and (@ToDate is null or convert(datetime,max_entdte) <= @ToDate)
		)
		or (not @AcctPeriodUniqueID is null and AccountingPeriod = @AcctPeriodUniqueID)
	)
order by cstcde

DROP TABLE #LaborCosts

--SET NOCOUNT OFF


GO
