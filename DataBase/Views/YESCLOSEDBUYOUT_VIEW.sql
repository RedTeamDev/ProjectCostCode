
CREATE VIEW [dbo].[YesClosedBuyout_View]

AS

SELECT DISTINCT vi.ID as ID, 'VendorInvoices' as Source, vi.BuyoutID, x.AccountID
, x.AcctControlRef, bo.WorkorderID, isnull(x.WorkorderMod,bo.WorkorderMod) as WorkorderMod
, x.CostCode as OrderCostCode
--, bt.CategoryNumber
, case x.AcctControlRef
	when 'DL' then '010'
	when 'DE' then '020'
	when 'DM' then '030'
	when 'DS' then '040'
  end as CategoryNumber
, x.GeneralLedgerID
, x.GeneralLedgerLineID
, convert(DECIMAL(19,8),isnull(x.Amount,0)) as glAmount
, convert(DECIMAL(19,8),0) as glPaidAmount
, x.glStatus
, CASE       
	--WHEN vi.VendorInvoiceStatus IN ('Committed','Executed','Closed') AND isnull(vi.InvoiceApprovedAmount,0) <> 0
	--THEN convert(DECIMAL(19,8),isnull(x.Amount,0) / isnull(vi.InvoiceApprovedAmount,0) * vi.ChangeInRetainage)
	WHEN vi.VendorInvoiceStatus IN ('Committed','Executed','Closed') AND isnull(vi.ChangeInRetainage,0) <> 0
	THEN convert(DECIMAL(19,8),vi.ChangeInRetainage)
	ELSE convert(DECIMAL(19,8),0)      
  END AS RetainedAmt      
, vi.VendorInvoiceStatus as OpenStatus
, vi.VendorInvoiceStatus as SourceStatus
, bo.Status AS BoStatus
, bo.Ordnum
FROM VendorInvoices vi         
INNER JOIN Buyout bo on bo.BuyoutID = vi.BuyoutID   
--INNER JOIN BuyoutLines bl on bl.Recnum = bo.BuyoutID     
--INNER JOIN BuyoutType bt on bo.BoTypeID = bt.BoTypeID
LEFT JOIN (          
	SELECT gl.GeneralLedgerID, jc.GeneralLedgerLineID, gl.Status as glStatus, gll.Amount, gl.SourceID, gl.Source, jc.CostCode, jc.WorkorderID, jc.WorkorderMod, ac.AccountID, gll.AcctControlRef          
	FROM JobCost jc                     
	INNER JOIN GeneralLedger gl on jc.GeneralLedgerID = gl.GeneralLedgerID           
	INNER JOIN GeneralLedgerLines gll on jc.GeneralLedgerLineID = gll.UniqueID
	INNER JOIN AccountingControl ac on ac.AcctControlRef = gll.AcctControlRef
	WHERE gl.Status <> 'Cancelled'
) x on x.SourceID = vi.ID
	and x.Source = 'VendorInvoices'
	--and x.CostCode = bl.Cstcde
	and x.WorkorderID = bo.WorkorderID
	/*
		and x.AcctControlRef = (case bt.CategoryNumber
		when '010' then 'DL'
		when '020' then 'DE'
		when '030' then 'DM'
		when '040' then 'DS'
		end)
	*/
WHERE bo.Status IN ('Committed','Executed','Closed')        
AND vi.VendorInvoiceStatus IN ('Committed','Executed','Closed')
AND NOT bo.BoTypeID IN (3,4,5)        
    
UNION ALL
    
SELECT DISTINCT tsl.TSlineID as ID, 'Timesheets' as Source, tsl.BuyoutID, x.AccountID
, x.AcctControlRef, bo.WorkorderID, isnull(x.WorkorderMod,bo.WorkorderMod) as WorkorderMod
, x.CostCode as OrderCostCode
--, bt.CategoryNumber
, case x.AcctControlRef
	when 'DL' then '010'
	when 'DE' then '020'
	when 'DM' then '030'
	when 'DS' then '040'
  end as CategoryNumber
, x.GeneralLedgerID
, x.GeneralLedgerLineID
, convert(DECIMAL(19,8),isnull(x.Amount,0)) as glAmount
, convert(DECIMAL(19,8),0) as glPaidAmount
, x.glStatus
, convert(DECIMAL(19,8),0) as RetainedAmt      
, 'Committed' as OpenStatus
, ts.TSstatus as SourceStatus
, bo.Status AS BoStatus
, bo.Ordnum
FROM TimesheetLines tsl
INNER JOIN Timesheet ts on ts.TSid = tsl.TSid
INNER JOIN Buyout bo on bo.BuyoutID = tsl.BuyoutID
--INNER JOIN BuyoutLines bl on bl.Recnum = bo.BuyoutID
--INNER JOIN BuyoutType bt on bo.BoTypeID = bt.BoTypeID
LEFT JOIN (          
	SELECT gl.GeneralLedgerID, jc.GeneralLedgerLineID, gl.Status as glStatus, gll.Amount, gl.SourceID, gl.Source, jc.CostCode, jc.WorkorderID, jc.WorkorderMod, ac.AccountID, gll.AcctControlRef          
	FROM JobCost jc                     
	INNER JOIN GeneralLedger gl on jc.GeneralLedgerID = gl.GeneralLedgerID           
	INNER JOIN GeneralLedgerLines gll on jc.GeneralLedgerLineID = gll.UniqueID
	INNER JOIN AccountingControl ac on ac.AcctControlRef = gll.AcctControlRef
	WHERE gl.Status <> 'Cancelled'
) x on x.SourceID = tsl.TSlineID
	and x.Source = 'Timesheets'
	--and x.CostCode = bl.Cstcde
	and x.WorkorderID = bo.WorkorderID
	/*
		and x.AcctControlRef = (case bt.CategoryNumber
		when '010' then 'DL'
		when '020' then 'DE'
		when '030' then 'DM'
		when '040' then 'DS'
		end)
	*/
