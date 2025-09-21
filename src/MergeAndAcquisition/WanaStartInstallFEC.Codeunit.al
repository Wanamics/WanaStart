// from codeunit 10829 "Install FEC"
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
// namespace Microsoft.Finance.AuditFileExport;
namespace Wanamics.Start.MergeAndAcquisition;

using Microsoft.Finance.AuditFileExport;

codeunit 87139 "WanaStart Install M&A"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        AuditFileExportSetup: Record "Audit File Export Setup";
        AuditFileExportFormatSetup: Record "Audit File Export Format Setup";
        AuditFileExportFormat: Enum "Audit File Export Format";
        AppInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(AppInfo);
        if (AppInfo.DataVersion() <> Version.Create('0.0.0.0')) then
            exit;

        AuditFileExportSetup.InitSetup(AuditFileExportFormat::WanaMerge);
        AuditFileExportFormatSetup.InitSetup(AuditFileExportFormat::WanaMerge, '', false);
    end;
}
