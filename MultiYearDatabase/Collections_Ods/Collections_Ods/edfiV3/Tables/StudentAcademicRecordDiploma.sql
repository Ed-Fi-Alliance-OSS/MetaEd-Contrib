﻿CREATE TABLE [edfiV3].[StudentAcademicRecordDiploma] (
    [ApiSchoolYear]	   SMALLINT NOT NULL,
	[DiplomaAwardDate]                DATE           NOT NULL,
    [DiplomaTypeDescriptorId]         INT            NOT NULL,
    [EducationOrganizationId]         INT            NOT NULL,
    [SchoolYear]                      SMALLINT       NOT NULL,
    [StudentUSI]                      INT            NOT NULL,
    [TermDescriptorId]                INT            NOT NULL,
    [AchievementTitle]                NVARCHAR (60)  NULL,
    [AchievementCategoryDescriptorId] INT            NULL,
    [AchievementCategorySystem]       NVARCHAR (60)  NULL,
    [IssuerName]                      NVARCHAR (150) NULL,
    [IssuerOriginURL]                 NVARCHAR (255) NULL,
    [Criteria]                        NVARCHAR (150) NULL,
    [CriteriaURL]                     NVARCHAR (255) NULL,
    [EvidenceStatement]               NVARCHAR (150) NULL,
    [ImageURL]                        NVARCHAR (255) NULL,
    [DiplomaLevelDescriptorId]        INT            NULL,
    [CTECompleter]                    BIT            NULL,
    [DiplomaDescription]              NVARCHAR (80)  NULL,
    [DiplomaAwardExpiresDate]         DATE           NULL,
    [CreateDate]                      DATETIME2 (7)       NOT NULL,
	CONSTRAINT [V3_StudentAcademicRecordDiploma_PK] PRIMARY KEY CLUSTERED ([ApiSchoolYear] ASC, [EducationOrganizationId] ASC, [SchoolYear] ASC, [StudentUSI] ASC, [TermDescriptorId] ASC, [DiplomaAwardDate] ASC, [DiplomaTypeDescriptorId] ASC),
    CONSTRAINT [V3_FK_StudentAcademicRecordDiploma_AchievementCategoryDescriptor] FOREIGN KEY ([AchievementCategoryDescriptorId]) REFERENCES [edfiV3].[AchievementCategoryDescriptor] ([AchievementCategoryDescriptorId]),
    --CONSTRAINT [V3_FK_StudentAcademicRecordDiploma_DiplomaLevelDescriptor] FOREIGN KEY ([DiplomaLevelDescriptorId]) REFERENCES [edfiV3].[DiplomaLevelDescriptor] ([DiplomaLevelDescriptorId]),
    CONSTRAINT [V3_FK_StudentAcademicRecordDiploma_DiplomaTypeDescriptor] FOREIGN KEY ([DiplomaTypeDescriptorId]) REFERENCES [edfiV3].[DiplomaTypeDescriptor] ([DiplomaTypeDescriptorId]),
    CONSTRAINT [V3_FK_StudentAcademicRecordDiploma_StudentAcademicRecord] FOREIGN KEY ([ApiSchoolYear], [EducationOrganizationId],[Schoolyear], [StudentUSI], [TermDescriptorId]) REFERENCES [edfiV3].[StudentAcademicRecord] ([ApiSchoolYear], [EducationOrganizationId],[SchoolYear],  [StudentUSI], [TermDescriptorId]) ON DELETE CASCADE
);