ALTER PROCEDURE [dbo].[BudgetAndActualCosts_pa]
  @CustomerFacilityIDParam varchar(5) = null
, @WorkorderIDParam varchar(7) 
, @WorkorderModParam char(2) = null              
, @Delete_Amounts_cero varchar(3) = 'yes'
, @AssemblyNumber varchar (25) = null

AS

SET NOCOUNT ON
SET ANSI_WARNINGS OFF    

DECLARE @showOriginal varchar(3)
SELECT @showOriginal = 'no'

IF @WorkorderModParam IS NULL
SELECT @showOriginal = 'yes'

              
CREATE TABLE #takeoff (              
 WorkorderID   VARCHAR(7) COLLATE Modern_Spanish_CI_AS,              
 WorkorderMod  VARCHAR(2) COLLATE Modern_Spanish_CI_AS,              
 CategoryName  VARCHAR(50) COLLATE Modern_Spanish_CI_AS,              
 CategoryNumber  VARCHAR(5) COLLATE Modern_Spanish_CI_AS,              
 AssemblyNumber  VARCHAR(25) COLLATE Modern_Spanish_CI_AS,              
 ItemAmount   DECIMAL(19,8),              
 ActualCost   DECIMAL(19,8),              
 OpenCost   DECIMAL(19,8),              
 GoalCost   DECIMAL(19,8),              
 AtRiskCost   DECIMAL(19,8),              
 ItemName   VARCHAR(MAX) COLLATE Modern_Spanish_CI_AS,              
 AssemblyDescription VARCHAR(MAX) COLLATE Modern_Spanish_CI_AS,              
 ModStatus   VARCHAR(25) COLLATE Modern_Spanish_CI_AS       
 , ProjectCostCodeID int          
)              
              
CREATE TABLE #atrisk (              
 WorkorderID   VARCHAR(7) COLLATE Modern_Spanish_CI_AS,              
 WorkorderMod  VARCHAR(2) COLLATE Modern_Spanish_CI_AS,              
 CategoryName  VARCHAR(50) COLLATE Modern_Spanish_CI_AS,              
 CategoryNumber  VARCHAR(5) COLLATE Modern_Spanish_CI_AS,              
 AssemblyNumber  VARCHAR(25) COLLATE Modern_Spanish_CI_AS,              
 ItemAmount   DECIMAL(19,8),              
 ActualCost   DECIMAL(19,8),              
 OpenCost   DECIMAL(19,8),              
 GoalCost   DECIMAL(19,8),              
 AtRiskCost   DECIMAL(19,8),              
 ItemName   VARCHAR(MAX) COLLATE Modern_Spanish_CI_AS,              
 AssemblyDescription VARCHAR(MAX) COLLATE Modern_Spanish_CI_AS,              
 ModStatus   VARCHAR(25) COLLATE Modern_Spanish_CI_AS              
 , ProjectCostCodeID int          
)              
             
			 
CREATE TABLE #unificacion1 (              
 WorkorderID   VARCHAR(7) COLLATE Modern_Spanish_CI_AS,              
 WorkorderMod  VARCHAR(2) COLLATE Modern_Spanish_CI_AS,              
 CategoryName  VARCHAR(50) COLLATE Modern_Spanish_CI_AS,              
 CategoryNumber  VARCHAR(5) COLLATE Modern_Spanish_CI_AS,              
 AssemblyNumber  VARCHAR(25) COLLATE Modern_Spanish_CI_AS,              
 ItemAmount   DECIMAL(19,8),              
 ActualCost   DECIMAL(19,8),              
 OpenCost   DECIMAL(19,8),              
 GoalCost   DECIMAL(19,8),              
 AtRiskCost   DECIMAL(19,8),              
 ItemName   VARCHAR(MAX) COLLATE Modern_Spanish_CI_AS,              
 AssemblyDescription VARCHAR(MAX) COLLATE Modern_Spanish_CI_AS,              
 ModStatus   VARCHAR(25) COLLATE Modern_Spanish_CI_AS              
 , ProjectCostCodeID int          
)
			  
CREATE TABLE #buyout (              
 WorkorderID   VARCHAR(7) COLLATE Modern_Spanish_CI_AS,              
 WorkorderMod  VARCHAR(2) COLLATE Modern_Spanish_CI_AS,              
 CategoryName  VARCHAR(50) COLLATE Modern_Spanish_CI_AS,              
 CategoryNumber  VARCHAR(5) COLLATE Modern_Spanish_CI_AS,              
 AssemblyNumber  VARCHAR(25) COLLATE Modern_Spanish_CI_AS,              
 ItemAmount   DECIMAL(19,8),              
 ActualCost   DECIMAL(19,8),              
 OpenCost   DECIMAL(19,8),              
 GoalCost   DECIMAL(19,8),              
 AtRiskCost   DECIMAL(19,8),              
 ItemName   VARCHAR(MAX) COLLATE Modern_Spanish_CI_AS,  
 AssemblyDescription VARCHAR(MAX) COLLATE Modern_Spanish_CI_AS,              
 ModStatus   VARCHAR(25) COLLATE Modern_Spanish_CI_AS,    
 BuyoutID VARCHAR(50) COLLATE Modern_Spanish_CI_AS    
 , ProjectCostCodeID int          
)         

CREATE TABLE #jobcost (              
 WorkorderID   VARCHAR(7) COLLATE Modern_Spanish_CI_AS,              
 WorkorderMod  VARCHAR(2) COLLATE Modern_Spanish_CI_AS,              
 CategoryName  VARCHAR(50) COLLATE Modern_Spanish_CI_AS,              
 CategoryNumber  VARCHAR(5) COLLATE Modern_Spanish_CI_AS,              
 AssemblyNumber  VARCHAR(25) COLLATE Modern_Spanish_CI_AS,              
 ItemAmount   DECIMAL(19,8),              
 ActualCost   DECIMAL(19,8),              
 OpenCost   DECIMAL(19,8),              
 GoalCost   DECIMAL(19,8),              
 AtRiskCost   DECIMAL(19,8),              
 ItemName   VARCHAR(MAX) COLLATE Modern_Spanish_CI_AS,              
 AssemblyDescription VARCHAR(MAX) COLLATE Modern_Spanish_CI_AS,              
 ModStatus   VARCHAR(25) COLLATE Modern_Spanish_CI_AS,    
 BuyoutID VARCHAR(50) COLLATE Modern_Spanish_CI_AS    
 , ProjectCostCodeID int          
)              

