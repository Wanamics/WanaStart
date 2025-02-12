// from codeunit 10828 "Data Check FEC" implements "Audit File Export Data Check"

// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
// namespace Microsoft.Finance.AuditFileExport;
namespace Wanamics.Start.MergeAndAcquisition;

using Microsoft.Foundation.Company;
using Microsoft.Finance.AuditFileExport;

codeunit 87138 "Export Data Check M&A" implements "Audit File Export Data Check"
{
    Access = Internal;

    procedure CheckDataToExport(var AuditFileExportHeader: Record "Audit File Export Header"): enum "Audit Data Check Status"
    begin
    end;

    procedure CheckAuditDocReadyToExport(var AuditFileExportHeader: Record "Audit File Export Header"): enum "Audit Data Check Status"
    var
        CompanyInformation: Record "Company Information";
    begin
        AuditFileExportHeader.TestField("Starting Date");
        AuditFileExportHeader.TestField("Ending Date");

        CompanyInformation.Get();
        CompanyInformation.TestField("Registration No.");

        exit("Audit Data Check Status"::Passed);
    end;
}
