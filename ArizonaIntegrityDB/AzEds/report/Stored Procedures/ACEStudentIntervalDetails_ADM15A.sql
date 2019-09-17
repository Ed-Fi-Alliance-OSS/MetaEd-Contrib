
/**************************************************************************************************************************
**Procedure Name:
**      report.ACEStudentIntervalDetails_ADM15A
**
**Author:
**      Harsha Kankanala
**
**Description:  
**  returns student detail information based on DOA or DOR filtered by Grade and School
**  Additionally, it is filtered by Fiscal Year. 
**   
**Input:
    @LEA			
	@SchoolsList	
	@ExecutionId    
	@District       
	@GradeList      
**
**Output:
**  None
**
**Returns:
**	@@Error
**

**
**Revision History:
**	Harsha Kankanala	11/28/2018	Initial creation
**  Harsha Kankanala	04/03/2019		Changed the query to fetch Calendar Code
**  Harsha Kankanala    05/01/2019    Added No Locks to Stored Proc
**************************************************************************************************************************/
CREATE PROC [report].[ACEStudentIntervalDetails_ADM15A] --4235,'78917,4984,4983,4980,4982,4981,4979,78932,78930,4975,4974,4957,4954,4946,4977,4951,4924,91812,4955,4916,4918,4921,4940,79490,4925,4915,90753,4927,79807,4960,4936,79225,4941,4959,4919,6229,4945,4917,4943,4973,4971,4931,4947,4933,492,4938,4922,89593,4930,4926,90752,4952,4937,4953,4920,4969,4929,79489,4958,4956,4913,4939,4967,4935,4934,78938,4932,4949,4944,4962,4948,4923,4970,4961,90303,92351,79687,80046',2853,'ALL','9,4,7,10,3,6,12,0,11,8,5,1,-1,2'
	@LEA			INT,
	@SchoolsList	NVARCHAR(max), -- Must be a comma seperated list of all the schools
	@ExecutionId    INT,
	@District       VARCHAR(100),
	@GradeList      NVARCHAR(max) -- Must be a comma seperated list of grades
AS

SET NOCOUNT ON  


Declare @FiscalYear Int = (Select FiscalYear from process.Execution where ExecutionId = @ExecutionId)

DECLARE @Schools TABLE 
(
	[SchoolId] int
)

-- Turn the list of schools into a table
INSERT INTO @Schools
SELECT DISTINCT 
	[Token] 
FROM 
	[util].[Split](@SchoolsList, ',') 

DECLARE @Grades TABLE 
(
	[Gradeleveltypeid] int
)

-- Turn the list of schools into a table
INSERT INTO @Grades
SELECT DISTINCT 
	[Token] 
FROM 
	[util].[Split](@GradeList, ',') 

IF (@District = 'of Residence')
BEGIN
-- Run the main query
SELECT 
	mi.[ExecutionId]
	, adm.Description AS ADMType
	, mi.[FiscalYear]
	, CONVERT(VARCHAR(10),DATEADD("hh", -7, eIntgy.InitiatedDateTime),101) + ' ' + RIGHT(CONVERT(VARCHAR(30),DATEADD("hh", -7, eIntgy.InitiatedDateTime),100),7) AS 'DataCaptureDate'
	--, eIntgy.InitiatedDateTime AS DataCaptureDate
	, [ResidentEducationOrganizationId]
	, eoR.NameOfInstitution AS DOR_Name
	, [AttendingLocalEducationAgencyId]
	, eoA.NameOfInstitution AS DOA_Name
	, mi.[SchoolId]
	, eoS.NameOfInstitution AS SchoolName
	, at.Description AS AggregationTypeName
	, s.StudentUniqueId
	, s.LastSurname
	, s.FirstName
	, CONVERT(date, s.BirthDate) AS BirthDate
	, dMT.Description AS MembershipTypeDescriptorName
	, dSED.Description SpecialEnrollmentDescriptorName
	, dGrade.CodeValue as GradeName
	, mi.[TrackNumber]
	, [StudentSchoolAssociationEntryDate]
	, ssa.ExitWithdrawDate 
	, rp.Description AS ReportingPeriodName
	, [IsHomeBound]
	, CASE ft.IsFundable 
		WHEN 1 Then 'Fundable' 
		ELSE 'Non-Fundable' 
	  END AS Fundability
	, ft.Description AS FundingTypeName
	, [MembershipIntervalStartDate]
	, [MembershipIntervalEndDate]
	, [UnadjustedDaysEnrolled]
	, dFTE.CodeValue AS MembershipFTEDescriptorValue
	, [UnadjustedMembershipDays]
	, [UnadjustedAverageDailyMembership]
	, [YearEndUnadjustedADM]
	, [LimitedAverageDailyMembership]
	, [YearEndAdjustedADM]
	, [IsConcurrentForLimiting]
	, [UnadjustedAbsenceDays]
	, [UnadjustedAverageDailyAttendance]
	, [SPEDSupportLevelWeight]
	,LimitedMembershipDays
	,LimitedAbsenceDays
	,mi.CalendarCode