CREATE TABLE #adjustments (              
 WorkorderID   VARCHAR(7) COLLATE Modern_Spanish_CI_AS,              
 WorkorderMod  VARCHAR(2) COLLATE Modern_Spanish_CI_AS,              
 CategoryName  VARCHAR(50) COLLATE Modern_Spanish_CI_AS,              
 CategoryNumber  VARCHAR(5) COLLATE Modern_Spanish_CI_AS,              
 AssemblyNumber  VARCHAR(25) COLLATE Modern_Spanish_CI_AS,              
 ItemAmount   DECIMAL(19,8),              
 ActualCost   DECIMAL(19,8),              
 OpenCost   DECIMAL(19,8),              
 GoalCost   DECIMAL(19,8),              
 AtRiskCost   DECIMAL(19,8),              
 ItemName   VARCHAR(MAX) COLLATE Modern_Spanish_CI_AS,              
 AssemblyDescription VARCHAR(MAX) COLLATE Modern_Spanish_CI_AS,              
 ModStatus   VARCHAR(25) COLLATE Modern_Spanish_CI_AS,    
 BuyoutID VARCHAR(50) COLLATE Modern_Spanish_CI_AS    
 , ProjectCostCodeID int          
)
              
CREATE TABLE #Final              
(              
  WorkorderID varchar(7)              
, WorkorderMod char(2)              
, CategoryName varchar(50)              
, CategoryNumber varchar(5)              
, AssemblyNumber varchar(25)              
, ItemName varchar(max)              
, AssemblyDescription varchar(max)              
, Estimate DECIMAL(19,8)              
, Estimate_band char(1)              
, Budget DECIMAL(19,8)              
, Budget_band char(1)              
, Adjust DECIMAL(19,8) NULL              
, Contingency DECIMAL(19,8)              
, ActualCost DECIMAL(19,8)    
, OpenCost DECIMAL(19,8)              
, GoalCost DECIMAL(19,8)              
, AtRiskCost DECIMAL(19,8)              
, AtRiskCost_band char(1)              
, CompleteCost DECIMAL(19,8)              
, OverUnder DECIMAL(19,8)              
, Notes varchar(max)
, ModStatus varchar(25)              
, Show varchar(5)  
, ProjectCostCodeID int            
)   
      
/******** REGISTROS DE BUDGET EXTRAIDOS DEL TAKE OFF *********/              
              
INSERT INTO #takeoff (WorkorderID,WorkorderMod,CategoryName,CategoryNumber,AssemblyNumber,ItemAmount,ActualCost,              
OpenCost,GoalCost,AtRiskCost,ItemName,AssemblyDescription,ModStatus, ProjectCostCodeID)              
          
Select  w.WorkorderID              
, w.WorkorderMod              
, case wi.CategoryNumber              
when '010' then 'Labor'              
when '020' then 'Equipment'              
when '030' then 'Material'              
when '040' then 'Subcontract'              
end as CategoryName              
, isnull(wi.CategoryNumber,'') as CategoryNumber              
, isnull(pcc.CostCodeNumber,wi.AssemblyNumber )
, case when isnull(ic.IsReimbursable,'no') = 'yes' 
	then isnull(wi.TotalItemPrice,0)
	else isnull(wi.TotalItemCost,0)
 end as [ItemAmount]
, Convert(DECIMAL(19,8),0) as ActualCost              
, Convert(DECIMAL(19,8),0) as OpenCost              
, Convert(DECIMAL(19,8),0) as GoalCost        
, Convert(DECIMAL(19,8),0) as [AtRiskCost]              
, (select [dbo].[GetAssemblyDescriptions_ProjectCostCode_fn](wa.WorkorderID,wa.WorkorderMod,wa.AssemblyNumber,wa.AssemblyMod, @showOriginal)) as ItemName
, (select [dbo].[GetAssemblyDescriptions_ProjectCostCode_fn](wa.WorkorderID,wa.WorkorderMod,wa.AssemblyNumber,wa.AssemblyMod, @showOriginal)) as AssemblyDescription
, Case WorkorderStatus              
 when 'InProgress' then 'Authorized'              
 when 'Closed' then 'Authorized'              
 when 'Acknowledge' then 'Authorized'              
 when 'Draft' then 'Potential'              
 when 'Request' then 'Potential'              
 when 'Proposal' then 'Potential'              
 when 'Cancelled' then 'Cancelled'              
End as ModStatus   
, wa.ProjectCostCodeID           
From dbo.Workorders w               
inner join dbo.WorkorderAssemblies wa on wa.workorderID = w.WorkorderID               
 and wa.WorkorderMod = w.WorkorderMod              
 and wa.CustomerFacilityID = w.CustomerFacilityID 
LEFT JOIN dbo.ProjectCostCodes pcc	ON wa.ProjectCostCodeID = pcc.ProjectCostCodeID AND  pcc.Status = 'on' 
inner join dbo.WorkorderItems wi on wa.waID = wi.waID              
 and wa.WorkorderMod = wi.WorkorderMod              
 and wi.Status <> '2' 
 left join ItemCosts ic on ic.ItemCostID = wi.ItemCostID 
