CREATE VIEW [dbo].[RTS_GeneralLedger_View]

AS

SELECT gl.SourceID as ID
, gl.Source
, jc.BuyoutID
, ac.AccountID
, gll.AcctControlRef
, jc.WorkorderID
, jc.WorkorderMod
, jc.CostCode as OrderCostCode
, case gll.AcctControlRef 
	when 'DL' then '010'
	when 'DE' then '020'
	when 'DM' then '030'
	when 'DS' then '040'
  end as CategoryNumber
, gl.GeneralLedgerID
, isnull(gll.Amount,0) as glAmount
, isnull(gll.Amount,0) * case gll.AcctControlRef 
	when 'DL' then w.LAohRate
	when 'DE' then w.EQohRate
	when 'DM' then w.MAohRate
	when 'DS' then w.SUohRate
  end as glOverhead
, gl.Status as glStatus
, gl.DateforJournal as glTransactionDate
, gl.AccountingPeriod as AccPeriodUniqueID
FROM JobCost jc                     
INNER JOIN GeneralLedger gl on jc.GeneralLedgerID = gl.GeneralLedgerID           
INNER JOIN GeneralLedgerLines gll on jc.GeneralLedgerLineID = gll.UniqueID
INNER JOIN AccountingControl ac on ac.AcctControlRef = gll.AcctControlRef
INNER JOIN (select WorkorderID, WorkorderMod, isnull(LAohRate,0) as LAohRate, isnull(EQohRate,0) as EQohRate, isnull(MAohRate,0) as MAohRate, isnull(SUohRate,0) as SUohRate from Workorders) w on w.WorkorderID = jc.WorkorderID and w.WorkorderMod = jc.WorkorderMod
WHERE gl.Source = 'VendorInvoices'
AND gl.Status <> 'Cancelled'
AND gll.AcctControlRef IN ('DL','DE','DM','DS')

    
UNION ALL


SELECT gl.SourceID as ID
, gl.Source
, jc.BuyoutID
, ac.AccountID
, gll.AcctControlRef
, jc.WorkorderID
, jc.WorkorderMod
, jc.CostCode as OrderCostCode
, case gll.AcctControlRef 
	when 'DL' then '010'
	when 'DE' then '020'
	when 'DM' then '030'
	when 'DS' then '040'
  end as CategoryNumber
, gl.GeneralLedgerID
, isnull(gll.Amount,0) as glAmount
, isnull(gll.Amount,0) * case gll.AcctControlRef 
	when 'DL' then w.LAohRate
	when 'DE' then w.EQohRate
	when 'DM' then w.MAohRate
	when 'DS' then w.SUohRate
  end as glOverhead
, gl.Status as glStatus
, gl.DateforJournal as glTransactionDate
, gl.AccountingPeriod as AccPeriodUniqueID
FROM JobCost jc                     
INNER JOIN GeneralLedger gl on jc.GeneralLedgerID = gl.GeneralLedgerID   
INNER JOIN GeneralLedgerLines gll on jc.GeneralLedgerLineID = gll.UniqueID
INNER JOIN AccountingControl ac on ac.AcctControlRef = gll.AcctControlRef
INNER JOIN (select WorkorderID, WorkorderMod, isnull(LAohRate,0) as LAohRate, isnull(EQohRate,0) as EQohRate, isnull(MAohRate,0) as MAohRate, isnull(SUohRate,0) as SUohRate from Workorders) w on w.WorkorderID = jc.WorkorderID and w.WorkorderMod = jc.WorkorderMod
WHERE gl.Source = 'Timesheets'
AND gl.Status <> 'Cancelled'
AND gll.AcctControlRef IN ('DL','DE','DM','DS')
     
    
UNION ALL


SELECT gl.SourceID as ID
, gl.Source
, jc.BuyoutID
, ac.AccountID
, gll.AcctControlRef
, jc.WorkorderID
, jc.WorkorderMod
, jc.CostCode as OrderCostCode
, case gll.AcctControlRef 
	when 'DL' then '010'
	when 'DE' then '020'
	when 'DM' then '030'
	when 'DS' then '040'
  end as CategoryNumber
, gl.GeneralLedgerID
, isnull(gll.Amount,0) as glAmount
, isnull(gll.Amount,0) * case gll.AcctControlRef 
	when 'DL' then w.LAohRate
	when 'DE' then w.EQohRate
	when 'DM' then w.MAohRate
	when 'DS' then w.SUohRate
  end as glOverhead