FROM 
	(select * from [ace].[MembershipInterval] (NOLOCK)
	where ExecutionId = @ExecutionId and  ResidentEducationOrganizationId = @LEA and FiscalYear = @FiscalYear ) mi
	INNER JOIN @Schools Sch ON
		(	
			
			
		 mi.SchoolId = Sch.SchoolId
		)
	INNER JOIN process.Execution (NOLOCK) e  ON 
		(mi.ExecutionId = e.ExecutionId)
	INNER JOIN process.Execution (NOLOCK) eIntgy ON 
		(e.ReferenceExecutionId = eIntgy.ExecutionId)
	INNER JOIN [entity].[GradeLevelType] (NOLOCK) dGrade ON 
            (
                    mi.GradeLevelTypeId = dGrade.GradeLevelTypeId
            )
	INNER JOIN @Grades AS G ON G.Gradeleveltypeid = dGrade.GradeLevelTypeId
	LEFT OUTER JOIN leadata.StudentSchoolAssociation (NOLOCK) ssa ON 
		(
			mi.FiscalYear = ssa.FiscalYear
			AND mi.StudentUSI = ssa.StudentUSI
			AND mi.SchoolId = ssa.SchoolId
			AND mi.StudentSchoolAssociationEntryDate = ssa.EntryDate
		)
	LEFT OUTER JOIN entity.EducationOrganization (NOLOCK) eoR ON 
		(
			mi.ResidentEducationOrganizationId = eoR.EducationOrganizationId
			AND mi.FiscalYear = eoR.FiscalYear
		)
  	LEFT OUTER JOIN entity.EducationOrganization (NOLOCK) eoA ON 
		(
			mi.AttendingLocalEducationAgencyId = eoA.EducationOrganizationId
			AND mi.FiscalYear = eoA.FiscalYear
		)
	LEFT OUTER JOIN entity.EducationOrganization (NOLOCK) eoS ON 
		(
			mi.SchoolId = eoS.EducationOrganizationId
			AND mi.FiscalYear = eoS.FiscalYear
		)
	LEFT OUTER JOIN leadata.Student (NOLOCK) s ON 
		(mi.StudentUSI = s.StudentUSI)
	LEFT OUTER JOIN ace.FundingType (NOLOCK) ft ON 
		(mi.FundingTypeId = ft.FundingTypeId)
	LEFT OUTER JOIN ace.ADMType (NOLOCK) adm ON 
		(mi.ADMTypeId = adm.ADMTypeId)
	LEFT OUTER JOIN leadata.Descriptor (NOLOCK) dSED ON 
		(
			mi.SpecialEnrollmentDescriptorId = dSED.DescriptorId
			AND mi.FiscalYear = dSED.FiscalYear
		)
	LEFT OUTER JOIN leadata.Descriptor (NOLOCK) dMT ON 
		(
			ssa.MembershipTypeDescriptorId = dMT.DescriptorId
			AND mi.FiscalYear = dMT.FiscalYear
		)
	LEFT OUTER JOIN leadata.Descriptor (NOLOCK) dFTE ON 
		(
			mi.MembershipFTEDescriptorId = dFTE.DescriptorId
			AND mi.FiscalYear = dFTE.FiscalYear
		)
	LEFT OUTER JOIN ace.AggregationType (NOLOCK) at ON 
		(mi.AggregationTypeId = at.AggregationTypeId)
	LEFT OUTER JOIN config.ReportingPeriod (NOLOCK) rp ON 
		(
			mi.ReportingPeriodId = rp.ReportingPeriodId
			AND mi.FiscalYear = rp.FiscalYear
		)

