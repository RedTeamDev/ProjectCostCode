CREATE PROCEDURE [dbo].[Subcontract_Costs_pa]
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
--, MIN(vi.VendorInvoiceDate) as min_trndte 
, convert(datetime,vi.VendorInvoiceDate) as min_trndte 
--, MAX(vi.VendorInvoiceDate) as max_entdte 
, convert(datetime,vi.VendorInvoiceDate) as max_entdte 
, gl.AccountingPeriod
, 0 as hours
--, SUM(gll.Amount) as sum_cstamt 
, gll.Amount as sum_cstamt 
, 'Subcontract' as category
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
--and (@FromDate is null or convert(datetime,vi.VendorInvoiceDate) >= @FromDate)
--and (@ToDate is null or convert(datetime,vi.VendorInvoiceDate) <= @ToDate)
and (
		(
			@AcctPeriodUniqueID is null and (@FromDate is null or convert(datetime,vi.VendorInvoiceDate) >= @FromDate) and (@ToDate is null or convert(datetime,vi.VendorInvoiceDate) <= @ToDate)
		)
		or (not @AcctPeriodUniqueID is null and gl.AccountingPeriod = @AcctPeriodUniqueID)
	)
--Group by c.CostCode, e.EntityName, c.WorkorderID, c.WorkorderMod, ac.AcctControlRef

UNION ALL

Select c.CostCode as cstcde 
, gll.Payee + ', ' + gll.Description as vendor
, dbo.GetAssemblyDescriptions_fn(@WorkorderID, @WorkorderMod, RTRIM(c.CostCode), '00', 'yes') as PayeeCol 
--, MIN(gll.Date) as min_trndte
, gll.Date as min_trndte
--, MAX(gll.Date) as max_entdte
, gll.Date as max_entdte
, gl.AccountingPeriod
, 0 as Hours
--, SUM(gll.Amount) as sum_cstamt 
, gll.Amount as sum_cstamt 
, 'Subcontract' as category
FROM (select distinct GeneralLedgerID, GeneralLedgerLineID, CostCode, WorkorderID, WorkorderMod from JobCost where WorkorderID = @WorkorderID and WorkorderMod = @WorkorderMod) c 
Inner Join GeneralLedger gl On gl.GeneralLedgerID = c.GeneralLedgerID and gl.Source = 'Adjustment'
Inner Join GeneralLedgerLines gll On gl.GeneralLedgerID = gll.GeneralLedgerID and gll.UniqueID = c.GeneralLedgerLineID
Inner Join AccountingControl ac On isnull(ac.AcctControlRef, '') = isnull(gll.AcctControlRef, '') and isnull(ac.AcctControlRef,'') = 'DS'
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
--group by c.CostCode, gll.Payee, c.WorkorderID, c.WorkorderMod, ac.AcctControlRef

Order by c.CostCode

/*
select *
, case when isnull(vendor,'') = '' then PayeeCol else vendor end as PayeeName
from #SubcontractCosts
group by cstcde, min_trndte, max_entdte, Hours, sum_cstamt, category, vendor, PayeeCol
*/

select cstcde
, vendor
, PayeeCol
, min(min_trndte) as min_trndte
, max(max_entdte) as max_entdte
, AccountingPeriod
, Hours
, sum(sum_cstamt) as sum_cstamt
, category
, case when isnull(vendor,'') = '' then PayeeCol else vendor end as PayeeName
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
group by cstcde, Hours, category, vendor, PayeeCol, AccountingPeriod
order by convert(datetime,min(min_trndte)), cstcde

DROP TABLE #SubcontractCosts

--SET NOCOUNT OFF


