﻿CREATE TABLE [edfiV3].[StudentCTEProgramAssociationCTEProgram] (
    [ApiSchoolYear]	   SMALLINT NOT NULL,
    [BeginDate]                      DATE           NOT NULL,
    [CareerPathwayDescriptorId]      INT            NOT NULL,
    [EducationOrganizationId]        INT            NOT NULL,
    [ProgramEducationOrganizationId] INT            NOT NULL,
    [ProgramName]                    NVARCHAR (60)  NOT NULL,
    [ProgramTypeDescriptorId]        INT            NOT NULL,
    [StudentUSI]                     INT            NOT NULL,
    [CIPCode]                        NVARCHAR (120) NULL,
    [PrimaryCTEProgramIndicator]     BIT            NULL,
    [CTEProgramCompletionIndicator]  BIT            NULL,
    [CreateDate]                     DATETIME2 (7)       NOT NULL,
    CONSTRAINT [V3_StudentCTEProgramAssociationCTEProgram_PK] PRIMARY KEY CLUSTERED ([ApiSchoolYear] Asc, [EducationOrganizationId] ASC, [StudentUSI] ASC, [BeginDate] ASC, [CareerPathwayDescriptorId] ASC, [ProgramEducationOrganizationId] ASC, [ProgramName] ASC, [ProgramTypeDescriptorId] ASC),
    CONSTRAINT [V3_FK_StudentCTEProgramAssociationCTEProgram_CareerPathwayDescriptor] FOREIGN KEY ([CareerPathwayDescriptorId]) REFERENCES [edfiV3].[CareerPathwayDescriptor] ([CareerPathwayDescriptorId]),
    CONSTRAINT [V3_FK_StudentCTEProgramAssociationCTEProgram_StudentCTEProgramAssociation] FOREIGN KEY ([ApiSchoolYear], [EducationOrganizationId], [StudentUSI], [BeginDate], [ProgramEducationOrganizationId], [ProgramName], [ProgramTypeDescriptorId]) REFERENCES [edfiV3].[StudentCTEProgramAssociation] ([ApiSchoolYear], [EducationOrganizationId], [StudentUSI], [BeginDate], [ProgramEducationOrganizationId], [ProgramName], [ProgramTypeDescriptorId]) ON DELETE CASCADE
);