ORDER BY 
	eoS.NameOfInstitution
	, mi.[GradeLevelTypeId]
	, s.LastSurname
	, s.FirstName
	, s.StudentUniqueID
	, mi.[ReportingPeriodId] 
	, [MembershipIntervalStartDate]

END

ELSE IF (@District = 'of Attendance')
BEGIN

SELECT 
	mi.[ExecutionId]
	, adm.Description AS ADMType
	, mi.[FiscalYear]
	, CONVERT(VARCHAR(10),DATEADD("hh", -7, eIntgy.InitiatedDateTime),101) + ' ' + RIGHT(CONVERT(VARCHAR(30),DATEADD("hh", -7, eIntgy.InitiatedDateTime),100),7) AS 'DataCaptureDate'
	--, eIntgy.InitiatedDateTime AS DataCaptureDate
	, [ResidentEducationOrganizationId]
	, eoR.NameOfInstitution AS DOR_Name
	, [AttendingLocalEducationAgencyId]
	, eoA.NameOfInstitution AS DOA_Name
	, mi.[SchoolId]
	, eoS.NameOfInstitution AS SchoolName
	, at.Description AS AggregationTypeName
	, s.StudentUniqueId
	, s.LastSurname
	, s.FirstName
	, CONVERT(date, s.BirthDate) AS BirthDate
	, dMT.Description AS MembershipTypeDescriptorName
	, dSED.Description SpecialEnrollmentDescriptorName
	, dGrade.CodeValue as GradeName
	, mi.[TrackNumber]
	, [StudentSchoolAssociationEntryDate]
	, ssa.ExitWithdrawDate 
	, rp.Description AS ReportingPeriodName
	, [IsHomeBound]
	, CASE ft.IsFundable 
		WHEN 1 Then 'Fundable' 
		ELSE 'Non-Fundable' 
	  END AS Fundability
	, ft.Description AS FundingTypeName
	, [MembershipIntervalStartDate]
	, [MembershipIntervalEndDate]
	, [UnadjustedDaysEnrolled]
	, dFTE.CodeValue AS MembershipFTEDescriptorValue
	, [UnadjustedMembershipDays]
	, [UnadjustedAverageDailyMembership]
	, [YearEndUnadjustedADM]
	, [LimitedAverageDailyMembership]
	, [YearEndAdjustedADM]
	, [IsConcurrentForLimiting]
	, [UnadjustedAbsenceDays]
	, [UnadjustedAverageDailyAttendance]
	, [SPEDSupportLevelWeight]
	,LimitedMembershipDays
	,LimitedAbsenceDays
	,mi.CalendarCode
