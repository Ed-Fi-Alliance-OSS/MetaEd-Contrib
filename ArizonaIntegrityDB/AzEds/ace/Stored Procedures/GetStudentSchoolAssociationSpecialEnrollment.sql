-- =============================================
--	Author	    : Abhi Gopalpuria
--	Create date: 06/23/2015
--	Description: Procedure to extract StudentSchoolAssociationSpecialEnrollment
--			 data for ACE
--	Revision History:
--	Who					When		What
--	Viju				09/11/2015	Fixed bug that returns duplicate records
-- =============================================
CREATE PROCEDURE [ace].[GetStudentSchoolAssociationSpecialEnrollment]
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
		, SP.[EntryDate]
		, SP.[SpecialEnrollmentStartDate]
		, SP.[SpecialEnrollmentEndDate]
		, SP.[SpecialEnrollmentDescriptorId]
		, PM.ELL
		, PM.SPED
	FROM [leadata].[StudentSchoolAssociationSpecialEnrollment] SP
	INNER JOIN @StudentID PM ON SP.StudentUSI = PM.StudentID AND SP.SchoolId = PM.SchoolId
	--LEFT JOIN [leadata].[Descriptor] DIS1 ON SP.[SpecialEnrollmentDescriptorId] = DIS1.DescriptorId
	WHERE SP.FiscalYear = @FY
END -- SP


