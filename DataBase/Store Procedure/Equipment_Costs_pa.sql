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