FROM 
	(select * from [ace].[MembershipInterval] (NOLOCK) where ExecutionId = @ExecutionId and  AttendingLocalEducationAgencyId = @LEA and FiscalYear = @FiscalYear) mi
	INNER JOIN @Schools Sch ON
		(	
			
			
			 mi.SchoolId = Sch.SchoolId
		)
	INNER JOIN process.Execution (NOLOCK) e  ON 
		(mi.ExecutionId = e.ExecutionId)
	INNER JOIN process.Execution (NOLOCK) eIntgy ON 
		(e.ReferenceExecutionId = eIntgy.ExecutionId)
	INNER JOIN [entity].[GradeLevelType] (NOLOCK) dGrade ON 
            (
                    mi.GradeLevelTypeId = dGrade.GradeLevelTypeId
            )
	INNER JOIN @Grades AS G ON G.Gradeleveltypeid = dGrade.GradeLevelTypeId
	LEFT OUTER JOIN leadata.StudentSchoolAssociation (NOLOCK) ssa ON 
		(
			mi.FiscalYear = ssa.FiscalYear
			AND mi.StudentUSI = ssa.StudentUSI
			AND mi.SchoolId = ssa.SchoolId
			AND mi.StudentSchoolAssociationEntryDate = ssa.EntryDate
		)
	LEFT OUTER JOIN entity.EducationOrganization (NOLOCK) eoR ON 
		(
			mi.ResidentEducationOrganizationId = eoR.EducationOrganizationId
			AND mi.FiscalYear = eoR.FiscalYear
		)
  	LEFT OUTER JOIN entity.EducationOrganization (NOLOCK) eoA ON 
		(
			mi.AttendingLocalEducationAgencyId = eoA.EducationOrganizationId
			AND mi.FiscalYear = eoA.FiscalYear
		)
	LEFT OUTER JOIN entity.EducationOrganization (NOLOCK) eoS ON 
		(
			mi.SchoolId = eoS.EducationOrganizationId
			AND mi.FiscalYear = eoS.FiscalYear
		)
	LEFT OUTER JOIN leadata.Student (NOLOCK) s ON 
		(mi.StudentUSI = s.StudentUSI)
	LEFT OUTER JOIN ace.FundingType (NOLOCK) ft ON 
		(mi.FundingTypeId = ft.FundingTypeId)
	LEFT OUTER JOIN ace.ADMType (NOLOCK) adm ON 
		(mi.ADMTypeId = adm.ADMTypeId)
	LEFT OUTER JOIN leadata.Descriptor (NOLOCK) dSED ON 
		(
			mi.SpecialEnrollmentDescriptorId = dSED.DescriptorId
			AND mi.FiscalYear = dSED.FiscalYear
		)
	LEFT OUTER JOIN leadata.Descriptor (NOLOCK) dMT ON 
		(
			ssa.MembershipTypeDescriptorId = dMT.DescriptorId
			AND mi.FiscalYear = dMT.FiscalYear
		)
	LEFT OUTER JOIN leadata.Descriptor (NOLOCK) dFTE ON 
		(
			mi.MembershipFTEDescriptorId = dFTE.DescriptorId
			AND mi.FiscalYear = dFTE.FiscalYear
		)
	LEFT OUTER JOIN ace.AggregationType (NOLOCK) at ON 
		(mi.AggregationTypeId = at.AggregationTypeId)
	LEFT OUTER JOIN config.ReportingPeriod (NOLOCK) rp ON 
		(
			mi.ReportingPeriodId = rp.ReportingPeriodId
			AND mi.FiscalYear = rp.FiscalYear
		)

ORDER BY 
	eoS.NameOfInstitution
	, mi.[GradeLevelTypeId]
	, s.LastSurname
	, s.FirstName
	, s.StudentUniqueID
	, mi.[ReportingPeriodId] 
	, [MembershipIntervalStartDate]

END
ELSE IF (@District = 'Submitted')
BEGIN

