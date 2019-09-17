-- =============================================
-- Author	    : Abhi Gopalpuria
-- Create date: 06/25/2015
-- Description: Procedure to extract StudentSpecialEducationProgramAssociation
--			 data for ACE
-- 
--Revision History:
--	Who					When		What
--	Viju Viswanathan	05/17/2016	Removed duplicate join 
-- =============================================
CREATE PROCEDURE [ace].[GetStudentSpecialEducationProgramAssociation]
	-- Add the parameters for the stored procedure here
	@StudentID ace.ISStudentEnrollment READONLY
	, @FY INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	SELECT SP.[FiscalYear]
		, SP.[StudentUSI]
		, SP.[ProgramTypeId]
		, SP.[ProgramName]
		, SP.[ProgramEducationOrganizationId]
		, SP.[BeginDate]
		, SP.[SpecialEducationSettingDescriptorId]
		, SP.[EducationOrganizationId]
		, SP.[MainSPEDSchool]
		, PM.ELL
		, PM.SPED
	FROM [leadata].[StudentSpecialEducationProgramAssociation] SP
	INNER JOIN @StudentID PM ON SP.StudentUSI = PM.StudentID 
		AND SP.EducationOrganizationId = PM.SchoolID
	WHERE SP.FiscalYear = @FY
END -- SP