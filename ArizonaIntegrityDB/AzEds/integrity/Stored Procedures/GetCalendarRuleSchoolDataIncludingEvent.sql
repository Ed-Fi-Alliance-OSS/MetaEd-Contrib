﻿/********************************************************************************************************
**Procedure Name:
**      [integrity].[GetCalendarRuleSchoolDataIncludingEvent]
**
**Author:
**     Pratibha Kanyar
**
**Description:  
**           Get School Calendar Track Data for Calendar rule integrity processing  
**               
**Input:
**
**Output:
**           School Calendar Track Data for Calendar rule integrity processing
**
**Returns:
**
**Revision History:
**           Who                      When                    What
**  Pratibha Kanyar                08/21/2017         Initial Creation
**  Vinoth A                       09/26/2017       Modified the SP to include Few Extra columns LEAID,IsA200DaySchool,SectorTypeId
**  Vinoth A                      10/03/2017        Modified the SP to include Extra columns SubmittedByEducationOrganizationId
**  Vinoth A                       11/15/2017       Modified the SP to fetch the sector type based on LEA ID instead of School ID
**  Sucharita M                   11/15/2017        Modified SP to remove join with table entity.CalendarDateTrackEvent in order to get only Track information. Task # 200926
**  Amit R                        05/10/2018        Modified SPROC to return all the Rule data from this SPROC and optimised querries and added calculated fields to improve Calendar integrity process run fast
**  Amit R                        05/21/2018        Modified SPROC to handle concurrent constraints bug - changed the way PRIMARY KEYs were defined on the TEMP TABLE
**  Amit R                        07/03/2018        Modified SPROC and added SubmittedByEducationOrganizationId as PrimaryKey for #TempTracktable
**  Vinoth K                      04/01/2019        Modified SPROC as per the Ed-FI 3.0 change
**  Vinoth K                      04/03/2019        Modified SPROC and added the IsHeadStart for the calendar rule
**  Vinoth K                      04/05/2019        Modified SPROC and added the Normal Submission window and NO Of Unplanned Dates
****************************************************************************************************************************************************************/
CREATE PROCEDURE [integrity].[GetCalendarRuleSchoolDataIncludingEvent]
                @ExecutionId as int,
                @MessageId as [nvarchar](36)
AS
BEGIN 

    SET NOCOUNT ON;
                SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  -- this is simiar to Nolock. Instead of doing for each table I set this at SP level.

--DROP all the temp table in case the SPROC failed in previous run -- fail safe                        
DROP TABLE IF EXISTS #TempTrackEventType
DROP TABLE IF EXISTS #WeekTable
DROP TABLE IF EXISTS #TempCalendarData
DROP TABLE IF EXISTS #TempTracktable

--create temp table with all the returning columns from [TrackEventType]
Create Table #TempTrackEventType
(
TrackEventTypeId int ,Primary Key (TrackEventTypeId)
);

insert into #TempTrackEventType (TrackEventTypeId)
select distinct(TrackEventTypeId) from [AzEds].[entity].[TrackEventType] with(nolock)  where IsInstructional = 1 

--create temp table with all the returning columns from track table
Create Table #TempTracktable
(
ID INT IDENTITY(1,1),
SchoolId int, TrackLocalEducationAgencyID int, TrackNumber int, FiscalYear int, IsVirtual bit, NumberOfSessionDaysInWeek int, WarningThresholdInDays int,
NumberOfFullWeeksRequired int, AllowedNumberOfDaysPerWeek int, TrackBeginDate datetime, TrackEndDate  datetime, IsA200DaySchool bit, SectorTypeId int,
  SubmittedByEducationOrganizationId int,TotalNumberOfFullWeeks int,TotalNumberOfInstructionalDays int, CalendarType varchar(50), CalendarCode varchar(60),
  IsHeadStart bit,IsNormalSubmissionWindow bit,NumberOfUnplannedDates int
   --CONSTRAINT [PK_Track_TempTracktable] PRIMARY KEY CLUSTERED 

   primary key (CalendarCode ASC,
				SchoolId ASC,
                [FiscalYear] ASC,
                [TrackNumber] ASC,
                [TrackLocalEducationAgencyId] ASC,
				SubmittedByEducationOrganizationId ASC)
);

