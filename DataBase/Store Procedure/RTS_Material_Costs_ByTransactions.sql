
CREATE PROCEDURE [dbo].[RTS_Material_Costs_ByTransactions]
  @WorkorderID varchar(7)
, @WorkorderMod char(2) = NULL
, @FromDate varchar(10) = NULL
, @ToDate varchar(10) = NULL
, @AcctPeriodUniqueID int = NULL

AS

SET NOCOUNT ON

SELECT gl.GeneralLedgerID as id
, c.GeneralLedgerLineID
, c.CostCode as cstcde 
, CASE gl.Source
	WHEN 'VendorInvoices' THEN vx.EntityName 
	WHEN 'ExpenseReimbursement' THEN rx.EmployeeName + ', ' + rx.ExpenseDescription
	WHEN 'Adjustment' THEN gll.Payee + ', ' + gll.Description
	ELSE 'No Data'
	END as [Name]
, CASE gl.Source
	WHEN 'VendorInvoices' THEN vx.VendorInvoiceDate
	WHEN 'ExpenseReimbursement' THEN rx.ExpenseDate
	WHEN 'Adjustment' THEN gll.Date
	ELSE NULL
	END as min_trndte 
, CASE gl.Source
	WHEN 'VendorInvoices' THEN vx.VendorInvoiceDate
	WHEN 'ExpenseReimbursement' THEN rx.ExpenseDate
	WHEN 'Adjustment' THEN gll.Date
	ELSE NULL
	END as max_entdte
, gl.AccountingPeriod
, 0 as hours 
, gll.Amount as sum_cstamt 
, 'Material' as category
, CASE gl.Source
	WHEN 'VendorInvoices' THEN 'VI-' + ltrim(gl.GeneralLedgerID)
	WHEN 'ExpenseReimbursement' THEN 'EA-' + ltrim(gl.GeneralLedgerID)
	WHEN 'Adjustment' THEN 'AE-' + ltrim(gl.GeneralLedgerID)
	ELSE 'TBD'
	END as SourceID
, c.WorkorderMod as scope
INTO #MaterialCosts
FROM (select distinct GeneralLedgerID, GeneralLedgerLineID, CostCode, WorkorderID, WorkorderMod from JobCost where WorkorderID = @WorkorderID and (@WorkorderMod is null or WorkorderMod = @WorkorderMod)) c 
INNER JOIN GeneralLedger gl On gl.GeneralLedgerID = c.GeneralLedgerID 
INNER JOIN GeneralLedgerLines gll On gl.GeneralLedgerID = gll.GeneralLedgerID and gll.UniqueID = c.GeneralLedgerLineID
INNER JOIN AccountingControl ac On isnull(ac.AcctControlRef, '') = isnull(gll.AcctControlRef, '') and isnull(ac.AcctControlRef,'DM') = 'DM' 
LEFT JOIN (	select vi.ID, e.EntityName, convert(datetime,vi.VendorInvoiceDate) as VendorInvoiceDate, VendorInvoiceNumber
			from VendorInvoices vi
			Left Join Buyout b On vi.BuyoutID = b.BuyoutID 
			Left Join Vendor v On b.VendorID = v.Vendor# 
			Left Join Entity e On v.EntityID = e.EntityID
			where vi.VendorInvoiceStatus in ('Committed','Executed','Closed') and not vi.ID is null 
		  ) vx ON gl.SourceID = vx.ID
LEFT JOIN ( select ex.ExpenseUniqueID, ex.ExpenseDate, isnull(ex.ExpenseDescription,'') as ExpenseDescription, u.FirstName + ' ' + u.LastName as EmployeeName, bo.WorkorderID, bo.Ordnum
			from Expenses ex
			inner join Buyout bo on bo.BuyoutID = ex.BuyoutID
			left join dbo.Users u on u.UserID = ex.ExpensePurchaserID
		  ) rx ON rx.ExpenseUniqueID = gl.sourceID
WHERE gl.Status <> 'Cancelled' 
AND NOT ac.AcctControlRef is null 
ORDER BY c.CostCode, vx.EntityName, c.WorkorderMod, rx.EmployeeName, gl.Source


select *
from #MaterialCosts
where 1 = 1
--and (@FromDate is null or convert(datetime,min_trndte) >= @FromDate)
--and (@ToDate is null or convert(datetime,max_entdte) <= @ToDate)
and (
		(
			@AcctPeriodUniqueID is null and (@FromDate is null or convert(datetime,min_trndte) >= @FromDate) and (@ToDate is null or convert(datetime,max_entdte) <= @ToDate)
		)
		or (not @AcctPeriodUniqueID is null and AccountingPeriod = @AcctPeriodUniqueID)
	)


DROP TABLE #MaterialCosts

--SET NOCOUNT OFF

GO
