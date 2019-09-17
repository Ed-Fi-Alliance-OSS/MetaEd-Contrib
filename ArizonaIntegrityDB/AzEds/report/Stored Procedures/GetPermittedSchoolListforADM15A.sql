/********************************************************************************************
**Procedure Name:
**      report.GetPermittedSchoolListforDOR
**
**Author:
**      Pratibha Kanyar
**
**Description:  
**  Lists of Schools based on User Permissions for AzEDS Portal & AggegationExecution ID
**   
**Input:
**  @LocalEducationAgencyId
**  @PermittedEdOrgIdList
**  @FiscalYear
**	@AggregationExecutionID 
**
**Output:
**  List of Schools
**
**Returns:
**	@@Error
**
**Implementation:
**	Called from AzEDS Portal UI 
**
**Revision History:
**	P Kanyar		08/04/2016	Initial Creation
**	Harsha Kankanala 11/28/2018 Customised the stored proc for ADM15A	
**	Harsha Kankanala 12/05/2018 FIXED THE ISSUE OF SCHOOLS NOT FILTERING
**  Harsha Kankanala 02/27/2019 Adding the indexing to the stored proc
**  Harsha Kankanala 05/1/2019 Changed the stored proc to fetch schools list from Membership Summary Table
**  Harsha Kankanala 05/8/2019 Fixed the bug where EVITSchools are missing
*********************************************************************************************/
CREATE PROC [report].[GetPermittedSchoolListforADM15A] --4235,2019,NULL,11146,'of Attendance'
	@LocalEducationAgencyId int,
	@FiscalYear int,
	@PermittedEdOrgIdList nvarchar(max) = null,
	@AggregationExecutionID int,
    @District VARCHAR(100)
AS
BEGIN

CREATE TABLE #PermittedEdOrgs  ([EdOrgId] int, [FiscalYear] int) 
create nonclustered index ix_membership on #PermittedEdOrgs ( [EdOrgId] , [FiscalYear]   ) ;
INSERT INTO #PermittedEdOrgs SELECT DISTINCT [Token], @FiscalYear FROM [util].[Split](@PermittedEdOrgIdList, ',') 	
	
	-- If LEAId passed in is in the @PermittedEdOrgs, then add all the schools under that LEA as DOR from ace.MembershipInterval table 
	-- to permittedEdOrgs 
	-- Similary add all schools under the LEA(@LocalEducationAgencyId) as DOR if the PermittedEdOrgIdList contains 79275 (ADE State EntityId)


	IF EXISTS(SELECT 1 FROM #PermittedEdOrgs WHERE EdOrgId = @LocalEducationAgencyId OR EdOrgId = 79275) AND @District = 'of Residence'  --THE CONDITION SHOULD BE OR
	BEGIN
		DELETE FROM #PermittedEdOrgs
		INSERT INTO #PermittedEdOrgs
			SELECT DISTINCT SchoolId, FiscalYear
			FROM ace.MembershipSummary WITH(NOLOCK)
			WHERE [ResidentEducationOrganizationId] = @LocalEducationAgencyId 
					AND FiscalYear = @FiscalYear
					AND ExecutionId = @AggregationExecutionID
	END
	ELSE IF EXISTS(SELECT 1 FROM #PermittedEdOrgs WHERE EdOrgId = @LocalEducationAgencyId OR EdOrgId = 79275) AND @District = 'of Attendance' --THE CONDITION SHOULD BE OR
	BEGIN
		DELETE FROM #PermittedEdOrgs
		INSERT INTO #PermittedEdOrgs
			SELECT DISTINCT SchoolId, FiscalYear
			FROM ace.MembershipSummary WITH(NOLOCK)
			WHERE AttendingLocalEducationAgencyId = @LocalEducationAgencyId 
					AND FiscalYear = @FiscalYear
					AND ExecutionId = @AggregationExecutionID
	END
	ELSE IF EXISTS(SELECT 1 FROM #PermittedEdOrgs WHERE EdOrgId = @LocalEducationAgencyId OR EdOrgId = 79275) AND @District = 'Submitted'  --THE CONDITION SHOULD BE OR
	BEGIN
		DELETE FROM #PermittedEdOrgs
		INSERT INTO #PermittedEdOrgs
			SELECT DISTINCT SchoolId, FiscalYear
			FROM ace.MembershipSummary WITH(NOLOCK)
			WHERE SubmittedByEducationOrganizationId = @LocalEducationAgencyId 
					AND FiscalYear = @FiscalYear
					AND ExecutionId = @AggregationExecutionID
	END

    ELSE 
	--IF EXISTS(SELECT 1 FROM @PermittedEdOrgs WHERE EdOrgId = @LocalEducationAgencyId OR EdOrgId = 79275) AND @District = 'ALL'
	BEGIN
		DELETE FROM #PermittedEdOrgs
		INSERT INTO #PermittedEdOrgs
			SELECT DISTINCT SchoolId, FiscalYear
			FROM ace.MembershipSummary WITH(NOLOCK)
			WHERE (SubmittedByEducationOrganizationId = @LocalEducationAgencyId OR AttendingLocalEducationAgencyId = @LocalEducationAgencyId OR ResidentEducationOrganizationId = @LocalEducationAgencyId) -- 11/28/2018 Corrected the issue where ResidentEducationOrganizationId is not being used
					AND FiscalYear = @FiscalYear
					AND ExecutionId = @AggregationExecutionID
	END


	SELECT 
		 SchoolId
		,sc.FiscalYear
		,SchoolName + ' (' + CONVERT(nvarchar(20),SchoolId) + ')'	AS SchoolName
		,SchoolCTDS
	FROM [entity].[vw_School] sc
		JOIN
	#PermittedEdOrgs ped ON ped.EdOrgId = sc.SchoolId AND ped.FiscalYear = sc.FiscalYear
	WHERE 
		OperationalStatusTypeId IN (1,2,3,8,9)											--Active, Added, Changed Agency, New & Reopened status 
	ORDER BY 
		SchoolId

		drop table #PermittedEdOrgs
END

/* END report.GetPermittedSchoolListforDOR */