left join (
	select distinct b.WorkorderID, b.WorkorderMod, bl.Cstcde as AssemblyNumber
	from Buyout b
	inner join BuyoutLines bl on bl.Recnum = b.BuyoutID
	where b.WorkorderID = @WorkorderIDParam and (@WorkorderModParam is null or b.WorkorderMod = @WorkorderModParam)
) x on x.WorkorderID = wi.WorkorderID and x.WorkorderMod = wi.WorkorderMod and x.AssemblyNumber = wi.AssemblyNumber
Where w.WorkorderID = @WorkorderIDParam              
and (@WorkorderModParam is null or w.WorkorderMod = @WorkorderModParam)   
and (@AssemblyNumber is null or wa.AssemblyNumber = @AssemblyNumber)
              

/******** REGISTROS DE BUDGET EXTRAIDOS DEL AT RISK  *********/              
INSERT INTO #atrisk (WorkorderID,WorkorderMod,CategoryName,CategoryNumber,AssemblyNumber,ItemAmount,ActualCost,OpenCost,GoalCost,AtRiskCost,ItemName,AssemblyDescription,ModStatus, ProjectCostCodeID)              
              
 Select  w.WorkorderID              
 , w.WorkorderMod              
 , 'Material' as CategoryName              
 , '030' as CategoryNumber              
 , ISNULL(pcc.CostCodeNumber, ba.AssemblyNumber)           
 , convert(DECIMAL(19,8),0) as [ItemAmount]              
 , Convert(DECIMAL(19,8),0) as ActualCost              
 , Convert(DECIMAL(19,8),0) as OpenCost              
 , Convert(DECIMAL(19,8),isnull(ba.MA_GoalAmount,0)) as GoalCost              
 , case              
  when isnull(ba.IsHidden,'no') = 'yes' and ba.BuyoutID is null then 0              
  when isnull(ba.IsHidden,'no') = 'yes' and bo.Status = 'Committed' then 0              
  when isnull(ba.IsHidden,'no') = 'no' then isnull(MATotal,0)              
  else 0              
  end as [AtRiskCost]              
, (select [dbo].[GetAssemblyDescriptions_ProjectCostCode_fn](ba.WorkorderID,ba.WorkorderMod,ba.AssemblyNumber,ba.AssemblyMod, @showOriginal)) as ItemName
, (select [dbo].[GetAssemblyDescriptions_ProjectCostCode_fn](ba.WorkorderID,ba.WorkorderMod,ba.AssemblyNumber,ba.AssemblyMod, @showOriginal)) as AssemblyDescription
 , WorkorderStatus as ModStatus              
 , ba.ProjectCostCodeID
 From dbo.Workorders w               
 inner join dbo.BuyoutAssemblies ba on w.workorderID = ba.workorderID and w.WorkorderMod = ba.WorkorderMod 
 LEFT JOIN dbo.ProjectCostCodes pcc	ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status	= 'on'
 left join dbo.Buyout bo on ba.BuyoutID = bo.BuyoutID              
 Where w.WorkorderID = @WorkorderIDParam               
 and (@WorkorderModParam is null or w.WorkorderMod = @WorkorderModParam)
 and (@AssemblyNumber is null or ba.AssemblyNumber = @AssemblyNumber)
 and ba.Status = 'Show'

 UNION ALL
       
 Select  w.WorkorderID              
 , w.WorkorderMod              
 , 'Labor' as CategoryName              
 , '010' as CategoryNumber              
 , ISNULL(pcc.CostCodeNumber, ba.AssemblyNumber)              
 , convert(DECIMAL(19,8),0) as [ItemAmount]              
 , Convert(DECIMAL(19,8),0) as ActualCost              
 , Convert(DECIMAL(19,8),0) as OpenCost              
 , Convert(DECIMAL(19,8),isnull(ba.LA_GoalAmount,0)) as GoalCost              
 , case              
  when isnull(ba.IsHidden,'no') = 'yes' and ba.BuyoutID is null then 0              
  when isnull(ba.IsHidden,'no') = 'yes' and bo.Status = 'Committed' then 0              
  when isnull(ba.IsHidden,'no') = 'no' then isnull(LATotal,0)              
  else 0              
  end as [AtRiskCost]              
, (select [dbo].[GetAssemblyDescriptions_ProjectCostCode_fn](ba.WorkorderID,ba.WorkorderMod,ba.AssemblyNumber,ba.AssemblyMod, @showOriginal)) as ItemName
, (select [dbo].[GetAssemblyDescriptions_ProjectCostCode_fn](ba.WorkorderID,ba.WorkorderMod,ba.AssemblyNumber,ba.AssemblyMod, @showOriginal)) as AssemblyDescription
 , WorkorderStatus as ModStatus
 ,ba.ProjectCostCodeID              
 From dbo.Workorders w               
 inner join dbo.BuyoutAssemblies ba on w.workorderID = ba.workorderID and w.WorkorderMod = ba.WorkorderMod    
 LEFT JOIN dbo.ProjectCostCodes pcc	ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status	= 'on'   
 left join dbo.Buyout bo on ba.BuyoutID = bo.BuyoutID              
 Where w.WorkorderID = @WorkorderIDParam               
 and (@WorkorderModParam is null or w.WorkorderMod = @WorkorderModParam)
 and (@AssemblyNumber is null or ba.AssemblyNumber = @AssemblyNumber)
 and ba.Status = 'Show'          

 UNION ALL
              
 Select  w.WorkorderID              
 , w.WorkorderMod              
 , 'Subcontract' as CategoryName              
 , '040' as CategoryNumber              
 , ISNULL(pcc.CostCodeNumber, ba.AssemblyNumber)               
 , convert(DECIMAL(19,8),0) as [ItemAmount]              
 , Convert(DECIMAL(19,8),0) as ActualCost              
 , Convert(DECIMAL(19,8),0) as OpenCost              
 , Convert(DECIMAL(19,8),isnull(ba.SU_GoalAmount,0)) as GoalCost              
 , case              
  when isnull(ba.IsHidden,'no') = 'yes' and ba.BuyoutID is null then 0
  when isnull(ba.IsHidden,'no') = 'yes' and bo.Status = 'Committed' then 0
  when isnull(ba.IsHidden,'no') = 'no' then isnull(SUTotal,0)              
  else 0
  end as [AtRiskCost]              