SELECT 
	mi.[ExecutionId]
	, adm.Description AS ADMType
	, mi.[FiscalYear]
	, CONVERT(VARCHAR(10),DATEADD("hh", -7, eIntgy.InitiatedDateTime),101) + ' ' + RIGHT(CONVERT(VARCHAR(30),DATEADD("hh", -7, eIntgy.InitiatedDateTime),100),7) AS 'DataCaptureDate'
	--, eIntgy.InitiatedDateTime AS DataCaptureDate
	, [ResidentEducationOrganizationId]
	, eoR.NameOfInstitution AS DOR_Name
	, [AttendingLocalEducationAgencyId]
	, eoA.NameOfInstitution AS DOA_Name
	, mi.[SchoolId]
	, eoS.NameOfInstitution AS SchoolName
	, at.Description AS AggregationTypeName
	, s.StudentUniqueId
	, s.LastSurname
	, s.FirstName
	, CONVERT(date, s.BirthDate) AS BirthDate
	, dMT.Description AS MembershipTypeDescriptorName
	, dSED.Description SpecialEnrollmentDescriptorName
	, dGrade.CodeValue as GradeName
	, mi.[TrackNumber]
	, [StudentSchoolAssociationEntryDate]
	, ssa.ExitWithdrawDate 
	, rp.Description AS ReportingPeriodName
	, [IsHomeBound]
	, CASE ft.IsFundable 
		WHEN 1 Then 'Fundable' 
		ELSE 'Non-Fundable' 
	  END AS Fundability
	, ft.Description AS FundingTypeName
	, [MembershipIntervalStartDate]
	, [MembershipIntervalEndDate]
	, [UnadjustedDaysEnrolled]
	, dFTE.CodeValue AS MembershipFTEDescriptorValue
	, [UnadjustedMembershipDays]
	, [UnadjustedAverageDailyMembership]
	, [YearEndUnadjustedADM]
	, [LimitedAverageDailyMembership]
	, [YearEndAdjustedADM]
	, [IsConcurrentForLimiting]
	, [UnadjustedAbsenceDays]
	, [UnadjustedAverageDailyAttendance]
	, [SPEDSupportLevelWeight]
	,LimitedMembershipDays
	,LimitedAbsenceDays
	,mi.CalendarCode
FROM 
	(select * from [ace].[MembershipInterval] (NOLOCK) where ExecutionId = @ExecutionId 
			AND SubmittedByEducationOrganizationId = @LEA and FiscalYear = @FiscalYear) mi
	INNER JOIN @Schools Sch ON
		(	
			
			 mi.SchoolId = Sch.SchoolId
		)
	INNER JOIN process.Execution (NOLOCK) e  ON 
		(mi.ExecutionId = e.ExecutionId)
	INNER JOIN process.Execution (NOLOCK) eIntgy ON 
		(e.ReferenceExecutionId = eIntgy.ExecutionId)
	INNER JOIN [entity].[GradeLevelType] (NOLOCK)dGrade ON 
            (
                    mi.GradeLevelTypeId = dGrade.GradeLevelTypeId
            )
	INNER JOIN @Grades AS G ON G.Gradeleveltypeid = dGrade.GradeLevelTypeId
	LEFT OUTER JOIN leadata.StudentSchoolAssociation (NOLOCK) ssa ON 
		(
			mi.FiscalYear = ssa.FiscalYear
			AND mi.StudentUSI = ssa.StudentUSI
			AND mi.SchoolId = ssa.SchoolId
			AND mi.StudentSchoolAssociationEntryDate = ssa.EntryDate
		)
	LEFT OUTER JOIN entity.EducationOrganization (NOLOCK) eoR ON 
		(
			mi.ResidentEducationOrganizationId = eoR.EducationOrganizationId
			AND mi.FiscalYear = eoR.FiscalYear
		)
  	LEFT OUTER JOIN entity.EducationOrganization (NOLOCK) eoA ON 
		(
			mi.AttendingLocalEducationAgencyId = eoA.EducationOrganizationId
			AND mi.FiscalYear = eoA.FiscalYear
		)
	LEFT OUTER JOIN entity.EducationOrganization  (NOLOCK)eoS ON 
		(
			mi.SchoolId = eoS.EducationOrganizationId
			AND mi.FiscalYear = eoS.FiscalYear
		)
	LEFT OUTER JOIN leadata.Student (NOLOCK) s ON 
		(mi.StudentUSI = s.StudentUSI)
	LEFT OUTER JOIN ace.FundingType (NOLOCK)ft ON 
		(mi.FundingTypeId = ft.FundingTypeId)
	LEFT OUTER JOIN ace.ADMType (NOLOCK) adm ON 
		(mi.ADMTypeId = adm.ADMTypeId)
	LEFT OUTER JOIN leadata.Descriptor (NOLOCK) dSED ON 
		(
			mi.SpecialEnrollmentDescriptorId = dSED.DescriptorId
			AND mi.FiscalYear = dSED.FiscalYear
		)
	LEFT OUTER JOIN leadata.Descriptor (NOLOCK) dMT ON 
		(
			ssa.MembershipTypeDescriptorId = dMT.DescriptorId
			AND mi.FiscalYear = dMT.FiscalYear
		)
	LEFT OUTER JOIN leadata.Descriptor (NOLOCK) dFTE ON 
		(
			mi.MembershipFTEDescriptorId = dFTE.DescriptorId
			AND mi.FiscalYear = dFTE.FiscalYear
		)
	LEFT OUTER JOIN ace.AggregationType (NOLOCK) at ON 
		(mi.AggregationTypeId = at.AggregationTypeId)
	LEFT OUTER JOIN config.ReportingPeriod (NOLOCK) rp ON 
		(
			mi.ReportingPeriodId = rp.ReportingPeriodId
			AND mi.FiscalYear = rp.FiscalYear
		)