/*******************************************************************

GO
IF EXISTS ( SELECT  *
            FROM    sys.objects
            WHERE   object_id = OBJECT_ID(N'Equipment_Costs_pa')
                    AND type IN ( N'P', N'PC' ) ) 
BEGIN
	DROP PROCEDURE [dbo].[Equipment_Costs_pa]
END
GO

CREATE PROCEDURE [dbo].[Equipment_Costs_pa]
  @WorkorderID varchar(7)
, @WorkorderMod char(2)
, @FromDate varchar(10) = NULL
, @ToDate varchar(10) = NULL
, @AcctPeriodUniqueID int = NULL --> to be used in the future

AS

SET NOCOUNT ON

SELECT pcc.CostCodeNumber --ea.CostCodeID
, u.FirstName + ' ' + u.LastName as CustondianName
, dbo.GetAssemblyDescriptions_fn(@WorkorderID, @WorkorderMod, RTRIM(pcc.CostCodeNumber), '00', 'yes') as PayeeCol 
, ea.AllocationStart
, isnull(ea.AllocationFinish,getdate()) as AllocationFinish
, isnull(ea.AllocationCost,0) as AllocationCost
, isnull(ea.AllocationUsage,0) as AllocationUsage
, cp.AllocationMethod
INTO #EquipmentCosts
FROM EquipmentAllocation ea
INNER JOIN ProjectCostCodes pcc ON ea.ProjectCostCodeID = pcc.ProjectCostCodeID
INNER JOIN Equipment e ON ea.EquipmentID = e.EquipmentID
INNER JOIN EquipmentCategory ec ON ec.categoryID = e.CategoryID
INNER JOIN CostPool cp ON ec.CostPoolID = cp.CostPoolID
INNER JOIN EquipmentUsage eu ON ea.SourceID = eu.EquipmentUsageID
INNER JOIN Users u ON eu.UserID = u.UserID
WHERE not pcc.CostCodeUniqueID is null
AND ea.WorkorderID = @WorkorderID
AND ea.WorkorderMod = @WorkorderMod
AND cp.AllocationMethod IN ('ActualUsage','WorkHours')
AND eu.Status = 'Committed'
AND ea.Source = 'ActualUsage'
and (@FromDate is null or convert(datetime,ea.AllocationStart) >= @FromDate)
and (@ToDate is null or convert(datetime,isnull(ea.AllocationFinish,getdate())) <= @ToDate)

UNION

SELECT pcc.CostCodeNumber --ea.CostCodeID
, u.FirstName + ' ' + u.LastName as CustondianName
, dbo.GetAssemblyDescriptions_fn(@WorkorderID, @WorkorderMod, RTRIM(pcc.CostCodeNumber), '00', 'yes') as PayeeCol 
, ea.AllocationStart
, isnull(ea.AllocationFinish,getdate()) as AllocationFinish
, CASE cp.AllocationMethod
	WHEN 'WorkDays' THEN dbo.NetWorkDays(ea.AllocationStart,ea.AllocationFinish) * cpr.Rate
	WHEN 'CalendarDays' THEN (DateDiff(day,ea.AllocationStart,isnull(ea.AllocationFinish,getdate()))) * cpr.Rate
	ELSE 0 --TDB
  END AS AllocationCost
, CASE cp.AllocationMethod
	WHEN 'WorkDays' THEN dbo.NetWorkDays(ea.AllocationStart,ea.AllocationFinish)
	WHEN 'CalendarDays' THEN DateDiff(day,ea.AllocationStart,isnull(ea.AllocationFinish,getdate()))
	ELSE 0 --TDB
  END AS AllocationUsage
, cp.AllocationMethod
FROM EquipmentAllocation ea
INNER JOIN ProjectCostCodes pcc ON ea.ProjectCostCodeID = pcc.ProjectCostCodeID
INNER JOIN Equipment e ON ea.EquipmentID = e.EquipmentID
INNER JOIN EquipmentCategory ec ON ec.CategoryID = e.CategoryID
INNER JOIN CostPool cp ON ec.CostPoolID = cp.CostPoolID
INNER JOIN CostPoolRates cpr ON cpr.CostPoolID = cp.CostPoolID AND cpr.[Year] = Year(isnull(ea.AllocationFinish,getdate()))
INNER JOIN EquipmentAssignment eas ON eas.AssignmentID = ea.SourceID
INNER JOIN Users u ON eas.EmployID = u.UserID
WHERE not pcc.CostCodeUniqueID is null
AND ea.WorkorderID = @WorkorderID
AND ea.WorkorderMod = @WorkorderMod
AND cp.AllocationMethod IN ('WorkDays','CalendarDays')
AND ea.Source = 'Assignment'
and (@FromDate is null or convert(datetime,ea.AllocationStart) >= @FromDate)
and (@ToDate is null or convert(datetime,isnull(ea.AllocationFinish,getdate())) <= @ToDate)


SELECT CostCodeNumber AS CostCodeID
, CustondianName
, PayeeCol
, MIN(AllocationStart) AS AllocationStart
, MAX(AllocationFinish) AS AllocationFinish
, 0 as AccountingPeriod
, 0 as hours
, SUM(AllocationCost) AS AllocationCost
, 'Equipment' as category
, CASE WHEN isnull(CustondianName,'') = '' THEN PayeeCol ELSE CustondianName END AS PayeeName
FROM #EquipmentCosts
WHERE 1 = 1
and (@FromDate is null or convert(datetime,AllocationStart) >= @FromDate)
and (@ToDate is null or convert(datetime,AllocationFinish) <= @ToDate)
GROUP BY CostCodeNumber, CustondianName, PayeeCol
ORDER BY convert(datetime,min(AllocationStart)), CostCodeID

DROP TABLE #EquipmentCosts

--SET NOCOUNT OFF


***************************************************************************************************************/
GO 