, (select [dbo].[GetAssemblyDescriptions_ProjectCostCode_fn](ba.WorkorderID,ba.WorkorderMod,ba.AssemblyNumber,ba.AssemblyMod, @showOriginal)) as ItemName
, (select [dbo].[GetAssemblyDescriptions_ProjectCostCode_fn](ba.WorkorderID,ba.WorkorderMod,ba.AssemblyNumber,ba.AssemblyMod, @showOriginal)) as AssemblyDescription
 , WorkorderStatus as ModStatus  
 ,ba.ProjectCostCodeID            
 From dbo.Workorders w               
 inner join dbo.BuyoutAssemblies ba on w.workorderID = ba.workorderID and w.WorkorderMod = ba.WorkorderMod              
 LEFT JOIN dbo.ProjectCostCodes pcc	ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status	= 'on'   
 left join dbo.Buyout bo on ba.BuyoutID = bo.BuyoutID              
 Where w.WorkorderID = @WorkorderIDParam               
 and (@WorkorderModParam is null or w.WorkorderMod = @WorkorderModParam)
 and (@AssemblyNumber is null or ba.AssemblyNumber = @AssemblyNumber)
 and ba.Status = 'Show'
              
 UNION ALL
         
 Select  w.WorkorderID              
 , w.WorkorderMod              
 , 'Equipment' as CategoryName              
 , '020' as CategoryNumber              
 , ISNULL(pcc.CostCodeNumber, ba.AssemblyNumber)                          
 , convert(DECIMAL(19,8),0) as [ItemAmount]     
 , Convert(DECIMAL(19,8),0) as ActualCost              
 , Convert(DECIMAL(19,8),0) as OpenCost              
 , Convert(DECIMAL(19,8),isnull(ba.EQ_GoalAmount,0)) as GoalCost              
 , case              
  when isnull(ba.IsHidden,'no') = 'yes' and ba.BuyoutID is null then 0              
  when isnull(ba.IsHidden,'no') = 'yes' and bo.Status = 'Committed' then 0              
  when isnull(ba.IsHidden,'no') = 'no' then isnull(EQTotal,0)              
  else 0
  end as [AtRiskCost]
, (select [dbo].[GetAssemblyDescriptions_ProjectCostCode_fn](ba.WorkorderID,ba.WorkorderMod,ba.AssemblyNumber,ba.AssemblyMod, @showOriginal)) as ItemName
, (select [dbo].[GetAssemblyDescriptions_ProjectCostCode_fn](ba.WorkorderID,ba.WorkorderMod,ba.AssemblyNumber,ba.AssemblyMod, @showOriginal)) as AssemblyDescription
 , WorkorderStatus as ModStatus   
 ,ba.ProjectCostCodeID           
 From dbo.Workorders w               
 inner join dbo.BuyoutAssemblies ba on w.workorderID = ba.workorderID and w.WorkorderMod = ba.WorkorderMod    
 LEFT JOIN dbo.ProjectCostCodes pcc	ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status	= 'on'   
 left join dbo.Buyout bo on ba.BuyoutID = bo.BuyoutID              
 Where w.WorkorderID = @WorkorderIDParam               
 and (@WorkorderModParam is null or w.WorkorderMod = @WorkorderModParam)
 and (@AssemblyNumber is null or ba.AssemblyNumber = @AssemblyNumber)
 and ba.Status = 'Show'

      
       
               
UPDATE #atrisk
SET ModStatus = Case ModStatus              
  when 'InProgress' then 'Authorized'              
  when 'Closed' then 'Authorized'              
  when 'Acknowledge' then 'Authorized'              
  when 'Draft' then 'Potential'              
  when 'Request' then 'Potential'              
  when 'Proposal' then 'Potential'              
  when 'Cancelled' then 'Cancelled'              
 End              
               
              
              
/****** UNIFICAR #takeoff Y #atrisk *********************************************************/              
INSERT INTO #unificacion1 (WorkorderID,WorkorderMod,CategoryName,CategoryNumber,AssemblyNumber,ItemAmount,ActualCost,OpenCost,GoalCost,AtRiskCost,ItemName,AssemblyDescription,ModStatus, ProjectCostCodeID)              
 SELECT x.WorkorderID, x.WorkorderMod, x.CategoryName, x.CategoryNumber, x.AssemblyNumber              
 , sum(x.ItemAmount) as ItemAmount              
 , sum(x.ActualCost) as ActualCost              
 , sum(x.OpenCost) as OpenCost              
 , sum(x.GoalCost) as GoalCost              
 , sum(x.AtRiskCost) as AtRiskCost              
 , x.ItemName, x.AssemblyDescription, x.ModStatus, x.ProjectCostCodeID 
 FROM (              
		SELECT WorkorderID, WorkorderMod, CategoryName, CategoryNumber, AssemblyNumber, ItemAmount, ActualCost, OpenCost, GoalCost, AtRiskCost, ItemName, AssemblyDescription, ModStatus, ProjectCostCodeID FROM #takeoff
		UNION ALL
		SELECT WorkorderID, WorkorderMod, CategoryName, CategoryNumber, AssemblyNumber, ItemAmount, ActualCost, OpenCost, GoalCost, AtRiskCost, ItemName, AssemblyDescription, ModStatus, ProjectCostCodeID FROM #atrisk
 ) x              
 GROUP BY WorkorderID, WorkorderMod, CategoryName, CategoryNumber, AssemblyNumber, ItemName, AssemblyDescription, ModStatus, ProjectCostCodeID              
              
              
              