ORDER BY 
	eoS.NameOfInstitution
	, mi.[GradeLevelTypeId]
	, s.LastSurname
	, s.FirstName
	, s.StudentUniqueID
	, mi.[ReportingPeriodId] 
	, [MembershipIntervalStartDate]

END

ELSE 
BEGIN

SELECT 
	mi.[ExecutionId]
	, adm.Description AS ADMType
	, mi.[FiscalYear]
	, CONVERT(VARCHAR(10),DATEADD("hh", -7, eIntgy.InitiatedDateTime),101) + ' ' + RIGHT(CONVERT(VARCHAR(30),DATEADD("hh", -7, eIntgy.InitiatedDateTime),100),7) AS 'DataCaptureDate'
	--, eIntgy.InitiatedDateTime AS DataCaptureDate
	, [ResidentEducationOrganizationId]
	, eoR.NameOfInstitution AS DOR_Name
	, [AttendingLocalEducationAgencyId]
	, eoA.NameOfInstitution AS DOA_Name
	, mi.[SchoolId]
	, eoS.NameOfInstitution AS SchoolName
	, at.Description AS AggregationTypeName
	, s.StudentUniqueId
	, s.LastSurname
	, s.FirstName
	, CONVERT(date, s.BirthDate) AS BirthDate
	, dMT.Description AS MembershipTypeDescriptorName
	, dSED.Description SpecialEnrollmentDescriptorName
	, dGrade.CodeValue as GradeName
	, mi.[TrackNumber]
	, [StudentSchoolAssociationEntryDate]
	, ssa.ExitWithdrawDate 
	, rp.Description AS ReportingPeriodName
	, [IsHomeBound]
	, CASE ft.IsFundable 
		WHEN 1 Then 'Fundable' 
		ELSE 'Non-Fundable' 
	  END AS Fundability
	, ft.Description AS FundingTypeName
	, [MembershipIntervalStartDate]
	, [MembershipIntervalEndDate]
	, [UnadjustedDaysEnrolled]
	, dFTE.CodeValue AS MembershipFTEDescriptorValue
	, [UnadjustedMembershipDays]
	, [UnadjustedAverageDailyMembership]
	, [YearEndUnadjustedADM]
	, [LimitedAverageDailyMembership]
	, [YearEndAdjustedADM]
	, [IsConcurrentForLimiting]
	, [UnadjustedAbsenceDays]
	, [UnadjustedAverageDailyAttendance]
	, [SPEDSupportLevelWeight]
	,LimitedMembershipDays
	,LimitedAbsenceDays
    ,mi.CalendarCode
