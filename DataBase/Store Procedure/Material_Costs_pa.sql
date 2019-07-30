CREATE PROCEDURE [dbo].[Material_Costs_pa]
  @WorkorderID varchar(7)
, @WorkorderMod char(2)
, @FromDate varchar(10) = NULL
, @ToDate varchar(10) = NULL
, @AcctPeriodUniqueID int = NULL

AS

SET NOCOUNT ON

SELECT c.CostCode as cstcde 
, CASE gl.Source
	WHEN 'VendorInvoices' THEN vx.EntityName 
	WHEN 'ExpenseReimbursement' THEN rx.EmployeeName + ', ' + rx.ExpenseDescription
	WHEN 'Adjustment' THEN gll.Payee + ', ' + gll.Description
	ELSE 'No Data'
	END as [Name]
, dbo.GetAssemblyDescriptions_fn(@WorkorderID, @WorkorderMod, RTRIM(c.CostCode), '00', 'yes') + ', ' + rx.ExpenseDescription as PayeeCol 
, CASE gl.Source
	WHEN 'VendorInvoices' THEN MIN(vx.VendorInvoiceDate) 
	WHEN 'ExpenseReimbursement' THEN MIN(rx.ExpenseDate)
	WHEN 'Adjustment' THEN MIN(gll.Date)
	ELSE NULL
	END as min_trndte 
, CASE gl.Source
	WHEN 'VendorInvoices' THEN MAX(vx.VendorInvoiceDate) 
	WHEN 'ExpenseReimbursement' THEN MAX(rx.ExpenseDate)
	WHEN 'Adjustment' THEN MAX(gll.Date)
	ELSE NULL
	END as max_entdte
, gl.AccountingPeriod
, 0 as hours 
, SUM(gll.Amount) as sum_cstamt 
, 'Material' as category
INTO #MaterialCosts
FROM (select distinct GeneralLedgerID, GeneralLedgerLineID, CostCode, WorkorderID, WorkorderMod from JobCost where WorkorderID = @WorkorderID and WorkorderMod = @WorkorderMod) c 
INNER JOIN GeneralLedger gl On gl.GeneralLedgerID = c.GeneralLedgerID 
INNER JOIN GeneralLedgerLines gll On gl.GeneralLedgerID = gll.GeneralLedgerID and gll.UniqueID = c.GeneralLedgerLineID
INNER JOIN AccountingControl ac On isnull(ac.AcctControlRef, '') = isnull(gll.AcctControlRef, '') and isnull(ac.AcctControlRef,'DM') = 'DM' 
LEFT JOIN (	select vi.ID, e.EntityName, convert(datetime,vi.VendorInvoiceDate) as VendorInvoiceDate
			from VendorInvoices vi
			Left Join Buyout b On vi.BuyoutID = b.BuyoutID 
			Left Join Vendor v On b.VendorID = v.Vendor# 
			Left Join Entity e On v.EntityID = e.EntityID
			where vi.VendorInvoiceStatus in ('Committed','Executed','Closed') and not vi.ID is null 
			--and (@FromDate is null or convert(datetime,vi.VendorInvoiceDate) >= @FromDate)
			--and (@ToDate is null or convert(datetime,vi.VendorInvoiceDate) <= @ToDate)
			and (@AcctPeriodUniqueID is null and (@FromDate is null or convert(datetime,vi.VendorInvoiceDate) >= @FromDate) and (@ToDate is null or convert(datetime,vi.VendorInvoiceDate) <= @ToDate))
		  ) vx ON gl.SourceID = vx.ID
LEFT JOIN ( select ex.ExpenseUniqueID, ex.ExpenseDate, isnull(ex.ExpenseDescription,'') as ExpenseDescription, u.FirstName + ' ' + u.LastName as EmployeeName
			from dbo.Expenses ex
			left join dbo.Users u on u.UserID = ex.ExpensePurchaserID
			where (@FromDate is null or ex.ExpenseDate >= @FromDate)
			and (@ToDate is null or ex.ExpenseDate <= @ToDate)
		  ) rx ON rx.ExpenseUniqueID = gl.sourceID
WHERE gl.Status <> 'Cancelled' 
AND NOT ac.AcctControlRef is null 

GROUP BY c.CostCode, vx.EntityName, c.WorkorderMod, ac.AcctControlRef, rx.EmployeeName, rx.ExpenseDescription, gl.Source, gll.Payee + ', ' + gll.Description, gl.AccountingPeriod

ORDER BY c.CostCode, vx.EntityName, c.WorkorderMod, gl.Source

SELECT *
, CASE WHEN isnull([Name],'') = '' THEN PayeeCol ELSE [Name] END AS	PayeeName
FROM #MaterialCosts
where 1 = 1
--and (@FromDate is null or convert(datetime,min_trndte) >= @FromDate)
--and (@ToDate is null or convert(datetime,max_entdte) <= @ToDate)
and (
		(
			@AcctPeriodUniqueID is null and (@FromDate is null or convert(datetime,min_trndte) >= @FromDate) and (@ToDate is null or convert(datetime,max_entdte) <= @ToDate)
		)
		or (not @AcctPeriodUniqueID is null and AccountingPeriod = @AcctPeriodUniqueID)
	)

--group by cstcde, min_trndte, max_entdte, Hours, sum_cstamt, category, [Name], PayeeCol
order by convert(datetime,min_trndte), cstcde

DROP TABLE #MaterialCosts

--SET NOCOUNT OFF

/****************************************************************/
GO