/*********** INSERTAR EN #buyout TODOS LOS CCs QUE ESTAN EN BUYOUT Y NO EN EL TAKE OFF ********/              
/*********** CON STATUS = COMMITTED, EXECUTED AND CLOSED *********************************/              
INSERT INTO #buyout (WorkorderID,WorkorderMod,CategoryName,CategoryNumber,AssemblyNumber,ItemAmount,ActualCost,OpenCost,GoalCost,AtRiskCost,ItemName,AssemblyDescription,ModStatus, BuyoutID, ProjectCostCodeID)              
 Select  bo.WorkorderID              
 , bo.WorkorderMod              
 , case bt.CategoryNumber              
  when '010' then 'Labor'              
  when '020' then 'Equipment'              
  when '030' then 'Material'              
  when '040' then 'Subcontract'              
   end as CategoryName    
 , bt.CategoryNumber    
 , isnull(pcc.CostCodeNumber, bl.Cstcde) as AssemblyNumber    
 , Convert(DECIMAL(19,8),0) as ItemAmount              
 , Convert(DECIMAL(19,8),0) as ActualCost              
 , Convert(DECIMAL(19,8),0) as OpenCost    
 , Convert(DECIMAL(19,8),0) as GoalCost              
 , Convert(DECIMAL(19,8),0) as AtRiskCost              
 , (select [dbo].[GetAssemblyDescriptions_ProjectCostCode_fn](bo.WorkorderID,bo.WorkorderMod,bl.Cstcde,null, @showOriginal)) as ItemName
 , (select [dbo].[GetAssemblyDescriptions_ProjectCostCode_fn](bo.WorkorderID,bo.WorkorderMod,bl.Cstcde,null, @showOriginal)) as AssemblyDescription
 , (Select Case               
	  when WorkorderStatus IN ('InProgress','Closed','Acknowledge') then 'Authorized'              
	  when WorkorderStatus IN ('Draft','Request','Proposal') then 'Potential'              
	  when WorkorderStatus = 'Cancelled' then 'Cancelled'              
	  End              
  From Workorders Where WorkorderID = bo.WorkorderID and WorkorderMod = bo.WorkorderMod              
 ) as [ModStatus]     
 , bo.BuyoutID     
 , bo.ProjectCostCodeID        
 From Buyout bo
 Inner Join BuyoutLines bl on bl.Recnum = bo.BuyoutID              
 INNER JOIN dbo.ProjectCostCodes pcc	ON	bl.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status	= 'on'            
 Inner Join BuyoutType bt on bt.BOTypeID = bo.BOTypeID
 Left join #unificacion1 a on a.WorkorderID = bo.WorkorderID              
  and a.WorkorderMod = bo.WorkorderMod               
  and a.AssemblyNumber = bl.Cstcde             
  and a.CategoryNumber = bt.CategoryNumber    
 Where bo.WorkorderID = @WorkorderIDParam              
  and (@WorkorderModParam is null or bo.WorkorderMod = @WorkorderModParam)
  and (@AssemblyNumber is null or bl.CstCde = @AssemblyNumber)
  and bo.Status in ('Committed','Executed','Closed')              
  and a.AssemblyNumber is null              
 Group by bo.BOTypeID, pcc.CostCodeNumber,bl.Cstcde, bo.WorkorderMod, bo.WorkorderID, bt.CategoryNumber, bo.BuyoutID  ,  bo.ProjectCostCodeID    
              

/******************EXTRAER LOS DECORDS DE JOBCOST ENTRY (ADJUSTMENTS)**************/
Insert Into #jobcost 
Select jc.WorkorderID              
 , jc.WorkorderMod      
 , Case gll.AcctControlRef 
	when 'DL' then 'Labor'
	when 'DE' then 'Equipment'
	when 'DM' then 'Material'
	when 'DS' then 'Subcontract'
   end as CategoryName         
 , Case gll.AcctControlRef 
	when 'DL' then '010'
	when 'DE' then '020'
	when 'DM' then '030'
	when 'DS' then '040'
   end as CategoryNumber              
 , isnull(pcc.CostCodeNumber, jc.CostCode) as AssemblyNumber 
 , Convert(DECIMAL(19,8),0) as ItemAmount              
 , Convert(DECIMAL(19,8),sum(gll.Amount)) as ActualCost
  , Convert(DECIMAL(19,8),0) as OpenCost  
 , Convert(DECIMAL(19,8),0) as GoalCost
 , Convert(DECIMAL(19,8),0) as AtRiskCost              
  , (select [dbo].[GetAssemblyDescriptions_ProjectCostCode_fn](jc.WorkorderID,jc.WorkorderMod,jc.CostCode,null, @showOriginal)) as ItemName
, (select [dbo].[GetAssemblyDescriptions_ProjectCostCode_fn](jc.WorkorderID,jc.WorkorderMod,jc.CostCode,null, @showOriginal)) as AssemblyDescription
 , (Select Case               
  when WorkorderStatus IN ('InProgress','Closed','Acknowledge') then 'Authorized'              
  when WorkorderStatus IN ('Draft','Request','Proposal') then 'Potential'              
  when WorkorderStatus = 'Cancelled' then 'Cancelled'              
  End              
  From Workorders Where WorkorderID = jc.WorkorderID and WorkorderMod = jc.WorkorderMod              
 ) as [ModStatus]  
 , NULL as BuyoutID
 ,  jc.ProjectCostCodeID    
From Jobcost jc
inner join GeneralLedger gl on gl.GeneralLedgerID = jc.GeneralLedgerID
inner join GeneralLedgerLines gll on gll.GeneralLedgerID = gl.GeneralLedgerID
inner join dbo.ProjectCostCodes pcc	 on pcc.ProjectCostCodeID = jc.ProjectCostCodeID AND pcc.Status	= 'on'
where jc.workorderid = @WorkorderIDParam 
and (@WorkorderModParam is null or jc.WorkorderMod = @WorkorderModParam)
and (@AssemblyNumber is null or jc.CostCode = @AssemblyNumber)
and gl.Source = 'Adjustment'
Group by jc.WorkorderID, jc.WorkorderMod, gll.AcctControlRef, pcc.CostCodeNumber,jc.CostCode, jc.ProjectCostCodeID


/****** JUNTAR EN #unificacion2 LOS CCs DEL TAKE OFF + ARTISK + BUYOUT + JOBCOST ******/              
              
