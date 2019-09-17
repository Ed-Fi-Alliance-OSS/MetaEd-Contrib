
-- =============================================
-- Author	    : Abhi Gopalpuria
-- Create date: 06/22/2015
-- Description: Procedure to extract Students data for ACE
-- =============================================
CREATE PROCEDURE [ace].[GetStudent]
	-- Add the parameters for the stored procedure here
	@StudentID [ace].[ISStudentEnrollment] READONLY
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	SELECT DISTINCT StudentUSI
		, FirstName
		, MiddleName
		, LastSurname LastName
		, BirthDate
	FROM leadata.Student Stu
	INNER JOIN @StudentID Par ON Stu.StudentUSI = Par.StudentID
END -- SP



GO