insert into #TempTracktable(SchoolId, TrackLocalEducationAgencyID, TrackNumber, FiscalYear,IsVirtual, NumberOfSessionDaysInWeek, WarningThresholdInDays,
  NumberOfFullWeeksRequired,AllowedNumberOfDaysPerWeek, TrackBeginDate, TrackEndDate, IsA200DaySchool, SectorTypeId, SubmittedByEducationOrganizationId,
  CalendarType,CalendarCode,IsHeadStart,IsNormalSubmissionWindow,NumberOfUnplannedDates )

SELECT DISTINCT 
                              tr.EducationOrganizationId                                                             AS 'SchoolId',                                                                                               
                              tr.TrackLocalEducationAgencyId                                                         AS 'TrackLocalEducationAgencyID',                        
                              tr.TrackNumber                                                                         AS 'TrackNumber',
                              tr.FiscalYear                                                                          AS 'FiscalYear',                                                    
                              (CASE WHEN sch.IsVirtual = 1 THEN 1 ELSE 0 END)                                        AS 'IsVirtual',                                                                                                               
                              --tr.TotalInstructionalDays                                                            AS 'TotalInstructionalDays',
                              tr.NumberOfSessionDaysInWeek                                                           AS 'NumberOfSessionDaysInWeek',   
                              ty.WarningThresholdInDays                                                              AS 'WarningThresholdInDays',
                              ty.NumberOfFullWeeksRequired                                                           AS 'NumberOfFullWeeksRequired',
                              ty.NumberOfSessionDaysInWeek                                                           AS 'AllowedNumberOfDaysPerWeek',
                              CONVERT(DATETIME,tr.BeginDate)                                                         AS 'TrackBeginDate',                   
                              CONVERT(DATETIME,tr.EndDate)                                                           AS 'TrackEndDate',   
                              (CASE WHEN dlea.localeducationagencyid is not null 
                              THEN 1 ELSE 0 END)                                                                     AS 'IsA200DaySchool',
                              lea.SectorTypeId                                                                       AS 'SectorTypeId',
                              ih.SubmittedByEducationOrganizationId                                                  AS 'SubmittedByEducationOrganizationId',                                                     
                              tr.CalendarType																		 AS 'CalendarType',
							  tr.CalendarCode																		 AS 'CalendarCode',
							  sch.IsHeadStart																		 AS 'IsHeadStart',
							  (CASE WHEN ds.SubmissionEndDate>GETUTCDATE() THEN 1 ELSE 0 END)						 AS 'IsNormalSubmissionWindow',
							  0																						 AS 'NumberOfUnplannedDates' -- Default we will say we have no unplanned
                     FROM [integrity].[vw_GetIntegrityHistoryPerExecution] ih
                           
                             INNER JOIN entity.Track tr with (nolock)
                                  ON tr.FiscalYear = ih.FiscalYear 
                                         AND tr.[EducationOrganizationId] = ih.SchoolId
                                         AND tr.[TrackLocalEducationAgencyId] = ih.[TrackLocalEducationAgencyId]
                                         AND tr.[TrackNumber] = ih.[TrackNumber]
										 AND tr.CalendarCode = ih.CalendarCode
                                         AND ih.IntegrityRuleTypeId = 16                                                                        -- Calendar integrity
							 INNER JOIN entity.vw_School sch with (nolock)
                                   ON tr.EducationOrganizationId = sch.SchoolId 
                                         AND tr.FiscalYear = sch.FiscalYear
							 INNER JOIN entity.vw_LocalEducationAgency lea with (nolock)
                                   ON tr.[TrackLocalEducationAgencyId] = lea.localeducationagencyid 
                                         AND tr.FiscalYear = lea.FiscalYear
							 INNER JOIN config.CalendarType ty with (nolock)
								        on tr.CalendarType =ty.CalendarType
	                         LEFT JOIN entity.Approved200DayLocalEducationAgency dlea with (nolock)
								   ON dlea.LocalEducationAgencyId =sch.LocalEducationAgencyId
										and dlea.FiscalYear = sch.FiscalYear
							 LEFT JOIN config.DataSubmissionWindow Ds
								 on Ds.FiscalYear=tr.FiscalYear
								 and ds.RequestTypeId=2

                       WHERE ih.Executionid = @executionid 
                           AND ih.messageid = @messageid   
                                                                                                   
                       ORDER BY  
                           SchoolId, 
                           TrackNumber,               
                           TrackLocalEducationAgencyID 