SELECT x.WorkorderID, x.WorkorderMod, x.CategoryName, x.CategoryNumber, x.AssemblyNumber              
, sum(x.ItemAmount) as ItemAmount              
, sum(x.ActualCost) as ActualCost              
, sum(x.OpenCost) as OpenCost              
, sum(x.AtRiskCost) as AtRiskCost              
, sum(x.GoalCost) as GoalCost              
, x.ItemName, x.AssemblyDescription, x.ModStatus, Max(x.BuyoutID) as BuyoutID  , MAX(x.ProjectCostCodeID) as ProjectCostCodeID
INTO #unificacion2              
FROM (
  SELECT WorkorderID, WorkorderMod, CategoryName, CategoryNumber, AssemblyNumber, ItemAmount,               
      ActualCost, OpenCost, AtRiskCost, GoalCost, ItemName, AssemblyDescription, ModStatus, NULL as BuyoutID, ProjectCostCodeID FROM #unificacion1              
  UNION ALL              
  SELECT WorkorderID, WorkorderMod, CategoryName, CategoryNumber, AssemblyNumber, ItemAmount,               
      ActualCost, OpenCost, AtRiskCost, GoalCost, ItemName, AssemblyDescription, ModStatus, BuyoutID, ProjectCostCodeID FROM #buyout
  UNION ALL              
  SELECT WorkorderID, WorkorderMod, CategoryName, CategoryNumber, AssemblyNumber, ItemAmount,               
      ActualCost, OpenCost, AtRiskCost, GoalCost, ItemName, AssemblyDescription, ModStatus, null as BuyoutID, ProjectCostCodeID FROM #jobcost
 ) x              
GROUP BY WorkorderID, WorkorderMod, CategoryName, CategoryNumber, AssemblyNumber, ItemName, AssemblyDescription, ModStatus  --, ProjectCostCodeID            


/***** AGREGAR LOS CCs DESDE LOS ADJUSTMENTS SI ES QUE NO EXISTEN EN #unificacion2 ********/
Insert Into #Adjustments
SELECT a.WorkorderID
, a.WorkorderMod
, a.AdjustCategory as CategoryName
, (select CategoryNumber from CostType ct where ct.CategoryName = a.AdjustCategory) as CategoryNumber
, ISNULL(pcc.CostCodeNumber, a.AdjustCostCode) as AssemblyNumber
, 0 as ItemAmount
, 0 as ActualCost, 0 as OpenCost, 0 as AtRiskCost, 0 as GoalCost
, (select [dbo].[GetAssemblyDescriptions_ProjectCostCode_fn](a.WorkorderID,a.WorkorderMod,a.AdjustCostCode,null, @showOriginal)) as ItemName
, (select [dbo].[GetAssemblyDescriptions_ProjectCostCode_fn](a.WorkorderID,a.WorkorderMod,a.AdjustCostCode,null, @showOriginal)) as AssemblyDescription
, Case w.WorkorderStatus              
 when 'InProgress' then 'Authorized'              
 when 'Closed' then 'Authorized'              
 when 'Acknowledge' then 'Authorized'              
 when 'Draft' then 'Potential'              
 when 'Request' then 'Potential'              
 when 'Proposal' then 'Potential'              
 when 'Cancelled' then 'Cancelled'              
End as ModStatus   
, NULL as BuyoutID
, a.ProjectCostCodeID
FROM Adjustments a
INNER JOIN dbo.ProjectCostCodes pcc	ON pcc.ProjectCostCodeID = a.ProjectCostCodeID AND pcc.status = 'on'
INNER JOIN Workorders w ON w.WorkorderID = a.WorkorderID AND w.WorkorderMod = a.WorkorderMod
LEFT JOIN #unificacion2 u2 on u2.WorkorderID = a.WorkorderID and u2.WorkorderMod = a.WorkorderMod and u2.CategoryName = a.AdjustCategory and u2.AssemblyNumber = a.AdjustCostCode
WHERE a.WorkorderID = @WorkorderIDParam
and (@WorkorderModParam is null or a.WorkorderMod = @WorkorderModParam)
and (@AssemblyNumber is null or a.AdjustCostCode = @AssemblyNumber)
AND u2.AssemblyNumber IS NULL

INSERT INTO #unificacion2
SELECT * FROM #Adjustments


/***** OBTENER EN #NoClosedBo LOS BUYOUT WHIT STATUS IN ('COMMITED','EXECUTED')******/

SELECT ID, Source, BuyoutID, WorkorderID, WorkorderMod, OrderCostCode, CategoryNumber, isnull(glAmount,0) as glAmount
INTO #NoClosedBo
FROM YesClosedBuyout_View_TEST
WHERE BoStatus IN ('Committed','Executed') 
AND SourceStatus IN ('Committed','Executed','Closed')
AND WorkorderID = @WorkorderIDParam              
AND (@WorkorderModParam is null or WorkorderMod = @WorkorderModParam)
AND Source IN ('ExpenseReimbursement','Timesheets')


/***** OBTENER EN #YesClosedBo LOS BUYOUT WHIT STATUS IN ('COMMITED','EXECUTED','CLOSED')******/

SELECT ID, Source, BuyoutID, WorkorderID, WorkorderMod, OrderCostCode, CategoryNumber, isnull(glAmount,0) as glAmount
INTO #YesClosedBo
FROM YesClosedBuyout_View_TEST
WHERE BoStatus IN ('Committed','Executed','Closed')
AND SourceStatus IN ('Committed','Executed','Closed')
AND WorkorderID = @WorkorderIDParam              
AND (@WorkorderModParam is null or WorkorderMod = @WorkorderModParam)

              
/******* CALCULAR EL OPEN INSERTANDO EL RESULTADO EN #Open ************/              