, gl.Status as glStatus
, gl.DateforJournal as glTransactionDate
, gl.AccountingPeriod as AccPeriodUniqueID
FROM JobCost jc                     
INNER JOIN GeneralLedger gl on jc.GeneralLedgerID = gl.GeneralLedgerID           
INNER JOIN GeneralLedgerLines gll on jc.GeneralLedgerLineID = gll.UniqueID
INNER JOIN AccountingControl ac on ac.AcctControlRef = gll.AcctControlRef
INNER JOIN (select WorkorderID, WorkorderMod, isnull(LAohRate,0) as LAohRate, isnull(EQohRate,0) as EQohRate, isnull(MAohRate,0) as MAohRate, isnull(SUohRate,0) as SUohRate from Workorders) w on w.WorkorderID = jc.WorkorderID and w.WorkorderMod = jc.WorkorderMod
WHERE gl.Source = 'Equipment'
AND gl.Status <> 'Cancelled'
AND gll.AcctControlRef IN ('DL','DE','DM','DS')       


UNION ALL


SELECT gl.SourceID as ID
, gl.Source
, jc.BuyoutID
, ac.AccountID
, gll.AcctControlRef
, jc.WorkorderID
, jc.WorkorderMod
, jc.CostCode as OrderCostCode
, case gll.AcctControlRef 
	when 'DL' then '010'
	when 'DE' then '020'
	when 'DM' then '030'
	when 'DS' then '040'
  end as CategoryNumber
, gl.GeneralLedgerID
, isnull(gll.Amount,0) as glAmount
, isnull(gll.Amount,0) * case gll.AcctControlRef 
	when 'DL' then w.LAohRate
	when 'DE' then w.EQohRate
	when 'DM' then w.MAohRate
	when 'DS' then w.SUohRate
  end as glOverhead
, gl.Status as glStatus
, gl.DateforJournal as glTransactionDate
, gl.AccountingPeriod as AccPeriodUniqueID
FROM JobCost jc                     
INNER JOIN GeneralLedger gl on jc.GeneralLedgerID = gl.GeneralLedgerID           
INNER JOIN GeneralLedgerLines gll on jc.GeneralLedgerLineID = gll.UniqueID
INNER JOIN AccountingControl ac on ac.AcctControlRef = gll.AcctControlRef
INNER JOIN (select WorkorderID, WorkorderMod, isnull(LAohRate,0) as LAohRate, isnull(EQohRate,0) as EQohRate, isnull(MAohRate,0) as MAohRate, isnull(SUohRate,0) as SUohRate from Workorders) w on w.WorkorderID = jc.WorkorderID and w.WorkorderMod = jc.WorkorderMod
WHERE gl.Source = 'ExpenseReimbursement'
AND gl.Status <> 'Cancelled'
AND gll.AcctControlRef IN ('DL','DE','DM','DS')


UNION ALL


SELECT gl.SourceID as ID
, gl.Source
, jc.BuyoutID
, ac.AccountID
, gll.AcctControlRef
, jc.WorkorderID
, jc.WorkorderMod
, jc.CostCode as OrderCostCode
, case gll.AcctControlRef 
	when 'DL' then '010'
	when 'DE' then '020'
	when 'DM' then '030'
	when 'DS' then '040'
  end as CategoryNumber
, gl.GeneralLedgerID
, isnull(gll.Amount,0) as glAmount
, isnull(gll.Amount,0) * case gll.AcctControlRef 
	when 'DL' then w.LAohRate
	when 'DE' then w.EQohRate
	when 'DM' then w.MAohRate
	when 'DS' then w.SUohRate
  end as glOverhead
, gl.Status as glStatus
, gl.DateforJournal as glTransactionDate
, gl.AccountingPeriod as AccPeriodUniqueID
FROM JobCost jc                     
INNER JOIN GeneralLedger gl on jc.GeneralLedgerID = gl.GeneralLedgerID           
INNER JOIN GeneralLedgerLines gll on jc.GeneralLedgerLineID = gll.UniqueID
INNER JOIN AccountingControl ac on ac.AcctControlRef = gll.AcctControlRef
INNER JOIN (select WorkorderID, WorkorderMod, isnull(LAohRate,0) as LAohRate, isnull(EQohRate,0) as EQohRate, isnull(MAohRate,0) as MAohRate, isnull(SUohRate,0) as SUohRate from Workorders) w on w.WorkorderID = jc.WorkorderID and w.WorkorderMod = jc.WorkorderMod
WHERE gl.Source = 'Adjustment'
AND gl.Status <> 'Cancelled'
AND gll.AcctControlRef IN ('DL','DE','DM','DS')       

GO