----------------------------------------------Populate CalendarDateTrackEvent into TempTable-------------------------------------------------------------
Create table #TempCalendarData
(SchoolId int,TrackLocalEducationAgencyId int,TrackNumber int,[Date] datetime,TrackEventTypeID int ,TrackCodeValue nvarchar(50), IsInstructional bit, IsPlanned bit,
CalendarCode varchar(60),CalendarType varchar(50)
Primary key (   CalendarCode ASC,
				SchoolId ASC,     
                [TrackNumber] ASC,
                [TrackLocalEducationAgencyId] ASC,
                [Date] ASC,
                [TrackEventTypeID] ASC )
);
CREATE INDEX eventtype ON  #TempCalendarData(TrackEventTypeID); 

insert into #TempCalendarData (SchoolId,TrackLocalEducationAgencyId,TrackNumber,Date,TrackEventTypeID,TrackCodeValue,IsInstructional,IsPlanned,CalendarCode,CalendarType )
SELECT DISTINCT
                     cd.EducationOrganizationId AS SchoolId,
                     cd.TrackLocalEducationAgencyId,
                     cd.TrackNumber,      
                     cd.[Date],    
                     tet.TrackEventTypeId                     AS TrackEventTypeID  ,             
                     tet.CodeValue                            AS CodeValue,
                     tet.IsInstructional,
					 tet.IsPlanned,
				     tmp.CalendarCode,
					 tmp.CalendarType						
from  entity.CalendarDateTrackEvent cd                   
     JOIN #TempTracktable tmp with (nolock)
              ON cd.EducationOrganizationId = tmp.SchoolId
                     AND cd.FiscalYear = tmp.FiscalYear
                     AND cd.TrackNumber = tmp.TrackNumber
                     AND cd.TrackLocalEducationAgencyId = tmp.TrackLocalEducationAgencyId
					 AND cd.CalendarCode = tmp.CalendarCode
       LEFT JOIN [entity].[TrackEventType] tet with (nolock)
              ON tet.TrackEventTypeId = cd.TrackEventTypeId   
                     
    ORDER BY         SchoolId,
                     cd.trackNumber,     
                     cd.TrackLocalEducationAgencyId,
                     cd.Date,
					 tmp.CalendarCode

