
CREATE VIEW [dbo].[BuyoutByCostCodeView]
AS

SELECT     po.BuyoutID, po.Ordnum, po.TO_Mod, po.Status, po.DelegatedTo, CONVERT(datetime, po.OrderDate, 101) AS OrderDate, po.VendorID, bt.BOTypeID, 
           bt.BOTypePrefix, bt.BOTypeTitle, bt.CategoryNumber, bt.[Changes] as BOTypeChanges, ct.CategoryAlias as CategoryName, 
		   case po.TO_Mod
		     when '00' then bt.BOViewFilename
		     else bt.BOViewCOFilename
		   end as BOViewFilename,
		   bt.boTypeMinValue, bt.boTypeMaxValue,
		   CASE bt.BOTypeID 
		      WHEN '3' THEN (Select top 1 FirstName + ' ' + LastName from Users u inner join BuyoutLines bl on bl.UserID = u.UserID where bl.Recnum = po.BuyoutID)
		      ELSE ISNULL(e.EntityName, u.FirstName + ' ' + u.LastName) 
		   END AS vendor_name,
		   (u.FirstName + ' ' + u.LastName) as Employee_name, e.Alias as VendorAlias,
		   po.WorkorderID, po.WorkorderMod, wo.WorkorderStatus, wo.Alias as WorkorderAlias, wo.CustomerFacilityID, cf.Region,
           CASE po.WorkorderMod 
		      WHEN '00' THEN 'Original' 
			  ELSE 'CO ' + po.WorkorderMod 
		   END AS WorkorderScope, 
		   bl.Cstcde, 
           ISNULL(po.OrderTotal, 0) AS OrderTotal, po.Description, po.waID, wu.FileName AS BuyoutAttachment, v.TeamServiceID AS vndTeamServiceID, 
           ISNULL(po.OrderNotes, '') AS OrderNotes, MAX(po.NotificationLog) AS NotificationLog, bt.CredValidation, po.Posted
FROM       Buyout po
		   INNER JOIN BuyoutLines bl ON po.BuyoutID = bl.recnum
		   INNER JOIN dbo.Workorders wo ON po.WorkorderID = wo.WorkorderID AND po.WorkorderMod = wo.WorkorderMod 
		   INNER JOIN CustomerFacilities cf ON wo.CustomerFacilityID = cf.CustomerFacilityID
           INNER JOIN dbo.BuyoutType AS bt ON po.BOTypeID = bt.BOTypeID
		   INNER JOIN dbo.CostType  ct ON bt.CategoryNumber = ct.CategoryNumber
		   LEFT OUTER JOIN dbo.WorkorderUploads AS wu ON po.BuyoutID = wu.SourceID AND wu.Type = 'Commitments' AND wu.Source = 'Buyout'
		   LEFT OUTER JOIN dbo.Vendor AS v ON po.VendorID = v.Vendor# AND v.Vendor# = po.VendorID 
		   LEFT OUTER JOIN dbo.Entity AS e ON v.EntityID = e.EntityID 
		   LEFT OUTER JOIN dbo.Users AS u ON po.DelegatedTo = u.UserID 
		   LEFT OUTER JOIN dbo.WorkorderAssemblies AS wa ON po.waID = wa.waID
WHERE      po.BuyoutType = 'Buyout'
GROUP BY   po.BuyoutID, po.Ordnum, po.Status, po.DelegatedTo, po.OrderDate, po.VendorID, bt.BOTypeID, bt.BOTypePrefix, bt.BOTypeTitle, bt.CategoryNumber, bt.[Changes], ct.CategoryAlias, bt.BOViewFilename, bt.BOViewCOFilename,
		   boTypeMinValue, bt.boTypeMaxValue, po.TO_Mod, e.EntityName, u.FirstName, e.Alias,
           u.LastName, po.WorkorderID, po.WorkorderMod, wo.WorkorderStatus, wo.Alias, wo.CustomerFacilityID, cf.Region, bl.Cstcde, po.OrderTotal, po.Description, po.waID, wu.FileName, v.TeamServiceID, 
           po.OrderNotes, bt.CredValidation, po.Posted


/*****************************************************************************************/
GO