Select c.WorkorderID              
 , c.WorkorderMod              
 , c.CategoryName              
 , c.CategoryNumber              
 , c.AssemblyNumber              
 , Convert(DECIMAL(19,8),isnull(max(c.ItemAmount),0)) as ItemAmount              
 , max(c.ActualCost) as ActualCost
 , Convert(DECIMAL(19,8),0) as PartialActual              
 , isnull((
	 select sum(isnull(o.OpenBudget,0)) as OpenCost
	 from 
		(
			select case 
				when CategoryNumber = '030' and BOTypeTitle = 'Expense Authorization' then isnull(OpenBudget_Exp,0)
				when CategoryNumber = '010' and BOTypeTitle = 'Labor Authorization' then isnull(OpenBudget_Lab,0)
				else isnull(OpenBudget,Extttl) 
			end as OpenBudget
			, Extttl
			, BOTypeTitle
			, CategoryNumber
			, BoLinesID
			from dbo.Budget_OpenCol_View v
			  where v.WorkorderID = c.WorkorderID
			  and v.WorkorderMod = c.WorkorderMod
			  and v.Cstcde = c.AssemblyNumber
			  and v.CategoryNumber = c.CategoryNumber 
		) o
	),0) as OpenCost

 , Convert(DECIMAL(19,8),max(c.GoalCost)) as GoalCost
 , Convert(DECIMAL(19,8),max(c.AtRiskCost)) as AtRiskCost              
 , Max(c.ItemName) as ItemName              
 , Max(c.AssemblyDescription) as AssemblyDescription              
 , Max(a.AdjustAmount) as Adjust
 , Max(isnull(a.AdjustContingency,0)) as Contingency
 , case Max(isnull(a.AdjustNotes,''))              
  when null then '-'              
  when '' then '-'              
  else Max(a.AdjustNotes)              
 end as [Notes]              
 , c.ModStatus      
 , null as [Source]
 , 0 as readed              
, 1 as show  
, c.ProjectCostCodeID                        
Into #Open    
From #unificacion2 c 
Left Join Adjustments a On c.WorkorderID = a.WorkorderID              
 and c.WorkorderMod = a.WorkorderMod              
 and c.CategoryName = a.AdjustCategory              
 and c.AssemblyNumber = a.AdjustCostCode              
 and isnull(a.AdjustDateCommitted,'') = '' 
Group by c.CategoryName, c.CategoryNumber, c.AssemblyNumber, c.WorkorderID, c.WorkorderMod, c.ModStatus, c.AssemblyDescription ,c.ProjectCostCodeID
Order by c.WorkorderID, c.WorkorderMod, c.AssemblyNumber, c.CategoryNumber              


DECLARE @woID varchar(7), @woMod char(2), @ccCat char(3), @assNum varchar(15), @Source varchar(50)              
DECLARE @Actual1 DECIMAL(19,8), @Actual2 DECIMAL(19,8), @Show int              

DECLARE @intRowCount int, @intMaxCount int              
SELECT @intRowCount = 1              
SELECT @intMaxCount = COUNT(1) FROM  #Open              

