

 ALTER TABLE [A_AssetHarvest] ADD CONSTRAINT [FK__A_AssetHa__asset__0432261C] FOREIGN KEY ([assetID]) REFERENCES [dbo].[Asset] (AssetID) ;
 
 ALTER TABLE [A_AssetHarvest] ADD CONSTRAINT [FK__A_AssetHa__event__05264A55] FOREIGN KEY ([eventID]) REFERENCES [dbo].[Sys_Event] (EventID) ;
 
 ALTER TABLE [A_AssetHarvestResults] ADD CONSTRAINT [FK__A_AssetHa__harve__070E92C7] FOREIGN KEY ([harvestID]) REFERENCES [dbo].[A_AssetHarvest] (harvestID) ;
 
 ALTER TABLE [A_Collection] ADD CONSTRAINT [fk_A_CollectionClass_id] FOREIGN KEY ([CollectionClassID]) REFERENCES [dbo].[A_CollectionClass] (CollectionClassID) ;
 
 ALTER TABLE [A_MenuAccess] ADD CONSTRAINT [FK_A_MenuAccess_A_Role_RoleID] FOREIGN KEY ([RoleID]) REFERENCES [dbo].[A_Role] (RoleID)  ON DELETE CASCADE ;
 
 ALTER TABLE [A_RequestCapture] ADD CONSTRAINT [FK_A_RequestCapture_Bookmarks_BookmarkID] FOREIGN KEY ([BookmarkID]) REFERENCES [dbo].[Bookmarks] (BookmarkID) ;
 
 ALTER TABLE [A_SlotStatusDefinition] ADD CONSTRAINT [FK_A_SlotStatusDefinition_Workstream_WorkstreamID] FOREIGN KEY ([WorkstreamID]) REFERENCES [dbo].[Workstream] (WorkstreamID) ;
 
 ALTER TABLE [A_Task] ADD CONSTRAINT [FK_A_Task_User_UserID] FOREIGN KEY ([UserID]) REFERENCES [dbo].[User] (UserID) ;
 
 ALTER TABLE [A_TaskResponse] ADD CONSTRAINT [FK_A_TaskResponse_User_UserID] FOREIGN KEY ([UserID]) REFERENCES [dbo].[User] (UserID) ;
 
 ALTER TABLE [A_WorkStreamACL] ADD CONSTRAINT [FK_A_WorkStreamACL_Workstream_WorkStreamID] FOREIGN KEY ([WorkStreamID]) REFERENCES [dbo].[Workstream] (WorkstreamID)  ON DELETE CASCADE ;
 
 ALTER TABLE [AppAstUnUsed] ADD CONSTRAINT [FK_AppAstUnUsed_Application_ApplicationID] FOREIGN KEY ([ApplicationID]) REFERENCES [dbo].[Application] (ApplicationID) ;
 
 ALTER TABLE [AppAstUnUsed] ADD CONSTRAINT [FK_AppAstUnUsed_Asset_AssetID] FOREIGN KEY ([AssetID]) REFERENCES [dbo].[Asset] (AssetID) ;
 
 ALTER TABLE [AppAutoGroupMapping] ADD CONSTRAINT [FK_AppAutoGroupMapping_Application_ApplicationID] FOREIGN KEY ([ApplicationID]) REFERENCES [dbo].[Application] (ApplicationID) ;
 
 ALTER TABLE [ApplicationTransaction] ADD CONSTRAINT [FK_ApplicationTransaction_Application_ApplicationID] FOREIGN KEY ([ApplicationID]) REFERENCES [dbo].[Application] (ApplicationID) ;
 
 ALTER TABLE [ApplicationTransaction] ADD CONSTRAINT [FK_ApplicationTransaction_Asset_AssetID] FOREIGN KEY ([AssetID]) REFERENCES [dbo].[Asset] (AssetID) ;
 
 ALTER TABLE [AppPackageRequest] ADD CONSTRAINT [FK_AppPackageRequest_Application_ApplicationID] FOREIGN KEY ([ApplicationID]) REFERENCES [dbo].[Application] (ApplicationID) ;
 
 ALTER TABLE [AppUnused] ADD CONSTRAINT [FK_AppUnused_Application_ApplicationID] FOREIGN KEY ([ApplicationID]) REFERENCES [dbo].[Application] (ApplicationID) ;
 
 ALTER TABLE [AppUnusedRemoved] ADD CONSTRAINT [FK_AppUnusedRemoved_Application_ApplicationId] FOREIGN KEY ([ApplicationId]) REFERENCES [dbo].[Application] (ApplicationID) ;
 
 ALTER TABLE [AppUnusedRemoved] ADD CONSTRAINT [FK_AppUnusedRemoved_Asset_AssetID] FOREIGN KEY ([AssetID]) REFERENCES [dbo].[Asset] (AssetID) ;
 
 ALTER TABLE [AppUsedMap] ADD CONSTRAINT [FK_AppUsedMap_Application_ApplicationID] FOREIGN KEY ([ApplicationID]) REFERENCES [dbo].[Application] (ApplicationID) ;
 
 ALTER TABLE [Licence] ADD CONSTRAINT [FK_Licence_AppGroup_AppGroupID] FOREIGN KEY ([AppGroupID]) REFERENCES [dbo].[AppGroup] (AppGroupID) ;
 
 ALTER TABLE [ScheduleBookDay] ADD CONSTRAINT [FK_ScheduleBookDay_ScheduleChannel_ChannelID] FOREIGN KEY ([ChannelID]) REFERENCES [dbo].[ScheduleChannel] (ChannelID) ;
 
 ALTER TABLE [ScheduleDeployRun] ADD CONSTRAINT [FK_ScheduleDeployRun_ScheduleChannel_ChannelID] FOREIGN KEY ([ChannelID]) REFERENCES [dbo].[ScheduleChannel] (ChannelID)  ON DELETE CASCADE ;
 
 ALTER TABLE [TransformAction] ADD CONSTRAINT [FK_TransformAction_Transform_TransformID] FOREIGN KEY ([TransformID]) REFERENCES [dbo].[Transform] (TransformID) ;
 
 ALTER TABLE [TransformUpdate] ADD CONSTRAINT [FK_TransformUpdate_Transform_TransformID] FOREIGN KEY ([TransformID]) REFERENCES [dbo].[Transform] (TransformID) ;
 
 ALTER TABLE [VennRing] ADD CONSTRAINT [FK_VennRing_Venn_VennID] FOREIGN KEY ([VennID]) REFERENCES [dbo].[Venn] (VennID) ;
 
 ALTER TABLE [Workstream] ADD CONSTRAINT [Fk_Workstream_A_CollectionClass] FOREIGN KEY ([KeyStatusID]) REFERENCES [dbo].[A_CollectionClass] (CollectionClassID) ;
 
