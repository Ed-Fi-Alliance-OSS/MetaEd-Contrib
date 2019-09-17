﻿
/******************************************************************************************************************
**Procedure Name:
**      report.ADM20SummaryAdjustedADM20
**
**Author:
**      Harsha Kankanala
**
**Description:  
**  Gives Total NON AOI, AOI FT, AOI PT ADMs for different Grades & Reporting periods And District Of and School
**   
**Input:
**	@LEAId - DOR district to filter upon
**  @FiscalYear - Fiscal year to filter upon
**	@ExecutionID - latest Aggregation Execution ID coming from GetLatestExecIdDataCaptureDate
**  @SchoolsList	NVARCHAR(max) = '5111,5113',
**  @District       VARCHAR(100) = 'Submitted'
**
**Output:
**  
**Returns:
**	@@Error
**
**Implementation:
**	Called from ADM20SummaryAdjustedADM20A.rdl (ADM20 Report)
**
**Revision History:
** Harsha Kankanala            Initial Creation
** Harsha Kankanala             Added All Option  12/11/2018
** Harsha Kankanala             Customized the stored pro for ADM20A
** Harsha Kankanala             FIXED THE ISSUE OF COUNT DOUBLING UP BY CHANGING THE QUERY TO ELIMINATE DUPLICATES
** Harsha Kankanala   1/15/2019 Changed the stored proc as per the new requierements 
***************************************************************************************************************/
CREATE  PROC [report].[ADM20SummaryAdjustedADM20A] --4242,2017,3900
	    @LEAId INT , 
	    @FiscalYear INT ,
	    @ExecutionID INT 
		         
		         
       AS	         
       BEGIN        
		         
    SET NOCOUNT ON;
		         

		         
	          



-------------------------------------------------------------------
	-- Gets the latest Statewide Aggregation ExecutionID (completed)

	--SELECT @ExecutionID = ExecutionId
	--FROM [ace].[vw_GetACEMaxCompletedStatewide] 

