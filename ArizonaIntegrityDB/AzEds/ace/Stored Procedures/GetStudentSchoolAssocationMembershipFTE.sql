-- =============================================
-- Author	    : Abhi Gopalpuria
-- Create date: 06/23/2015
-- Description: Procedure to extract StudentSchoolAssocatonMembersipFTE
--			 data for ACE
--	Revision History:
--	Who					When		What
--	Viju				09/16/2015	Fixed bug that returns duplicate records
-- =============================================
CREATE PROCEDURE [ace].[GetStudentSchoolAssocationMembershipFTE]
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
		, SP.[FTEStartDate]
		, SP.[FTEEndDate]
		, SP.[MembershipFTEDescriptorId]
		, DIS1.CodeValue AS MembershipFTEDescriptorCodeValue
		, PM.ELL
		, PM.SPED
	FROM [leadata].[StudentSchoolAssociationMembershipFTE] SP
	INNER JOIN @StudentID PM ON SP.StudentUSI = PM.StudentID AND SP.SchoolId = PM.SchoolId
	INNER JOIN [leadata].[Descriptor] DIS1 ON SP.[MembershipFTEDescriptorId] = DIS1.DescriptorId
		AND SP.FiscalYear = DIS1.FiscalYear
	WHERE SP.FiscalYear = @FY
END -- SP