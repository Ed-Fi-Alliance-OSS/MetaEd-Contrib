-- =============================================
--	Author	    : Abhi Gopalpuria
--	Create date: 06/23/2015
--	Description: Procedure to extract StudentSchoolAssociation data for ACE
--  April 3, 2019 Chris M added CalendarCode logic
-- =============================================
CREATE PROCEDURE [ace].[GetStudentSchoolAssociation]
	@StudentID ace.ISStudentEnrollment READONLY
	, @FY INT
AS
BEGIN

	SET NOCOUNT ON;

	CREATE TABLE #ssa
		(	
			FiscalYear INT,
			StudentUSI INT,
			SchoolId INT,
			EntryDate DATE,
			EntryGradeLevelDescriptorId INT,
			ExitWithdrawDate DATE,
			ExitWithdrawTypeDescriptorId INT,
			ClassOfSchoolYear INT,
			MembershipTypeDescriptorId INT,
			TrackEducationOrganizationId INT,
			CalendarCode NVARCHAR(60),
			ELL BIT,
			SPED BIT,
			GradeLevelTypeId INT,
			SourceId uniqueidentifier
		)

	CREATE TABLE #ro
		(	FiscalYear INT,
			ResourceId uniqueidentifier,
			RecordOwnershipTypeId INT,
			SubmittedByEducationOrganizationId INT,
			DOR INT
		)

	CREATE TABLE #roCnt
		(	FiscalYear INT,
			ResourceId uniqueidentifier,
			RecordOwnershipTypeId INT,
			SubmittedByEducationOrganizationId INT,
			DOR INT,
			RecordOwnershipRowCount INT
		)

	INSERT INTO #ssa
		(	
			FiscalYear,
			StudentUSI,
			SchoolId,
			EntryDate,
			EntryGradeLevelDescriptorId,
			ExitWithdrawDate,
			ExitWithdrawTypeDescriptorId,
			ClassOfSchoolYear,
			MembershipTypeDescriptorId,
			TrackEducationOrganizationId,
			CalendarCode,
			ELL,
			SPED,
			GradeLevelTypeId,
			SourceId
		)
	SELECT SP.[FiscalYear]
		, SP.[StudentUSI]
		, SP.[SchoolId]
		, SP.[EntryDate]
		, SP.[EntryGradeLevelDescriptorId]
		, SP.[ExitWithdrawDate]
		, SP.[ExitWithdrawTypeDescriptorId]
		, SP.[ClassOfSchoolYear]
		, SP.[MembershipTypeDescriptorId]
		, SP.[TrackEducationOrganizationId]
		, CASE SP.TrackNumber
			WHEN -2 THEN SP.CalendarCode
			ELSE CAST(SP.TrackNumber AS nvarchar(60))
		  END AS CalendarCode
		, PM.ELL
		, PM.SPED
		, GLT.GradeLevelTypeId
		, SourceId
	FROM [leadata].[StudentSchoolAssociation] SP
	INNER JOIN @StudentID PM ON SP.StudentUSI = PM.StudentID AND SP.SchoolId = PM.SchoolId
	INNER JOIN [entity].[GradeLevelType] GLT ON SP.EntryGradeLevelDescriptorId = GLT.GradeLevelDescriptorId
	WHERE SP.FiscalYear = @FY
	AND NOT EXISTS 
	(SELECT * FROM config.ExcludeExitWithdrawType w
		WHERE w.fiscalYear = sp.FiscalYear
		AND w.ExitWithdrawTypeDescriptorId = sp.ExitWithdrawTypeDescriptorId)
	AND NOT EXISTS
	(SELECT * FROM config.ExcludeMembershipType m
		WHERE m.FiscalYear = sp.FiscalYear
		AND m.MembershipTypeDescriptorId = sp.MembershipTypeDescriptorId)

	INSERT INTO #ro
		(	FiscalYear,
			ResourceId,
			RecordOwnershipTypeId,
			SubmittedByEducationOrganizationId,
			DOR
		)
		SELECT ro.FiscalYear,
			ro.ResourceId,
			ro.RecordOwnershipTypeId,
			ro.SubmittedByEducationOrganizationId,
			sEdOrg.EducationOrganizationId AS DOR
		FROM [leadata].[RecordOwnership] ro
			JOIN #ssa 
				ON ro.FiscalYear = #ssa.FiscalYear 
				AND #ssa.SourceId = ro.ResourceId
			LEFT OUTER JOIN [leadata].[StudentSchoolAssociationLocalEducationAgency] sEdOrg 
				ON sEdOrg.SchoolId = #ssa.SchoolId 
				AND sEdOrg.StudentUSI = #ssa.StudentUSI
				AND sEdOrg.FiscalYear = #ssa.FiscalYear
				AND sEdOrg.EntryDate = #ssa.EntryDate
		WHERE ro.RecordOwnerShipTypeId = 1 
			AND ro.FiscalYear = @FY


	;WITH cte AS
	(
		SELECT sub.fiscalYear, sub.resourceId, sub.recordOwnershipTypeId, Cnt, r2.SubmittedByEducationOrganizationId, dor,
				ROW_NUMBER() OVER (PARTITION BY sub.FiscalYear, sub.ResourceId, sub.RecordOwnershipTypeId ORDER BY sub.FiscalYear DESC) AS rn
		FROM 
		(select r.fiscalYear, r.resourceId, r.recordOwnershipTypeId, count(*) As Cnt
		from #ro r 
		group by r.fiscalYear, r.resourceId, r.recordOwnershipTypeId
		) as sub,
		#ro r2
		where sub.fiscalYear = r2.fiscalYear and sub.ResourceId = r2.ResourceId and sub.RecordOwnershipTypeId = r2.RecordOwnershipTypeId
	)

	INSERT INTO #roCnt
		(	FiscalYear,
			ResourceId,
			RecordOwnershipTypeId,
			SubmittedByEducationOrganizationId,
			DOR,
			RecordOwnershipRowCount
		)
		SELECT fiscalYear, resourceId, recordOwnershipTypeId, Cnt, SubmittedByEducationOrganizationId, dor
		FROM cte
		WHERE rn = 1

	SELECT #ssa.FiscalYear,
			StudentUSI,
			SchoolId,
			EntryDate,
			EntryGradeLevelDescriptorId,
			ExitWithdrawDate,
			ExitWithdrawTypeDescriptorId,
			ClassOfSchoolYear,
			MembershipTypeDescriptorId,
			TrackEducationOrganizationId,
			CalendarCode,
			ELL,
			SPED,
			GradeLevelTypeId,
			SourceId,
			CASE WHEN #roCnt.RecordOwnershipRowCount = 1 THEN #roCnt.SubmittedByEducationOrganizationId ELSE #roCnt.DOR END AS SubmittedByEducationOrganizationId
		FROM #ssa 
			JOIN #roCnt ON #roCnt.FiscalYear = #ssa.FiscalYear
						AND #roCnt.ResourceId = #ssa.SourceId


	drop table #ssa
	drop table #ro
	drop table #roCnt

END -- SP