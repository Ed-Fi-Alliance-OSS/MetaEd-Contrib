-- =============================================
-- Author	    : Abhi Gopalpuria
-- Create date: 06/25/2015
-- Description: Procedure to extract StudentSchoolAttendanceEvent
--			 data for ACE
--Revision History:
--	Who					When		What
--	Viju Viswanathan	10/16/2015	Modifed JOIN to fix bug that 
--									returned duplicate records
--  Viju Viswanathan	10/22/2015	Modifed INNER JOIN to LEFT OUTER
-- =============================================
CREATE PROCEDURE [ace].[GetStudentSchoolAttendanceEvent]
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
		, SP.[SchoolId]
		, SP.[EventDate]
		, SP.[AttendanceEventCategoryDescriptorId]
		, SP.[AbsenceAmountDescriptorId]
		, DIS1.CodeValue AS AbsenceAmountDescriptorCodeValue
		, SP.[InstructionalMinutes]
		, PM.ELL
		, PM.SPED
	FROM [leadata].[StudentSchoolAttendanceEvent] SP
	INNER JOIN @StudentID PM ON SP.StudentUSI = PM.StudentID AND SP.SchoolId = PM.SchoolID
	LEFT OUTER JOIN [leadata].[Descriptor] DIS1 ON SP.[AbsenceAmountDescriptorId] = DIS1.DescriptorId
		AND SP.[FiscalYear] = DIS1.[FiscalYear]
	WHERE SP.FiscalYear = @FY
END -- SP