------------------------------------------------------------------------
          CREATE TABLE #MembershipSummary  -- CREATED TEMP TABLES HERE BEFORE IF STATEMENT SO THAT SAME TEMP TABLE CAN BE USED 
          (
                   ExecutionId INT, 
                   FiscalYear INT, 
                   ADMTypeId INT,
                   AggregationTypeId INT, 
                   ReportingPeriodTypeId INT,
                   ReportingPeriodId INT, 
                   GradeLevelTypeId INT, 
                   ResidentEducationOrganizationId INT,   
                   FTFStatus BIT, 
                   LimitedAverageDailyMembership decimal(20,4),
                   GRADE NVARCHAR(50),
                   GradeGroup INT
           )
          CREATE TABLE #ReportingPeriod        -- CREATED TEMP TABLES HERE BEFORE IF STATEMENT SO THAT SAME TEMP TABLE CAN BE USED 
          (
                  [ReportingPeriodId] INT,
                  [ReportingPeriodTypeId] INT
          )
          CREATE TABLE #GradeAndReportingPeriod   -- CREATED TEMP TABLES HERE BEFORE IF STATEMENT SO THAT SAME TEMP TABLE CAN BE USED 
          (
                   [GradeLevelTypeId] INT,
                   [GRADE] NVARCHAR(50),
                   [GradeGroup] INT,
                   [ReportingPeriodId] INT,
                   [ReportingPeriodTypeId] INT
          )

         
          
          INSERT INTO #MembershipSummary
          (
          ExecutionId , 
          FiscalYear , 
          ADMTypeId ,
          AggregationTypeId , 
          ReportingPeriodTypeId ,
          ReportingPeriodId , 
          GradeLevelTypeId , 
          ResidentEducationOrganizationId ,   
          FTFStatus , 
          LimitedAverageDailyMembership ,
          GRADE ,
          GradeGroup
          )
	      SELECT  MS.ExecutionId,
             MS.FiscalYear,
	         MS.ADMTypeId,
	         MS.AggregationTypeId,
	         MS.ReportingPeriodTypeId,
	         MS.ReportingPeriodId,
	         MS.GradeLevelTypeId,
	         MS.AttendingLocalEducationAgencyId,
	         --MS.FundingTypeId,
	         MS.FTFStatus,
	         MS.LimitedAverageDailyMembership,
	         GLT.CodeValue							AS Grade,
	         GLT.GradeGroup
	      FROM [ace].[MembershipSummary] MS WITH(NOLOCK)
	      JOIN [entity].[GradeLevelType] GLT WITH(NOLOCK)
		   ON MS.GradeLevelTypeId = GLT.GradeLevelTypeId
		 JOIN ace.FundingType FT
		   ON MS.FundingTypeId = FT.FundingTypeId
	     WHERE MS.ExecutionId = @ExecutionID  
		    AND MS.AttendingLocalEducationAgencyId = @LEAId 
		    AND MS.FiscalYear = @FiscalYear
		    AND FT.IsFundable = 1
		    AND GLT.GradeGroup IS NOT NULL


         INSERT INTO #ReportingPeriod
         (
         [ReportingPeriodId] ,
         [ReportingPeriodTypeId]
         )
    
	     -- Reporting Period Type Projected or Actual
	     SELECT ReportingPeriodId,
	            MIN(ReportingPeriodTypeId) AS ReportingPeriodTypeId
         FROM [ace].[MembershipSummary] 
	     WHERE ExecutionId = @ExecutionID  
	     	  AND AttendingLocalEducationAgencyId = @LEAId 
	     	  AND FiscalYear = @FiscalYear
	     	  AND ADMTypeId = 1
	     	  AND ReportingPeriodId IN (1,5,6)
	     GROUP BY ReportingPeriodId
         INSERT INTO #GradeAndReportingPeriod
         (
         [GradeLevelTypeId] ,
         [GRADE] ,
         [GradeGroup] ,
         [ReportingPeriodId] ,
         [ReportingPeriodTypeId]
         )
	     SELECT GLT.GradeLevelTypeId,
	            GLT.CodeValue AS Grade,
	     	   GLT.GradeGroup,
	     	   RP.ReportingPeriodId,
	     	   RP.ReportingPeriodTypeId
	     FROM #ReportingPeriod RP 
	     CROSS JOIN entity.GradeLevelType GLT
	     WHERE GLT.GradeGroup IS NOT NULL
	     
	   
	---- To get Total ADMs for the latest executionid
	--SELECT * FROM #MembershipSummary
	    CREATE TABLE #ADMSummary 
		( 
		 GradeGroup int
		,Grade nvarchar(50)
		,GradeLevelTypeId int
		,ReportingPeriodId int
		,ADMGroupId int
		,TOTAL_ADM	decimal(20,4)

		)
   

   
			BEGIN
			INSERT INTO #ADMSummary 
				SELECT
					 GradeGroup
					,Grade
					,GradeLevelTypeId
					,ReportingPeriodId
					,ADMGroupId
					,TOTAL_ADM
				FROM
					(
						-- NON AOI ADM 
						SELECT 
							 MS.GradeGroup
							,MS.Grade
							,MS.GradeLevelTypeId
							,MS.ReportingPeriodId
							,1												AS ADMGroupId		-- NON AOI ADM	
							,ROUND(SUM(MS.LimitedAverageDailyMembership),4)	AS TOTAL_ADM
						FROM #MembershipSummary MS
						WHERE MS.AggregationTypeId = 1			 	-- B&M (NON AOI)
							  AND MS.ADMTypeId = 1					-- Regular ADM
							  AND MS.ReportingPeriodId IN (1,5,6)	
						GROUP BY 
							 MS.GradeGroup
							,MS.Grade
							,MS.GradeLevelTypeId
							,ReportingPeriodId


					UNION

						-- AOI FULL TIME ADM 
						SELECT 
							 MS.GradeGroup
							,MS.Grade
							,MS.GradeLevelTypeId
							,MS.ReportingPeriodId
							,2												AS ADMGroupId		--'AOI_FULL-TIME_ADM'
							,ROUND(SUM(MS.LimitedAverageDailyMembership),4)	AS TOTAL_ADM
                        FROM #MembershipSummary MS
						WHERE MS.AggregationTypeId = 2				-- AOI
							  AND MS.ADMTypeId = 1					-- Regular ADM
							  AND MS.FTFStatus = 1					-- FULL TIME (FTE = 1)
							  AND MS.ReportingPeriodId IN (1,5,6)	
						GROUP BY 
							 MS.GradeGroup
							,MS.Grade
							,MS.GradeLevelTypeId
							,ReportingPeriodId
			

			
					UNION

						-- AOI PART TIME ADM 
						SELECT 
							 MS.GradeGroup
							,MS.Grade
							,MS.GradeLevelTypeId
							,MS.ReportingPeriodId
							,3												AS ADMGroupId		--'AOI_PART-TIME_ADM'
							,ROUND(SUM(MS.LimitedAverageDailyMembership),4)	AS TOTAL_ADM
					    FROM #MembershipSummary MS
						WHERE MS.AggregationTypeId = 2				-- AOI
							  AND MS.ADMTypeId = 1					-- Regular ADM
							  AND MS.FTFStatus = 0					-- PART TIME (FTE < 1)
							  AND MS.ReportingPeriodId IN (1,5,6)	
						GROUP BY 
							 MS.GradeGroup
							,MS.Grade
							,MS.GradeLevelTypeId
							,MS.ReportingPeriodId
							

					UNION
					    -- DRP
						SELECT 
							 MS.GradeGroup
							,MS.Grade
							,MS.GradeLevelTypeId
							,MS.ReportingPeriodId
							,4												AS ADMGroupId		-- DRP	
							,ROUND(SUM(MS.LimitedAverageDailyMembership),4)	AS TOTAL_ADM
						FROM #MembershipSummary MS
						WHERE MS.AggregationTypeId = 4				-- DRP
							  AND MS.ADMTypeId = 1					-- Regular ADM
							  AND MS.ReportingPeriodId IN (1,5,6)	
						GROUP BY 
							 MS.GradeGroup
							,MS.Grade
							,MS.GradeLevelTypeId
							,ReportingPeriodId


					UNION
					    -- GCD
						SELECT 
							 MS.GradeGroup
							,MS.Grade
							,MS.GradeLevelTypeId
							,MS.ReportingPeriodId
							,5												AS ADMGroupId		-- GCD
							,ROUND(SUM(MS.LimitedAverageDailyMembership),4)	AS TOTAL_ADM
						FROM #MembershipSummary MS
						WHERE MS.AggregationTypeId = 3				--GCD 
							  AND MS.ADMTypeId = 1					-- Regular ADM
							  AND MS.ReportingPeriodId IN (1,5,6)	
						GROUP BY 
							 MS.GradeGroup
							,MS.Grade
							,MS.GradeLevelTypeId
							,ReportingPeriodId

					)SQ
			END
   
	
	-- PIVOTING THE REPORT DATA
	SELECT 
		  CumGradeGroup
		 ,GradeSection = CASE WHEN GradeGroup = 1	  THEN 'S1'
							 WHEN GradeGroup IN (2,3) THEN 'S2'
							 WHEN GradeGroup = 4	  THEN 'S3'	 
							 END
		,GradeGroup 
		,Grade 
		,GradeLevelTypeId 
		,ReportingPeriodId 
		,[1]	AS 'NON_AOI_ADM'	
		,[2]	AS 'AOI_FULL-TIME_ADM'
		,[3]	AS 'AOI_PART-TIME_ADM'
		,[4]	AS 'DRP_ADM'
		,[5]	AS 'GCD_ADM'
	INTO #ADMReport
	FROM
		(
			SELECT 
				'S' AS CumGradeGroup
				,GradeGroup 
				,Grade
				,GradeLevelTypeId
				,ReportingPeriodId
				,ADMGroupId
				,TOTAL_ADM

			FROM #ADMSummary
		)P
		PIVOT
		(
			MAX(TOTAL_ADM)
			FOR ADMGroupId IN ([1], [2], [3], [4], [5] )
		) AS PVT
	WHERE 
		[1] IS NOT NULL OR [2] IS NOT NULL OR [3] IS NOT NULL OR [4] IS NOT NULL OR [5] IS NOT NULL
 
	ORDER BY 
		 GradeLevelTypeId
		,ReportingPeriodId
    
	--Report Data Joined with Reporting Period Type (Actual or Projected)
	SELECT CASE WHEN ADMR.CumGradeGroup IS NULL THEN 'S'
		   ELSE ADMR.CumGradeGroup END AS CumGradeGroup,
		   --CASE WHEN ADMR.GradeSection IS NULL THEN 'S'+ CONVERT(VARCHAR(10),GRP.GradeGroup)
		   --ELSE ADMR.GradeSection END 
		   GradeSection = CASE WHEN GRP.GradeGroup = 1	  THEN 'S1'
							 WHEN GRP.GradeGroup IN (2,3) THEN 'S2'
							 WHEN GRP.GradeGroup = 4	  THEN 'S3'	 
							 END, 
		   GRP.GradeGroup,
		   GRP.Grade,
		   GRP.GradeLevelTypeId,
		   CASE WHEN ADMR.ReportingPeriodId IS NULL THEN 
		             GRP.ReportingPeriodId 
			    ELSE ADMR.ReportingPeriodId END AS ReportingPeriodId,
		   ADMR.NON_AOI_ADM,	
		   ADMR.[AOI_FULL-TIME_ADM],
		   ADMR.[AOI_PART-TIME_ADM],
		   ADMR.DRP_ADM,
		   ADMR.GCD_ADM,
           GRP.ReportingPeriodTypeId
	INTO #FINAL
	FROM #GradeAndReportingPeriod GRP
	     LEFT JOIN #ADMReport ADMR
	       ON ADMR.ReportingPeriodId = GRP.ReportingPeriodId
		      AND ADMR.GradeLevelTypeId = GRP.GradeLevelTypeId
			


	SELECT  --Added a join with school view to extract school name
		  DISTINCT CumGradeGroup,
		   GradeSection , 
		   GradeGroup,
		   Grade,
		   GradeLevelTypeId,
		   ReportingPeriodId,
		   NON_AOI_ADM,	
		   [AOI_FULL-TIME_ADM],
		   [AOI_PART-TIME_ADM],
		   DRP_ADM,
		   GCD_ADM,
           ReportingPeriodTypeId

	FROM   #FINAL A
	   

	DROP TABLE #ADMSummary
	DROP TABLE #MembershipSummary
	DROP TABLE #ReportingPeriod
	DROP TABLE #ADMReport
	DROP TABLE #GradeAndReportingPeriod
	DROP TABLE #Final




END


GO


