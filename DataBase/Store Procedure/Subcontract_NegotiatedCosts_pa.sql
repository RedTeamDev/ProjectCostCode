
CREATE PROCEDURE [dbo].[Subcontract_NegotiatedCosts_pa]
  @WorkorderID varchar(7)
, @WorkorderMod char(2)
, @FromDate varchar(10) = NULL
, @ToDate varchar(10) = NULL
, @AcctPeriodUniqueID int = NULL

AS

SET NOCOUNT ON

Select c.CostCode as cstcde 
, e.EntityName as vendor
, dbo.GetAssemblyDescriptions_fn(@WorkorderID, @WorkorderMod, RTRIM(c.CostCode), '00', 'yes') as PayeeCol 
, MIN(convert(datetime,vi.VendorInvoiceDate)) as min_trndte 
, MAX(convert(datetime,vi.VendorInvoiceDate)) as max_entdte 
, 0 as hours
, SUM(gll.Amount) as sum_cstamt 
, 'Subcontract' as category
, gl.AccountingPeriod
INTO #SubcontractCosts
FROM (select distinct GeneralLedgerID, GeneralLedgerLineID, CostCode, WorkorderID, WorkorderMod from JobCost where WorkorderID = @WorkorderID and WorkorderMod = @WorkorderMod) c 
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
and (@FromDate is null or convert(datetime,vi.VendorInvoiceDate) >= @FromDate)
and (@ToDate is null or convert(datetime,vi.VendorInvoiceDate) <= @ToDate)
and not c.CostCode in (
	select wi.AssemblyNumber
	from WorkorderItems wi
	inner join ItemCosts ic on ic.ItemCostID = wi.ItemCostID
	where wi.WorkorderID = @WorkorderID and wi.WorkorderMod = @WorkorderMod
	and ic.IsReimbursable = 'yes'
)
Group by c.CostCode, e.EntityName, c.WorkorderMod, ac.AcctControlRef, gl.AccountingPeriod
Order by c.CostCode, e.EntityName, c.WorkorderMod

select *
, case when isnull(vendor,'') = '' then PayeeCol else vendor end as PayeeName
from #SubcontractCosts
where 1 = 1
and (
		(
			@AcctPeriodUniqueID is null and (@FromDate is null or convert(datetime,min_trndte) >= @FromDate) and (@ToDate is null or convert(datetime,max_entdte) <= @ToDate)
		)
		or (not @AcctPeriodUniqueID is null and AccountingPeriod = @AcctPeriodUniqueID)
	)
--group by cstcde, min_trndte, max_entdte, Hours, sum_cstamt, category, vendor, PayeeCol
order by convert(datetime,min_trndte), cstcde

DROP TABLE #SubcontractCosts

--SET NOCOUNT OFF

GO