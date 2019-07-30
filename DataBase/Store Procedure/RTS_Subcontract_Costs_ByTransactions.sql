 
CREATE PROCEDURE [dbo].[RTS_Subcontract_Costs_ByTransactions]
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
, e.EntityName as vendor
, convert(datetime,vi.VendorInvoiceDate) as min_trndte 
, convert(datetime,vi.VendorInvoiceDate) as max_entdte 
, gl.AccountingPeriod
, 0 as hours
, gll.Amount as sum_cstamt 
, 'Subcontract' as category
, 'VI-' + ltrim(gl.GeneralLedgerID) as SourceID
, c.WorkorderMod as scope
INTO #SubcontractCosts
FROM (select distinct GeneralLedgerID, GeneralLedgerLineID, CostCode, WorkorderID, WorkorderMod from JobCost where WorkorderID = @WorkorderID and (@WorkorderMod is null or WorkorderMod = @WorkorderMod)) c 
Inner Join GeneralLedger gl On gl.GeneralLedgerID = c.GeneralLedgerID 
Inner Join GeneralLedgerLines gll On gl.GeneralLedgerID = gll.GeneralLedgerID and gll.UniqueID = c.GeneralLedgerLineID
Inner Join AccountingControl ac On isnull(ac.AcctControlRef, '') = isnull(gll.AcctControlRef, '') and isnull(ac.AcctControlRef,'') = 'DS' 
Left Join VendorInvoices vi On gl.SourceID = vi.ID and vi.VendorInvoiceStatus in ('Committed','Executed','Closed') 
Left Join Buyout b On vi.BuyoutID = b.BuyoutID 
Left Join Vendor v On b.VendorID = v.Vendor# 
Left Join Entity e On v.EntityID = e.EntityID 
Where gl.Status <> 'Cancelled' 
and not ac.AcctControlRef is null 
and not vi.ID is null

UNION ALL

Select gl.GeneralLedgerID as id
, c.GeneralLedgerLineID
, c.CostCode as cstcde 
, gll.Payee + ', '+ gll.Description as vendor
, gll.Date as min_trndte
, gll.Date as max_entdte
, gl.AccountingPeriod
, 0 as Hours
, gll.Amount as sum_cstamt 
, 'Subcontract' as category
, 'AE-' + ltrim(gl.GeneralLedgerID) as SourceID
, c.WorkorderMod as scope
FROM (select distinct GeneralLedgerID, GeneralLedgerLineID, CostCode, WorkorderID, WorkorderMod from JobCost where WorkorderID = @WorkorderID and (@WorkorderMod is null or WorkorderMod = @WorkorderMod)) c 
Inner Join GeneralLedger gl On gl.GeneralLedgerID = c.GeneralLedgerID and gl.Source = 'Adjustment'
Inner Join GeneralLedgerLines gll On gl.GeneralLedgerID = gll.GeneralLedgerID and gll.UniqueID = c.GeneralLedgerLineID
Inner Join AccountingControl ac On isnull(ac.AcctControlRef, '') = isnull(gll.AcctControlRef, '') and isnull(ac.AcctControlRef,'') = 'DS'
Where gl.Status <> 'Cancelled' 
and not ac.AcctControlRef is null 

Order by c.CostCode

select *
from #SubcontractCosts
where 1 = 1
--and (@FromDate is null or convert(datetime,min_trndte) >= @FromDate)
--and (@ToDate is null or convert(datetime,max_entdte) <= @ToDate)
and (
		(
			@AcctPeriodUniqueID is null and (@FromDate is null or convert(datetime,min_trndte) >= @FromDate) and (@ToDate is null or convert(datetime,max_entdte) <= @ToDate)
		)
		or (not @AcctPeriodUniqueID is null and AccountingPeriod = @AcctPeriodUniqueID)
	)

order by cstcde

DROP TABLE #SubcontractCosts

GO