FROM 
	(select * from [ace].[MembershipInterval] (NOLOCK) where
	 ExecutionId = @ExecutionId AND (SubmittedByEducationOrganizationId = @LEA 
	 OR AttendingLocalEducationAgencyId = @LEA OR ResidentEducationOrganizationId = @LEA) and FiscalYear = @FiscalYear)  mi
	INNER JOIN @Schools Sch ON
		(	
			 
			
			 mi.SchoolId = Sch.SchoolId
		)
	INNER JOIN process.Execution (NOLOCK) e  ON 
		(mi.ExecutionId = e.ExecutionId)
	INNER JOIN process.Execution (NOLOCK) eIntgy ON 
		(e.ReferenceExecutionId = eIntgy.ExecutionId)
	INNER JOIN [entity].[GradeLevelType] (NOLOCK) dGrade ON 
            (
                    mi.GradeLevelTypeId = dGrade.GradeLevelTypeId
            )
	INNER JOIN @Grades AS G ON G.Gradeleveltypeid = dGrade.GradeLevelTypeId
	LEFT OUTER JOIN leadata.StudentSchoolAssociation (NOLOCK) ssa ON 
		(
			mi.FiscalYear = ssa.FiscalYear
			AND mi.StudentUSI = ssa.StudentUSI
			AND mi.SchoolId = ssa.SchoolId
			AND mi.StudentSchoolAssociationEntryDate = ssa.EntryDate
		)
	LEFT OUTER JOIN entity.EducationOrganization (NOLOCK) eoR ON 
		(
			mi.ResidentEducationOrganizationId = eoR.EducationOrganizationId
			AND mi.FiscalYear = eoR.FiscalYear
		)
  	LEFT OUTER JOIN entity.EducationOrganization (NOLOCK) eoA ON 
		(
			mi.AttendingLocalEducationAgencyId = eoA.EducationOrganizationId
			AND mi.FiscalYear = eoA.FiscalYear
		)
	LEFT OUTER JOIN entity.EducationOrganization (NOLOCK) eoS ON 
		(
			mi.SchoolId = eoS.EducationOrganizationId
			AND mi.FiscalYear = eoS.FiscalYear
		)
	LEFT OUTER JOIN leadata.Student (NOLOCK) s ON 
		(mi.StudentUSI = s.StudentUSI)
	LEFT OUTER JOIN ace.FundingType (NOLOCK) ft ON 
		(mi.FundingTypeId = ft.FundingTypeId)
	LEFT OUTER JOIN ace.ADMType (NOLOCK) adm ON 
		(mi.ADMTypeId = adm.ADMTypeId)
	LEFT OUTER JOIN leadata.Descriptor (NOLOCK) dSED ON 
		(
			mi.SpecialEnrollmentDescriptorId = dSED.DescriptorId
			AND mi.FiscalYear = dSED.FiscalYear
		)
	LEFT OUTER JOIN leadata.Descriptor (NOLOCK) dMT ON 
		(
			ssa.MembershipTypeDescriptorId = dMT.DescriptorId
			AND mi.FiscalYear = dMT.FiscalYear
		)
	LEFT OUTER JOIN leadata.Descriptor (NOLOCK) dFTE ON 
		(
			mi.MembershipFTEDescriptorId = dFTE.DescriptorId
			AND mi.FiscalYear = dFTE.FiscalYear
		)
	LEFT OUTER JOIN ace.AggregationType (NOLOCK) at ON 
		(mi.AggregationTypeId = at.AggregationTypeId)
	LEFT OUTER JOIN config.ReportingPeriod (NOLOCK) rp ON 
		(
			mi.ReportingPeriodId = rp.ReportingPeriodId
			AND mi.FiscalYear = rp.FiscalYear
		)

ORDER BY 
	eoS.NameOfInstitution
	, mi.[GradeLevelTypeId]
	, s.LastSurname
	, s.FirstName
	, s.StudentUniqueID
	, mi.[ReportingPeriodId] 
	, [MembershipIntervalStartDate]


END

GO


