-- =============================================
-- Author	    : Abhi Gopalpuria
-- Create date: 06/23/2015
-- Description: Procedure to extract StudentProgramAssociation
--			 data for ACE
-- Revision History:
--	Who					When		What
--	Viju				10/14/2015	Modified the join
-- =============================================
CREATE PROCEDURE [ace].[GetStudentProgramAssociation]
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
		, SP.[EndDate]
		, SP.[EducationOrganizationId]
		, PM.ELL
		, PM.SPED
	FROM [leadata].[StudentProgramAssociation] SP
	INNER JOIN @StudentID PM ON SP.StudentUSI = PM.StudentID AND SP.EducationOrganizationId = PM.SchoolID
	WHERE SP.[FiscalYear] = @FY
END -- SP