
CREATE PROCEDURE [dbo].[RTS_Labor_NegociatedCosts_ByTransactions]
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
, tsl.TSlineTotal as hours
, Case isnull(wp.UnitPrice,0)
    when 0 then convert(varchar(30),(tsl.TSlineTotal * isnull(eo.LaborPayRate,0)))
    else convert(varchar(30),(tsl.TSlineTotal * wp.UnitPrice))
  end as sum_cstamt
, 'Labor' as category
, 'ET-' + ltrim(gl.GeneralLedgerID) as SourceID
, c.WorkorderMod as scope
FROM Workorders w 
inner join (select distinct GeneralLedgerID, GeneralLedgerLineID, CostCode, WorkorderID, WorkorderMod from JobCost where WorkorderID = @WorkorderID and (@WorkorderMod is null or WorkorderMod = @WorkorderMod)) c on c.WorkorderID = w.WorkorderID and c.WorkorderMod = w.WorkorderMod
Inner Join GeneralLedger gl On gl.GeneralLedgerID = c.GeneralLedgerID and gl.Source = 'Timesheets'
Inner Join GeneralLedgerLines gll On gl.GeneralLedgerID = gll.GeneralLedgerID and gll.UniqueID = c.GeneralLedgerLineID
Inner Join AccountingControl ac On isnull(ac.AcctControlRef, '') = isnull(gll.AcctControlRef, '') and isnull(ac.AcctControlRef,'') = 'DL'
Inner Join TimesheetLines tsl On gl.SourceID = tsl.TSLineID
Inner Join Timesheet ts On tsl.TSid = ts.TSid and ts.TSstatus in ('Committed','Executed','Closed') 
Inner Join Users u On ts.TSAuthor = u.UserID
Inner Join EmployeeOnly eo On u.UserID = eo.UserID
Inner Join ItemCosts ic On ic.ItemCostID = eo.ItemCostID
left join WorkorderPrices wp on wp.WorkorderID = w.WorkorderID and wp.ItemCostID = ic.ItemCostID
Where gl.Status <> 'Cancelled'
and not ac.AcctControlRef is null 
and not c.CostCode in (
	select wi.AssemblyNumber
	from WorkorderItems wi
	inner join ItemCosts ic on ic.ItemCostID = wi.ItemCostID
	where wi.WorkorderID = @WorkorderID and (@WorkorderMod is null or wi.WorkorderMod = @WorkorderMod)
	and ic.IsReimbursable = 'yes'
)
and tsl.TSlineTotal > 0
--and (@FromDate is null or convert(datetime,ts.TSperiod) >= @FromDate)
--and (@ToDate is null or convert(datetime,ts.TSperiod) <= @ToDate)
and (
		(
			@AcctPeriodUniqueID is null and (@FromDate is null or ts.TSperiod >= @FromDate) and (@ToDate is null or ts.TSperiod <= @ToDate)
		)
		or (not @AcctPeriodUniqueID is null and gl.AccountingPeriod = @AcctPeriodUniqueID)
	)
order by c.CostCode, u.FirstName + ' ' + u.LastName, c.WorkorderID, c.WorkorderMod


GO