WHILE @intRowCount <= @intMaxCount              
BEGIN              

	SELECT TOP 1 @woID = WorkorderID              
	, @woMod = WorkorderMod              
	, @ccCat = CategoryNumber              
	, @assNum = AssemblyNumber              
	, @Source = Source              
	FROM #Open  
	WHERE readed = 0        


	SELECT @Actual1 = 0, @Actual2 = 0, @Show = 1              

	/***** EL ACTUAL SE CONSIDERA LOS COMMITMENTS EN COMMITTED, EXECUTED Y CLOSED *****/     
	SELECT @Actual1 = SUM(glAmount)    
	FROM #YesClosedBo    
	WHERE WorkorderID = @WoID    
	AND WorkorderMod = @WoMod    
	AND OrderCostCode = @assNum    
	AND CategoryNumber = @ccCat
	 
   
    
	/***** EL PARTIAL ACTUAL SE CONSIDERA LOS COMMITMENTS EN COMMITTED Y EXECUTED *****/           
	SELECT @Actual2 = SUM(glAmount)    
	FROM #NoClosedBo    
	WHERE WorkorderID = @WoID    
	AND WorkorderMod = @WoMod    
	AND OrderCostCode = @assNum    
	AND CategoryNumber = @ccCat    
     
	SELECT @intRowCount = @intRowCount + 1          
    
	              
	UPDATE d              
	SET d.ActualCost = isnull(d.ActualCost,0) + isnull(@Actual1,0)              
	, d.PartialActual = isnull(@Actual2,0)              
	, d.readed = 1, d.show = @Show              
	FROM (SELECT TOP 1 ActualCost, PartialActual, readed, show FROM #Open WHERE readed = 0) as d              
               
END              


/******************************************************************************************/
              
IF @WorkorderModParam IS NULL              
BEGIN              
              
 INSERT INTO #Final              
 SELECT WorkorderID              
 , WorkorderMod              
 , CategoryName              
 , CategoryNumber              
 , AssemblyNumber              
 , ItemName              
 , AssemblyDescription              
 , case WorkorderMod              
  when '00' then ItemAmount              
  else               
   case ModStatus              
    when 'Authorized' then ItemAmount              
    else 0              
   end              
   end as [Estimate]              
 , case WorkorderMod              
  when '00' then ''              
  else               
   case ModStatus              
    when 'Authorized' then ''              
    else '-'              
   end              
   end as [Estimate_band]              
 , case WorkorderMod              
  when '00' then ItemAmount              
  else               
   case ModStatus              
    when 'Authorized' then ItemAmount              
    else 0              
   end              
   end as [Budget]              
 , case WorkorderMod              
  when '00' then ''              
  else               
   case ModStatus              
    when 'Authorized' then ''              
    else '-'              
   end              
   end as [Budget_band]              
 , case ModStatus              
  when 'Authorized' then Adjust              
  when 'Potential' then Adjust              
  else 0              
   end as [Adjust]              
 , case ModStatus              
  when 'Authorized' then Contingency              
  when 'Potential' then Contingency              
  else 0              
   end as [Contingency]              
 , ActualCost        

, CASE              
	WHEN convert(DECIMAL(19,8),OpenCost) = 0 AND convert(DECIMAL(19,8),PartialActual) > 0 THEN 0              
	ELSE convert(DECIMAL(19,8),OpenCost) - convert(DECIMAL(19,8),PartialActual)
   END  as [OpenCost]


 , convert(DECIMAL(19,8),GoalCost) as [GoalCost]
 , case WorkorderMod              
	when '00' then               
		case ModStatus              
			when 'Cancelled' then 0              
			else AtRiskCost              
		end              
	else               
		case ModStatus              
			when 'Authorized' then AtRiskCost              
			else 0              
		end              
   end as [AtRiskCost]              
 , case WorkorderMod              
	when '00' then              
		case ModStatus              
			when 'Cancelled' then '-'              
			else ''              
		end              
	else               
		case ModStatus              
			when 'Authorized' then ''     
			else '-'              
		end             
   end as [AtRiskCost_band]              
 , convert(DECIMAL(19,8),0) as [CompleteCost]              
 , convert(DECIMAL(19,8),0) as [OverUnder]              
 , Notes              
 , ModStatus              
 , Show      
, ProjectCostCodeID            
 FROM #Open              
 WHERE not CategoryName is null              
               
              
END              
        
ELSE              
              
BEGIN              
              
 INSERT INTO #Final              
 SELECT WorkorderID              
 , WorkorderMod              
 , CategoryName              
 , CategoryNumber              
 , AssemblyNumber              
 , ItemName              
 , AssemblyDescription              
 , case WorkorderMod              
  when '00' then ItemAmount              
  else               
   case ModStatus              
    when 'Authorized' then ItemAmount              
    else 0              
   end              
   end as [Estimate]              
 , case WorkorderMod              
  when '00' then ''              
  else               
   case ModStatus              
    when 'Authorized' then ''              
    else '-'              
   end              
   end as [Estimate_band]              
 , case WorkorderMod              
  when '00' then ItemAmount              
  else               
   case ModStatus              
    when 'Authorized' then ItemAmount              
    else 0              
   end              
   end as [Budget]              
 , case WorkorderMod              
  when '00' then ''        
  else               
   case ModStatus              
    when 'Authorized' then ''              
    else '-'              
   end              
   end as [Budget_band]              
 , case ModStatus              
  when 'Authorized' then Adjust              
  when 'Potential' then Adjust              
  else 0              
   end as [Adjust]              
 , case ModStatus              
  when 'Authorized' then Contingency              
  when 'Potential' then Contingency              
  else 0              
   end as [Contingency]              
 , ActualCost              
, CASE              
	WHEN convert(DECIMAL(19,8),OpenCost) = 0 AND convert(DECIMAL(19,8),PartialActual) > 0 THEN 0              
	ELSE convert(DECIMAL(19,8),OpenCost) - convert(DECIMAL(19,8),PartialActual)
   END  as [OpenCost]

 , convert(DECIMAL(19,8),GoalCost) as [GoalCost]
 , case WorkorderMod              
	when '00' then AtRiskCost              
	else               
		case ModStatus
			when 'Authorized' then AtRiskCost
			when 'Potential' then AtRiskCost
			when 'Cancelled' then 0              
			else 0              
		end              
   end as [AtRiskCost]              
 , case WorkorderMod              
	when '00' then ''              
	else               
		case ModStatus
			when 'Authorized' then ''
			when 'Potential' then ''
			when 'Cancelled' then '-'              
			else '-'              
		end              
   end as [AtRiskCost_band]              
 , convert(DECIMAL(19,8),0) as [CompleteCost]              
 , convert(DECIMAL(19,8),0) as [OverUnder]              
 , Notes              
 , ModStatus              
 , Show       
 , ProjectCostCodeID             
 FROM #Open
 WHERE not CategoryName is null              

END              


IF @Delete_Amounts_cero = 'yes'              
BEGIN              
 DELETE #Final               
 WHERE isnull(Estimate,0) = 0 AND isnull(Budget,0) = 0 AND isnull(Adjust,0) = 0            
 AND isnull(ActualCost,0) = 0 AND isnull(OpenCost,0) = 0
 AND isnull(AtRiskCost,0) = 0 AND isnull(Contingency,0) = 0              
END
     

SELECT WorkorderID              
, WorkorderMod              
, CategoryName              
, CategoryNumber              
, AssemblyNumber              
, ItemName              
, AssemblyDescription              
, case when Estimate_band = '' then Estimate else 0 end as Estimate
, '' as Estimate_band
, case when Budget_band = '' then Budget else 0 end as Budget
, '' as Budget_band
, isnull(Adjust,Estimate) as Adjust
, Contingency              
, ActualCost     
, OpenCost
, GoalCost
, case when AtRiskCost_band = '' then AtRiskCost else 0 end as AtRiskCost
, '' as AtRiskCost_band
, case 
	when ModStatus = 'Authorized' then ActualCost + OpenCost + Contingency + AtRiskCost 
	else ActualCost + OpenCost + Contingency + AtRiskCost
  end as CompleteCost --> ETC = Contingency + AtRiskCost
, case
	when ModStatus = 'Authorized' then isnull(Adjust,Estimate) - (ActualCost + OpenCost + Contingency + AtRiskCost)
	else isnull(Adjust,Estimate) - (ActualCost + OpenCost + Contingency + AtRiskCost)
  end as OverUnder
, Notes              
, ModStatus              
, Show 
, ProjectCostCodeID             
FROM #Final      
           
              
DROP TABLE #takeoff
DROP TABLE #atrisk
DROP TABLE #buyout
DROP TABLE #unificacion1
DROP TABLE #unificacion2
DROP TABLE #Open
DROP TABLE #NoClosedBo
DROP TABLE #YesClosedBo
DROP TABLE #Final
DROP TABLE #Jobcost
DROP TABLE #Adjustments






