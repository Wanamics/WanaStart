// from enumextension 10826 "Audit File Export Format FEC" extends "Audit File Export Format"

// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
// namespace Microsoft.Finance.AuditFileExport;
namespace Wanamics.Start.MergeAndAcquisition;

using Microsoft.Finance.AuditFileExport;

enumextension 87136 "Export Format M&A" extends "Audit File Export Format"
{
    value(87130; WanaMerge)
    {
        Caption = 'WanaMerge';
        Implementation = "Audit File Export Data Handling" = "Export Data Handling M&A",
                         "Audit File Export Data Check" = "Export Data Check M&A"
                         ;
    }
}
