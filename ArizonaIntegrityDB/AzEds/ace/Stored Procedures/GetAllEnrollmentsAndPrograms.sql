

-- =============================================
-- Author	    : Abhi Gopalpuria
-- Create date: 06/23/2015
-- Description: Procedure to extract ALL data for ACE
-- =============================================
CREATE PROCEDURE [ace].[GetAllEnrollmentsAndPrograms]
	-- Add the parameters for the stored procedure here
	@StudentID [ace].[ISStudentEnrollment] READONLY,
	@FY INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	-- Insert statements for procedure here
	EXEC ace.GetStudent @StudentID
	EXEC ace.GetStudentSchoolAssociation @StudentID, @FY
	EXEC ace.GetStudentProgramAssociation @StudentID, @FY
	EXEC ace.GetStudentEdOrgAssociation @StudentID, @FY
	EXEC ace.GetStudentSchoolAssociationTuitionPayer @StudentID, @FY
	EXEC ace.GetStudentSchoolAssocationMembershipFTE @StudentID, @FY
	EXEC ace.GetStudentSchoolAssociationSpecialEnrollment @StudentID, @FY
	EXEC ace.GetStudentSpecialEducationProgramAssociation @StudentID, @FY
	EXEC ace.GetStudentSchoolAttendanceEvent @StudentID, @FY
	EXEC ace.GetStudentNeed @StudentID, @FY

END -- SP


GO