------------------------------------------------------Get 
--------------------------------------------------------logic to find week begin end date to count number of full weeks and total number of instructional days
DECLARE @TrackCnt int = 0;
DECLARE @maxTrackCnt int = (SELECT COUNT(*) FROM #TempTracktable with (nolock));

    CREATE TABLE #WeekTable -- Local temporary table
  (
       Week int,
        WeekStartDate date,
       WeekEndDate date,
       InstructionalDaysCount int   
   );


   Declare @NumberOfweeks int
       Declare @TrackBeginDate  DATETIME
       Declare @TrackEndDate  DATETIME
       Declare @TotalNumberOfFullWeeks int   
                   Declare @TotalNumberOfInstructionalDays int
                   Declare @TrackLocalEducationAgencyID int
                   Declare @SchoolId int
                   Declare @TrackNumber int
                   Declare @WeekStartDate datetime
                   Declare @WeekEndDate datetime
                   Declare @ID int
                   Declare @NumberOfSessionDaysInWeek int
				   Declare @CalendarCode varchar(60)
				   Declare @NumberOfUnplannedDates int

DECLARE TrackCursor CURSOR FOR select ID,SchoolId, TrackLocalEducationAgencyID, TrackBeginDate,TrackEndDate, TrackNumber, CalendarCode, TotalNumberOfFullWeeks,TotalNumberOfInstructionalDays,NumberOfSessionDaysInWeek,NumberOfUnplannedDates
 from #TempTracktable for update of TotalNumberOfInstructionalDays , TotalNumberOfFullWeeks, NumberOfUnplannedDates
OPEN TrackCursor-- for update

  ----------get weeks-------
    
 Fetch NEXT from TrackCursor INTO @ID, @SchoolId, @TrackLocalEducationAgencyID, @TrackBeginDate,@TrackEndDate, @TrackNumber, @CalendarCode,@TotalNumberOfFullWeeks,@TotalNumberOfInstructionalDays,@NumberOfSessionDaysInWeek,@NumberOfUnplannedDates


while @@FETCH_STATUS = 0
  BEGIN
       
   select @WeekStartDate= DATEADD(DD,-(CHOOSE(DATEPART(dw, @TrackBeginDate) ,1,2,3,4,5,6,7)-1),@TrackBeginDate) 
   select @WeekEndDate= DATEADD(DD,7-CHOOSE(DATEPART(dw, @TrackEndDate), 1,2,3,4,5,6,7),@TrackEndDate) 
   select @NumberOfweeks = DATEDIFF(wk,@TrackBeginDate,@TrackEndDate)

   insert INTO #WeekTable  ( Week, WeekStartDate,WeekEndDate)
   SELECT v.Number AS Week,
        DATEADD(wk, v.Number ,@WeekStartDate) AS WeekStartDate,
        (DATEADD(wk, v.Number+1 ,@WeekStartDate)-1) AS WeekEndDate
    FROM Master.dbo.spt_Values v with (nolock)
    WHERE Type = 'P'
    AND Number BETWEEN 0 AND (@NumberOfweeks)


---------------------update #TempTracktable with TotalNumberOfFullWeeks and TotalNumberOfInstructionalDays------------------

   set @TotalNumberOfFullWeeks=(select count(*)  from 
                                   (
                                    select wkk.Week, count(eve.Date) cnt from #WeekTable wkk with (nolock)
                                   cross join #TempCalendarData eve with (nolock)
                                       join #TempTrackEventType eventtype             
                                        on eve.TrackEventTypeID = eventtype.TrackEventTypeId                                          
                                        where eve.TrackLocalEducationAgencyId = @TrackLocalEducationAgencyID
                                                and eve.SchoolId =  @SchoolId 
                                                and eve.TrackNumber = @TrackNumber
												and eve.CalendarCode = @CalendarCode
                                                and eve.Date between wkk.WeekStartDate and wkk.WeekEndDate                                                              
                                                                                                                                                                                                                                                
                                    group by wkk.week
                                  ) result 
                                   where result.cnt >= @NumberOfSessionDaysInWeek)  
                
                UPDATE #TempTracktable set     TotalNumberOfFullWeeks = @TotalNumberOfFullWeeks where CURRENT OF TrackCursor
   
   set @TotalNumberOfInstructionalDays =  (select sum(cnt) from
                           
                                           (
                                              select wkk.Week, count(eve1.Date) cnt from #WeekTable wkk with (nolock)
                                              cross join #TempCalendarData eve1 with (nolock)
                                              join #TempTrackEventType eventtype             
                                               on eve1.TrackEventTypeID = eventtype.TrackEventTypeId
                                               where eve1.TrackLocalEducationAgencyId = @TrackLocalEducationAgencyID
                                                    and eve1.SchoolId = @SchoolId
                                                    and eve1.TrackNumber = @TrackNumber
													and eve1.CalendarCode = @CalendarCode
                                                    and eve1.Date between wkk.WeekStartDate and wkk.WeekEndDate                                                                        
                                                                                                                                                                                                                                                                                                  
                                               group by wkk.week
                                            )TotalDays                                                                                                                                             
                                          ) 
					UPDATE #TempTracktable set     TotalNumberOfInstructionalDays = @TotalNumberOfInstructionalDays where CURRENT OF TrackCursor
-------------------------------get the number of unplanned event dates submitted------------------------------------

set @NumberOfUnplannedDates = (select count(eve2.IsPlanned) cnt from #TempCalendarData eve2 with (nolock)
                                               where eve2.TrackLocalEducationAgencyId = @TrackLocalEducationAgencyID
                                                    and eve2.SchoolId = @SchoolId
                                                    and eve2.TrackNumber = @TrackNumber
													and eve2.CalendarCode = @CalendarCode
													and eve2.IsPlanned =0
                                               group by eve2.TrackLocalEducationAgencyId,eve2.SchoolId,eve2.TrackNumber,eve2.CalendarCode,eve2.IsPlanned)                            


                UPDATE #TempTracktable set NumberOfUnplannedDates = ISNULL(@NumberOfUnplannedDates,0) where CURRENT OF TrackCursor
   
  truncate table #WeekTable
FETCH NEXT from TrackCursor INTO @ID, @SchoolId, @TrackLocalEducationAgencyID, @TrackBeginDate,@TrackEndDate, @TrackNumber, @CalendarCode,@TotalNumberOfFullWeeks,@TotalNumberOfInstructionalDays,@NumberOfSessionDaysInWeek,@NumberOfUnplannedDates


END
DEALLOCATE TrackCursor
SET NOCOUNT OFF

select * from #TempTracktable
select * from #TempCalendarData


DROP TABLE IF EXISTS #TempTrackEventType
DROP TABLE IF EXISTS #WeekTable
DROP TABLE IF EXISTS #TempCalendarData
DROP TABLE IF EXISTS #TempTracktable

END
