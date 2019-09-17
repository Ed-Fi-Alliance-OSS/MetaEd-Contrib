﻿CREATE TABLE [leadata].[CourseTranscript] (
	[FiscalYear]					INT				 NOT NULL,
    [StudentUSI]                    INT              NOT NULL,
    [SchoolYear]                    SMALLINT         NOT NULL,
    [TermTypeId]                    INT              NOT NULL,
    [CourseEducationOrganizationId] INT              NOT NULL,
    [EducationOrganizationId]       INT              NOT NULL,
    [CourseCode]                    NVARCHAR (60)    NOT NULL,
    [CourseAttemptResultTypeId]     INT              NOT NULL,
	[CourseAttemptResultTypeCodeValue] NVARCHAR(50)	 NOT NULL,
	[CourseAttemptResultTypeDescription] NVARCHAR(1024)	 NOT NULL,
    [AttemptedCreditTypeId]         INT              NULL,
	[AttemptedCreditTypeCodeValue]     NVARCHAR(50)	 NULL,
	[AttemptedCreditTypeDescription]   NVARCHAR(1024) NULL,
    [AttemptedCreditConversion]     DECIMAL (9, 2)   NULL,
    [AttemptedCredit]               DECIMAL (9, 2)   NULL,
    [EarnedCreditTypeId]            INT              NULL,
	[EarnedCreditTypeCodeValue]     NVARCHAR(50)     NULL,
	[EarnedCreditTypeDescription]   NVARCHAR(1024)   NULL,
    [EarnedCreditConversion]        DECIMAL (9, 2)   NULL,
    [EarnedCredit]                  DECIMAL (9, 2)   NOT NULL,
    [GradeLevelDescriptorId]        INT              NULL,
	[GradeLevelDescriptor]      NVARCHAR(50)         NULL,
    [MethodCreditEarnedTypeId]      INT              NULL,
	[MethodCreditEarnedTypeCodeValue]   NVARCHAR(50) NULL,
	[MethodCreditEarnedTypeDescription] NVARCHAR(1024) NULL,
    [FinalLetterGradeEarned]        NVARCHAR (20)    NULL,
    [FinalNumericGradeEarned]       INT              NULL,
    [CourseRepeatCodeTypeId]        INT              NULL,
	[CourseRepeatCodeTypeCodeValue]     NVARCHAR(50) NULL,
	[CourseRepeatCodeTypeDescription]   NVARCHAR(1024) NULL,
    [SchoolId]                      INT              NULL,
    [CourseTitle]                   NVARCHAR (60)    NULL,
    [LocalCourseCode]               NVARCHAR (60)    NULL,
    [LocalCourseTitle]              NVARCHAR (60)    NULL,
	[ExternalEducationOrganizationId] INT			 NULL,
    [SourceId]                      UNIQUEIDENTIFIER NOT NULL,
    [SourceLastModifiedDate]        DATETIME       NOT NULL,
    [SourceCreateDate]              DATETIME        NOT NULL,
	[LoadDate]  DATETIME    CONSTRAINT [CourseTranscript_DF_LoadDate] DEFAULT (GETUTCDATE()) NOT NULL,
	[HashValue]				[binary](64)	  CONSTRAINT [CourseTranscript_DF_HashValue] DEFAULT (00) NOT NULL,
	CONSTRAINT [PK_CourseTranscript] PRIMARY KEY CLUSTERED ([FiscalYear] ASC, [StudentUSI] ASC, [SchoolYear] ASC, [TermTypeId] ASC, [CourseEducationOrganizationId] ASC, [EducationOrganizationId] ASC, [CourseCode] ASC, [CourseAttemptResultTypeId] ASC),
    --CONSTRAINT [FK_CourseTranscript_CourseAttemptResultType_CourseAttemptResultTypeId] FOREIGN KEY ([CourseAttemptResultTypeId]) REFERENCES [edfi].[CourseAttemptResultType] ([CourseAttemptResultTypeId]),
    --CONSTRAINT [FK_CourseTranscript_CourseRepeatCodeType_CourseRepeatCodeTypeId] FOREIGN KEY ([CourseRepeatCodeTypeId]) REFERENCES [edfi].[CourseRepeatCodeType] ([CourseRepeatCodeTypeId]),
    --CONSTRAINT [FK_CourseTranscript_CreditType_AttemptedCreditTypeId] FOREIGN KEY ([AttemptedCreditTypeId]) REFERENCES [edfi].[CreditType] ([CreditTypeId]),
    --CONSTRAINT [FK_CourseTranscript_CreditType_EarnedCreditTypeId] FOREIGN KEY ([EarnedCreditTypeId]) REFERENCES [edfi].[CreditType] ([CreditTypeId]),
    --CONSTRAINT [FK_CourseTranscript_GradeLevelDescriptorId] FOREIGN KEY ([GradeLevelDescriptorId]) REFERENCES [edfi].[GradeLevelDescriptor] ([GradeLevelDescriptorId]),
    --CONSTRAINT [FK_CourseTranscript_MethodCreditEarnedType_MethodCreditEarnedTypeId] FOREIGN KEY ([MethodCreditEarnedTypeId]) REFERENCES [edfi].[MethodCreditEarnedType] ([MethodCreditEarnedTypeId]),
   -- CONSTRAINT [FK_CourseTranscript_StudentAcademicRecord_StudentUSI] FOREIGN KEY ([StudentUSI], [EducationOrganizationId], [SchoolYear], [TermTypeId]) REFERENCES [edfi].[StudentAcademicRecord] ([StudentUSI], [EducationOrganizationId], [SchoolYear], [TermTypeId])
);