WHERE bo.Status IN ('Committed','Executed','Closed')        
AND bo.BoTypeID = 3        
    
UNION ALL
    
SELECT DISTINCT erl.ERLinesID as ID, 'Equipment' as Source, erl.BuyoutID, x.AccountID
, x.AcctControlRef, bo.WorkorderID, isnull(x.WorkorderMod,bo.WorkorderMod) as WorkorderMod
, x.CostCode as OrderCostCode
--, bt.CategoryNumber
, case x.AcctControlRef
	when 'DL' then '010'
	when 'DE' then '020'
	when 'DM' then '030'
	when 'DS' then '040'
  end as CategoryNumber
, x.GeneralLedgerID
, x.GeneralLedgerLineID
, convert(DECIMAL(19,8),isnull(x.Amount,0)) as glAmount
, convert(DECIMAL(19,8),0) as glPaidAmount
, x.glStatus
, convert(DECIMAL(19,8),0) as RetainedAmt
, 'Committed' as OpenStatus
, 'Committed' as SourceStatus
, bo.Status AS BoStatus
, bo.Ordnum
FROM ERLines erl         
INNER JOIN Buyout bo on bo.BuyoutID = erl.BuyoutID
--INNER JOIN BuyoutLines bl on bl.Recnum = bo.BuyoutID
--INNER JOIN BuyoutType bt on bo.BoTypeID = bt.BoTypeID
LEFT JOIN (          
	SELECT gl.GeneralLedgerID, jc.GeneralLedgerLineID, gl.Status as glStatus, gll.Amount, gl.SourceID, gl.Source, jc.CostCode, jc.WorkorderID, jc.WorkorderMod, ac.AccountID, gll.AcctControlRef          
	FROM JobCost jc                     
	INNER JOIN GeneralLedger gl on jc.GeneralLedgerID = gl.GeneralLedgerID           
	INNER JOIN GeneralLedgerLines gll on jc.GeneralLedgerLineID = gll.UniqueID
	INNER JOIN AccountingControl ac on ac.AcctControlRef = gll.AcctControlRef
	WHERE gl.Status <> 'Cancelled'
) x on x.SourceID = erl.ERLinesID
	and x.Source = 'Equipment'
	--and x.CostCode = bl.Cstcde
	and x.WorkorderID = bo.WorkorderID
	/*
		and x.AcctControlRef = (case bt.CategoryNumber
		when '010' then 'DL'
		when '020' then 'DE'
		when '030' then 'DM'
		when '040' then 'DS'
		end)
	*/
WHERE bo.Status IN ('Committed','Executed','Closed')        
AND bo.BoTypeID = 4        
    
UNION ALL
    
SELECT DISTINCT e.ExpenseUniqueID as ID, 'ExpenseReimbursement' as Source, e.BuyoutID, x.AccountID
, x.AcctControlRef, bo.WorkorderID, isnull(x.WorkorderMod,bo.WorkorderMod) as WorkorderMod
, x.CostCode as OrderCostCode
--, bt.CategoryNumber
, case x.AcctControlRef
	when 'DL' then '010'
	when 'DE' then '020'
	when 'DM' then '030'
	when 'DS' then '040'
  end as CategoryNumber
, x.GeneralLedgerID
, x.GeneralLedgerLineID
, convert(DECIMAL(19,8),isnull(x.Amount,0)) as glAmount
, convert(DECIMAL(19,8),0) as glPaidAmount
, x.glStatus
, convert(DECIMAL(19,8),0) as RetainedAmt        
, 'Committed' as OpenStatus
, e.ExpenseStatus as SourceStatus
, bo.Status AS BoStatus
, bo.Ordnum
FROM Expenses e        
INNER JOIN Buyout bo on bo.BuyoutID = e.BuyoutID
--INNER JOIN BuyoutLines bl on bl.Recnum = bo.BuyoutID
--INNER JOIN BuyoutType bt on bo.BoTypeID = bt.BoTypeID
LEFT JOIN (          
	SELECT gl.GeneralLedgerID, jc.GeneralLedgerLineID, gl.Status as glStatus, gll.Amount, gl.SourceID, gl.Source, jc.CostCode, jc.WorkorderID, jc.WorkorderMod, ac.AccountID, gll.AcctControlRef          
	FROM JobCost jc                     
	INNER JOIN GeneralLedger gl on jc.GeneralLedgerID = gl.GeneralLedgerID           
	INNER JOIN GeneralLedgerLines gll on jc.GeneralLedgerLineID = gll.UniqueID
	INNER JOIN AccountingControl ac on ac.AcctControlRef = gll.AcctControlRef
	WHERE gl.Status <> 'Cancelled'
) x on x.SourceID = e.ExpenseUniqueID
	and x.Source = 'ExpenseReimbursement'
	--and x.CostCode = bl.Cstcde
	and x.WorkorderID = bo.WorkorderID
	/*
		and x.AcctControlRef = (case bt.CategoryNumber
		when '010' then 'DL'
		when '020' then 'DE'
		when '030' then 'DM'
		when '040' then 'DS'
		end)
	*/
WHERE bo.Status IN ('Committed','Executed','Closed')        
AND bo.BoTypeID = 5 

/**********************************************************************************/
GO